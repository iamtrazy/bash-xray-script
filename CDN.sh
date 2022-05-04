#!/usr/bin/env bash

echo "enter a valid UUID"
read UUID
echo "enter your domain (*pointed to server ip)"
read DOMAIN_NAME

#updating and adding firewall rules

apt update
apt upgrade
apt purge iptables-persistent
apt install ufw
ufw allow 'OpenSSH'
ufw allow 443/tcp
ufw allow 80/tcp
ufw enable

#installing latest caddy

VERSION=$(curl --silent 'https://api.github.com/repos/caddyserver/caddy/releases/latest' | sed 'y/,/\n/' | grep 'tag_name' | awk -F '"' '{print $4}')

if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'amd64' | 'x86_64')
        MACHINE='amd64'
        ;;
       'armv8' | 'aarch64')
        MACHINE='arm64'
        ;;
        *)
        echo "error: The architecture is not supported by the script"
        exit 1
        ;;
    esac
else
    echo "error: This operating system is not supported."
    exit 1
fi

VERSION_NO="${VERSION:1}"

DOWNLOAD_LINK="https://github.com/caddyserver/caddy/releases/download/"$VERSION"/caddy_"$VERSION_NO"_linux_"$MACHINE".tar.gz"

TARBALL="caddy_"$VERSION_NO"_linux_"$MACHINE".tar.gz"

curl -LJO $DOWNLOAD_LINK

tar -xvf $TARBALL

mv caddy /usr/local/bin

groupadd --system caddy

useradd --system \
    --gid caddy \
    --create-home \
    --home-dir /var/lib/caddy \
    --shell /usr/sbin/nologin \
    --comment "Caddy web server" \
    caddy

cat << EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

mkdir /etc/caddy
cat << EOF > /etc/caddy/Caddyfile
{
	order reverse_proxy before route
	admin off
	log {
		output file /var/log/caddy/access.log
		level ERROR
	}
}

:443, $DOMAIN_NAME {
	tls {
		ciphers TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
		alpn http/1.1 h2
	}

	@vws {
		path /iamtrazy
		header Connection *Upgrade*
		header Upgrade websocket
	}
	reverse_proxy @vws unix//dev/shm/vws.sock

	@host {
		host $DOMAIN_NAME
	}
	route @host {
		header {
			Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
		}
		file_server {
			root /var/www/$DOMAIN_NAME/html
		}
	}
}
EOF

#Fake website

mkdir -p /var/www/$DOMAIN_NAME/html
cat << EOF > /var/www/$DOMAIN_NAME/html/index.html
<html>
    <head>
        <title>iamtrazy</title>
    </head>
    <body>
        <h1>I LOVE TAYLOR SWIFT</h1>
    </body>
</html>
EOF
chown -R $SUDO_USER:$SUDO_USER /var/www/$DOMAIN_NAME/html
chmod -R 755 /var/www/$DOMAIN_NAME

#installing xray-core

timedatectl set-timezone Asia/Colombo
timedatectl set-ntp true

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

#Adding a xray config json

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning",
    "error": "/var/log/xray/error.log",
    "access": "/var/log/xray/access.log"
  },
  "inbounds": [
    {
      "listen": "/dev/shm/vws.sock,666",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/iamtrazy"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
EOF

#installing bbr

curl -LJO https://raw.githubusercontent.com/teddysun/across/master/bbr.sh
bash bbr.sh

#starting caddy & xray

systemctl daemon-reload

systemctl enable caddy
systemctl enable xray

systemctl restart caddy
systemctl restart xray
