#!/bin/bash

#input uuid & domain

echo Enter a valid gen4 UUID:
read uuid
echo Enter a valid domain:
read domain

#configure timezone to sri lanka standards

rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R

#disable ubuntu firewall
ufw disable

#running xray install script for linux - systemd

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

#adding new configuration files 

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/config0.json
{
    "inbounds": [
	{
	"port": 80,
	"protocol": "vmess",
	"tag":"http",
	"settings": {
		"clients": [
					{
						"id": "$uuid",
						"level": 1,
						"alterId": 4,
						"security": "auto"
					}
		]
	},
	"streamSettings": {
		"network": "tcp",
		"tcpSettings": {
			"header": {
				"type": "http",
				"response": {
					"version": "1.1",
					"status": "200",
					"reason": "OK",
					"headers": {
						"Content-encoding": [
							"gzip"
						],
						"Content-Type": [
							"text/html; charset=utf-8"
						],
						"Cache-Control": [
							"no-cache"
						],
						"Vary": [
							"Accept-Encoding"
						],
						"X-Frame-Options": [
							"deny"
						],
						"X-XSS-Protection": [
							"1; mode=block"
						],
						"X-content-type-options": [
							"nosniff"
						]
					}
				}
			}
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
]
}
EOF
cat << EOF > /usr/local/etc/xray/config1.json
{
    "inbounds": [
	{
            "port": 443,
            "protocol": "vless",
			"tag":"XTLS",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid",
                        "flow": "xtls-rprx-direct",
                        "level": 0
                    }
                ],
                "decryption": "none",
				"fallbacks": [
                    {
                        "dest": "www.baidu.com:80"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/xray.crt",
                            "keyFile": "/etc/xray/xray.key"
                        }
                    ]
                }
            }
        }
	]
}
EOF
cat << EOF > /usr/local/etc/xray/config2.json
{
    "outbounds": [
	{
      "protocol": "freedom",
      "settings": {}
    }
	]
}
EOF

#accuring a ssl certificate

apt-get update && apt-get install curl -y && apt-get install cron -y && apt-get install socat -y
curl https://get.acme.sh | sh
source ~/.bashrc
bash ~/.acme.sh/acme.sh --issue -d $domain --alpn -k ec-256
mkdir /etc/xray && sudo ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
chmod 644 /etc/xray/xray.key

#starting xray core on sytem startup

cat << EOF > /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf
# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/
EOF
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

#install bbr

mkdir ~/across
git clone https://github.com/teddysun/across ~/across
chmod 777 ~/across
bash ~/across/bbr.sh

