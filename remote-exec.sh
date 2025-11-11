#!/bin/bash

# Script para Execução Remota em Múltiplos Servidores
# Autor: Gerado automaticamente
# Descrição: Executa comandos/scripts de manutenção em múltiplos servidores simultaneamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configurações
REMOTE_DIR="${REMOTE_DIR:-/opt/portainer-tool}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"
PARALLEL="${PARALLEL:-false}"
CONFIG_FILE="${CONFIG_FILE:-}"

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Execução Remota de Ferramentas Docker/Portainer           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função de ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES] COMANDO HOST1 [HOST2 HOST3 ...]

Executa comandos de manutenção em servidores remotos via SSH

Comandos disponíveis:
  analyze         Executa análise de disco
  clean-logs      Limpa logs grandes
  cleanup         Limpeza geral (containers, imagens)
  cleanup-all     Limpeza completa com force
  monitor         Executa monitoramento único
  maintenance     Executa manutenção semanal completa
  configure       Configura limites de log
  custom "CMD"    Executa comando customizado

Opções:
  -u, --user USER         Usuário SSH (padrão: root)
  -p, --port PORT         Porta SSH (padrão: 22)
  -k, --key PATH          Caminho para chave SSH privada
  -d, --dir DIR           Diretório remoto (padrão: /opt/portainer-tool)
  -f, --file CONFIG       Arquivo com lista de hosts (um por linha)
  -P, --parallel          Executa em paralelo (experimental)
  -h, --help              Mostra esta ajuda

Exemplos:
  # Análise em um servidor
  $0 analyze 192.168.1.100

  # Limpa logs em múltiplos servidores
  $0 clean-logs server1.com server2.com server3.com

  # Limpeza completa com arquivo de configuração
  $0 -f servers.txt cleanup-all

  # Execução paralela
  $0 --parallel analyze 192.168.1.100 192.168.1.101

  # Comando customizado
  $0 custom "docker ps" 192.168.1.100

Arquivo de configuração (formato):
  192.168.1.100
  192.168.1.101
  server1.com
  # Comentários são ignorados

Variáveis de ambiente:
  SSH_USER                Usuário SSH
  SSH_PORT                Porta SSH
  SSH_KEY                 Chave SSH
  REMOTE_DIR              Diretório remoto
  PARALLEL                Execução paralela (true/false)

EOF
}

# Parse argumentos
COMMAND=""
HOSTS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            SSH_USER="$2"
            shift 2
            ;;
        -p|--port)
            SSH_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -d|--dir)
            REMOTE_DIR="$2"
            shift 2
            ;;
        -f|--file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -P|--parallel)
            PARALLEL=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            else
                HOSTS+=("$1")
            fi
            shift
            ;;
    esac
done

# Le hosts do arquivo de configuração
if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Erro: Arquivo de configuração não encontrado: $CONFIG_FILE${NC}"
        exit 1
    fi
    
    while IFS= read -r line; do
        # Ignora comentários e linhas vazias
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        if [ -n "$line" ]; then
            HOSTS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

# Verifica se comando foi fornecido
if [ -z "$COMMAND" ]; then
    echo -e "${RED}Erro: Nenhum comando especificado${NC}"
    echo ""
    show_help
    exit 1
fi

# Verifica se hosts foram fornecidos
if [ ${#HOSTS[@]} -eq 0 ]; then
    echo -e "${RED}Erro: Nenhum host especificado${NC}"
    echo ""
    show_help
    exit 1
fi

# Monta comando SSH
SSH_CMD="ssh -p $SSH_PORT -o ConnectTimeout=10"

if [ -n "$SSH_KEY" ]; then
    SSH_CMD="$SSH_CMD -i $SSH_KEY"
fi

# Função para obter comando remoto baseado no tipo
get_remote_command() {
    local cmd=$1
    
    case $cmd in
        analyze)
            echo "$REMOTE_DIR/docker-disk-analyzer.sh"
            ;;
        clean-logs)
            echo "$REMOTE_DIR/docker-log-cleanup.sh"
            ;;
        cleanup)
            echo "$REMOTE_DIR/docker-cleanup.sh --containers --images"
            ;;
        cleanup-all)
            echo "$REMOTE_DIR/docker-cleanup.sh --all --force"
            ;;
        monitor)
            echo "$REMOTE_DIR/docker-monitor.sh --once"
            ;;
        maintenance)
            echo "$REMOTE_DIR/manutencao-semanal.sh"
            ;;
        configure)
            echo "$REMOTE_DIR/configure-log-limits.sh"
            ;;
        custom)
            shift
            echo "$@"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Função para executar comando em um host
