#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

set -e

# ============================================================
# V2Ray for AlwaysData - Improved Installer
# ============================================================

VERSION="4.45.0"
BASE_URL="https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}"

USER_NAME="${USER}"
HOME_DIR="$HOME"
WEB_DIR="$HOME/www"

VMESS_PORT="8300"
VLESS_PORT="8400"

VMESS_PATH="/vmess"
VLESS_PATH="/vless"

HOST="${USER_NAME}.alwaysdata.net"

TMP_DIR="$(mktemp -d)"

echo
echo "============================================================"
echo "        V2Ray for AlwaysData"
echo "============================================================"
echo

# ------------------------------------------------------------
# Check dependencies
# ------------------------------------------------------------

for cmd in wget unzip qrencode; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is not installed."
        exit 1
    fi
done

# ------------------------------------------------------------
# UUID
# ------------------------------------------------------------

if [ -f "$HOME_DIR/.v2ray_uuid" ]; then
    UUID="$(cat "$HOME_DIR/.v2ray_uuid")"
else
    UUID="$(cat /proc/sys/kernel/random/uuid)"
    echo "$UUID" > "$HOME_DIR/.v2ray_uuid"
fi

echo "Host : $HOST"
echo "UUID : $UUID"
echo

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

mkdir -p "$WEB_DIR"

# ------------------------------------------------------------
# Download V2Ray
# ------------------------------------------------------------

echo "[1/8] Downloading V2Ray ${VERSION}..."

wget -q --show-progress \
    -O "$TMP_DIR/v2ray.zip" \
    "${BASE_URL}/v2ray-linux-64.zip"

# ------------------------------------------------------------
# Extract
# ------------------------------------------------------------

echo "[2/8] Installing V2Ray..."

unzip -oq "$TMP_DIR/v2ray.zip" -d "$TMP_DIR/v2ray"

cp "$TMP_DIR/v2ray/v2ray" "$HOME_DIR/v2ray"
cp "$TMP_DIR/v2ray/v2ctl" "$HOME_DIR/v2ctl"
cp "$TMP_DIR/v2ray/geoip.dat" "$HOME_DIR/geoip.dat"
cp "$TMP_DIR/v2ray/geosite.dat" "$HOME_DIR/geosite.dat"

chmod +x "$HOME_DIR/v2ray" "$HOME_DIR/v2ctl"

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------

echo "[3/8] Creating config.json..."

cat > "$HOME_DIR/config.json" <<EOF
{
    "log": {
        "access": "/dev/null",
        "error": "/dev/null",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": ${VMESS_PORT},
            "listen": "::",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "alterId": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "${VMESS_PATH}"
                }
            }
        },
        {
            "port": ${VLESS_PORT},
            "listen": "::",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "${VLESS_PATH}"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF

# ------------------------------------------------------------
# Test config
# ------------------------------------------------------------

echo "[4/8] Testing configuration..."

"$HOME_DIR/v2ray" -test -config "$HOME_DIR/config.json"

# ------------------------------------------------------------
# VMess link
# ------------------------------------------------------------

VMESS_JSON=$(printf \
'{"v":"2","ps":"AlwaysData-VMess","add":"%s","port":"443","id":"%s","aid":"0","net":"ws","type":"none","host":"%s","path":"%s","tls":"tls"}' \
"$HOST" "$UUID" "$HOST" "$VMESS_PATH")

VMESS_LINK="vmess://$(printf '%s' "$VMESS_JSON" | base64 -w0)"

# ------------------------------------------------------------
# VLESS link
# ------------------------------------------------------------

VLESS_LINK="vless://${UUID}@${HOST}:443?encryption=none&security=tls&type=ws&host=${HOST}&path=%2Fvless#AlwaysData-VLESS"

# ------------------------------------------------------------
# QR codes
# ------------------------------------------------------------

echo "[5/8] Creating QR codes..."

qrencode -o "$WEB_DIR/vmess.png" "$VMESS_LINK"
qrencode -o "$WEB_DIR/vless.png" "$VLESS_LINK"

# ------------------------------------------------------------
# Apache configuration
# ------------------------------------------------------------

echo "[6/8] Creating apache.conf..."

cat > "$HOME_DIR/apache.conf" <<EOF
ProxyRequests off
ProxyPreserveHost On

ProxyPass "${VMESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VMESS_PORT}${VMESS_PATH}"
ProxyPassReverse "${VMESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VMESS_PORT}${VMESS_PATH}"

ProxyPass "${VLESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VLESS_PORT}${VLESS_PATH}"
ProxyPassReverse "${VLESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VLESS_PORT}${VLESS_PATH}"
EOF

# ------------------------------------------------------------
# Web page
# ------------------------------------------------------------

echo "[7/8] Creating web pages..."

cat > "$WEB_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AlwaysData</title>
</head>
<body>
<h2>V2Ray for AlwaysData</h2>
<p>Service is installed.</p>
</body>
</html>
EOF

cat > "$WEB_DIR/${UUID}.html" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>V2Ray - AlwaysData</title>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 750px;
    margin: 30px auto;
    padding: 20px;
    text-align: center;
}

