#!/bin/bash

echo Enter a valid gen4 UUID:
read UUID

rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Colombo /etc/localtime
date -R

ufw disable

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

rm -rf /usr/local/etc/xray/config.json
cat << EOF > /usr/local/etc/xray/CONF0.json
{
  "log": {
    "loglevel": "warning"
  }
}
EOF
cat << EOF > /usr/local/etc/xray/CONF1.json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "tag": "XTLS",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-direct",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 1310,
            "xver": 1
          },
          {
            "path": "/websocket",
            "dest": 1234,
            "xver": 1
          },
          {
            "path": "/vmesstcp",
            "dest": 2345,
            "xver": 1
          },
          {
            "path": "/vmessws",
            "dest": 3456,
            "xver": 1
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
    },
    {
      "port": 1310,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag": "TROJAN",
      "settings": {
        "clients": [
          {
            "password": "$UUID",
            "level": 0
          }
        ],
        "fallbacks": [
          {
            "dest": 80
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      }
    },
    {
      "port": 1234,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "tag": "VLESS_WEBSOCKET",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/websocket"
        }
      }
    },
    {
      "port": 2345,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "tag": "VMESS_TCP",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true,
          "header": {
            "type": "http",
            "request": {
              "path": [
                "/vmesstcp"
              ]
            }
          }
        }
      }
    },
    {
      "port": 3456,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "tag": "VMESS_WEBSOCKET",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmessws"
        }
      }
    }
  ]
}
EOF
cat << EOF > /usr/local/etc/xray/CONF2.json
{
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "tag": "VMESS_HTTP",
      "settings": {
        "clients": [
          {
            "id": "$UUID"
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
                "Content-Type": [
                  "application/octet-stream",
                  "video/mpeg",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": [
                  "chunked"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }
            }
          }
        },
        "security": "none"
      }
    }
  ]
}
EOF
cat << EOF > /usr/local/etc/xray/CONF3.json
{
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout xray.key  -out xray.crt
mkdir /etc/xray
cp xray.key /etc/xray/xray.key
cp xray.crt /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

sed -i 's/-config/-confdir/g' /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf
sed -i 's/\/config.json/\//g' /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

mkdir ~/across
git clone https://github.com/teddysun/across ~/across
chmod 777 ~/across
bash ~/across/bbr.sh
