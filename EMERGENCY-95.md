# 🚨 GUIA DE EMERGÊNCIA - Disco 95% Cheio

> **Situação Crítica**: Seu disco está com **95% de uso** (80G usado de 88G)
> 
> Este guia fornece comandos **prontos para copiar e colar** na ordem correta.

---

## 📊 PASSO 1: Análise Completa (Host + Docker)

Execute estes dois comandos para identificar o problema:

```bash
# Análise do HOST (logs do sistema Linux)
sudo ./host-disk-analyzer.sh

# Análise do DOCKER (containers, imagens, volumes)
./docker-disk-analyzer.sh
```

**Olhe especialmente para**:
- 🔍 Top 10 Maiores Logs em /var/log
- 🔍 Tamanho dos Logs do Journal (systemd)
- 🔍 Logs dos Containers Docker
- 🔍 Maiores Arquivos do Sistema

---

## 🔥 PASSO 2: Limpeza de Emergência - Logs do Sistema

**MAIS COMUM**: Logs do sistema (journal, syslog, etc.) ocupando muito espaço

```bash
# Limpar logs do journal (pode liberar vários GB!)
sudo journalctl --vacuum-size=100M

# Verificar quanto liberou
df -h /
```

**Se ainda precisar de mais espaço**:

```bash
# Limpeza completa do host (RECOMENDADO)
sudo ./host-cleanup.sh

# Ou execute manualmente:

# Remove logs antigos compactados (> 7 dias)
sudo find /var/log -name "*.gz" -mtime +7 -delete

# Remove logs rotacionados antigos
sudo find /var/log -name "*.log.*" -mtime +7 -delete

# Trunca logs muito grandes
sudo find /var/log -type f -size +100M -exec truncate -s 0 {} \;

# Limpa cache de pacotes
sudo apt-get clean && sudo apt-get autoclean  # Ubuntu/Debian
# OU
sudo yum clean all  # CentOS/RHEL
```

---

## 🐳 PASSO 3: Limpeza de Emergência - Docker

**SEGUNDO MAIS COMUM**: Logs dos containers Docker

```bash
# Limpar logs dos containers Docker
./docker-log-cleanup.sh --all

# Verificar quanto liberou
df -h /
```

**Se ainda precisar de mais espaço**:

```bash
# Limpeza de recursos Docker não usados
./docker-cleanup.sh --all --force

# Ou comando direto do Docker (CUIDADO!)
docker system prune -a -f
```

---

## 🎯 PASSO 4: Verificar Resultado

```bash
# Verificar uso atual
df -h /

# Verificar uso do Docker especificamente
docker system df

# Verificar tamanho do journal
sudo journalctl --disk-usage
```

---

## 📋 CHECKLIST DE LIMPEZA COMPLETA

Execute na ordem, verificando o espaço após cada etapa:

### ✅ **1. Journal Logs** (Geralmente o maior problema)
```bash
sudo journalctl --vacuum-size=100M
df -h /
```

### ✅ **2. Logs Antigos do Sistema**
```bash
sudo find /var/log -name "*.gz" -mtime +7 -delete
sudo find /var/log -name "*.log.*" -mtime +7 -delete
df -h /
```

### ✅ **3. Logs dos Containers Docker**
```bash
./docker-log-cleanup.sh --all
df -h /
```

### ✅ **4. Cache de Pacotes**
```bash
sudo apt-get clean && sudo apt-get autoclean
df -h /
```

### ✅ **5. Recursos Docker Não Usados**
```bash
docker container prune -f
docker image prune -f
df -h /
```

### ✅ **6. Arquivos Temporários**
```bash
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
df -h /
```

### ✅ **7. Logs Grandes (> 100MB)**
```bash
sudo find /var/log -type f -size +100M -exec truncate -s 0 {} \;
df -h /
```

---

## 🔍 COMANDOS DE DIAGNÓSTICO RÁPIDO

Use estes para identificar rapidamente o problema:

```bash
# Top 10 diretórios maiores na raiz
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10

# Top 10 maiores logs
sudo find /var/log -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -10

# Tamanho do journal
sudo journalctl --disk-usage

# Top 20 maiores arquivos do sistema
sudo find / -type f -size +100M -exec du -h {} \; 2>/dev/null | sort -rh | head -20

# Uso do Docker
docker system df -v

# Logs dos containers
sudo du -sh /var/lib/docker/containers/*/*-json.log | sort -rh | head -10
```

---

## 🆘 ÚLTIMO RECURSO - Limpeza Agressiva

