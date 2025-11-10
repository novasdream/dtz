#!/bin/bash

# Script para analisar uso de disco do Docker e Portainer
# Autor: Gerado automaticamente
# Descrição: Identifica onde o armazenamento está sendo utilizado

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Análise de Disco Docker/Portainer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Uso geral do disco
echo -e "${GREEN}[1] Uso Geral do Disco:${NC}"
df -h | grep -E "Filesystem|/$|/var"
echo ""

# 2. Informações do Docker
echo -e "${GREEN}[2] Informações do Docker System:${NC}"
docker system df -v
echo ""

# 3. Tamanho dos logs dos containers
echo -e "${GREEN}[3] Top 10 Containers com Maiores Logs:${NC}"
echo -e "${YELLOW}Container Name${NC} | ${YELLOW}Log Size${NC}"
echo "----------------------------------------"

# Lista todos os containers (incluindo parados)
docker ps -aq | while read container_id; do
    container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/\///')
    log_path=$(docker inspect --format='{{.LogPath}}' "$container_id")
    
    if [ -f "$log_path" ]; then
        log_size=$(du -h "$log_path" 2>/dev/null | cut -f1)
        echo "$container_name|$log_size"
    fi
done | sort -t'|' -k2 -rh | head -10 | column -t -s'|'

echo ""

# 4. Imagens Docker
echo -e "${GREEN}[4] Top 10 Maiores Imagens Docker:${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -11
echo ""

# 5. Volumes Docker
echo -e "${GREEN}[5] Volumes Docker:${NC}"
docker volume ls -q | while read volume; do
    size=$(docker system df -v | grep "$volume" | awk '{print $3}' | head -1)
    echo "$volume: $size"
done | head -10
echo ""

# 6. Containers parados
echo -e "${GREEN}[6] Containers Parados (podem ser removidos):${NC}"
stopped_count=$(docker ps -a -f status=exited -q | wc -l | xargs)
echo "Total de containers parados: $stopped_count"
if [ "$stopped_count" -gt 0 ]; then
    docker ps -a -f status=exited --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
fi
echo ""

# 7. Imagens não utilizadas (dangling)
echo -e "${GREEN}[7] Imagens Não Utilizadas (dangling):${NC}"
dangling_count=$(docker images -f dangling=true -q | wc -l | xargs)
echo "Total de imagens dangling: $dangling_count"
if [ "$dangling_count" -gt 0 ]; then
    docker images -f dangling=true
fi
echo ""

# 8. Volumes não utilizados
echo -e "${GREEN}[8] Volumes Não Utilizados:${NC}"
unused_volumes=$(docker volume ls -qf dangling=true | wc -l | xargs)
echo "Total de volumes não utilizados: $unused_volumes"
if [ "$unused_volumes" -gt 0 ]; then
    docker volume ls -f dangling=true
fi
echo ""

# 9. Diretório Docker
echo -e "${GREEN}[9] Tamanho do Diretório Docker (/var/lib/docker):${NC}"
if [ -d "/var/lib/docker" ]; then
    sudo du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -10
else
    echo "Diretório /var/lib/docker não encontrado (pode ser outro local no MacOS)"
    echo "Verificando Docker Desktop..."
    if [ -d "$HOME/Library/Containers/com.docker.docker" ]; then
        du -sh "$HOME/Library/Containers/com.docker.docker/Data" 2>/dev/null
    fi
fi
echo ""

# 10. Resumo e Recomendações
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Resumo e Recomendações${NC}"
echo -e "${BLUE}========================================${NC}"

total_space=$(docker system df | grep "Total" | awk '{print $4}')
echo -e "Espaço total usado pelo Docker: ${YELLOW}$total_space${NC}"

echo ""
echo -e "${YELLOW}Recomendações:${NC}"
echo "1. Execute 'docker-cleanup.sh' para limpar recursos não utilizados"
echo "2. Execute 'docker-log-cleanup.sh' para limpar logs grandes"
echo "3. Configure limites de log nos containers (docker-compose ou docker run)"
echo "4. Considere usar volumes nomeados em vez de volumes anônimos"
echo ""

