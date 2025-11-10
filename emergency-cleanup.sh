#!/bin/bash

# Script de Limpeza de Emergência - 95% Disco
# Autor: Gerado automaticamente
# Descrição: Executa limpeza completa automática em situações críticas

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verifica sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Este script precisa ser executado com sudo${NC}"
    echo "Execute: sudo $0"
    exit 1
fi

echo -e "${RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║              LIMPEZA DE EMERGÊNCIA - DISCO CRÍTICO                 ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Mostra uso atual
USAGE_BEFORE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
USED_BEFORE=$(df -h / | awk 'NR==2 {print $3}')
AVAIL_BEFORE=$(df -h / | awk 'NR==2 {print $4}')

echo -e "${RED}⚠️  SITUAÇÃO ATUAL:${NC}"
echo -e "   Uso: ${RED}${USAGE_BEFORE}%${NC}"
echo -e "   Usado: ${USED_BEFORE}"
echo -e "   Disponível: ${AVAIL_BEFORE}"
echo ""

if [ "$USAGE_BEFORE" -lt 80 ]; then
    echo -e "${GREEN}Disco com ${USAGE_BEFORE}% de uso. Não é crítico.${NC}"
    echo "Execute este script apenas se o disco estiver > 80%"
    exit 0
fi

echo -e "${YELLOW}Este script irá executar limpeza automática:${NC}"
echo "  1. Logs do journal (systemd)"
echo "  2. Logs antigos do sistema"
echo "  3. Logs dos containers Docker"
echo "  4. Cache de pacotes"
echo "  5. Recursos Docker não usados"
echo "  6. Arquivos temporários"
echo ""
echo -e "${RED}ATENÇÃO: Esta operação não pode ser desfeita!${NC}"
echo ""

read -p "Continuar com a limpeza de emergência? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi
echo ""

# Função para mostrar progresso
show_progress() {
    local step=$1
    local total=$2
    local description=$3
    
    echo -e "${CYAN}[Etapa $step/$total] $description${NC}"
}

# Função para verificar espaço liberado
check_space() {
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local used=$(df -h / | awk 'NR==2 {print $3}')
    local avail=$(df -h / | awk 'NR==2 {print $4}')
    
    echo -e "   Uso atual: ${YELLOW}${usage}%${NC} | Disponível: ${GREEN}${avail}${NC}"
}

echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}INICIANDO LIMPEZA AUTOMÁTICA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ETAPA 1: Journal Logs (maior impacto)
show_progress 1 7 "Limpando logs do journal (systemd)"
if command -v journalctl &> /dev/null; then
    journalctl --vacuum-size=100M >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Journal limpo para max 100MB"
    check_space
else
    echo -e "   ${YELLOW}⊘${NC} Journalctl não disponível"
fi
echo ""

# ETAPA 2: Logs antigos do sistema
show_progress 2 7 "Removendo logs antigos do sistema"

