# 🐳 Ferramentas de Manutenção Docker/Portainer

Conjunto de scripts para auxiliar na manutenção e gerenciamento de armazenamento em servidores Docker/Portainer.

## 📋 Problema Resolvido

Este toolkit resolve problemas comuns de armazenamento em servidores Docker, especialmente relacionados a:
- ❌ Logs de containers crescendo descontroladamente
- ❌ Imagens Docker não utilizadas ocupando espaço
- ❌ Volumes órfãos acumulando ao longo do tempo
- ❌ Falta de visibilidade sobre o uso de disco
- ❌ Containers parados consumindo recursos

## 🛠️ Scripts Disponíveis

### 1. `docker-disk-analyzer.sh` - Análise de Uso de Disco

**Propósito**: Identifica onde o armazenamento está sendo utilizado no ambiente Docker.

**Funcionalidades**:
- ✅ Análise completa do uso de disco Docker
- ✅ Top 10 containers com maiores logs
- ✅ Top 10 maiores imagens Docker
- ✅ Lista de volumes e seus tamanhos
- ✅ Identificação de containers parados
- ✅ Identificação de imagens não utilizadas (dangling)
- ✅ Identificação de volumes órfãos
- ✅ Análise do diretório `/var/lib/docker`
- ✅ Recomendações automáticas

**Uso**:
```bash
# Torna o script executável
chmod +x docker-disk-analyzer.sh

# Executa a análise
./docker-disk-analyzer.sh
```

**Exemplo de saída**:
```
========================================
  Análise de Disco Docker/Portainer
========================================

[1] Uso Geral do Disco:
Filesystem      Size   Used  Avail Capacity
/dev/sda1       100G   75G   25G   75%

[2] Informações do Docker System:
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          25        10        5GB       3GB (60%)
Containers      15        8         2GB       500MB (25%)
Local Volumes   10        5         10GB      5GB (50%)

[3] Top 10 Containers com Maiores Logs:
portainer       2.5GB
nginx-proxy     1.2GB
mysql-db        800MB
...
```

---

### 2. `docker-log-cleanup.sh` - Limpeza de Logs

**Propósito**: Limpa logs grandes de containers mantendo as últimas linhas.

**Funcionalidades**:
- ✅ Limpeza segura de logs (mantém últimas N linhas)
- ✅ Modo dry-run para teste
- ✅ Filtro por tamanho mínimo
- ✅ Configuração de quantas linhas manter
- ✅ Estatísticas de espaço liberado

**Uso**:
```bash
# Torna o script executável
chmod +x docker-log-cleanup.sh

# Modo teste (não faz alterações)
./docker-log-cleanup.sh --dry-run

# Limpa logs maiores que 100MB (padrão)
./docker-log-cleanup.sh

# Limpa logs maiores que 200MB
./docker-log-cleanup.sh --size 200M

# Mantém apenas as últimas 500 linhas
./docker-log-cleanup.sh --lines 500

# Limpa todos os logs independente do tamanho
./docker-log-cleanup.sh --all
```

**Opções**:
- `-d, --dry-run`: Mostra o que seria feito sem executar
- `-s, --size TAMANHO`: Tamanho mínimo para limpeza (ex: 100M, 1G)
- `-l, --lines LINHAS`: Número de linhas a manter (padrão: 1000)
- `-a, --all`: Limpa todos os logs independente do tamanho
- `-h, --help`: Mostra ajuda

---

### 3. `docker-cleanup.sh` - Limpeza Geral

**Propósito**: Remove recursos Docker não utilizados (containers, imagens, volumes).

**Funcionalidades**:
- ✅ Remove containers parados
- ✅ Remove imagens não utilizadas
- ✅ Remove volumes órfãos
- ✅ Remove networks não utilizadas
- ✅ Limpa cache de build
- ✅ Modo dry-run
- ✅ Confirmação antes de executar
- ✅ Estatísticas antes e depois

**Uso**:
```bash
# Torna o script executável
chmod +x docker-cleanup.sh

# Mostra ajuda
./docker-cleanup.sh --help

# Modo teste (não faz alterações)
./docker-cleanup.sh --all --dry-run

# Remove apenas containers parados
./docker-cleanup.sh --containers

# Remove apenas imagens não utilizadas
./docker-cleanup.sh --images

# Remove apenas volumes órfãos
./docker-cleanup.sh --volumes

# Limpeza completa (com confirmação)
./docker-cleanup.sh --all

# Limpeza completa sem confirmação
./docker-cleanup.sh --all --force
```

**Opções**:
- `-d, --dry-run`: Mostra o que seria feito sem executar
- `-c, --containers`: Limpa apenas containers parados
- `-i, --images`: Limpa apenas imagens não utilizadas
- `-v, --volumes`: Limpa apenas volumes não utilizados
- `-a, --all`: Limpa tudo
- `-f, --force`: Não pede confirmação
- `-h, --help`: Mostra ajuda

**⚠️ ATENÇÃO**: A remoção de volumes é irreversível. Certifique-se de ter backups!

---

### 4. `docker-monitor.sh` - Monitoramento Contínuo

