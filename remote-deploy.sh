#!/bin/bash

# Script para Deploy Remoto via SSH
# Autor: Gerado automaticamente
# Descrição: Copia e instala as ferramentas em servidores remotos via SSH

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
REMOTE_DIR="${REMOTE_DIR:-/opt/portainer-tool}"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"

# Lista de arquivos para copiar
FILES_TO_COPY=(
    "docker-disk-analyzer.sh"
    "docker-log-cleanup.sh"
    "docker-cleanup.sh"
    "docker-monitor.sh"
    "configure-log-limits.sh"
    "manutencao-semanal.sh"
    "README.md"
    "QUICK-START.md"
    "cron-example.txt"
    "docker-compose-examples.yml"
)

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Deploy Remoto de Ferramentas Docker/Portainer             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES] HOST1 [HOST2 HOST3 ...]"
    echo ""
    echo "Copia e instala as ferramentas em servidores remotos via SSH"
    echo ""
    echo "Argumentos:"
    echo "  HOST                    Endereço do servidor (ex: 192.168.1.100)"
    echo ""
    echo "Opções:"
    echo "  -u, --user USER         Usuário SSH (padrão: root)"
    echo "  -p, --port PORT         Porta SSH (padrão: 22)"
    echo "  -k, --key PATH          Caminho para chave SSH privada"
    echo "  -d, --dir DIR           Diretório remoto (padrão: /opt/portainer-tool)"
    echo "  -r, --run               Executa análise após instalação"
    echo "  -h, --help              Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 192.168.1.100"
    echo "  $0 -u admin -k ~/.ssh/id_rsa server1.com server2.com"
    echo "  $0 --run 192.168.1.100 192.168.1.101"
    echo ""
    echo "Variáveis de ambiente:"
    echo "  SSH_USER                Usuário SSH"
    echo "  SSH_PORT                Porta SSH"
    echo "  SSH_KEY                 Chave SSH"
    echo "  REMOTE_DIR              Diretório remoto"
    echo ""
}

# Parse argumentos
RUN_ANALYSIS=false
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
        -r|--run)
            RUN_ANALYSIS=true
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
            HOSTS+=("$1")
            shift
            ;;
    esac
done

