#!/bin/bash
# ============================================================
# OpenClaw + Dashboard — Actualizador
# By Duvan AI (contenads.site)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   🔄 OpenClaw + Dashboard — Actualizador        ║"
echo "║   By Duvan AI · contenads.site                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

DASHBOARD_DIR="/opt/openclaw-dashboard"
INSTALL_DIR="/opt/openclaw"

# ─── Actualizar Dashboard ───
echo -e "${CYAN}[1/3] Actualizando Dashboard...${NC}"

if [ -d "$DASHBOARD_DIR/.git" ]; then
    cd "$DASHBOARD_DIR"
    
    # Guardar cambios locales si existen
    git stash --quiet 2>/dev/null
    
    # Traer cambios
    OLD_COMMIT=$(git rev-parse --short HEAD)
    git pull --quiet origin main 2>/dev/null
    NEW_COMMIT=$(git rev-parse --short HEAD)
    
    if [ "$OLD_COMMIT" = "$NEW_COMMIT" ]; then
        echo -e "${GREEN}  ✓ Dashboard ya está actualizado ($NEW_COMMIT)${NC}"
    else
        echo -e "${GREEN}  ✓ Dashboard actualizado: $OLD_COMMIT → $NEW_COMMIT${NC}"
        
        # Reiniciar dashboard
        systemctl restart openclaw-dashboard
        sleep 2
        
        if systemctl is-active --quiet openclaw-dashboard; then
            echo -e "${GREEN}  ✓ Dashboard reiniciado${NC}"
        else
            echo -e "${RED}  ⚠ Error al reiniciar. Revisa: journalctl -u openclaw-dashboard -n 20${NC}"
        fi
    fi
else
    echo -e "${RED}  ✗ Dashboard no encontrado en $DASHBOARD_DIR${NC}"
    echo -e "${YELLOW}  Instalando...${NC}"
    git clone --quiet https://github.com/duvanchat2/openclaw-dashboard.git "$DASHBOARD_DIR" 2>/dev/null
    if [ $? -eq 0 ]; then
        systemctl restart openclaw-dashboard 2>/dev/null
        echo -e "${GREEN}  ✓ Dashboard instalado${NC}"
    else
        echo -e "${RED}  ✗ Error al clonar dashboard${NC}"
    fi
fi

# ─── Actualizar Installer ───
echo -e "${CYAN}[2/3] Verificando actualizaciones del instalador...${NC}"

LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/duvanchat2/openclaw-installer/main/VERSION 2>/dev/null)
LOCAL_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "0")

if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$LOCAL_VERSION" ]; then
    echo -e "${GREEN}  Nueva versión disponible: v$LATEST_VERSION${NC}"
    echo "$LATEST_VERSION" > "$INSTALL_DIR/VERSION"
else
    echo -e "${GREEN}  ✓ Instalador actualizado${NC}"
fi

# ─── Verificar estado de servicios ───
echo -e "${CYAN}[3/3] Verificando servicios...${NC}"

if docker ps --format '{{.Names}} {{.Status}}' | grep -q "openclaw.*Up"; then
    echo -e "${GREEN}  ✓ OpenClaw corriendo${NC}"
else
    echo -e "${YELLOW}  ⚠ OpenClaw no está corriendo. Reiniciando...${NC}"
    cd "$INSTALL_DIR" && docker compose up -d
fi

if systemctl is-active --quiet openclaw-dashboard; then
    echo -e "${GREEN}  ✓ Dashboard corriendo${NC}"
else
    echo -e "${YELLOW}  ⚠ Dashboard no está corriendo. Reiniciando...${NC}"
    systemctl start openclaw-dashboard
fi

echo ""
echo -e "${GREEN}✅ Actualización completada${NC}"
echo ""
