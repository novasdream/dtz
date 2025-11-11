# 🌐 Guia de Uso Remoto

> Documentação completa para executar as ferramentas em servidores remotos via SSH

## 📋 Visão Geral

Este guia cobre três formas de executar as ferramentas remotamente:

1. **One-Liner** - Execução única sem instalação
2. **Deploy Remoto** - Instala permanentemente no servidor
3. **Execução Remota** - Executa comandos em múltiplos servidores

---

## 🚀 Método 1: One-Liner (Execução Única)

**Ideal para**: Diagnósticos rápidos, emergências, servidores temporários

### Vantagens
✅ Não requer instalação no servidor  
✅ Execução imediata  
✅ Perfeito para diagnóstico emergencial  
✅ Sem arquivos deixados no servidor  

### Uso Básico

```bash
# Análise rápida de disco
ssh user@servidor "bash -s analyze" < one-liner.sh

# Limpeza de logs
ssh user@servidor "sudo bash -s clean-logs" < one-liner.sh

# Limpeza geral
ssh user@servidor "bash -s cleanup" < one-liner.sh

# Monitoramento
ssh user@servidor "bash -s monitor" < one-liner.sh
```

### Múltiplos Servidores

```bash
# Análise em vários servidores sequencialmente
for host in server1 server2 server3; do
  echo "=== Analisando $host ==="
  ssh user@$host "bash -s analyze" < one-liner.sh
  echo ""
done

# Execução paralela
for host in server1 server2 server3; do
  (ssh user@$host "bash -s analyze" < one-liner.sh > "report-$host.txt") &
done
wait
```

### Com Lista de Servidores

```bash
# Criar lista
cat > servers.txt << EOF
192.168.1.100
192.168.1.101
192.168.1.102
EOF

# Executar em todos
while read host; do
  echo "=== $host ==="
  ssh root@$host "bash -s analyze" < one-liner.sh
done < servers.txt
```

---

## 📦 Método 2: Deploy Remoto (Instalação Permanente)

**Ideal para**: Servidores de produção, uso recorrente, automação

### Vantagens
✅ Scripts instalados permanentemente  
✅ Execução mais rápida após instalação  
✅ Suporta automação via cron  
✅ Acesso local aos scripts no servidor  

### Deploy em Um Servidor

```bash
# Deploy básico
./remote-deploy.sh 192.168.1.100

# Com usuário específico
./remote-deploy.sh -u admin 192.168.1.100

# Com chave SSH
./remote-deploy.sh -k ~/.ssh/id_rsa 192.168.1.100

# Com análise após instalação
./remote-deploy.sh --run 192.168.1.100
```

### Deploy em Múltiplos Servidores

```bash
# Deploy em vários servidores
./remote-deploy.sh server1.com server2.com server3.com

# Com arquivo de configuração
./remote-deploy.sh -f servers.txt

# Especificando diretório customizado
./remote-deploy.sh -d /usr/local/portainer-tool server1.com
```

### Exemplo Completo

```bash
# Deploy em servidores de produção
./remote-deploy.sh \
  --user admin \
  --key ~/.ssh/prod_key \
  --dir /opt/portainer-tool \
  --run \
  prod-web-01.com \
  prod-web-02.com \
  prod-db-01.com
```

### Após o Deploy

```bash
# Executar análise no servidor remoto
ssh user@servidor '/opt/portainer-tool/docker-disk-analyzer.sh'

# Executar limpeza
ssh user@servidor '/opt/portainer-tool/docker-cleanup.sh --all'

# Configurar manutenção automática
ssh user@servidor << 'EOF'
  crontab -l | { cat; echo "0 4 * * 0 /opt/portainer-tool/manutencao-semanal.sh"; } | crontab -
EOF
```

---

## 🎯 Método 3: Execução Remota (Comando Centralizado)

**Ideal para**: Gerenciamento centralizado, múltiplos servidores, operações em lote

### Vantagens
✅ Controle centralizado  
✅ Execução em múltiplos servidores com um comando  
✅ Suporta execução paralela  
✅ Relatórios consolidados  

### Comandos Disponíveis

