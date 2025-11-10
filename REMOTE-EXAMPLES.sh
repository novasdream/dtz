#!/bin/bash

# ============================================================================
# Exemplos Práticos de Execução Remota
# ============================================================================
#
# Este arquivo contém exemplos prontos para copiar e colar
# Ajuste os endereços e credenciais conforme necessário
#
# ATENÇÃO: Este arquivo é apenas para referência/documentação
#          Não execute diretamente: bash REMOTE-EXAMPLES.sh
#
# ============================================================================

# ============================================================================
# CONFIGURAÇÃO INICIAL
# ============================================================================

# Defina suas variáveis (ajuste conforme necessário)
SERVER1="192.168.1.100"
SERVER2="192.168.1.101"
SERVER3="192.168.1.102"
SSH_USER="root"
SSH_KEY="~/.ssh/id_rsa"

# ============================================================================
# EXEMPLO 1: ONE-LINER - Análise Rápida em Um Servidor
# ============================================================================

# Análise rápida sem instalar nada
ssh $SSH_USER@$SERVER1 "bash -s analyze" < one-liner.sh

# ============================================================================
# EXEMPLO 2: ONE-LINER - Limpeza de Emergência
# ============================================================================

# Servidor sem espaço - limpeza imediata
ssh $SSH_USER@$SERVER1 "sudo bash -s clean-logs" < one-liner.sh
ssh $SSH_USER@$SERVER1 "bash -s cleanup" < one-liner.sh

# ============================================================================
# EXEMPLO 3: ONE-LINER - Análise em Múltiplos Servidores
# ============================================================================

# Loop sequencial
for host in $SERVER1 $SERVER2 $SERVER3; do
  echo "=== Analisando $host ==="
  ssh $SSH_USER@$host "bash -s analyze" < one-liner.sh
  echo ""
done

# Execução paralela (mais rápido)
for host in $SERVER1 $SERVER2 $SERVER3; do
  (
    echo "=== $host ===" > "report-$host.txt"
    ssh $SSH_USER@$host "bash -s analyze" < one-liner.sh >> "report-$host.txt"
  ) &
done
wait
echo "Relatórios salvos em report-*.txt"

# ============================================================================
# EXEMPLO 4: DEPLOY - Instalar em Um Servidor
# ============================================================================

# Deploy básico
./remote-deploy.sh $SERVER1

# Deploy com todas as opções
./remote-deploy.sh \
  --user $SSH_USER \
  --key $SSH_KEY \
  --dir /opt/portainer-tool \
  --run \
  $SERVER1

# ============================================================================
# EXEMPLO 5: DEPLOY - Instalar em Múltiplos Servidores
# ============================================================================

# Deploy em vários servidores
./remote-deploy.sh \
  --user $SSH_USER \
  --key $SSH_KEY \
  $SERVER1 $SERVER2 $SERVER3

# Usando arquivo de configuração
cat > my-servers.txt << EOF
$SERVER1
$SERVER2
$SERVER3
EOF

./remote-deploy.sh -f my-servers.txt

# ============================================================================
# EXEMPLO 6: REMOTE-EXEC - Executar Comandos Remotamente
# ============================================================================

# Análise em um servidor
./remote-exec.sh analyze $SERVER1

# Limpeza em múltiplos servidores
./remote-exec.sh cleanup $SERVER1 $SERVER2 $SERVER3

# Usando arquivo de servidores
./remote-exec.sh -f my-servers.txt analyze

# Com credenciais específicas
./remote-exec.sh \
  --user $SSH_USER \
  --key $SSH_KEY \
  analyze $SERVER1

# ============================================================================
# EXEMPLO 7: REMOTE-EXEC - Comandos Específicos
# ============================================================================

# Análise completa
./remote-exec.sh analyze $SERVER1

# Limpeza de logs
./remote-exec.sh clean-logs $SERVER1

# Limpeza geral
./remote-exec.sh cleanup $SERVER1

# Limpeza completa (força)
./remote-exec.sh cleanup-all $SERVER1

# Monitoramento único
./remote-exec.sh monitor $SERVER1

# Manutenção semanal
./remote-exec.sh maintenance $SERVER1

# Configurar limites
./remote-exec.sh configure $SERVER1

