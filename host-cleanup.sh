#!/bin/bash

# Script para Limpeza de Logs e Cache do Host Linux
# Autor: Gerado automaticamente
# Descrição: Limpa logs do sistema, journal, cache de pacotes, etc.

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações padrão
DRY_RUN=false
JOURNAL_SIZE="100M"
LOG_DAYS=7
FORCE=false

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Limpa logs e cache do sistema host Linux"
    echo ""
    echo "Opções:"
    echo "  -d, --dry-run              Mostra o que seria feito sem executar"
    echo "  -j, --journal-size SIZE    Tamanho máximo do journal (padrão: 100M)"
    echo "  -l, --log-days DIAS        Remove logs com mais de X dias (padrão: 7)"
    echo "  -f, --force                Não pede confirmação"
    echo "  -h, --help                 Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --dry-run               # Teste sem executar"
    echo "  $0                         # Limpeza padrão"
    echo "  $0 --journal-size 50M      # Journal com max 50MB"
    echo "  $0 --log-days 30           # Remove logs > 30 dias"
    echo "  $0 --force                 # Sem confirmação"
    echo ""
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -j|--journal-size)
            JOURNAL_SIZE="$2"
            shift 2
            ;;
        -l|--log-days)
            LOG_DAYS="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Limpeza de Logs e Cache do Host                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}MODO DRY-RUN: Nenhuma alteração será feita${NC}"
    echo ""
fi

# Verifica se está rodando com sudo
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then 
    echo -e "${RED}Este script precisa ser executado com sudo${NC}"
    echo "Execute: sudo $0"
    exit 1
fi

# Função para executar ou simular
execute_or_simulate() {
    local description=$1
    local command=$2
    local show_output=${3:-true}
    
    echo -e "${CYAN}$description${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Comando: $command"
        echo ""
    else
        if [ "$show_output" = true ]; then
            eval "$command"
        else
            eval "$command" >/dev/null 2>&1
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Concluído${NC}"
        else
            echo -e "${YELLOW}⚠ Aviso: Comando retornou erro (pode ser normal)${NC}"
        fi
        echo ""
    fi
}

# Mostra estatísticas antes
echo -e "${GREEN}Estado ANTES da limpeza:${NC}"
df -h / | grep -E "Filesystem|/"
echo ""

# Confirmação
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Esta operação irá limpar:${NC}"
    echo "  - Logs do journal (systemd)"
    echo "  - Logs antigos em /var/log"
    echo "  - Cache de pacotes (apt/yum)"
    echo "  - Arquivos temporários"
    echo "  - Logs compactados antigos"
    echo ""
    echo -e "${RED}ATENÇÃO: Esta ação não pode ser desfeita!${NC}"
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
    echo ""
fi

# 1. Limpar logs do journal
execute_or_simulate \
    "1. Limpando logs do journal (systemd)..." \
    "journalctl --vacuum-size=$JOURNAL_SIZE"

# 2. Remover logs antigos em /var/log
execute_or_simulate \
    "2. Removendo logs compactados com mais de $LOG_DAYS dias..." \
    "find /var/log -name '*.gz' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

execute_or_simulate \
    "3. Removendo logs rotacionados antigos..." \
    "find /var/log -name '*.log.*' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

execute_or_simulate \
    "4. Removendo logs .old antigos..." \
    "find /var/log -name '*.old' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

# 3. Limpar cache de pacotes
if [ -f "/usr/bin/apt-get" ]; then
    execute_or_simulate \
        "5. Limpando cache do APT..." \
        "apt-get clean && apt-get autoclean"
elif [ -f "/usr/bin/yum" ]; then
    execute_or_simulate \
        "5. Limpando cache do YUM..." \
        "yum clean all"
elif [ -f "/usr/bin/dnf" ]; then
    execute_or_simulate \
        "5. Limpando cache do DNF..." \
        "dnf clean all"
else
    echo -e "${YELLOW}5. Sistema de pacotes não identificado, pulando...${NC}"
    echo ""
fi

# 4. Limpar arquivos temporários
execute_or_simulate \
    "6. Limpando /tmp (arquivos com +7 dias)..." \
    "find /tmp -type f -atime +7 -delete 2>/dev/null || true"

execute_or_simulate \
    "7. Limpando /var/tmp (arquivos com +7 dias)..." \
    "find /var/tmp -type f -atime +7 -delete 2>/dev/null || true"

# 5. Limpar logs específicos conhecidos por crescer muito
execute_or_simulate \
    "8. Truncando logs grandes em /var/log..." \
    "find /var/log -type f -name '*.log' -size +100M -exec truncate -s 0 {} \; 2>/dev/null || true"

# 6. Limpar core dumps (se existirem)
if [ -d "/var/crash" ]; then
    execute_or_simulate \
        "9. Removendo core dumps antigos..." \
        "find /var/crash -type f -mtime +7 -delete 2>/dev/null || true"
fi

# 7. Limpar logs do syslog antigos
execute_or_simulate \
    "10. Removendo syslog antigos..." \
    "find /var/log -name 'syslog.*' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

# 8. Limpar logs do auth antigos
execute_or_simulate \
    "11. Removendo auth.log antigos..." \
    "find /var/log -name 'auth.log.*' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

# 9. Limpar logs do kern antigos
execute_or_simulate \
    "12. Removendo kern.log antigos..." \
    "find /var/log -name 'kern.log.*' -mtime +$LOG_DAYS -delete 2>/dev/null || true"

# Mostra estatísticas depois
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Resultado${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}Estado DEPOIS da limpeza:${NC}"
df -h / | grep -E "Filesystem|/"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Execute sem --dry-run para aplicar as mudanças${NC}"
else
    echo -e "${GREEN}✓ Limpeza concluída!${NC}"
    echo ""
    echo -e "${CYAN}Próximos passos recomendados:${NC}"
    echo "1. Analise novamente: ./host-disk-analyzer.sh"
    echo "2. Configure logrotate para logs automáticos"
    echo "3. Adicione ao cron para limpeza periódica:"
    echo "   0 3 * * 0 $(pwd)/host-cleanup.sh --force"
fi

echo ""

