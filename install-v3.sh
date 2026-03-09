#!/bin/bash
# ============================================================
# OpenClaw + Dashboard — Instalación para Clientes
# By Duvan AI (contenads.site)
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   🤖 OpenClaw + Dashboard — Instalador      ║"
echo "║   By Duvan AI · contenads.site              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Verificar Docker ───
if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker compose &>/dev/null && ! docker compose version &>/dev/null; then
    echo -e "${RED}Error: docker compose no encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker disponible${NC}"

# ─── Directorio base ───
INSTALL_DIR="/opt/openclaw"
DASHBOARD_DIR="/opt/openclaw-dashboard"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ─── Recoger datos del cliente ───
echo ""
echo -e "${CYAN}═══ Configuración del agente ═══${NC}"
echo ""

read -p "Nombre del agente (ej: Nova, Atlas, Max): " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-Nova}

read -p "Nombre del negocio/proyecto: " BUSINESS_NAME
BUSINESS_NAME=${BUSINESS_NAME:-Mi Proyecto}

echo ""
echo -e "${CYAN}═══ Canales de comunicación ═══${NC}"
echo ""

read -p "Token de Telegram Bot (dejar vacío si no usa): " TELEGRAM_TOKEN
read -p "Token de Discord Bot (dejar vacío si no usa): " DISCORD_TOKEN

echo ""
echo -e "${CYAN}═══ API Keys de IA (mínimo 1 requerida) ═══${NC}"
echo ""

read -p "Google/Gemini API Key (recomendado, gratis): " GOOGLE_KEY
read -p "OpenRouter API Key (opcional): " OPENROUTER_KEY
read -p "Anthropic API Key (opcional): " ANTHROPIC_KEY
read -p "OpenAI API Key (opcional): " OPENAI_KEY

# Verificar que al menos una key existe
if [ -z "$GOOGLE_KEY" ] && [ -z "$OPENROUTER_KEY" ] && [ -z "$ANTHROPIC_KEY" ] && [ -z "$OPENAI_KEY" ]; then
    echo -e "${RED}Error: necesitas al menos 1 API key de IA${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}═══ Puerto del Dashboard ═══${NC}"
echo ""

read -p "Puerto del dashboard (default 7000): " DASH_PORT
DASH_PORT=${DASH_PORT:-7000}

read -p "Puerto de OpenClaw Gateway (default 18789): " GW_PORT
GW_PORT=${GW_PORT:-18789}

# ─── Crear Dockerfile ───
echo -e "${YELLOW}Creando Dockerfile...${NC}"

cat > "$INSTALL_DIR/Dockerfile" << 'DOCKEREOF'
FROM node:25-bookworm-slim
RUN apt-get update && apt-get install -y \
    git python3 make g++ cmake curl wget \
    && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
RUN npm install -g openclaw@2026.2.25
RUN useradd -m -s /bin/bash openclaw
USER openclaw
WORKDIR /home/openclaw
EXPOSE 18789
CMD ["openclaw", "gateway"]
DOCKEREOF

# ─── Crear docker-compose.yml ───
echo -e "${YELLOW}Creando docker-compose.yml...${NC}"

cat > "$INSTALL_DIR/docker-compose.yml" << COMPOSEEOF
version: '3.8'
services:
  openclaw:
    build: .
    container_name: openclaw
    restart: unless-stopped
    network_mode: host
    command: ["openclaw", "gateway", "--allow-unconfigured"]
    volumes:
      - ./data:/home/openclaw/.openclaw
      - ./config:/home/openclaw/.config
    environment:
      - NODE_ENV=production
      - TZ=America/Bogota
COMPOSEEOF

# Agregar tokens condicionalmente
[ -n "$TELEGRAM_TOKEN" ] && echo "      - TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN" >> "$INSTALL_DIR/docker-compose.yml"
[ -n "$DISCORD_TOKEN" ] && echo "      - DISCORD_BOT_TOKEN=$DISCORD_TOKEN" >> "$INSTALL_DIR/docker-compose.yml"
[ -n "$GOOGLE_KEY" ] && echo "      - GOOGLE_API_KEY=$GOOGLE_KEY" >> "$INSTALL_DIR/docker-compose.yml"
[ -n "$OPENROUTER_KEY" ] && echo "      - OPENROUTER_API_KEY=$OPENROUTER_KEY" >> "$INSTALL_DIR/docker-compose.yml"
[ -n "$ANTHROPIC_KEY" ] && echo "      - ANTHROPIC_API_KEY=$ANTHROPIC_KEY" >> "$INSTALL_DIR/docker-compose.yml"
[ -n "$OPENAI_KEY" ] && echo "      - OPENAI_API_KEY=$OPENAI_KEY" >> "$INSTALL_DIR/docker-compose.yml"

