```bash
#!/bin/bash

# ============================================================
# V2Ray for AlwaysData - Improved Installer
# Based on: hiifeng/V2ray-for-AlwaysData
# V2Ray version: 4.45.0
# ============================================================

set -e

VERSION="4.45.0"
BASE_URL="https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}"
TMP_DIR="$(mktemp -d)"

USER_NAME="${USER}"
HOME_DIR="$HOME"
WEB_DIR="$HOME/www"

VMESS_PORT="8300"
VLESS_PORT="8400"

VMESS_PATH="/vmess"
VLESS_PATH="/vless"

HOST="${USER_NAME}.alwaysdata.net"

echo
echo "============================================================"
echo "        V2Ray for AlwaysData"
echo "============================================================"
echo

# ------------------------------------------------------------
# Check dependencies
# ------------------------------------------------------------

for cmd in wget unzip qrencode openssl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is not installed."
        exit 1
    fi
done

# ------------------------------------------------------------
# Generate UUID
# ------------------------------------------------------------

if [ -f "$HOME_DIR/.v2ray_uuid" ]; then
    UUID="$(cat "$HOME_DIR/.v2ray_uuid")"
else
    UUID="$(cat /proc/sys/kernel/random/uuid)"
    echo "$UUID" > "$HOME_DIR/.v2ray_uuid"
fi

echo "UUID: $UUID"
echo "Host: $HOST"
echo

# ------------------------------------------------------------
# Create directories
# ------------------------------------------------------------

mkdir -p "$WEB_DIR"

# ------------------------------------------------------------
# Download V2Ray
# ------------------------------------------------------------

echo "[1/7] Downloading V2Ray ${VERSION}..."

wget -q --show-progress \
    -O "$TMP_DIR/v2ray.zip" \
    "${BASE_URL}/v2ray-linux-64.zip"

# ------------------------------------------------------------
# Extract V2Ray
# ------------------------------------------------------------

echo "[2/7] Installing V2Ray..."

unzip -oq "$TMP_DIR/v2ray.zip" \
    -d "$TMP_DIR/v2ray"

cp "$TMP_DIR/v2ray/v2ray" "$HOME_DIR/v2ray"
cp "$TMP_DIR/v2ray/v2ctl" "$HOME_DIR/v2ctl"
cp "$TMP_DIR/v2ray/geoip.dat" "$HOME_DIR/geoip.dat"
cp "$TMP_DIR/v2ray/geosite.dat" "$HOME_DIR/geosite.dat"

chmod +x "$HOME_DIR/v2ray" "$HOME_DIR/v2ctl"

# ------------------------------------------------------------
# Create config.json
# ------------------------------------------------------------

echo "[3/7] Creating config.json..."

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
    ],
    "dns": {
        "server": [
            "8.8.8.8",
            "8.8.4.4",
            "localhost"
        ]
    }
}
EOF

# ------------------------------------------------------------
# Test configuration
# ------------------------------------------------------------

echo "[4/7] Testing V2Ray configuration..."

"$HOME_DIR/v2ray" -test -config "$HOME_DIR/config.json"

# ------------------------------------------------------------
# Generate VMess link
# ------------------------------------------------------------

VMESS_JSON=$(printf \
'{"v":"2","ps":"AlwaysData-VMess","add":"%s","port":"443","id":"%s","aid":"0","net":"ws","type":"none","host":"%s","path":"%s","tls":"tls"}' \
"$HOST" "$UUID" "$HOST" "$VMESS_PATH")

VMESS_LINK="vmess://$(printf '%s' "$VMESS_JSON" | base64 -w0)"

# ------------------------------------------------------------
# Generate VLESS link
# ------------------------------------------------------------

VLESS_LINK="vless://${UUID}@${HOST}:443?encryption=none&security=tls&type=ws&host=${HOST}&path=%2Fvless#AlwaysData-VLESS"

# ------------------------------------------------------------
# Generate QR codes
# ------------------------------------------------------------

echo "[5/7] Creating QR codes..."

qrencode -o "$WEB_DIR/M${UUID}.png" "$VMESS_LINK"
qrencode -o "$WEB_DIR/L${UUID}.png" "$VLESS_LINK"

# ------------------------------------------------------------
# Create index page
# ------------------------------------------------------------

cat > "$WEB_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AlwaysData</title>
</head>
<body>
<h2>AlwaysData</h2>
<p>V2Ray service is installed.</p>
</body>
</html>
EOF

# ------------------------------------------------------------
# Create node page
# ------------------------------------------------------------

echo "[6/7] Creating node page..."

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

<img src="M${UUID}.png">

<textarea readonly>${VMESS_LINK}</textarea>

<hr>

<h3>VLESS</h3>

<img src="L${UUID}.png">

<textarea readonly>${VLESS_LINK}</textarea>

</body>
</html>
EOF

# ------------------------------------------------------------
# Apache configuration
# ------------------------------------------------------------

APACHE_CONFIG=$(cat <<EOF
#UUID=${UUID}
#VMESS_WSPATH=${VMESS_PATH}
#VLESS_WSPATH=${VLESS_PATH}

ProxyRequests off
ProxyPreserveHost On

ProxyPass "${VMESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VMESS_PORT}${VMESS_PATH}"
ProxyPassReverse "${VMESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VMESS_PORT}${VMESS_PATH}"

ProxyPass "${VLESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VLESS_PORT}${VLESS_PATH}"
ProxyPassReverse "${VLESS_PATH}" "ws://services-${USER_NAME}.alwaysdata.net:${VLESS_PORT}${VLESS_PATH}"
EOF
)

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

rm -rf "$TMP_DIR"

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------

echo
echo "============================================================"
echo "                 INSTALLATION COMPLETE"
echo "============================================================"
echo

echo "V2Ray version : ${VERSION}"
echo "UUID          : ${UUID}"
echo "Host          : ${HOST}"
echo

echo "------------------------------------------------------------"
echo "SERVICE COMMAND"
echo "------------------------------------------------------------"
echo
echo "./v2ray -config config.json"
echo

echo "------------------------------------------------------------"
echo "APACHE CONFIGURATION"
echo "------------------------------------------------------------"
echo
echo "$APACHE_CONFIG"
echo

echo "------------------------------------------------------------"
echo "NODE PAGE"
echo "------------------------------------------------------------"
echo
echo "https://${HOST}/${UUID}.html"
echo

echo "------------------------------------------------------------"
echo "FILES"
echo "------------------------------------------------------------"
echo
echo "$HOME_DIR/v2ray"
echo "$HOME_DIR/config.json"
echo "$WEB_DIR/${UUID}.html"
echo "$WEB_DIR/M${UUID}.png"
echo "$WEB_DIR/L${UUID}.png"
echo

echo "============================================================"
echo "Now configure:"
echo "1. AlwaysData -> Advanced -> Services"
echo "2. AlwaysData -> Web -> Sites"
echo "3. AlwaysData panel settings as required"
echo "============================================================"
echo
```
