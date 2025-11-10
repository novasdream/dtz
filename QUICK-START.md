# 🚀 Guia Rápido de Início

> Guia condensado para começar a usar as ferramentas de manutenção Docker/Portainer imediatamente.

## ⚡ Primeiros Passos (5 minutos)

### 1. Verifique a Situação Atual
```bash
./docker-disk-analyzer.sh
```
**O que faz**: Mostra onde seu disco está sendo usado.

### 2. Limpe os Logs Grandes (se necessário)
```bash
# Teste primeiro (não faz alterações)
./docker-log-cleanup.sh --dry-run

# Execute a limpeza
./docker-log-cleanup.sh
```
**O que faz**: Limpa logs maiores que 100MB, mantendo as últimas 1000 linhas.

### 3. Remova Recursos Não Utilizados
```bash
# Teste primeiro
./docker-cleanup.sh --all --dry-run

# Execute a limpeza
./docker-cleanup.sh --all
```
**O que faz**: Remove containers parados, imagens não usadas, volumes órfãos.

### 4. Configure Limites para o Futuro
```bash
./configure-log-limits.sh
```
**O que faz**: Evita que logs cresçam descontroladamente em novos containers.

---

## 📊 Comandos Mais Usados

### Análise Rápida
```bash
./docker-disk-analyzer.sh
```

### Limpeza de Emergência
```bash
# Limpa tudo que for seguro
./docker-log-cleanup.sh --all
./docker-cleanup.sh --all --force
```

### Monitoramento em Tempo Real
```bash
./docker-monitor.sh
```
Pressione `Ctrl+C` para sair.

### Manutenção Completa
```bash
./manutencao-semanal.sh
```

---

## 🎯 Casos de Uso Comuns

### 😱 "HELP! Meu disco está cheio!"
```bash
# 1. Veja onde está o problema
./docker-disk-analyzer.sh

# 2. Limpe logs imediatamente
./docker-log-cleanup.sh --all

# 3. Remova tudo não utilizado
./docker-cleanup.sh --all --force

# 4. Verifique o resultado
df -h
```

### 🔍 "Quero só ver, sem fazer nada"
```bash
# Análise completa sem alterações
./docker-disk-analyzer.sh
./docker-monitor.sh --once

# Teste limpezas
./docker-log-cleanup.sh --dry-run
./docker-cleanup.sh --all --dry-run
```

### 🗓️ "Quero automação semanal"
```bash
# Edite o crontab
crontab -e

# Adicione esta linha (ajuste o caminho):
0 4 * * 0 /caminho/para/portainer-tool/manutencao-semanal.sh
```

### 📈 "Quero monitorar continuamente"
```bash
# Em um terminal separado
./docker-monitor.sh --interval 10
```

---

## 🛠️ Opções Úteis de Cada Script

### docker-log-cleanup.sh
```bash
--dry-run          # Teste sem fazer alterações
--size 200M        # Limpa logs > 200MB
--lines 500        # Mantém últimas 500 linhas
--all              # Limpa todos os logs
```

### docker-cleanup.sh
```bash
--dry-run          # Teste sem fazer alterações
--containers       # Remove apenas containers parados
--images           # Remove apenas imagens não usadas
--volumes          # Remove apenas volumes órfãos
--all              # Remove tudo
--force            # Não pede confirmação
```

### docker-monitor.sh
```bash
--interval 30      # Atualiza a cada 30 segundos
--once             # Executa uma vez e sai
--log-threshold 200  # Alerta para logs > 200MB
```

---

## ⚠️ Avisos Importantes

### ✅ Seguro para Executar
- `docker-disk-analyzer.sh` - Apenas leitura
- `docker-monitor.sh` - Apenas leitura
- Qualquer comando com `--dry-run`

### ⚠️ Execute com Cuidado
- `docker-log-cleanup.sh` - Trunca logs (mantém últimas linhas)
- `docker-cleanup.sh --containers` - Remove containers parados
- `docker-cleanup.sh --images` - Remove imagens não usadas

### 🔴 CUIDADO!
- `docker-cleanup.sh --volumes` - Pode remover dados permanentemente
- `docker-cleanup.sh --all --force` - Remove tudo sem perguntar
- `configure-log-limits.sh` - Reinicia o Docker daemon

**Regra de ouro**: Sempre teste com `--dry-run` primeiro!

---

## 📁 Estrutura de Arquivos

```
portainer-tool/
├── docker-disk-analyzer.sh      # Análise de uso de disco
├── docker-log-cleanup.sh        # Limpeza de logs
├── docker-cleanup.sh            # Limpeza geral
├── docker-monitor.sh            # Monitoramento em tempo real
├── configure-log-limits.sh      # Configura limites de log
├── manutencao-semanal.sh        # Manutenção automatizada
├── README.md                    # Documentação completa
├── QUICK-START.md              # Este arquivo
├── cron-example.txt            # Exemplos de cron jobs
└── .gitignore                  # Ignora logs no git
```

---

## 🔄 Workflow Recomendado

### Primeira Vez
1. Análise → 2. Limpeza → 3. Configuração → 4. Monitoramento

### Manutenção Regular
**Diária**: Monitoramento rápido
```bash
./docker-monitor.sh --once
```

**Semanal**: Limpeza de logs
```bash
./docker-log-cleanup.sh --size 100M
```

**Mensal**: Limpeza completa
```bash
./docker-cleanup.sh --all
```

---

## 💡 Dicas Rápidas

1. **Sempre comece analisando**
   ```bash
   ./docker-disk-analyzer.sh
   ```

2. **Use dry-run quando em dúvida**
   ```bash
   ./script.sh --dry-run
   ```

3. **Configure limites desde o início**
   ```bash
   ./configure-log-limits.sh
   ```

4. **Automatize com cron**
   ```bash
   # Ver exemplos em cron-example.txt
   ```

5. **Mantenha o monitor rodando**
   ```bash
   ./docker-monitor.sh &
   ```

---

## 🆘 Ajuda Rápida

### Ver todas as opções de um script
```bash
./script.sh --help
```

### Verificar se Docker está rodando
```bash
docker ps
```

### Ver uso atual do disco
```bash
df -h
docker system df
```

### Ver logs de um container
```bash
docker logs nome-do-container --tail 100
```

### Tornar scripts executáveis (se necessário)
```bash
chmod +x *.sh
```

---

## 📚 Mais Informações

Para documentação completa, veja: `README.md`

Para exemplos de automação, veja: `cron-example.txt`

---

**Pronto para começar? Execute:**
```bash
./docker-disk-analyzer.sh
```

🎉 Boa manutenção!