**APENAS SE NADA MAIS FUNCIONAR** e você souber o que está fazendo:

```bash
# Backup primeiro (se possível)
# Então:

# Remove TUDO não usado do Docker (CUIDADO!)
docker system prune -a --volumes -f

# Remove todos os containers parados
docker container prune -f

# Remove todas as imagens não usadas
docker image prune -a -f

# Remove todos os volumes não usados (DADOS PODEM SER PERDIDOS!)
docker volume prune -f

# Limpa mais journal
sudo journalctl --vacuum-time=1d

# Remove logs do sistema
sudo rm -f /var/log/*.log.*
sudo rm -f /var/log/*.gz
```

---

## 🛡️ PREVENÇÃO - Configure Após Resolver

Depois de liberar espaço, **configure para não acontecer de novo**:

### 1. **Configurar Limites de Log do Docker**
```bash
./configure-log-limits.sh
```

### 2. **Configurar Limite do Journal**
```bash
sudo nano /etc/systemd/journald.conf

# Adicione/edite:
SystemMaxUse=100M
RuntimeMaxUse=100M

# Salve e reinicie
sudo systemctl restart systemd-journald
```

### 3. **Configurar Logrotate**
```bash
# Criar regra para rotacionar logs do Docker
sudo nano /etc/logrotate.d/docker-containers

# Adicione:
/var/lib/docker/containers/*/*.log {
    rotate 3
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
}
```

### 4. **Automatizar Limpeza**
```bash
# Adicionar ao crontab
sudo crontab -e

# Adicione estas linhas:

# Limpa journal toda segunda às 2h
0 2 * * 1 journalctl --vacuum-size=100M

# Limpa logs do host toda semana
0 3 * * 0 /root/portainer-tool/host-cleanup.sh --force

# Limpa logs do Docker toda semana
0 4 * * 0 /root/portainer-tool/docker-log-cleanup.sh --size 100M

# Limpa recursos Docker todo mês
0 5 1 * * /root/portainer-tool/docker-cleanup.sh --containers --images --force
```

---

## 📱 MONITORAMENTO

Configure alertas para não chegar a 95% novamente:

```bash
# Script de monitoramento (adicionar ao cron)
cat > /root/check-disk-usage.sh << 'EOF'
#!/bin/bash
USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$USAGE" -gt 80 ]; then
    echo "ALERTA: Disco com ${USAGE}% de uso!" | mail -s "Alerta de Disco" seu-email@example.com
    # Ou envie para webhook/Slack/Discord
fi
EOF

chmod +x /root/check-disk-usage.sh

# Adicionar ao cron (verifica a cada hora)
0 * * * * /root/check-disk-usage.sh
```

---

## 🎯 RESUMO EXECUTIVO

**Para resolver AGORA (copie e cole)**:

```bash
# 1. Análise
sudo ./host-disk-analyzer.sh
./docker-disk-analyzer.sh

# 2. Limpeza Journal (principal suspeito)
sudo journalctl --vacuum-size=100M
df -h /

# 3. Limpeza Logs Sistema
sudo find /var/log -name "*.gz" -mtime +7 -delete
sudo find /var/log -name "*.log.*" -mtime +7 -delete
df -h /

# 4. Limpeza Docker
./docker-log-cleanup.sh --all
./docker-cleanup.sh --all --force
df -h /

# 5. Verificar resultado
df -h /
docker system df
```

**Se ainda estiver > 90%**:

```bash
# Investigar manualmente os maiores arquivos
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10

# E limpar conforme necessário
```

---

## ❓ PERGUNTAS FREQUENTES

**Q: É seguro rodar estes comandos?**  
A: Sim, os scripts mantêm os logs recentes e removem apenas o que é seguro.

**Q: Vou perder dados?**  
A: Não, a menos que você execute `docker volume prune` sem verificar primeiro.

**Q: Quanto espaço vou liberar?**  
A: Geralmente 10-50GB, dependendo do tempo sem manutenção.

**Q: Posso automatizar tudo?**  
A: Sim! Veja a seção de Prevenção acima.

**Q: E se nada funcionar?**  
A: Investigue os 10 maiores diretórios manualmente:
```bash
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10
```

---

## 📞 PRÓXIMOS PASSOS

1. ✅ Execute a análise completa
2. ✅ Limpe o que for identificado como maior problema
3. ✅ Configure limites para prevenir
4. ✅ Automatize a limpeza periódica
5. ✅ Configure alertas de monitoramento

**Boa sorte! 🚀**

*Depois de resolver, não esqueça de configurar a prevenção para isso não acontecer de novo.*