# Logs compactados > 7 dias
removed=$(find /var/log -name "*.gz" -mtime +7 -delete -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $removed arquivos .gz removidos"

# Logs rotacionados > 7 dias
removed=$(find /var/log -name "*.log.*" -mtime +7 -delete -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $removed arquivos .log.* removidos"

# Logs .old
removed=$(find /var/log -name "*.old" -mtime +7 -delete -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $removed arquivos .old removidos"

check_space
echo ""

# ETAPA 3: Logs dos containers Docker
show_progress 3 7 "Limpando logs dos containers Docker"
if [ -d "/var/lib/docker/containers" ]; then
    cleaned=0
    for log in $(find /var/lib/docker/containers -name "*-json.log" -size +100M 2>/dev/null); do
        if [ -f "$log" ]; then
            # Mantém últimas 1000 linhas
            temp=$(mktemp)
            tail -n 1000 "$log" > "$temp" 2>/dev/null || true
            truncate -s 0 "$log" 2>/dev/null || true
            cat "$temp" > "$log" 2>/dev/null || true
            rm -f "$temp"
            ((cleaned++))
        fi
    done
    echo -e "   ${GREEN}✓${NC} $cleaned logs de containers limpos"
    check_space
else
    echo -e "   ${YELLOW}⊘${NC} Docker não encontrado"
fi
echo ""

# ETAPA 4: Cache de pacotes
show_progress 4 7 "Limpando cache de pacotes"
if [ -f "/usr/bin/apt-get" ]; then
    apt-get clean >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Cache APT limpo"
elif [ -f "/usr/bin/yum" ]; then
    yum clean all >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Cache YUM limpo"
elif [ -f "/usr/bin/dnf" ]; then
    dnf clean all >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Cache DNF limpo"
else
    echo -e "   ${YELLOW}⊘${NC} Gerenciador de pacotes não identificado"
fi
check_space
echo ""

# ETAPA 5: Recursos Docker não usados
show_progress 5 7 "Removendo recursos Docker não usados"
if command -v docker &> /dev/null; then
    # Containers parados
    stopped=$(docker ps -aq -f status=exited 2>/dev/null | wc -l)
    if [ "$stopped" -gt 0 ]; then
        docker container prune -f >/dev/null 2>&1
        echo -e "   ${GREEN}✓${NC} $stopped containers parados removidos"
    fi
    
    # Imagens não usadas
    docker image prune -f >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Imagens dangling removidas"
    
    # Networks não usadas
    docker network prune -f >/dev/null 2>&1
    echo -e "   ${GREEN}✓${NC} Networks não usadas removidas"
    
    check_space
else
    echo -e "   ${YELLOW}⊘${NC} Docker não disponível"
fi
echo ""

# ETAPA 6: Arquivos temporários
show_progress 6 7 "Limpando arquivos temporários"

# /tmp
removed=$(find /tmp -type f -atime +7 -delete -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $removed arquivos em /tmp removidos"

# /var/tmp
removed=$(find /var/tmp -type f -atime +7 -delete -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $removed arquivos em /var/tmp removidos"

check_space
echo ""

# ETAPA 7: Logs muito grandes (truncar)
show_progress 7 7 "Truncando logs muito grandes (> 100MB)"
truncated=$(find /var/log -type f -size +100M -exec truncate -s 0 {} \; -print 2>/dev/null | wc -l)
echo -e "   ${GREEN}✓${NC} $truncated logs grandes truncados"
check_space
echo ""

# Resultado final
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}RESULTADO DA LIMPEZA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

USAGE_AFTER=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
USED_AFTER=$(df -h / | awk 'NR==2 {print $3}')
AVAIL_AFTER=$(df -h / | awk 'NR==2 {print $4}')

echo -e "${CYAN}ANTES:${NC}"
echo -e "   Uso: ${RED}${USAGE_BEFORE}%${NC}"
echo -e "   Usado: ${USED_BEFORE}"
echo -e "   Disponível: ${AVAIL_BEFORE}"
echo ""

echo -e "${CYAN}DEPOIS:${NC}"
if [ "$USAGE_AFTER" -lt 80 ]; then
    echo -e "   Uso: ${GREEN}${USAGE_AFTER}%${NC} ✓"
elif [ "$USAGE_AFTER" -lt 90 ]; then
    echo -e "   Uso: ${YELLOW}${USAGE_AFTER}%${NC} ⚠"
else
    echo -e "   Uso: ${RED}${USAGE_AFTER}%${NC} ⚠"
fi
echo -e "   Usado: ${USED_AFTER}"
echo -e "   Disponível: ${GREEN}${AVAIL_AFTER}${NC}"
echo ""

# Calcula melhoria
IMPROVEMENT=$((USAGE_BEFORE - USAGE_AFTER))

if [ "$IMPROVEMENT" -gt 0 ]; then
    echo -e "${GREEN}✓ Liberado ${IMPROVEMENT}% do disco!${NC}"
else
    echo -e "${YELLOW}⚠ Nenhum espaço significativo foi liberado${NC}"
fi
echo ""

# Recomendações finais
if [ "$USAGE_AFTER" -gt 90 ]; then
    echo -e "${RED}⚠️  AINDA CRÍTICO (${USAGE_AFTER}%)${NC}"
    echo ""
    echo -e "${YELLOW}Investigação manual necessária:${NC}"
    echo ""
    echo "1. Identifique os maiores diretórios:"
    echo "   sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10"
    echo ""
    echo "2. Identifique os maiores arquivos:"
    echo "   sudo find / -type f -size +500M 2>/dev/null -exec du -h {} \; | sort -rh"
    echo ""
    echo "3. Considere:"
    echo "   - Mover logs para outro disco"
    echo "   - Remover containers/imagens Docker não essenciais"
    echo "   - Limpar volumes Docker (CUIDADO com dados!)"
    echo "   - Expandir o disco"
    echo ""
elif [ "$USAGE_AFTER" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  ATENÇÃO (${USAGE_AFTER}%)${NC}"
    echo ""
    echo "Ainda acima de 80%. Configure prevenção:"
    echo "  ./configure-log-limits.sh"
    echo ""
else
    echo -e "${GREEN}✓ Situação normalizada (${USAGE_AFTER}%)${NC}"
    echo ""
    echo "Configure prevenção para não acontecer de novo:"
    echo "  ./configure-log-limits.sh"
    echo ""
fi

echo -e "${CYAN}Próximos passos recomendados:${NC}"
echo "1. Análise detalhada: ./host-disk-analyzer.sh"
echo "2. Configure limites: ./configure-log-limits.sh"
echo "3. Automatize limpeza: adicione ao cron"
echo ""

exit 0