```bash
# Análise de disco
./remote-exec.sh analyze server1.com

# Limpeza de logs
./remote-exec.sh clean-logs server1.com server2.com

# Limpeza geral
./remote-exec.sh cleanup server1.com server2.com

# Limpeza completa com force
./remote-exec.sh cleanup-all server1.com

# Monitoramento único
./remote-exec.sh monitor server1.com

# Manutenção semanal
./remote-exec.sh maintenance server1.com

# Configurar limites de log
./remote-exec.sh configure server1.com

# Comando customizado
./remote-exec.sh custom "docker ps -a" server1.com
```

### Com Arquivo de Configuração

```bash
# Criar arquivo servers.txt
cat > servers.txt << EOF
192.168.1.100
192.168.1.101
192.168.1.102
EOF

# Executar em todos os servidores
./remote-exec.sh -f servers.txt analyze

# Com usuário e chave específicos
./remote-exec.sh \
  -u admin \
  -k ~/.ssh/id_rsa \
  -f servers.txt \
  cleanup
```

### Execução Paralela

```bash
# Análise paralela em múltiplos servidores
./remote-exec.sh --parallel analyze server1 server2 server3

# Limpeza paralela
./remote-exec.sh -P -f servers.txt cleanup
```

---

## 🔐 Configuração de Acesso SSH

### Configurar Chave SSH

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096 -C "seu-email@example.com"

# Copiar chave para servidor
ssh-copy-id user@servidor

# Ou manualmente
cat ~/.ssh/id_rsa.pub | ssh user@servidor "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Testar conexão
ssh user@servidor "echo 'Conexão OK'"
```

### SSH Config (Recomendado)

Criar `~/.ssh/config`:

```ssh-config
# Servidor de Produção Web 1
Host prod-web-01
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/prod_key

# Servidor de Produção Web 2
Host prod-web-02
    HostName 192.168.1.101
    User admin
    Port 22
    IdentityFile ~/.ssh/prod_key

# Servidor de Database
Host prod-db-01
    HostName 192.168.1.102
    User admin
    Port 22
    IdentityFile ~/.ssh/prod_key

# Configuração padrão para todos
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
```

Agora você pode usar apenas o nome:

```bash
./remote-deploy.sh prod-web-01 prod-web-02
./remote-exec.sh analyze prod-db-01
```

---

## 📊 Casos de Uso Práticos

### Caso 1: Análise de Emergência

```bash
# Servidor sem espaço - análise rápida
ssh root@servidor "bash -s analyze" < one-liner.sh

# Limpeza imediata de logs
ssh root@servidor "sudo bash -s clean-logs" < one-liner.sh
```

### Caso 2: Manutenção Semanal em Cluster

```bash
# Criar lista de servidores
cat > prod-servers.txt << EOF
prod-web-01.com
prod-web-02.com
prod-web-03.com
prod-app-01.com
prod-app-02.com
EOF

# Executar manutenção em todos
./remote-exec.sh -f prod-servers.txt maintenance
```

### Caso 3: Deploy Inicial em Nova Infraestrutura

```bash
# Deploy em todos os servidores novos
./remote-deploy.sh -f new-servers.txt --run

# Configurar limites de log em todos
./remote-exec.sh -f new-servers.txt configure

# Configurar cron em todos
for host in $(cat new-servers.txt); do
  ssh root@$host << 'EOF'
    (crontab -l 2>/dev/null; echo "0 4 * * 0 /opt/portainer-tool/manutencao-semanal.sh") | crontab -
EOF
done
```

### Caso 4: Auditoria de Múltiplos Servidores

```bash
# Criar diretório para relatórios
mkdir -p reports/$(date +%Y%m%d)

# Coletar análises de todos os servidores
while read host; do
  echo "Coletando dados de $host..."
  ssh root@$host "bash -s analyze" < one-liner.sh > "reports/$(date +%Y%m%d)/$host.txt" &
done < servers.txt

wait
echo "Relatórios salvos em reports/$(date +%Y%m%d)/"
```

### Caso 5: Limpeza Agendada Centralizada

```bash
# Criar script de limpeza centralizada
cat > /usr/local/bin/docker-cleanup-all-servers.sh << 'EOF'
#!/bin/bash
cd /path/to/portainer-tool
./remote-exec.sh -f /etc/docker-servers.txt cleanup-all
EOF

chmod +x /usr/local/bin/docker-cleanup-all-servers.sh

