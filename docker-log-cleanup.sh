#!/bin/bash

# Script para limpeza de logs do Docker
# Autor: Gerado automaticamente
# Descrição: Limpa logs grandes dos containers Docker

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações padrão
DRY_RUN=false
SIZE_THRESHOLD="100M" # Limpa logs maiores que este tamanho
KEEP_LINES=1000 # Mantém as últimas N linhas

# Função de ajuda
show_help() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -d, --dry-run          Mostra o que seria feito sem executar"
    echo "  -s, --size TAMANHO     Define o tamanho mínimo para limpeza (padrão: 100M)"
    echo "  -l, --lines LINHAS     Número de linhas a manter (padrão: 1000)"
    echo "  -a, --all              Limpa todos os logs independente do tamanho"
    echo "  -h, --help             Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --dry-run           # Verifica sem executar"
    echo "  $0 --size 200M         # Limpa logs maiores que 200M"
    echo "  $0 --lines 500         # Mantém apenas as últimas 500 linhas"
    echo ""
}

# Parse argumentos
CLEAN_ALL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--size)
            SIZE_THRESHOLD="$2"
            shift 2
            ;;
        -l|--lines)
            KEEP_LINES="$2"
            shift 2
            ;;
        -a|--all)
            CLEAN_ALL=true
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
echo -e "${BLUE}  Limpeza de Logs Docker${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}MODO DRY-RUN: Nenhuma alteração será feita${NC}"
    echo ""
fi

# Converter tamanho threshold para bytes para comparação
convert_to_bytes() {
    local size=$1
    local number=${size//[^0-9]/}
    local unit=${size//[0-9]/}
    
    case $unit in
        K|k) echo $((number * 1024)) ;;
        M|m) echo $((number * 1024 * 1024)) ;;
        G|g) echo $((number * 1024 * 1024 * 1024)) ;;
        *) echo $number ;;
    esac
}

threshold_bytes=$(convert_to_bytes "$SIZE_THRESHOLD")
total_freed=0
cleaned_count=0

echo -e "${GREEN}Analisando logs dos containers...${NC}"
echo ""

# Lista todos os containers
docker ps -aq | while read container_id; do
    container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/\///')
    log_path=$(docker inspect --format='{{.LogPath}}' "$container_id")
    
    if [ -f "$log_path" ]; then
        log_size_bytes=$(stat -f%z "$log_path" 2>/dev/null || stat -c%s "$log_path" 2>/dev/null)
        log_size_human=$(du -h "$log_path" 2>/dev/null | cut -f1)
        
        # Verifica se deve limpar este log
        should_clean=false
        if [ "$CLEAN_ALL" = true ]; then
            should_clean=true
        elif [ "$log_size_bytes" -gt "$threshold_bytes" ]; then
            should_clean=true
        fi
        
        if [ "$should_clean" = true ]; then
            echo -e "${YELLOW}Container:${NC} $container_name"
            echo -e "${YELLOW}Tamanho do log:${NC} $log_size_human"
            echo -e "${YELLOW}Localização:${NC} $log_path"
            
            if [ "$DRY_RUN" = false ]; then
                # Backup das últimas linhas
                temp_file=$(mktemp)
                sudo tail -n "$KEEP_LINES" "$log_path" > "$temp_file" 2>/dev/null || echo "Erro ao criar backup"
                
                # Trunca o arquivo de log
                sudo truncate -s 0 "$log_path" 2>/dev/null || echo "Erro ao truncar"
                
                # Restaura as últimas linhas
                sudo cat "$temp_file" > "$log_path" 2>/dev/null || echo "Erro ao restaurar"
                rm -f "$temp_file"
                
                new_size=$(du -h "$log_path" 2>/dev/null | cut -f1)
                freed=$((log_size_bytes))
                total_freed=$((total_freed + freed))
                cleaned_count=$((cleaned_count + 1))
                
                echo -e "${GREEN}✓ Limpo!${NC} Novo tamanho: $new_size (mantidas últimas $KEEP_LINES linhas)"
            else
                echo -e "${BLUE}[DRY-RUN]${NC} Seria limpo (mantendo últimas $KEEP_LINES linhas)"
            fi
            echo ""
        fi
    fi
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Resumo${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$DRY_RUN" = false ]; then
    echo -e "Containers limpos: ${GREEN}$cleaned_count${NC}"
    
    # Converter bytes liberados para formato legível
    if [ $total_freed -gt $((1024*1024*1024)) ]; then
        freed_human=$(echo "scale=2; $total_freed / 1024 / 1024 / 1024" | bc)
        echo -e "Espaço liberado: ${GREEN}${freed_human} GB${NC}"
    elif [ $total_freed -gt $((1024*1024)) ]; then
        freed_human=$(echo "scale=2; $total_freed / 1024 / 1024" | bc)
        echo -e "Espaço liberado: ${GREEN}${freed_human} MB${NC}"
    else
        freed_human=$(echo "scale=2; $total_freed / 1024" | bc)
        echo -e "Espaço liberado: ${GREEN}${freed_human} KB${NC}"
    fi
else
    echo -e "${YELLOW}Execute sem --dry-run para aplicar as mudanças${NC}"
fi

echo ""
echo -e "${YELLOW}Dica:${NC} Para prevenir logs grandes no futuro, configure limites:"
echo ""
echo "Docker Compose:"
echo "  services:"
echo "    seu-servico:"
echo "      logging:"
echo "        driver: \"json-file\""
echo "        options:"
echo "          max-size: \"10m\""
echo "          max-file: \"3\""
echo ""
echo "Docker Run:"
echo "  docker run --log-opt max-size=10m --log-opt max-file=3 ..."
echo ""