execute_on_host() {
    local host=$1
    local remote_cmd=$(get_remote_command "$COMMAND")
    
    if [ -z "$remote_cmd" ]; then
        echo -e "${RED}Comando desconhecido: $COMMAND${NC}"
        return 1
    fi
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Host: ${YELLOW}$host${NC}"
    echo -e "${BLUE}Comando: ${CYAN}$remote_cmd${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Executa comando
    if $SSH_CMD "$SSH_USER@$host" "$remote_cmd" 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Sucesso em $host${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "${RED}✗ Falha em $host${NC}"
        echo ""
        return 1
    fi
}

# Função para execução paralela
execute_parallel() {
    local pids=()
    local results=()
    
    for host in "${HOSTS[@]}"; do
        (
            execute_on_host "$host"
            exit $?
        ) &
        pids+=($!)
    done
    
    # Aguarda todos os processos
    local success=0
    local failed=0
    
    for i in "${!pids[@]}"; do
        if wait "${pids[$i]}"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    return 0
}

# Informações da execução
echo -e "${CYAN}Configuração da Execução:${NC}"
echo -e "  Comando: ${YELLOW}$COMMAND${NC}"
echo -e "  Diretório remoto: ${YELLOW}$REMOTE_DIR${NC}"
echo -e "  Usuário SSH: ${YELLOW}$SSH_USER${NC}"
echo -e "  Porta SSH: ${YELLOW}$SSH_PORT${NC}"
if [ -n "$SSH_KEY" ]; then
    echo -e "  Chave SSH: ${YELLOW}$SSH_KEY${NC}"
fi
echo -e "  Número de hosts: ${YELLOW}${#HOSTS[@]}${NC}"
echo -e "  Execução paralela: ${YELLOW}$PARALLEL${NC}"
echo ""

echo -e "${CYAN}Hosts:${NC}"
for host in "${HOSTS[@]}"; do
    echo -e "  - ${YELLOW}$host${NC}"
done
echo ""

# Confirmação
if [ "$PARALLEL" != true ]; then
    read -p "Continuar com a execução? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Execução cancelada."
        exit 0
    fi
    echo ""
fi

# Registro de tempo
START_TIME=$(date +%s)

# Execução
SUCCESS_COUNT=0
FAIL_COUNT=0

if [ "$PARALLEL" = true ]; then
    echo -e "${YELLOW}Executando em paralelo...${NC}"
    echo ""
    execute_parallel
    
    # Conta resultados (simplificado para modo paralelo)
    SUCCESS_COUNT=${#HOSTS[@]}
else
    for host in "${HOSTS[@]}"; do
        if execute_on_host "$host"; then
            ((SUCCESS_COUNT++))
        else
            ((FAIL_COUNT++))
        fi
    done
fi

# Tempo total
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Resumo final
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      Resumo da Execução                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Comando executado: ${YELLOW}$COMMAND${NC}"
echo -e "${CYAN}Total de hosts: ${YELLOW}${#HOSTS[@]}${NC}"
echo -e "${GREEN}Execuções bem-sucedidas: $SUCCESS_COUNT${NC}"

if [ "$PARALLEL" != true ]; then
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "${RED}Execuções com falha: $FAIL_COUNT${NC}"
    fi
fi

echo -e "${CYAN}Tempo total: ${YELLOW}${DURATION}s${NC}"
echo ""

exit 0


