#!/bin/bash

# Script para limpeza geral do Docker
# Autor: Gerado automaticamente
# Descrição: Remove containers parados, imagens não utilizadas, volumes órfãos, etc.

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DRY_RUN=false
CLEAN_VOLUMES=false
CLEAN_IMAGES=false
CLEAN_CONTAINERS=false
CLEAN_ALL=false
FORCE=false

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -d, --dry-run          Mostra o que seria feito sem executar"
    echo "  -c, --containers       Limpa apenas containers parados"
    echo "  -i, --images           Limpa apenas imagens não utilizadas"
    echo "  -v, --volumes          Limpa apenas volumes não utilizados"
    echo "  -a, --all              Limpa tudo (containers, imagens, volumes, cache)"
    echo "  -f, --force            Não pede confirmação"
    echo "  -h, --help             Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --dry-run           # Verifica sem executar"
    echo "  $0 --containers        # Remove apenas containers parados"
    echo "  $0 --all               # Limpeza completa"
    echo "  $0 --all --force       # Limpeza completa sem confirmação"
    echo ""
}

# Parse argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        -i|--images)
            CLEAN_IMAGES=true
            shift
            ;;
        -v|--volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        -a|--all)
            CLEAN_ALL=true
            CLEAN_CONTAINERS=true
            CLEAN_IMAGES=true
            CLEAN_VOLUMES=true
            shift
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Limpeza do Docker${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}MODO DRY-RUN: Nenhuma alteração será feita${NC}"
    echo ""
fi

# Mostra estatísticas antes da limpeza
echo -e "${GREEN}Estado ANTES da limpeza:${NC}"
docker system df
echo ""

# Confirmação
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Esta operação irá:${NC}"
    [ "$CLEAN_CONTAINERS" = true ] && echo "  - Remover containers parados"
    [ "$CLEAN_IMAGES" = true ] && echo "  - Remover imagens não utilizadas"
    [ "$CLEAN_VOLUMES" = true ] && echo "  - Remover volumes não utilizados"
    [ "$CLEAN_ALL" = true ] && echo "  - Limpar cache de build"
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

# Função para executar comando ou simular
execute_or_simulate() {
    local description=$1
    local command=$2
    
    echo -e "${YELLOW}$description${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Comando: $command"
        eval "$command --dry-run 2>/dev/null || echo '  (dry-run não suportado para este comando)'"
    else
        eval "$command"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Concluído${NC}"
        else
            echo -e "${RED}✗ Erro ao executar${NC}"
        fi
    fi
    echo ""
}

# Limpa containers parados
if [ "$CLEAN_CONTAINERS" = true ]; then
    stopped_count=$(docker ps -aq -f status=exited | wc -l | xargs)
    if [ "$stopped_count" -gt 0 ]; then
        execute_or_simulate "Removendo $stopped_count containers parados..." "docker container prune -f"
    else
        echo -e "${GREEN}Nenhum container parado para remover${NC}"
        echo ""
    fi
fi

# Limpa imagens não utilizadas
if [ "$CLEAN_IMAGES" = true ]; then
    # Remove imagens dangling
    dangling_count=$(docker images -qf dangling=true | wc -l | xargs)
    if [ "$dangling_count" -gt 0 ]; then
        execute_or_simulate "Removendo $dangling_count imagens dangling..." "docker image prune -f"
    else
        echo -e "${GREEN}Nenhuma imagem dangling para remover${NC}"
        echo ""
    fi
    
    # Remove todas as imagens não utilizadas (opcional)
    if [ "$CLEAN_ALL" = true ]; then
        execute_or_simulate "Removendo todas as imagens não utilizadas..." "docker image prune -a -f"
    fi
fi

# Limpa volumes não utilizados
if [ "$CLEAN_VOLUMES" = true ]; then
    unused_volumes=$(docker volume ls -qf dangling=true | wc -l | xargs)
    if [ "$unused_volumes" -gt 0 ]; then
        echo -e "${RED}ATENÇÃO: $unused_volumes volumes órfãos serão removidos!${NC}"
        echo -e "${RED}Certifique-se de que não há dados importantes nesses volumes.${NC}"
        
        if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
            read -p "Confirmar remoção de volumes? (s/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                execute_or_simulate "Removendo volumes não utilizados..." "docker volume prune -f"
            else
                echo "Remoção de volumes cancelada."
                echo ""
            fi
        else
            execute_or_simulate "Removendo volumes não utilizados..." "docker volume prune -f"
        fi
    else
        echo -e "${GREEN}Nenhum volume não utilizado para remover${NC}"
        echo ""
    fi
fi

# Limpa networks não utilizadas
if [ "$CLEAN_ALL" = true ]; then
    execute_or_simulate "Removendo networks não utilizadas..." "docker network prune -f"
fi

# Limpa cache de build
if [ "$CLEAN_ALL" = true ]; then
    execute_or_simulate "Removendo cache de build..." "docker builder prune -f"
fi

# System prune (limpeza geral)
if [ "$CLEAN_ALL" = true ]; then
    echo -e "${YELLOW}Executando limpeza geral do sistema...${NC}"
    if [ "$DRY_RUN" = false ]; then
        docker system prune -f
        echo -e "${GREEN}✓ Concluído${NC}"
    else
        echo -e "${BLUE}[DRY-RUN]${NC} docker system prune -f"
    fi
    echo ""
fi

# Mostra estatísticas depois da limpeza
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Resultado${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}Estado DEPOIS da limpeza:${NC}"
docker system df
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Execute sem --dry-run para aplicar as mudanças${NC}"
else
    echo -e "${GREEN}Limpeza concluída com sucesso!${NC}"
fi

echo ""
echo -e "${YELLOW}Dicas para manutenção:${NC}"
echo "1. Execute este script regularmente (ex: semanalmente)"
echo "2. Configure um cron job para automação"
echo "3. Monitore o uso de disco com: docker system df"
echo "4. Configure limites de logs nos containers"
echo ""