# Comando customizado
./remote-exec.sh custom "docker ps -a" $SERVER1

# ============================================================================
# EXEMPLO 8: Execução Paralela
# ============================================================================

# Análise paralela em múltiplos servidores
./remote-exec.sh --parallel analyze $SERVER1 $SERVER2 $SERVER3

# Limpeza paralela
./remote-exec.sh -P -f my-servers.txt cleanup

# ============================================================================
# EXEMPLO 9: Pipeline de Manutenção Completa
# ============================================================================

# Criar script de pipeline
cat > pipeline-manutencao.sh << 'SCRIPT_END'
#!/bin/bash

SERVERS="server1 server2 server3"

echo "1. Análise inicial..."
./remote-exec.sh analyze $SERVERS > pre-cleanup.txt

echo "2. Limpando logs..."
./remote-exec.sh clean-logs $SERVERS

echo "3. Limpando recursos..."
./remote-exec.sh cleanup $SERVERS

echo "4. Análise final..."
./remote-exec.sh analyze $SERVERS > post-cleanup.txt

echo "5. Comparação..."
diff pre-cleanup.txt post-cleanup.txt > comparison.txt

echo "Pipeline concluído!"
SCRIPT_END

chmod +x pipeline-manutencao.sh
# ./pipeline-manutencao.sh

# ============================================================================
# EXEMPLO 10: Coletar Relatórios de Múltiplos Servidores
# ============================================================================

# Criar diretório
mkdir -p reports/$(date +%Y%m%d)

# Coletar de todos os servidores
for host in $SERVER1 $SERVER2 $SERVER3; do
  echo "Coletando de $host..."
  ssh $SSH_USER@$host "bash -s analyze" < one-liner.sh > "reports/$(date +%Y%m%d)/$host.txt" &
done

wait
echo "Relatórios salvos em reports/$(date +%Y%m%d)/"

