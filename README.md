# V2Ray for AlwaysData

Automated installer for deploying V2Ray on AlwaysData with VMess and VLESS over WebSocket and TLS.

## Features

* Latest version of V2Ray
* VMess + WebSocket
* VLESS + WebSocket
* TLS through AlwaysData Apache
* Automatic UUID generation
* Automatic `config.json` generation
* Automatic VMess/VLESS links
* Automatic QR codes
* Automatic HTML node page
* AlwaysData-compatible IPv6 listener (`::`)

## V2Ray Version

The installer automatically downloads the latest stable V2Ray release from V2Fly.

No manual version change is required.

The installer is compatible with V2Ray 5.x and uses the modern:

./v2ray run -c config.json

command.

## Installation

Connect to your AlwaysData account through SSH and run:

```bash
wget -O install.sh https://raw.githubusercontent.com/myhac34/V2ray-for-AlwaysData/main/install.sh
chmod +x install.sh
./install.sh
```


The installer will automatically create the V2Ray configuration, WebSocket paths, VMess/VLESS links, QR codes and the node page.

## AlwaysData configuration

After running the installer, configure the following in the AlwaysData panel:

1. Create a Service using:

```bash
./v2ray -config config.json
```

2. Configure the Web Site with the Apache `ProxyPass` configuration printed by the installer.

3. Make sure the website uses HTTPS.

The installer prints the generated UUID, node URL and Apache configuration at the end.

## Important

The generated UUID and node URL provide access to the V2Ray service. Keep them private and do not publish generated configuration files or personal credentials in the repository.