# Verifica se hosts foram fornecidos
if [ ${#HOSTS[@]} -eq 0 ]; then
    echo -e "${RED}Erro: Nenhum host especificado${NC}"
    echo ""
    show_help
    exit 1
fi

# Monta comando SSH
SSH_CMD="ssh -p $SSH_PORT"
SCP_CMD="scp -P $SSH_PORT"

if [ -n "$SSH_KEY" ]; then
    SSH_CMD="$SSH_CMD -i $SSH_KEY"
    SCP_CMD="$SCP_CMD -i $SSH_KEY"
fi

# Função para testar conexão SSH
test_connection() {
    local host=$1
    echo -e "${CYAN}Testando conexão com $host...${NC}"
    
    if $SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$host" "echo 2>&1" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Conexão bem-sucedida${NC}"
        return 0
    else
        echo -e "${RED}✗ Falha na conexão${NC}"
        return 1
    fi
}

# Função para criar diretório remoto
create_remote_dir() {
    local host=$1
    echo -e "${CYAN}Criando diretório remoto...${NC}"
    
    $SSH_CMD "$SSH_USER@$host" "mkdir -p $REMOTE_DIR" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Diretório criado: $REMOTE_DIR${NC}"
        return 0
    else
        echo -e "${RED}✗ Falha ao criar diretório${NC}"
        return 1
    fi
}

# Função para copiar arquivos
copy_files() {
    local host=$1
    echo -e "${CYAN}Copiando arquivos...${NC}"
    
    local copied=0
    local failed=0
    
    for file in "${FILES_TO_COPY[@]}"; do
        if [ -f "$LOCAL_DIR/$file" ]; then
            echo -n "  Copiando $file... "
            if $SCP_CMD "$LOCAL_DIR/$file" "$SSH_USER@$host:$REMOTE_DIR/" >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
                ((copied++))
            else
                echo -e "${RED}✗${NC}"
                ((failed++))
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}Arquivos copiados: $copied${NC}"
    if [ $failed -gt 0 ]; then
        echo -e "${RED}Arquivos com falha: $failed${NC}"
    fi
    
    return 0
}

# Função para configurar permissões remotas
set_remote_permissions() {
    local host=$1
    echo -e "${CYAN}Configurando permissões...${NC}"
    
    $SSH_CMD "$SSH_USER@$host" "chmod +x $REMOTE_DIR/*.sh" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Permissões configuradas${NC}"
        return 0
    else
        echo -e "${RED}✗ Falha ao configurar permissões${NC}"
        return 1
    fi
}

# Função para executar análise remota
run_remote_analysis() {
    local host=$1
    echo -e "${CYAN}Executando análise inicial...${NC}"
    echo ""
    
    $SSH_CMD "$SSH_USER@$host" "$REMOTE_DIR/docker-disk-analyzer.sh" 2>&1
    
    echo ""
}

# Função para deploy em um host
deploy_to_host() {
    local host=$1
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Deploy para: ${YELLOW}$host${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Testa conexão
    if ! test_connection "$host"; then
        echo -e "${RED}Pulando $host devido a erro de conexão${NC}"
        echo ""
        return 1
    fi
    echo ""
    
    # Cria diretório
    if ! create_remote_dir "$host"; then
        echo -e "${RED}Pulando $host devido a erro ao criar diretório${NC}"
        echo ""
        return 1
    fi
    echo ""
    
    # Copia arquivos
    if ! copy_files "$host"; then
        echo -e "${RED}Erro ao copiar arquivos para $host${NC}"
        echo ""
        return 1
    fi
    echo ""
    
    # Configura permissões
    if ! set_remote_permissions "$host"; then
        echo -e "${RED}Erro ao configurar permissões em $host${NC}"
        echo ""
        return 1
    fi
    echo ""
    
    # Executa análise se solicitado
    if [ "$RUN_ANALYSIS" = true ]; then
        run_remote_analysis "$host"
    fi
    
    echo -e "${GREEN}✓ Deploy concluído em $host${NC}"
    echo -e "${CYAN}Arquivos instalados em: ${YELLOW}$REMOTE_DIR${NC}"
    echo ""
    
    return 0
}

# Verifica se diretório local existe
if [ ! -d "$LOCAL_DIR" ]; then
    echo -e "${RED}Erro: Diretório local não encontrado: $LOCAL_DIR${NC}"
    exit 1
fi

# Informações do deploy
echo -e "${CYAN}Configuração do Deploy:${NC}"
echo -e "  Diretório local: ${YELLOW}$LOCAL_DIR${NC}"
echo -e "  Diretório remoto: ${YELLOW}$REMOTE_DIR${NC}"
echo -e "  Usuário SSH: ${YELLOW}$SSH_USER${NC}"
echo -e "  Porta SSH: ${YELLOW}$SSH_PORT${NC}"
if [ -n "$SSH_KEY" ]; then
    echo -e "  Chave SSH: ${YELLOW}$SSH_KEY${NC}"
fi
echo -e "  Hosts: ${YELLOW}${HOSTS[*]}${NC}"
echo ""

# Confirmação
read -p "Continuar com o deploy? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Deploy cancelado."
    exit 0
fi
echo ""

# Deploy para cada host
SUCCESS_COUNT=0
FAIL_COUNT=0

for host in "${HOSTS[@]}"; do
    if deploy_to_host "$host"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

# Resumo final
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      Resumo do Deploy                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Hosts com sucesso: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Hosts com falha: $FAIL_COUNT${NC}"
fi
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${CYAN}Para executar remotamente:${NC}"
    echo "  ssh $SSH_USER@HOST 'cd $REMOTE_DIR && ./docker-disk-analyzer.sh'"
    echo ""
fi

exit 0


