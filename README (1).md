# OpenClaw Installer

Instalador automático de OpenClaw + Dashboard para VPS.

## Instalación

Un solo comando:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/contenads/openclaw-installer/main/install.sh)
```

## Qué instala

- OpenClaw v2026.2.25 (Docker)
- Dashboard de administración
- Estructura de workspace lista para usar
- Servicio systemd para el dashboard

## Requisitos

- VPS con Ubuntu 22+ o Debian 12+
- Mínimo 2GB RAM libre
- Docker (se instala automáticamente si no existe)

## Qué necesitas tener listo

- Al menos 1 API key de IA (Google/Gemini recomendado, es gratis)
- Token de Telegram Bot y/o Discord Bot (opcional)

## Después de instalar

1. Verificar: `docker logs openclaw --tail 20`
2. Enviar mensaje al bot en Telegram/Discord
3. Acceder al dashboard: `http://TU_IP:7000`

## By

[Duvan AI](https://contenads.site) — Automatización con IA