# ─── Crear estructura de datos ───
echo -e "${YELLOW}Creando estructura de workspace...${NC}"

mkdir -p "$INSTALL_DIR/data/workspace/skills"
mkdir -p "$INSTALL_DIR/data/workspace/memory"
mkdir -p "$INSTALL_DIR/data/workspace/data"
mkdir -p "$INSTALL_DIR/data/agents/main/sessions"
mkdir -p "$INSTALL_DIR/data/config"
mkdir -p "$INSTALL_DIR/config"

# ─── Config principal de OpenClaw (CRÍTICO — sin esto no arranca) ───
cat > "$INSTALL_DIR/data/config/config.json" << CFGEOF
{
  "gateway": {
    "mode": "local"
  }
}
CFGEOF

# ─── Gateway service config ───
mkdir -p "$INSTALL_DIR/config/systemd/user"

# ─── SOUL.md ───
cat > "$INSTALL_DIR/data/workspace/SOUL.md" << SOULEOF
# SOUL.md — $AGENT_NAME

## Identidad
Soy $AGENT_NAME, el agente de IA de $BUSINESS_NAME.

## Principios
- **Acción > Palabras:** Ejecuto primero, explico después.
- **Velocidad > Perfección:** Entrego rápido e itero.
- **Proactiva:** Si veo un problema u oportunidad, actúo sin esperar.
- **Directa:** Sin relleno, sin frases vacías. Solo resultados.

## Comunicación
- Respondo en español
- Soy concisa y clara
- Uso emojis con moderación
- Confirmo antes de acciones destructivas (eliminar, publicar)

## Reglas
- Siempre leo MEMORY.md antes de actuar
- Documento mis acciones en el historial
- Pido confirmación antes de publicar o eliminar contenido
- Si no sé algo, lo digo y busco la respuesta
SOULEOF

# ─── MEMORY.md ───
cat > "$INSTALL_DIR/data/workspace/MEMORY.md" << MEMEOF
# MEMORY.md — $AGENT_NAME

## Proyecto
- Nombre: $BUSINESS_NAME
- Agente: $AGENT_NAME
- Instalado: $(date '+%Y-%m-%d')

## Skills disponibles
(Ninguna configurada aún)

## Notas
(Vacío — se irá llenando con el uso)
MEMEOF

# ─── IDENTITY.md ───
cat > "$INSTALL_DIR/data/workspace/IDENTITY.md" << IDEOF
# $AGENT_NAME
Agente de IA para $BUSINESS_NAME
Powered by OpenClaw
IDEOF

# ─── USER.md ───
cat > "$INSTALL_DIR/data/workspace/USER.md" << USEREOF
# Usuario
- Proyecto: $BUSINESS_NAME
- Idioma: Español
USEREOF

# ─── AGENTS.md ───
cat > "$INSTALL_DIR/data/workspace/AGENTS.md" << AGENTEOF
# Agentes
- main: $AGENT_NAME (orquestador principal)
AGENTEOF

# ─── TOOLS.md ───
cat > "$INSTALL_DIR/data/workspace/TOOLS.md" << TOOLSEOF
# Herramientas disponibles
- curl: Peticiones HTTP
- python3: Scripts y procesamiento
- exec: Ejecutar comandos del sistema
TOOLSEOF

# ─── credentials-vault.json (vacío) ───
cat > "$INSTALL_DIR/data/workspace/data/credentials-vault.json" << VAULTEOF
{
  "providers": [],
  "mcps": []
}
VAULTEOF

# ─── Auth profiles ───
mkdir -p "$INSTALL_DIR/data/agents/main/agent"

AUTH_JSON="{"
FIRST=true

if [ -n "$GOOGLE_KEY" ]; then
    AUTH_JSON="$AUTH_JSON\"google\":{\"apiKey\":\"$GOOGLE_KEY\"}"
    FIRST=false