**Propósito**: Monitora em tempo real o uso de recursos e detecta problemas.

**Funcionalidades**:
- ✅ Dashboard em tempo real
- ✅ Monitoramento de CPU e memória por container
- ✅ Alertas para logs grandes
- ✅ Alertas para uso de disco elevado
- ✅ Contagem de recursos não utilizados
- ✅ Log de alertas em arquivo
- ✅ Interface colorida e organizada

**Uso**:
```bash
# Torna o script executável
chmod +x docker-monitor.sh

# Inicia monitoramento (atualiza a cada 5 segundos)
./docker-monitor.sh

# Define intervalo de atualização
./docker-monitor.sh --interval 10

# Define threshold para alertas de logs (em MB)
./docker-monitor.sh --log-threshold 200

# Define threshold para alertas de disco (em %)
./docker-monitor.sh --disk-threshold 90

# Executa apenas uma vez (não fica em loop)
./docker-monitor.sh --once
```

**Opções**:
- `-i, --interval SEGUNDOS`: Intervalo de atualização (padrão: 5)
- `-l, --log-threshold MB`: Alerta para logs maiores que X MB (padrão: 100)
- `-d, --disk-threshold %`: Alerta para disco acima de X% (padrão: 80)
- `-o, --once`: Executa apenas uma vez
- `-h, --help`: Mostra ajuda

**Alertas salvos em**: `~/.docker-monitor-alerts.log`

---

### 5. `configure-log-limits.sh` - Configuração de Limites

**Propósito**: Configura limites globais de log para o Docker daemon.

**Funcionalidades**:
- ✅ Configura limites para novos containers
- ✅ Backup automático da configuração anterior
- ✅ Validação de JSON
- ✅ Instruções específicas para MacOS/Linux

**Uso**:
```bash
# Torna o script executável
chmod +x configure-log-limits.sh

# Configura com valores padrão (10MB, 3 arquivos)
./configure-log-limits.sh

# Configura tamanho máximo por arquivo
./configure-log-limits.sh --max-size 50m

# Configura número de arquivos
./configure-log-limits.sh --max-files 5

# Configura ambos
./configure-log-limits.sh --max-size 20m --max-files 4
```

**⚠️ MacOS com Docker Desktop**:
No MacOS, o script fornece instruções para configurar através da interface gráfica do Docker Desktop.

**⚠️ Importante**:
- Esta configuração afeta apenas **novos** containers
- Containers existentes precisam ser recriados para aplicar os limites

---

## 🚀 Guia de Início Rápido

### 1️⃣ Análise Inicial
```bash
# Primeiro, analise onde está o problema
./docker-disk-analyzer.sh
```

### 2️⃣ Limpeza de Logs
```bash
# Teste primeiro
./docker-log-cleanup.sh --dry-run

# Execute a limpeza
./docker-log-cleanup.sh
```

### 3️⃣ Limpeza Geral
```bash
# Teste primeiro
./docker-cleanup.sh --all --dry-run

# Execute a limpeza
./docker-cleanup.sh --all
```

### 4️⃣ Configure Limites
```bash
# Previna problemas futuros
./configure-log-limits.sh
```

### 5️⃣ Monitore Continuamente
```bash
# Mantenha um olho no sistema
./docker-monitor.sh
```

---

## 📅 Manutenção Automatizada

### Cron Job Recomendado

Adicione ao crontab para execução automática:

```bash
# Edita o crontab
crontab -e

# Adicione as seguintes linhas:

# Limpeza de logs toda segunda-feira às 2h
0 2 * * 1 /caminho/para/docker-log-cleanup.sh --size 100M

# Limpeza geral todo domingo às 3h
0 3 * * 0 /caminho/para/docker-cleanup.sh --containers --images --force

# Análise diária às 8h (salva em arquivo)
0 8 * * * /caminho/para/docker-disk-analyzer.sh > /var/log/docker-analysis-$(date +\%Y\%m\%d).log
```

### Script de Manutenção Semanal

Crie um script combinado:

```bash
#!/bin/bash
# manutencao-semanal.sh

echo "Iniciando manutenção semanal do Docker..."

# 1. Análise antes
echo "[1/4] Análise inicial..."
./docker-disk-analyzer.sh > /var/log/docker-before.log

# 2. Limpa logs
echo "[2/4] Limpando logs..."
./docker-log-cleanup.sh --size 50M

# 3. Limpa recursos
echo "[3/4] Limpando recursos..."
./docker-cleanup.sh --all --force

# 4. Análise depois
echo "[4/4] Análise final..."
./docker-disk-analyzer.sh > /var/log/docker-after.log

echo "Manutenção concluída!"
```

---

## 🔧 Requisitos

- Docker instalado e rodando
- Bash 4.0 ou superior
- Permissões sudo (para alguns scripts)
- Comandos necessários: `docker`, `du`, `stat`, `awk`, `sed`

### MacOS
- Docker Desktop instalado
- Homebrew (opcional, para instalar dependências)

### Linux
- Docker CE ou EE
- Acesso ao systemctl (para reiniciar daemon)

---

## 📊 Casos de Uso