# Adicionar ao cron
(crontab -l 2>/dev/null; echo "0 3 * * 0 /usr/local/bin/docker-cleanup-all-servers.sh") | crontab -
```

---

## 🛠️ Troubleshooting

### Problema: "Permission denied (publickey)"

```bash
# Verificar chave SSH
ssh-add -l

# Adicionar chave
ssh-add ~/.ssh/id_rsa

# Especificar chave no comando
./remote-deploy.sh -k ~/.ssh/id_rsa servidor
```

### Problema: "Connection timeout"

```bash
# Testar conectividade
ping servidor

# Testar porta SSH
nc -zv servidor 22

# Aumentar timeout
ssh -o ConnectTimeout=30 user@servidor
```

### Problema: "bash: command not found"

```bash
# Verificar se Docker está instalado remotamente
ssh user@servidor "which docker"

# Verificar se scripts foram copiados
ssh user@servidor "ls -la /opt/portainer-tool/"
```

### Problema: "sudo: no tty present"

```bash
# Para limpeza de logs (que requer sudo)
ssh -t user@servidor "sudo bash -s clean-logs" < one-liner.sh

# Ou configurar NOPASSWD no sudoers (cuidado!)
```

---

## 🔒 Boas Práticas de Segurança

### 1. Use Chaves SSH, Não Senhas

```bash
# Sempre use autenticação por chave
ssh-keygen -t rsa -b 4096
ssh-copy-id user@servidor
```

### 2. Limite Acesso SSH

```bash
# No servidor, editar /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

### 3. Use Usuários Específicos

```bash
# Crie usuário dedicado para automação
sudo useradd -m -s /bin/bash docker-admin
sudo usermod -aG docker docker-admin

# Deploy com esse usuário
./remote-deploy.sh -u docker-admin servidor
```

### 4. Teste em Staging Primeiro

```bash
# Sempre teste em ambiente de staging
./remote-exec.sh -f staging-servers.txt cleanup --dry-run

# Só então execute em produção
./remote-exec.sh -f prod-servers.txt cleanup
```

### 5. Mantenha Logs de Auditoria

```bash
# Log todas as execuções
./remote-exec.sh analyze servidor 2>&1 | tee -a execution-log.txt
```

---

## 📝 Referência Rápida

### One-Liner
```bash
ssh user@host "bash -s COMANDO" < one-liner.sh
```

### Deploy Remoto
```bash
./remote-deploy.sh [opções] HOST1 HOST2 ...
```

### Execução Remota
```bash
./remote-exec.sh [opções] COMANDO HOST1 HOST2 ...
```

### Arquivo de Servidores
```bash
# servers.txt (um host por linha)
192.168.1.100
server1.com
```

---

## 🎓 Exemplos Avançados

### Pipeline de Manutenção Completa

```bash
#!/bin/bash
# pipeline-manutencao.sh

SERVERS_FILE="prod-servers.txt"

echo "1. Coletando análises..."
./remote-exec.sh -f $SERVERS_FILE analyze > pre-cleanup-report.txt

echo "2. Limpando logs..."
./remote-exec.sh -f $SERVERS_FILE clean-logs

echo "3. Limpando recursos..."
./remote-exec.sh -f $SERVERS_FILE cleanup

echo "4. Análise final..."
./remote-exec.sh -f $SERVERS_FILE analyze > post-cleanup-report.txt

echo "5. Gerando comparação..."
diff pre-cleanup-report.txt post-cleanup-report.txt > comparison.txt

echo "Concluído! Ver comparison.txt"
```

### Monitoramento Contínuo

```bash
#!/bin/bash
# monitor-continuo.sh

while true; do
    clear
    date
    echo "===================="
    
    ./remote-exec.sh -f servers.txt monitor
    
    sleep 300  # 5 minutos
done
```

---

## 📚 Recursos Adicionais

- **README.md** - Documentação completa das ferramentas
- **QUICK-START.md** - Guia de início rápido
- **cron-example.txt** - Exemplos de automação
- **docker-compose-examples.yml** - Exemplos de configuração

---

**Dica Final**: Comece com one-liner para testes rápidos, faça deploy permanente em servidores importantes, e use execução remota para operações em lote!

🚀 Boa sorte com a manutenção remota!