# Consolidar relatórios
cat reports/$(date +%Y%m%d)/*.txt > reports/$(date +%Y%m%d)/consolidated.txt

# ============================================================================
# EXEMPLO 11: Configurar Cron em Múltiplos Servidores
# ============================================================================

# Adicionar manutenção semanal em todos os servidores
for host in $SERVER1 $SERVER2 $SERVER3; do
  echo "Configurando cron em $host..."
  ssh $SSH_USER@$host << 'EOF'
    # Adiciona ao crontab se ainda não existir
    (crontab -l 2>/dev/null | grep -v "portainer-tool"; \
     echo "0 4 * * 0 /opt/portainer-tool/manutencao-semanal.sh") | crontab -
    echo "Cron configurado!"
EOF
done

# ============================================================================
# EXEMPLO 12: Monitoramento Contínuo
# ============================================================================

# Criar script de monitoramento contínuo
cat > monitor-continuo.sh << 'SCRIPT_END'
#!/bin/bash

SERVERS="server1 server2 server3"
INTERVAL=300  # 5 minutos

while true; do
    clear
    echo "=== Monitoramento - $(date) ==="
    echo ""
    
    ./remote-exec.sh -P monitor $SERVERS
    
    echo ""
    echo "Próxima atualização em ${INTERVAL}s..."
    sleep $INTERVAL
done
SCRIPT_END

chmod +x monitor-continuo.sh
# ./monitor-continuo.sh

# ============================================================================
# EXEMPLO 13: Backup Antes de Limpeza
# ============================================================================

# Script que faz backup antes de limpar
cat > cleanup-with-backup.sh << 'SCRIPT_END'
#!/bin/bash

SERVERS="$@"

for host in $SERVERS; do
    echo "=== Processando $host ==="
    
    # Backup dos logs importantes
    echo "1. Fazendo backup..."
    ssh root@$host "tar czf /tmp/docker-logs-backup-$(date +%Y%m%d).tar.gz /var/lib/docker/containers/*/`*-json.log"
    
    # Análise antes
    echo "2. Análise antes da limpeza..."
    ssh root@$host "bash -s analyze" < one-liner.sh > "before-$host.txt"
    
    # Limpeza
    echo "3. Executando limpeza..."
    ssh root@$host "bash -s cleanup" < one-liner.sh
    
    # Análise depois
    echo "4. Análise após limpeza..."
    ssh root@$host "bash -s analyze" < one-liner.sh > "after-$host.txt"
    
    echo "✓ Concluído em $host"
    echo ""
done
SCRIPT_END

chmod +x cleanup-with-backup.sh
# ./cleanup-with-backup.sh server1 server2

# ============================================================================
# EXEMPLO 14: Alertas por Email
# ============================================================================

# Script que envia email se disco > 80%
cat > check-and-alert.sh << 'SCRIPT_END'
#!/bin/bash

SERVERS="$@"
EMAIL="admin@example.com"
THRESHOLD=80

for host in $SERVERS; do
    usage=$(ssh root@$host "df -h / | awk 'NR==2 {print \$5}' | sed 's/%//'")
    
    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "ALERTA: $host está com $usage% de uso de disco" | \
        mail -s "Alerta de Disco - $host" $EMAIL
        
        # Executa limpeza automática
        echo "Executando limpeza automática em $host..."
        ./remote-exec.sh cleanup-all $host
    fi
done
SCRIPT_END

chmod +x check-and-alert.sh
# ./check-and-alert.sh server1 server2 server3

# ============================================================================
# EXEMPLO 15: Execução com Log de Auditoria
# ============================================================================

# Todas as execuções ficam registradas
mkdir -p audit-logs

# Função para logar execuções
log_execution() {
    local command=$1
    local servers=$2
    local logfile="audit-logs/$(date +%Y%m%d-%H%M%S)-$command.log"
    
    {
        echo "=== Execução de $command ==="
        echo "Data: $(date)"
        echo "Servidores: $servers"
        echo "Usuário: $(whoami)"
        echo "================================"
        echo ""
        
        ./remote-exec.sh $command $servers
        
    } 2>&1 | tee "$logfile"
}

# Uso
# log_execution analyze "server1 server2"
# log_execution cleanup "server1 server2 server3"

# ============================================================================
# EXEMPLO 16: Deploy com Rollback
# ============================================================================

# Deploy com capacidade de rollback
deploy_with_rollback() {
    local servers=$@
    
    for host in $servers; do
        echo "=== Deploy em $host ==="
        
        # Backup do diretório existente
        ssh root@$host "[ -d /opt/portainer-tool ] && \
            cp -r /opt/portainer-tool /opt/portainer-tool.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Deploy
        if ./remote-deploy.sh $host; then
            echo "✓ Deploy bem-sucedido em $host"
        else
            echo "✗ Erro no deploy em $host. Executando rollback..."
            ssh root@$host "[ -d /opt/portainer-tool.backup.* ] && \
                rm -rf /opt/portainer-tool && \
                mv /opt/portainer-tool.backup.* /opt/portainer-tool"
        fi
    done
}

# ============================================================================
# DICAS FINAIS
# ============================================================================

: << 'TIPS'

1. SEMPRE teste com one-liner primeiro
   ssh user@servidor "bash -s analyze" < one-liner.sh

2. Use --dry-run quando disponível
   ./remote-exec.sh cleanup --dry-run servidor

3. Faça backups antes de limpezas importantes
   ssh user@servidor "tar czf backup.tar.gz /var/lib/docker"

4. Configure SSH config para facilitar
   # Em ~/.ssh/config
   Host prod-*
       User admin
       IdentityFile ~/.ssh/prod_key

5. Use tmux/screen para execuções longas
   tmux new -s docker-cleanup
   ./remote-exec.sh maintenance server1 server2 server3

6. Mantenha logs de todas as execuções
   ./remote-exec.sh comando servidor 2>&1 | tee log.txt

7. Teste em staging antes de produção
   ./remote-exec.sh -f staging-servers.txt cleanup
   # Se OK, então:
   ./remote-exec.sh -f prod-servers.txt cleanup

8. Use execução paralela para grandes clusters
   ./remote-exec.sh --parallel analyze $(cat servers.txt)

9. Configure alertas para uso de disco
   # Adicionar ao cron
   0 */6 * * * /path/to/check-and-alert.sh server1 server2

10. Documente suas execuções
    echo "$(date): Limpeza executada em prod" >> operations.log

TIPS

echo "Exemplos carregados! Ajuste as variáveis e execute os comandos."