fi
if [ -n "$OPENROUTER_KEY" ]; then
    [ "$FIRST" = false ] && AUTH_JSON="$AUTH_JSON,"
    AUTH_JSON="$AUTH_JSON\"openrouter\":{\"apiKey\":\"$OPENROUTER_KEY\"}"
    FIRST=false
fi
if [ -n "$ANTHROPIC_KEY" ]; then
    [ "$FIRST" = false ] && AUTH_JSON="$AUTH_JSON,"
    AUTH_JSON="$AUTH_JSON\"anthropic\":{\"apiKey\":\"$ANTHROPIC_KEY\"}"
    FIRST=false
fi
if [ -n "$OPENAI_KEY" ]; then
    [ "$FIRST" = false ] && AUTH_JSON="$AUTH_JSON,"
    AUTH_JSON="$AUTH_JSON\"openai\":{\"apiKey\":\"$OPENAI_KEY\"}"
fi

AUTH_JSON="$AUTH_JSON}"

echo "$AUTH_JSON" | python3 -m json.tool > "$INSTALL_DIR/data/agents/main/agent/auth-profiles.json" 2>/dev/null || echo "$AUTH_JSON" > "$INSTALL_DIR/data/agents/main/agent/auth-profiles.json"

# ─── Permisos ───
chmod -R 777 "$INSTALL_DIR/data"
chmod -R 777 "$INSTALL_DIR/config"

# ─── Build y arrancar OpenClaw ───
echo -e "${YELLOW}Construyendo imagen Docker (puede tardar 2-5 min)...${NC}"
cd "$INSTALL_DIR"
docker compose build
docker compose up -d

echo -e "${GREEN}✓ OpenClaw corriendo en puerto $GW_PORT${NC}"

# ─── Instalar Dashboard ───
echo -e "${YELLOW}Instalando Dashboard...${NC}"

if [ ! -d "$DASHBOARD_DIR" ]; then
    mkdir -p "$DASHBOARD_DIR"
    cd "$DASHBOARD_DIR"
    
    # Descargar dashboard desde GitHub
    # Si tienes el repo, reemplaza esta URL
    # git clone https://github.com/TU_USUARIO/openclaw-dashboard.git .
    
    echo -e "${YELLOW}Dashboard pendiente: copiar archivos server.js e index.html${NC}"
    echo -e "${YELLOW}O clonarlo desde el repositorio del dashboard${NC}"
else
    echo -e "${GREEN}✓ Dashboard ya existe en $DASHBOARD_DIR${NC}"
fi

# ─── Crear servicio systemd para dashboard ───
cat > /etc/systemd/system/openclaw-dashboard.service << SVCEOF
[Unit]
Description=OpenClaw Dashboard
After=network.target docker.service

[Service]
Type=simple
WorkingDirectory=$DASHBOARD_DIR
Environment=DASHBOARD_PORT=$DASH_PORT
Environment=OPENCLAW_DIR=$INSTALL_DIR/data
Environment=WORKSPACE_DIR=$INSTALL_DIR/data/workspace
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

# ─── Resumen final ───
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅ Instalación completada                  ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "  🤖 Agente: ${CYAN}$AGENT_NAME${NC}"
echo -e "  📁 Datos: ${CYAN}$INSTALL_DIR/data${NC}"
echo -e "  🌐 Gateway: ${CYAN}http://TU_IP:$GW_PORT${NC}"
echo -e "  📊 Dashboard: ${CYAN}http://TU_IP:$DASH_PORT${NC}"
echo ""

if [ -n "$TELEGRAM_TOKEN" ]; then
    echo -e "  💬 Telegram: ${GREEN}Configurado${NC}"
else
    echo -e "  💬 Telegram: ${YELLOW}No configurado${NC}"
fi

if [ -n "$DISCORD_TOKEN" ]; then
    echo -e "  🎮 Discord: ${GREEN}Configurado${NC}"
else
    echo -e "  🎮 Discord: ${YELLOW}No configurado${NC}"
fi

echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Verificar: docker logs openclaw --tail 20"
echo "  2. Enviar mensaje al bot en Telegram/Discord"
echo "  3. Acceder al dashboard: http://TU_IP:$DASH_PORT"
echo "  4. Agregar skills según necesidad"
echo ""
