# 🤖 OpenClaw Installer

Instalador automático de **OpenClaw + Dashboard** para VPS. Un solo comando.

## Instalación

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/duvanchat2/openclaw-installer/main/install.sh)
```

## Qué instala

| Componente | Descripción |
|---|---|
| OpenClaw v2026.2.25 | Agente de IA en Docker |
| Dashboard | Panel de administración web |
| Nginx + SSL | Proxy reverso con HTTPS (si tienes dominio) |

## Requisitos

- **VPS:** Ubuntu 22+ o Debian 12+
- **RAM:** Mínimo 2GB libre (recomendado 4GB)
- **Disco:** 5GB libres
- **Docker:** Se instala automáticamente si no existe

## Qué necesitas tener listo antes de instalar

### 1. Al menos 1 API Key de IA (obligatorio)

| Proveedor | Costo | Cómo obtenerla |
|---|---|---|
| **Google/Gemini** (recomendado) | Gratis | [aistudio.google.com](https://aistudio.google.com) → Get API Key |
| OpenRouter | Desde $0 | [openrouter.ai](https://openrouter.ai) → Keys |
| Anthropic/Claude | Desde $5 | [console.anthropic.com](https://console.anthropic.com) |
| OpenAI | Desde $5 | [platform.openai.com](https://platform.openai.com) |

### 2. Token de Telegram Bot (si usas Telegram)

1. Abre Telegram → busca **@BotFather**
2. Escribe `/newbot`
3. Ponle nombre al bot
4. BotFather te da el token → cópialo

El token se ve así: `1234567890:AAH_abcdefghijklmnopqrstuvwxyz`

### 3. Token de Discord Bot (si usas Discord)

1. Ve a [discord.com/developers](https://discord.com/developers/applications)
2. New Application → Bot → Reset Token → cópialo
3. Activa: Message Content Intent, Server Members Intent
4. Invita el bot a tu server con permisos de admin

### 4. Dominio (opcional)

Si tienes dominio, configura un registro DNS tipo **A** apuntando a la IP de tu VPS antes de instalar.

## El instalador te pide

1. **Nombre del agente** — cómo se llama tu IA (ej: Nova, Atlas, Max)
2. **Nombre del negocio** — para personalizar el agente
3. **Token de Telegram** — pega el token completo o Enter para saltar
4. **Token de Discord** — pega el token completo o Enter para saltar
5. **API Keys** — al menos 1 requerida
6. **Puerto** — default 7000, solo da Enter
7. **Dominio** — si tienes, escríbelo. Si no, Enter para saltar

## Después de instalar

### Verificar que funciona

```bash
# Ver logs de OpenClaw
docker logs openclaw --tail 20

# Ver estado del dashboard
systemctl status openclaw-dashboard

# Ver estado de todo
docker ps
```

### Probar el bot

Envía un mensaje al bot en Telegram o Discord. Debería responder.

### Acceder al dashboard

- **Sin dominio:** `http://TU_IP:7000`
- **Con dominio:** `https://tu-dominio.com`

## Solución de problemas

### Bot no responde en Telegram

**Error:** `404: Not Found` o `setMyCommands failed`

**Causa:** Token de Telegram inválido o expirado.

**Solución:**
```bash
# 1. Crea nuevo token con @BotFather → /mybots → tu bot → API Token
# 2. Edita el compose
nano /opt/openclaw/docker-compose.yml
# 3. Reemplaza TELEGRAM_BOT_TOKEN con el nuevo token
# 4. Reinicia
cd /opt/openclaw && docker compose down && docker compose up -d
```

### OpenClaw se reinicia constantemente

**Error:** `Missing config` o `unknown command 'start'`

**Solución:** Esto ya está manejado en el instalador v4. Si persiste:
```bash
mkdir -p /opt/openclaw/data/config
cat > /opt/openclaw/data/config/config.json << 'EOF'
{
  "gateway": {
    "mode": "local"
  }
}
EOF
cd /opt/openclaw && docker compose down && docker compose up -d
```

### Dashboard no carga

```bash
journalctl -u openclaw-dashboard -n 20
systemctl restart openclaw-dashboard
```

### SSL no funciona

1. Ve a tu proveedor de dominio
2. Agrega registro DNS: **Tipo A** → **@** → **IP de tu VPS**
3. Espera 5-30 minutos
4. Corre: `certbot --nginx -d tu-dominio.com`

### Cambiar API Keys

```bash
nano /opt/openclaw/docker-compose.yml
# Cambia la key en environment
cd /opt/openclaw && docker compose down && docker compose up -d
```

## Estructura de archivos

```
/opt/openclaw/
├── Dockerfile
├── docker-compose.yml
├── data/
│   ├── config/config.json        ← Config del gateway
│   ├── workspace/
│   │   ├── SOUL.md               ← Personalidad del agente
│   │   ├── MEMORY.md             ← Memoria del agente
│   │   ├── skills/               ← Skills del agente
│   │   └── data/credentials-vault.json
│   └── agents/main/
│       ├── agent/auth-profiles.json  ← API keys
│       └── sessions/                 ← Historial
└── config/

/opt/openclaw-dashboard/
├── server.js
├── index.html
└── data/
```

## Comandos útiles

```bash
# Reiniciar OpenClaw
cd /opt/openclaw && docker compose down && docker compose up -d

# Logs en tiempo real
docker logs -f openclaw

# Reiniciar dashboard
systemctl restart openclaw-dashboard

# Editar personalidad
nano /opt/openclaw/data/workspace/SOUL.md

# Editar memoria
nano /opt/openclaw/data/workspace/MEMORY.md

# Ver recursos
docker stats openclaw --no-stream
```

## Actualizaciones

Cuando haya nuevas funcionalidades o correcciones, los clientes actualizan con:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/duvanchat2/openclaw-installer/main/update.sh)
```

Esto automáticamente:
- Descarga los cambios del dashboard desde GitHub
- Reinicia el dashboard
- Verifica que OpenClaw esté corriendo
- Muestra el estado de todo

## Desinstalar

```bash
cd /opt/openclaw && docker compose down
systemctl stop openclaw-dashboard && systemctl disable openclaw-dashboard
rm -rf /opt/openclaw /opt/openclaw-dashboard
rm /etc/systemd/system/openclaw-dashboard.service
systemctl daemon-reload
```

---

**By [Duvan AI](https://contenads.site)** — Automatización con IA
