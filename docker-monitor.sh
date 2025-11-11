#!/bin/bash

# Script de monitoramento contínuo do Docker
# Autor: Gerado automaticamente
# Descrição: Monitora uso de disco, logs e recursos do Docker em tempo real

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações padrão
INTERVAL=5
LOG_THRESHOLD=100 # MB
DISK_THRESHOLD=80 # Porcentagem
ALERT_FILE="$HOME/.docker-monitor-alerts.log"

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -i, --interval SEGUNDOS    Intervalo entre atualizações (padrão: 5)"
    echo "  -l, --log-threshold MB     Alerta para logs maiores que X MB (padrão: 100)"
    echo "  -d, --disk-threshold %     Alerta para uso de disco acima de X% (padrão: 80)"
    echo "  -o, --once                 Executa apenas uma vez (não fica em loop)"
    echo "  -h, --help                 Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                         # Monitora com configurações padrão"
    echo "  $0 --interval 10           # Atualiza a cada 10 segundos"
    echo "  $0 --once                  # Executa uma vez e sai"
    echo ""
}

# Parse argumentos
RUN_ONCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -l|--log-threshold)
            LOG_THRESHOLD="$2"
            shift 2
            ;;
        -d|--disk-threshold)
            DISK_THRESHOLD="$2"
            shift 2
            ;;
        -o|--once)
            RUN_ONCE=true
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

# Função para limpar a tela
clear_screen() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Monitor Docker/Portainer - $(date '+%d/%m/%Y %H:%M:%S')           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para registrar alertas
log_alert() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$ALERT_FILE"
}

# Função para obter uso de CPU e memória de um container
get_container_stats() {
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | tail -n +2
}

# Função principal de monitoramento
monitor() {
    clear_screen
    
    # 1. Status geral do Docker
    echo -e "${CYAN}[1] Status do Sistema Docker:${NC}"
    docker_status=$(docker system df 2>/dev/null || echo "Docker não disponível")
    echo "$docker_status"
    
    # Calcula uso de disco
    total_space=$(echo "$docker_status" | grep "Local Volumes" | awk '{print $4}' | sed 's/GB//g' 2>/dev/null || echo "0")
    if (( $(echo "$total_space > 0" | bc -l 2>/dev/null || echo 0) )); then
        echo ""
        if (( $(echo "$total_space > 50" | bc -l) )); then
            echo -e "${RED}⚠ ALERTA: Uso de disco elevado (${total_space}GB)${NC}"
            log_alert "Uso de disco elevado: ${total_space}GB"
        fi
    fi
    echo ""
    
    # 2. Containers em execução
    echo -e "${CYAN}[2] Containers Ativos ($(docker ps -q | wc -l | xargs)):${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Nenhum container ativo"
    echo ""
    
    # 3. Uso de recursos dos containers
    echo -e "${CYAN}[3] Uso de Recursos (CPU/Memória):${NC}"
    get_container_stats 2>/dev/null || echo "Não foi possível obter estatísticas"
    echo ""
    
    # 4. Logs grandes
    echo -e "${CYAN}[4] Top 5 Maiores Logs:${NC}"
    log_threshold_bytes=$((LOG_THRESHOLD * 1024 * 1024))
    
    docker ps -aq 2>/dev/null | while read container_id; do
        container_name=$(docker inspect --format='{{.Name}}' "$container_id" 2>/dev/null | sed 's/\///')
        log_path=$(docker inspect --format='{{.LogPath}}' "$container_id" 2>/dev/null)
        
        if [ -f "$log_path" ]; then
            log_size_bytes=$(stat -f%z "$log_path" 2>/dev/null || stat -c%s "$log_path" 2>/dev/null || echo "0")
            log_size_mb=$((log_size_bytes / 1024 / 1024))
            
            echo "$log_size_mb|$container_name"
        fi
    done | sort -t'|' -k1 -rn | head -5 | while IFS='|' read size name; do
        if [ "$size" -gt "$LOG_THRESHOLD" ]; then
            echo -e "  ${RED}$name: ${size}MB ⚠${NC}"
            log_alert "Log grande detectado: $name (${size}MB)"
        else
            echo -e "  ${GREEN}$name: ${size}MB${NC}"
        fi
    done
    echo ""
    
    # 5. Containers parados
    stopped_count=$(docker ps -aq -f status=exited 2>/dev/null | wc -l | xargs)
    echo -e "${CYAN}[5] Containers Parados: ${YELLOW}$stopped_count${NC}"
    if [ "$stopped_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Execute: docker-cleanup.sh --containers${NC}"
    fi
    echo ""
    
    # 6. Imagens não utilizadas
    dangling_count=$(docker images -qf dangling=true 2>/dev/null | wc -l | xargs)
    echo -e "${CYAN}[6] Imagens Dangling: ${YELLOW}$dangling_count${NC}"
    if [ "$dangling_count" -gt 5 ]; then
        echo -e "  ${YELLOW}Execute: docker-cleanup.sh --images${NC}"
    fi
    echo ""
    
    # 7. Volumes não utilizados
    unused_volumes=$(docker volume ls -qf dangling=true 2>/dev/null | wc -l | xargs)
    echo -e "${CYAN}[7] Volumes Órfãos: ${YELLOW}$unused_volumes${NC}"
    if [ "$unused_volumes" -gt 0 ]; then
        echo -e "  ${YELLOW}Execute: docker-cleanup.sh --volumes${NC}"
    fi
    echo ""
    
    # 8. Uso de disco do sistema
    echo -e "${CYAN}[8] Uso de Disco do Sistema:${NC}"
    df -h / | tail -1 | awk '{
        use = int($5);
        if (use >= 80) 
            printf "  \033[0;31m%s usado de %s (%.0f%%) ⚠\033[0m\n", $3, $2, use;
        else if (use >= 60)
            printf "  \033[1;33m%s usado de %s (%.0f%%)\033[0m\n", $3, $2, use;
        else
            printf "  \033[0;32m%s usado de %s (%.0f%%)\033[0m\n", $3, $2, use;
    }'
    echo ""
    
    # 9. Últimos alertas
    if [ -f "$ALERT_FILE" ]; then
        echo -e "${CYAN}[9] Últimos Alertas:${NC}"
        tail -3 "$ALERT_FILE" 2>/dev/null | while read line; do
            echo -e "  ${YELLOW}$line${NC}"
        done
        echo ""
    fi
    
    # Rodapé
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    if [ "$RUN_ONCE" = false ]; then
        echo -e "Atualizando a cada ${INTERVAL}s | Pressione ${RED}Ctrl+C${NC} para sair"
        echo -e "Alertas salvos em: ${YELLOW}$ALERT_FILE${NC}"
    fi
    echo ""
}

# Trap para Ctrl+C
trap 'echo -e "\n${GREEN}Monitor finalizado.${NC}\n"; exit 0' INT TERM

# Loop principal
if [ "$RUN_ONCE" = true ]; then
    monitor
else
    while true; do
        monitor
        sleep "$INTERVAL"
    done
fi


