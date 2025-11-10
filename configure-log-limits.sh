#!/bin/bash

# Script para configurar limites de log em daemon do Docker
# Autor: Gerado automaticamente
# Descrição: Configura limites globais de log para prevenir problemas de armazenamento

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DAEMON_FILE="/etc/docker/daemon.json"
MAX_SIZE="10m"
MAX_FILE="3"

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Descrição:"
    echo "  Configura limites de log globais para o Docker daemon."
    echo "  Isso afetará todos os novos containers criados."
    echo ""
    echo "Opções:"
    echo "  -s, --max-size TAMANHO    Tamanho máximo por arquivo de log (padrão: 10m)"
    echo "  -f, --max-files NUM       Número máximo de arquivos de log (padrão: 3)"
    echo "  -h, --help                Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                        # Configura com valores padrão (10m, 3 arquivos)"
    echo "  $0 --max-size 50m         # Configura para 50MB por arquivo"
    echo "  $0 --max-files 5          # Mantém 5 arquivos de log"
    echo ""
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--max-size)
            MAX_SIZE="$2"
            shift 2
            ;;
        -f|--max-files)
            MAX_FILE="$2"
            shift 2
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuração de Limites de Log${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verifica se está rodando no MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}Detectado MacOS${NC}"
    echo ""
    echo -e "${YELLOW}No MacOS com Docker Desktop, a configuração é feita através da interface gráfica:${NC}"
    echo ""
    echo "1. Abra o Docker Desktop"
    echo "2. Vá em Preferences/Settings"
    echo "3. Clique em 'Docker Engine'"
    echo "4. Adicione a seguinte configuração ao JSON:"
    echo ""
    echo "{"
    echo "  \"log-driver\": \"json-file\","
    echo "  \"log-opts\": {"
    echo "    \"max-size\": \"$MAX_SIZE\","
    echo "    \"max-file\": \"$MAX_FILE\""
    echo "  }"
    echo "}"
    echo ""
    echo "5. Clique em 'Apply & Restart'"
    echo ""
    echo -e "${GREEN}Isso limitará os logs de NOVOS containers.${NC}"
    echo -e "${YELLOW}Containers existentes não serão afetados.${NC}"
    echo ""
    exit 0
fi

# Para Linux
echo -e "${GREEN}Configurando limites de log...${NC}"
echo ""

# Backup do arquivo existente
if [ -f "$DAEMON_FILE" ]; then
    echo -e "${YELLOW}Fazendo backup do daemon.json existente...${NC}"
    sudo cp "$DAEMON_FILE" "${DAEMON_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backup criado${NC}"
    echo ""
fi

# Cria ou atualiza a configuração
echo -e "${YELLOW}Criando nova configuração...${NC}"

# Verifica se o arquivo existe e tem conteúdo válido
if [ -f "$DAEMON_FILE" ] && [ -s "$DAEMON_FILE" ]; then
    # Arquivo existe, vamos mesclar a configuração
    temp_file=$(mktemp)
    
    # Usa jq se disponível, senão faz manualmente
    if command -v jq &> /dev/null; then
        sudo jq ". + {\"log-driver\": \"json-file\", \"log-opts\": {\"max-size\": \"$MAX_SIZE\", \"max-file\": \"$MAX_FILE\"}}" "$DAEMON_FILE" > "$temp_file"
        sudo mv "$temp_file" "$DAEMON_FILE"
    else
        echo -e "${YELLOW}jq não encontrado, criando arquivo manualmente...${NC}"
        cat > "$temp_file" << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "$MAX_SIZE",
    "max-file": "$MAX_FILE"
  }
}
EOF
        sudo mv "$temp_file" "$DAEMON_FILE"
    fi
else
    # Arquivo não existe, criar novo
    sudo mkdir -p "$(dirname "$DAEMON_FILE")"
    sudo cat > "$DAEMON_FILE" << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "$MAX_SIZE",
    "max-file": "$MAX_FILE"
  }
}
EOF
fi

echo -e "${GREEN}✓ Configuração atualizada${NC}"
echo ""

# Mostra a configuração
echo -e "${BLUE}Configuração atual em $DAEMON_FILE:${NC}"
sudo cat "$DAEMON_FILE"
echo ""

# Valida o JSON
echo -e "${YELLOW}Validando configuração...${NC}"
if command -v jq &> /dev/null; then
    if sudo jq empty "$DAEMON_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ JSON válido${NC}"
    else
        echo -e "${RED}✗ JSON inválido! Restaurando backup...${NC}"
        sudo mv "${DAEMON_FILE}.backup."* "$DAEMON_FILE"
        exit 1
    fi
else
    echo -e "${YELLOW}jq não disponível, pulando validação${NC}"
fi
echo ""

# Reinicia o Docker
echo -e "${YELLOW}Reiniciando Docker daemon...${NC}"
echo -e "${RED}ATENÇÃO: Isso irá interromper temporariamente todos os containers${NC}"
read -p "Deseja continuar? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    sudo systemctl restart docker
    echo -e "${GREEN}✓ Docker reiniciado${NC}"
    echo ""
    
    # Aguarda Docker ficar pronto
    echo -e "${YELLOW}Aguardando Docker ficar pronto...${NC}"
    sleep 5
    
    if docker info &>/dev/null; then
        echo -e "${GREEN}✓ Docker está funcionando${NC}"
    else
        echo -e "${RED}✗ Docker não está respondendo. Verifique os logs.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Reinicialização cancelada.${NC}"
    echo -e "${YELLOW}Execute 'sudo systemctl restart docker' manualmente quando estiver pronto.${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuração Concluída${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Limites de log configurados:${NC}"
echo "  - Tamanho máximo por arquivo: $MAX_SIZE"
echo "  - Número máximo de arquivos: $MAX_FILE"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "- Esta configuração afeta apenas NOVOS containers"
echo "- Containers existentes mantêm suas configurações originais"
echo "- Para aplicar aos containers existentes, recrie-os"
echo ""
echo -e "${YELLOW}Para recriar containers com Portainer:${NC}"
echo "1. Acesse o Portainer"
echo "2. Pare o container"
echo "3. Duplique o container (mantendo as configurações)"
echo "4. Remova o container antigo"
echo "5. Inicie o novo container"
echo ""

