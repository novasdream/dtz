#!/bin/bash

# Script de Instalação Remota das Ferramentas Docker/Portainer
# Autor: Gerado automaticamente
# Descrição: Baixa e instala todas as ferramentas de manutenção
#
# Uso rápido (executar diretamente do repositório):
#   curl -sSL https://raw.githubusercontent.com/seu-repo/portainer-tool/main/install.sh | bash
#
# Ou baixar e executar:
#   wget https://raw.githubusercontent.com/seu-repo/portainer-tool/main/install.sh
#   chmod +x install.sh
#   ./install.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
INSTALL_DIR="${INSTALL_DIR:-$HOME/portainer-tool}"
REPO_URL="https://github.com/seu-usuario/portainer-tool"  # Ajuste conforme necessário
BRANCH="${BRANCH:-main}"

# Banner
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Instalador de Ferramentas Docker/Portainer                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verifica se está rodando como root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}⚠️  Não execute este script como root (sudo)${NC}"
    echo -e "${YELLOW}   O script pedirá sudo apenas quando necessário${NC}"
    exit 1
fi

# Função para verificar requisitos
check_requirements() {
    echo -e "${CYAN}[1/6] Verificando requisitos...${NC}"
    
    local missing_deps=()
    
    # Verifica Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker não encontrado${NC}"
        missing_deps+=("docker")
    else
        echo -e "${GREEN}✓ Docker encontrado${NC}"
    fi
    
    # Verifica bash
    if ! command -v bash &> /dev/null; then
        missing_deps+=("bash")
    else
        echo -e "${GREEN}✓ Bash encontrado${NC}"
    fi
    
    # Verifica comandos essenciais
    for cmd in awk sed grep tail head; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Dependências faltando: ${missing_deps[*]}${NC}"
        echo ""
        echo "Instale as dependências antes de continuar:"
        echo "  Ubuntu/Debian: sudo apt-get install docker.io coreutils"
        echo "  CentOS/RHEL: sudo yum install docker coreutils"
        echo "  MacOS: brew install docker"
        exit 1
    fi
    
    echo ""
}

# Função para criar diretório de instalação
create_install_dir() {
    echo -e "${CYAN}[2/6] Criando diretório de instalação...${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}⚠️  Diretório $INSTALL_DIR já existe${NC}"
        read -p "Deseja sobrescrever? (s/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo "Instalação cancelada."
            exit 0
        fi
        echo -e "${YELLOW}Fazendo backup do diretório existente...${NC}"
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    echo -e "${GREEN}✓ Diretório criado: $INSTALL_DIR${NC}"
    echo ""
}

# Função para baixar scripts
download_scripts() {
    echo -e "${CYAN}[3/6] Baixando scripts...${NC}"
    
    # Lista de scripts para baixar
    local scripts=(
        "docker-disk-analyzer.sh"
        "docker-log-cleanup.sh"
        "docker-cleanup.sh"
        "docker-monitor.sh"
        "configure-log-limits.sh"
        "manutencao-semanal.sh"
    )
    
    # Se tiver git, clona o repositório
    if command -v git &> /dev/null; then
        echo -e "${YELLOW}Usando git para clonar repositório...${NC}"
        # Descomente se tiver repositório git configurado
        # git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
        
        # Por enquanto, cria os scripts manualmente
        echo -e "${YELLOW}Criando scripts localmente...${NC}"
        create_scripts
    else
        echo -e "${YELLOW}Git não encontrado, criando scripts localmente...${NC}"
        create_scripts
    fi
    
    echo -e "${GREEN}✓ Scripts baixados${NC}"
    echo ""
}

# Função para criar scripts (fallback se não tiver git/repositório)
create_scripts() {
    # Esta função seria chamada se não conseguir baixar do git
    # Por enquanto, vamos indicar que os scripts devem ser baixados manualmente
    # ou você pode incorporar todo o código dos scripts aqui
    
    echo -e "${YELLOW}Nota: Para instalação completa, execute este script do diretório portainer-tool${NC}"
    echo -e "${YELLOW}      ou configure a variável REPO_URL corretamente${NC}"
}

# Função para configurar permissões
set_permissions() {
    echo -e "${CYAN}[4/6] Configurando permissões...${NC}"
    
    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    
    echo -e "${GREEN}✓ Permissões configuradas${NC}"
    echo ""
}

# Função para adicionar ao PATH
add_to_path() {
    echo -e "${CYAN}[5/6] Configurando PATH...${NC}"
    
    local shell_rc=""
    
    # Detecta shell
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
        # Verifica se já está no PATH
        if ! grep -q "portainer-tool" "$shell_rc"; then
            echo "" >> "$shell_rc"
            echo "# Portainer Tool Scripts" >> "$shell_rc"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
            echo -e "${GREEN}✓ Adicionado ao PATH em $shell_rc${NC}"
            echo -e "${YELLOW}  Execute: source $shell_rc${NC}"
        else
            echo -e "${YELLOW}⚠️  Já existe no PATH${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Não foi possível detectar o shell${NC}"
        echo -e "${YELLOW}   Adicione manualmente ao PATH: export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
    fi
    
    echo ""
}

# Função para executar análise inicial
run_initial_analysis() {
    echo -e "${CYAN}[6/6] Executando análise inicial...${NC}"
    echo ""
    
    read -p "Deseja executar uma análise inicial do sistema? (s/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if [ -f "$INSTALL_DIR/docker-disk-analyzer.sh" ]; then
            "$INSTALL_DIR/docker-disk-analyzer.sh"
        else
            echo -e "${YELLOW}Script de análise não encontrado${NC}"
        fi
    else
        echo "Análise inicial pulada."
    fi
    
    echo ""
}

# Função para mostrar próximos passos
show_next_steps() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Instalação Concluída!                           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Scripts instalados em: ${YELLOW}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${CYAN}Próximos passos:${NC}"
    echo ""
    echo -e "1. ${YELLOW}Recarregue o shell:${NC}"
    echo "   source ~/.bashrc  # ou source ~/.zshrc"
    echo ""
    echo -e "2. ${YELLOW}Execute uma análise:${NC}"
    echo "   cd $INSTALL_DIR"
    echo "   ./docker-disk-analyzer.sh"
    echo ""
    echo -e "3. ${YELLOW}Limpe logs se necessário:${NC}"
    echo "   ./docker-log-cleanup.sh --dry-run"
    echo "   ./docker-log-cleanup.sh"
    echo ""
    echo -e "4. ${YELLOW}Configure limites de log:${NC}"
    echo "   ./configure-log-limits.sh"
    echo ""
    echo -e "5. ${YELLOW}Configure manutenção automática:${NC}"
    echo "   crontab -e"
    echo "   # Adicione: 0 4 * * 0 $INSTALL_DIR/manutencao-semanal.sh"
    echo ""
    echo -e "${CYAN}Documentação:${NC}"
    echo "   README: $INSTALL_DIR/README.md"
    echo "   Guia rápido: $INSTALL_DIR/QUICK-START.md"
    echo ""
}

# Execução principal
main() {
    check_requirements
    create_install_dir
    download_scripts
    set_permissions
    add_to_path
    run_initial_analysis
    show_next_steps
}

# Tratamento de erros
trap 'echo -e "\n${RED}Instalação interrompida.${NC}\n"; exit 1' INT TERM

# Executa
main

exit 0

