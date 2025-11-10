#!/bin/bash

# Script para Análise de Disco do Host Linux
# Autor: Gerado automaticamente
# Descrição: Identifica o que está ocupando espaço no sistema host

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Análise de Disco do Host Linux${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Uso geral dos discos
echo -e "${GREEN}[1] Uso Geral dos Discos:${NC}"
df -h | grep -E "Filesystem|/dev/"
echo ""

# 2. Top 10 diretórios que ocupam mais espaço na raiz
echo -e "${GREEN}[2] Top 10 Diretórios Maiores (Raiz):${NC}"
echo "Analisando... (pode demorar alguns segundos)"
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -11 | tail -10
echo ""

# 3. Análise de /var (onde ficam logs)
echo -e "${GREEN}[3] Análise do /var:${NC}"
if [ -d "/var" ]; then
    sudo du -h --max-depth=1 /var 2>/dev/null | sort -rh | head -10
else
    echo "Diretório /var não encontrado"
fi
echo ""

# 4. Logs em /var/log
echo -e "${GREEN}[4] Top 10 Maiores Logs em /var/log:${NC}"
if [ -d "/var/log" ]; then
    sudo find /var/log -type f -name "*.log*" -o -name "*.gz" 2>/dev/null | while read file; do
        size=$(sudo du -h "$file" 2>/dev/null | cut -f1)
        echo "$size|$file"
    done | sort -rh | head -10 | column -t -s'|'
else
    echo "Diretório /var/log não encontrado"
fi
echo ""

# 5. Journal logs (systemd)
echo -e "${GREEN}[5] Tamanho dos Logs do Journal (systemd):${NC}"
if command -v journalctl &> /dev/null; then
    journal_size=$(sudo journalctl --disk-usage 2>/dev/null | grep -oP '\d+\.\d+[MGT]' || echo "N/A")
    echo "Tamanho atual: $journal_size"
    
    if [ "$journal_size" != "N/A" ]; then
        # Extrai número e unidade
        size_value=$(echo "$journal_size" | grep -oP '\d+\.\d+')
        size_unit=$(echo "$journal_size" | grep -oP '[MGT]')
        
        # Alerta se > 1GB
        if [ "$size_unit" = "G" ]; then
            echo -e "${YELLOW}⚠ Logs do journal estão grandes!${NC}"
            echo -e "${YELLOW}  Use: sudo journalctl --vacuum-size=100M${NC}"
        fi
    fi
else
    echo "journalctl não disponível (sistema não usa systemd)"
fi
echo ""

# 6. Docker (se existir)
echo -e "${GREEN}[6] Análise do Docker (se instalado):${NC}"
if [ -d "/var/lib/docker" ]; then
    docker_size=$(sudo du -sh /var/lib/docker 2>/dev/null | cut -f1)
    echo "Tamanho do /var/lib/docker: $docker_size"
    echo ""
    
    # Detalhamento
    sudo du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -10
else
    echo "Docker não instalado ou /var/lib/docker não existe"
fi
echo ""

# 7. Logs do Docker (containers)
echo -e "${GREEN}[7] Logs dos Containers Docker:${NC}"
if [ -d "/var/lib/docker/containers" ]; then
    total_logs_size=0
    echo "Container Log | Tamanho"
    echo "------------------------------------"
    
    sudo find /var/lib/docker/containers -name "*-json.log" 2>/dev/null | while read log; do
        if [ -f "$log" ]; then
            size_bytes=$(sudo stat -c%s "$log" 2>/dev/null || echo "0")
            size_human=$(sudo du -h "$log" 2>/dev/null | cut -f1)
            container_id=$(basename $(dirname "$log"))
            short_id=${container_id:0:12}
            
            echo "$short_id | $size_human"
        fi
    done | sort -t'|' -k2 -rh | head -10
else
    echo "Logs de containers não encontrados"
fi
echo ""

# 8. Arquivos grandes no sistema
echo -e "${GREEN}[8] Top 20 Maiores Arquivos do Sistema:${NC}"
echo "Procurando arquivos > 100MB... (pode demorar)"
sudo find / -type f -size +100M 2>/dev/null | while read file; do
    size=$(sudo du -h "$file" 2>/dev/null | cut -f1)
    echo "$size|$file"
done | sort -rh | head -20 | column -t -s'|'
echo ""

# 9. Cache do apt/yum
echo -e "${GREEN}[9] Cache de Pacotes:${NC}"
if [ -d "/var/cache/apt" ]; then
    apt_cache=$(sudo du -sh /var/cache/apt 2>/dev/null | cut -f1)
    echo "APT cache: $apt_cache"
    echo -e "${YELLOW}  Para limpar: sudo apt-get clean${NC}"
elif [ -d "/var/cache/yum" ]; then
    yum_cache=$(sudo du -sh /var/cache/yum 2>/dev/null | cut -f1)
    echo "YUM cache: $yum_cache"
    echo -e "${YELLOW}  Para limpar: sudo yum clean all${NC}"
fi
echo ""

# 10. Arquivos temporários
echo -e "${GREEN}[10] Arquivos Temporários:${NC}"
if [ -d "/tmp" ]; then
    tmp_size=$(sudo du -sh /tmp 2>/dev/null | cut -f1)
    echo "/tmp: $tmp_size"
fi
if [ -d "/var/tmp" ]; then
    var_tmp_size=$(sudo du -sh /var/tmp 2>/dev/null | cut -f1)
    echo "/var/tmp: $var_tmp_size"
fi
echo ""

# 11. Logs antigos compactados
echo -e "${GREEN}[11] Logs Antigos Compactados (.gz):${NC}"
if [ -d "/var/log" ]; then
    gz_count=$(sudo find /var/log -name "*.gz" 2>/dev/null | wc -l)
    gz_size=$(sudo du -ch /var/log/*.gz 2>/dev/null | tail -1 | cut -f1)
    echo "Arquivos .gz encontrados: $gz_count"
    echo "Tamanho total: ${gz_size:-0}"
    
    if [ "$gz_count" -gt 10 ]; then
        echo -e "${YELLOW}⚠ Muitos logs antigos compactados${NC}"
        echo -e "${YELLOW}  Considere remover os mais antigos${NC}"
    fi
fi
echo ""

# 12. Resumo e Recomendações
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Resumo e Recomendações${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Calcula uso atual
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$disk_usage" -gt 90 ]; then
    echo -e "${RED}⚠️  CRÍTICO: Disco com ${disk_usage}% de uso!${NC}"
    echo ""
    echo -e "${YELLOW}Ações Imediatas Recomendadas:${NC}"
    echo ""
    echo "1. Limpar logs do journal:"
    echo "   sudo journalctl --vacuum-size=100M"
    echo ""
    echo "2. Limpar logs do Docker:"
    echo "   ./docker-log-cleanup.sh --all"
    echo ""
    echo "3. Limpar cache do sistema:"
    echo "   sudo apt-get clean  # Ubuntu/Debian"
    echo "   sudo yum clean all  # CentOS/RHEL"
    echo ""
    echo "4. Limpar recursos Docker não usados:"
    echo "   ./docker-cleanup.sh --all --force"
    echo ""
    echo "5. Remover logs antigos:"
    echo "   sudo find /var/log -name '*.gz' -mtime +30 -delete"
    echo "   sudo find /var/log -name '*.log.*' -mtime +7 -delete"
    echo ""
    echo "6. Limpar arquivos temporários:"
    echo "   sudo rm -rf /tmp/*"
    echo "   sudo rm -rf /var/tmp/*"
    echo ""
elif [ "$disk_usage" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  ATENÇÃO: Disco com ${disk_usage}% de uso${NC}"
    echo ""
    echo "Considere executar manutenção preventiva."
else
    echo -e "${GREEN}✓ Disco com ${disk_usage}% de uso (OK)${NC}"
fi

echo ""
echo -e "${CYAN}Para limpeza automatizada do host, execute:${NC}"
echo "  ./host-cleanup.sh"
echo ""