### Caso 1: Servidor sem espaço
```bash
# 1. Identifique o problema
./docker-disk-analyzer.sh

# 2. Limpe logs imediatamente
./docker-log-cleanup.sh --all

# 3. Remova recursos não utilizados
./docker-cleanup.sh --all --force

# 4. Configure limites
./configure-log-limits.sh
```

### Caso 2: Prevenção
```bash
# 1. Configure limites globais
./configure-log-limits.sh

# 2. Agende limpezas automáticas
# (configure cron jobs)

# 3. Monitore regularmente
./docker-monitor.sh --interval 30
```

### Caso 3: Investigação de container específico
```bash
# 1. Execute análise
./docker-disk-analyzer.sh

# 2. Identifique o container problemático
# 3. Limpe apenas logs grandes
./docker-log-cleanup.sh --size 500M

# 4. Verifique logs do container
docker logs nome-do-container --tail 100
```

---

## 🎯 Boas Práticas

### 1. **Configure Limites de Log no docker-compose.yml**
```yaml
version: '3.8'
services:
  seu-servico:
    image: sua-imagem
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 2. **Configure Limites de Log no docker run**
```bash
docker run \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  sua-imagem
```

### 3. **Use Volumes Nomeados**
```yaml
volumes:
  dados-app:  # Volume nomeado (melhor)
    driver: local
```

Em vez de volumes anônimos que são difíceis de rastrear.

### 4. **Monitore Regularmente**
- Execute `docker-monitor.sh` periodicamente
- Configure alertas por email/slack
- Mantenha backups antes de limpezas

### 5. **Documente Seus Containers**
- Use labels para identificar containers importantes
- Documente quais volumes contêm dados críticos
- Mantenha um inventário atualizado

---

## ⚠️ Avisos Importantes

### 🔴 Antes de Executar em Produção

1. **Teste em ambiente de desenvolvimento primeiro**
2. **Faça backup de volumes importantes**
3. **Documente quais containers são críticos**
4. **Execute em horário de baixo movimento**
5. **Tenha um plano de rollback**

### 🔴 Sobre Remoção de Volumes

- A remoção de volumes é **IRREVERSÍVEL**
- Sempre verifique se não há dados importantes
- Use `--dry-run` antes de executar
- Faça backup se houver dúvida

### 🔴 Sobre Reinicialização do Docker

- Reiniciar o Docker **interrompe todos os containers**
- Planeje uma janela de manutenção
- Notifique usuários se aplicável
- Tenha procedimento de recuperação

---

## 🐛 Troubleshooting

### Problema: "Permission denied"
**Solução**: Execute com sudo ou adicione seu usuário ao grupo docker
```bash
sudo usermod -aG docker $USER
# Faça logout e login novamente
```

### Problema: "Command not found"
**Solução**: Certifique-se de que o script tem permissão de execução
```bash
chmod +x *.sh
```

### Problema: Scripts não funcionam no MacOS
**Solução**: Instale GNU coreutils
```bash
brew install coreutils
```

### Problema: "Docker daemon não responde"
**Solução**: Reinicie o Docker
```bash
# MacOS
# Reinicie pelo Docker Desktop

# Linux
sudo systemctl restart docker
```

---

## 📝 Logs e Auditoria

### Locais de Log
- Alertas do monitor: `~/.docker-monitor-alerts.log`
- Logs do Docker: `/var/lib/docker/containers/*/` *-json.log`
- Backup de configuração: `/etc/docker/daemon.json.backup.*`

### Como Visualizar Logs
```bash
# Últimos alertas do monitor
tail -f ~/.docker-monitor-alerts.log

# Logs de um container específico
docker logs nome-do-container

# Logs do Docker daemon
journalctl -u docker.service
```

---

## 🤝 Contribuindo

Sugestões de melhorias são bem-vindas! Alguns recursos planejados:
- [ ] Integração com Prometheus/Grafana
- [ ] Notificações por email/Slack
- [ ] Dashboard web
- [ ] Suporte a Docker Swarm
- [ ] Análise de performance
- [ ] Exportação de relatórios em PDF

---

## 📄 Licença

Scripts gerados para uso livre. Use por sua conta e risco.

---

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique a seção de Troubleshooting
2. Execute com `--help` para ver todas as opções
3. Teste com `--dry-run` antes de aplicar mudanças

---

## 🎉 Conclusão

Este toolkit fornece todas as ferramentas necessárias para manter seu ambiente Docker/Portainer saudável e com armazenamento otimizado.

**Recomendação**: Comece executando `docker-disk-analyzer.sh` para entender seu ambiente atual, depois aplique as limpezas conforme necessário e, finalmente, configure limites e monitoramento para prevenir problemas futuros.

**Manutenção sugerida**:
- 📊 **Diariamente**: Monitore com `docker-monitor.sh --once`
- 🧹 **Semanalmente**: Execute `docker-log-cleanup.sh`
- 🗑️ **Mensalmente**: Execute `docker-cleanup.sh --all`
- ⚙️ **Único**: Configure `configure-log-limits.sh`

Bom gerenciamento! 🚀

