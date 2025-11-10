#!/bin/bash

# Script de manutenção semanal automatizada
# Autor: Gerado automaticamente
# Descrição: Executa análise, limpeza e gera relatórios

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/docker-maintenance-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$LOG_DIR/manutencao-$TIMESTAMP.log"

# Cria diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para logar mensagens
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$REPORT_FILE"
}

# Função para executar comando e logar
execute_and_log() {
    local description=$1
    local command=$2
    
    echo "" | tee -a "$REPORT_FILE"
    log_message "=================================================="
    log_message "$description"
    log_message "=================================================="
    echo "" | tee -a "$REPORT_FILE"
    
    eval "$command" 2>&1 | tee -a "$REPORT_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_message "✓ $description - SUCESSO"
    else
        log_message "✗ $description - ERRO"
        return 1
    fi
}

# Início
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Manutenção Semanal Docker/Portainer                      ║${NC}"
echo -e "${BLUE}║           $(date '+%d/%m/%Y %H:%M:%S')                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_message "Iniciando manutenção semanal do Docker/Portainer"
log_message "Relatório será salvo em: $REPORT_FILE"
echo ""

# 1. Análise ANTES da limpeza
execute_and_log "ETAPA 1/5: Análise inicial do sistema" \
    "$SCRIPT_DIR/docker-disk-analyzer.sh"

# Salva estatísticas antes
BEFORE_STATS=$(docker system df 2>/dev/null)
log_message "Estatísticas ANTES da limpeza:"
echo "$BEFORE_STATS" | tee -a "$REPORT_FILE"

# 2. Limpeza de logs
execute_and_log "ETAPA 2/5: Limpeza de logs de containers" \
    "$SCRIPT_DIR/docker-log-cleanup.sh --size 50M"

# 3. Limpeza de containers parados
execute_and_log "ETAPA 3/5: Remoção de containers parados" \
    "$SCRIPT_DIR/docker-cleanup.sh --containers --force"

# 4. Limpeza de imagens não utilizadas
execute_and_log "ETAPA 4/5: Remoção de imagens não utilizadas" \
    "$SCRIPT_DIR/docker-cleanup.sh --images --force"

# 5. Análise DEPOIS da limpeza
execute_and_log "ETAPA 5/5: Análise final do sistema" \
    "$SCRIPT_DIR/docker-disk-analyzer.sh"

# Salva estatísticas depois
AFTER_STATS=$(docker system df 2>/dev/null)
log_message "Estatísticas DEPOIS da limpeza:"
echo "$AFTER_STATS" | tee -a "$REPORT_FILE"

# Resumo
echo "" | tee -a "$REPORT_FILE"
log_message "=================================================="
log_message "RESUMO DA MANUTENÇÃO"
log_message "=================================================="
echo "" | tee -a "$REPORT_FILE"

# Calcula espaço liberado (simplificado)
log_message "Comparação antes/depois:"
echo "" | tee -a "$REPORT_FILE"
echo "ANTES:" | tee -a "$REPORT_FILE"
echo "$BEFORE_STATS" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "DEPOIS:" | tee -a "$REPORT_FILE"
echo "$AFTER_STATS" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

log_message "Manutenção concluída com sucesso!"
log_message "Relatório completo salvo em: $REPORT_FILE"

# Mantém apenas os últimos 30 relatórios
cd "$LOG_DIR"
ls -t manutencao-*.log 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true

log_message "Limpeza de relatórios antigos concluída (mantidos últimos 30)"

# Envia notificação (opcional)
# Descomente e configure se desejar receber notificações
# if command -v mail &> /dev/null; then
#     cat "$REPORT_FILE" | mail -s "Relatório de Manutenção Docker - $TIMESTAMP" seu-email@example.com
#     log_message "Relatório enviado por email"
# fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Manutenção Finalizada!                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Relatório: ${YELLOW}$REPORT_FILE${NC}"
echo ""