img {
    width: 260px;
    height: 260px;
    margin: 10px;
}

textarea {
    width: 100%;
    height: 90px;
    box-sizing: border-box;
    margin: 10px 0;
    padding: 10px;
}

hr {
    margin: 40px 0;
}
</style>
</head>

<body>

<h2>V2Ray</h2>

<h3>VMess</h3>

<img src="vmess.png">

<textarea readonly>${VMESS_LINK}</textarea>

<hr>

<h3>VLESS</h3>

<img src="vless.png">

<textarea readonly>${VLESS_LINK}</textarea>

</body>
</html>
EOF

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

echo "[8/8] Cleaning temporary files..."

rm -rf "$TMP_DIR"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

echo
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}             INSTALLATION COMPLETE${NC}"
echo -e "${GREEN}============================================================${NC}"
echo

echo -e "${CYAN}V2Ray version:${NC}"
echo -e "${CYAN}${VERSION}${NC}"
echo

echo -e "${CYAN}UUID:${NC}"
echo -e "${CYAN}${UUID}${NC}"
echo

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${BLUE}SERVICE${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"
echo
echo -e "${YELLOW}./v2ray -config config.json${NC}"
echo

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${BLUE}APACHE CONFIG${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"
echo
echo -e "${YELLOW}$(cat "$HOME_DIR/apache.conf")${NC}"
echo

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${BLUE}NODE PAGE${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"
echo
echo -e "${CYAN}https://${HOST}/${UUID}.html${NC}"
echo

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "${BLUE}FILES${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}"
echo
echo -e "${YELLOW}~/v2ray${NC}"
echo -e "${YELLOW}~/v2ctl${NC}"
echo -e "${YELLOW}~/config.json${NC}"
echo -e "${YELLOW}~/apache.conf${NC}"
echo -e "${YELLOW}~/www/index.html${NC}"
echo -e "${YELLOW}~/www/${UUID}.html${NC}"
echo -e "${YELLOW}~/www/vmess.png${NC}"
echo -e "${YELLOW}~/www/vless.png${NC}"
echo

echo -e "${MAGENTA}============================================================${NC}"
echo -e "${MAGENTA}Configure AlwaysData:${NC}"
echo
echo -e "${MAGENTA}1. Advanced -> Processes -> Services${NC}"
echo -e "   Command: ${YELLOW}./v2ray -config config.json${NC}"
echo
echo -e "${MAGENTA}2. Web -> Sites${NC}"
echo -e "   Type: ${YELLOW}Static files${NC}"
echo -e "   Document root: ${YELLOW}~/www${NC}"
echo -e "   HTTPS: ${YELLOW}Enabled${NC}"
echo
echo -e "${MAGENTA}3. Apache configuration${NC}"
echo -e "   Paste the contents of ${YELLOW}~/apache.conf${NC}"
echo -e "${MAGENTA}============================================================${NC}"
echo
