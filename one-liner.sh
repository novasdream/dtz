#!/bin/bash

# One-Liner Scripts - Execução Remota Rápida via SSH
# Autor: Gerado automaticamente
# Descrição: Scripts compactos para execução remota sem necessidade de instalação

# Este arquivo contém one-liners que podem ser executados diretamente via SSH
# sem necessidade de instalar nada no servidor remoto.

# ============================================================================
# ANÁLISE RÁPIDA DE DISCO
# ============================================================================

# Uso: ssh user@host "bash -s" < one-liner.sh analyze
# Ou: cat one-liner.sh | ssh user@host "bash -s analyze"

if [ "$1" = "analyze" ] || [ "$1" = "analyse" ]; then
    echo "=== Análise Rápida Docker ===" >&2
    echo "" >&2
    
    # Uso geral do disco
    echo "Uso de Disco:" >&2
    df -h / | grep -v Filesystem
    echo "" >&2
    
    # Docker system
    echo "Docker System:" >&2
    docker system df
    echo "" >&2
    
    # Top 5 containers com maiores logs
    echo "Top 5 Maiores Logs:" >&2
    docker ps -aq 2>/dev/null | while read cid; do
        name=$(docker inspect --format='{{.Name}}' "$cid" | sed 's/\///')
        log=$(docker inspect --format='{{.LogPath}}' "$cid")
        if [ -f "$log" ]; then
            size=$(du -h "$log" 2>/dev/null | cut -f1)
            echo "$name: $size"
        fi
    done | sort -rh | head -5
    echo "" >&2
    
    # Containers parados
    stopped=$(docker ps -aq -f status=exited | wc -l)
    echo "Containers parados: $stopped" >&2
    
    # Imagens não usadas
    dangling=$(docker images -qf dangling=true | wc -l)
    echo "Imagens dangling: $dangling" >&2
    
    exit 0
fi

# ============================================================================
# LIMPEZA RÁPIDA DE LOGS
# ============================================================================

if [ "$1" = "clean-logs" ]; then
    echo "=== Limpeza de Logs ===" >&2
    
    docker ps -aq | while read cid; do
        name=$(docker inspect --format='{{.Name}}' "$cid" | sed 's/\///')
        log=$(docker inspect --format='{{.LogPath}}' "$cid")
        
        if [ -f "$log" ]; then
            size_before=$(stat -f%z "$log" 2>/dev/null || stat -c%s "$log" 2>/dev/null)
            
            if [ "$size_before" -gt 104857600 ]; then  # > 100MB
                echo "Limpando: $name ($(($size_before/1024/1024))MB)" >&2
                temp=$(mktemp)
                sudo tail -n 1000 "$log" > "$temp"
                sudo truncate -s 0 "$log"
                sudo cat "$temp" > "$log"
                rm -f "$temp"
                echo "  ✓ Limpo" >&2
            fi
        fi
    done
    
    exit 0
fi

# ============================================================================
# LIMPEZA RÁPIDA GERAL
# ============================================================================

if [ "$1" = "cleanup" ]; then
    echo "=== Limpeza Geral ===" >&2
    
    # Remove containers parados
    stopped=$(docker ps -aq -f status=exited | wc -l)
    if [ "$stopped" -gt 0 ]; then
        echo "Removendo $stopped containers parados..." >&2
        docker container prune -f
    fi
    
    # Remove imagens dangling
    dangling=$(docker images -qf dangling=true | wc -l)
    if [ "$dangling" -gt 0 ]; then
        echo "Removendo $dangling imagens dangling..." >&2
        docker image prune -f
    fi
    
    # Remove networks não usadas
    echo "Removendo networks não usadas..." >&2
    docker network prune -f
    
    echo "" >&2
    echo "✓ Limpeza concluída" >&2
    
    exit 0
fi

# ============================================================================
# MONITORAMENTO RÁPIDO
# ============================================================================

if [ "$1" = "monitor" ]; then
    echo "=== Monitoramento Docker ===" >&2
    echo "" >&2
    
    # Containers ativos
    echo "Containers Ativos:" >&2
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    echo "" >&2
    
    # Estatísticas
    echo "Uso de Recursos:" >&2
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    echo "" >&2
    
    # Uso de disco
    echo "Uso de Disco:" >&2
    docker system df
    
    exit 0
fi

# ============================================================================
# AJUDA
# ============================================================================

if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║           One-Liner Scripts Docker/Portainer                       ║
╚════════════════════════════════════════════════════════════════════╝

Scripts para execução remota rápida sem instalação prévia.

COMANDOS DISPONÍVEIS:

  analyze       Análise rápida de uso de disco
  clean-logs    Limpa logs maiores que 100MB
  cleanup       Limpeza geral (containers, imagens)
  monitor       Monitoramento de recursos
  help          Mostra esta ajuda

USO LOCAL:

  ./one-liner.sh analyze
  ./one-liner.sh clean-logs
  ./one-liner.sh cleanup
  ./one-liner.sh monitor

USO REMOTO (via SSH):

  # Análise remota
  ssh user@host "bash -s analyze" < one-liner.sh

  # Limpeza remota
  ssh user@host "bash -s cleanup" < one-liner.sh

  # Com sudo (para limpeza de logs)
  ssh user@host "sudo bash -s clean-logs" < one-liner.sh

  # Via cat
  cat one-liner.sh | ssh user@host "bash -s analyze"

USO EM MÚLTIPLOS SERVIDORES:

  # Análise em vários servidores
  for host in server1 server2 server3; do
    echo "=== $host ==="
    ssh user@$host "bash -s analyze" < one-liner.sh
    echo ""
  done

  # Limpeza em paralelo
  for host in server1 server2 server3; do
    (ssh user@$host "bash -s cleanup" < one-liner.sh) &
  done
  wait

EXEMPLOS PRÁTICOS:

  # Análise em servidor remoto
  ssh root@192.168.1.100 "bash -s analyze" < one-liner.sh

  # Limpeza de logs em produção
  ssh admin@prod.example.com "sudo bash -s clean-logs" < one-liner.sh

  # Monitoramento de múltiplos servidores
  for i in {100..110}; do
    ssh root@192.168.1.$i "bash -s monitor" < one-liner.sh > "log-$i.txt" &
  done

VANTAGENS:

  ✓ Não requer instalação no servidor remoto
  ✓ Execução única e rápida
  ✓ Ideal para diagnóstico emergencial
  ✓ Funciona em qualquer servidor com Docker

NOTA:

  Para funcionalidades completas, use os scripts de instalação:
    ./install.sh
    ./remote-deploy.sh

EOF
    exit 0
fi

# Comando desconhecido
echo "Comando desconhecido: $1" >&2
echo "Use: $0 help" >&2
exit 1

