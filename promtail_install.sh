#!/bin/sh
echo -e "\n"
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
WHITE=`tput setaf 7`
RESET=`tput sgr0`


echo "${GREEN}################################################################"
echo "   _____  _____   ____  __  __ _______       _____ _           #"
echo "  |  __ \|  __ \ / __ \|  \/  |__   __| /\   |_   _| |         #"
echo "  | |__) | |__) | |  | | \  / |  | |   /  \    | | | |         #"
echo "  |  ___/|  _  /| |  | | |\/| |  | |  / /\ \   | | | |         #"
echo "  | |    | | \ \| |__| | |  | |  | | / ____ \ _| |_| |____     #"
echo "  |_|    |_|  \_\\____/|_|  |_|  |_ /_/    \_\_____|______|    #"
echo "                                                               #"
echo "################################################################${RESET}"

echo -e "Creating group promtail \n"
groupadd --system promtail

echo -e "Creating user promtail \n"
useradd -s /sbin/nologin --system -g promtail promtail

wget https://github.com/grafana/loki/releases/download/v2.3.0/promtail-linux-amd64.zip -P /tmp
cd /tmp
apt install unzip
unzip promtail-linux-amd64.zip
rm promtail-linux-amd64.zip && mv promtail-linux-amd64 /usr/local/bin/promtail

read -p "IP address of the loki server : " lokiserver
echo "You have to set a log file to begin (/var/log/***.log) "
read -p "Path of your log file : " logfilepath
read -p "Host (Name of the host which logs arer collected) : " host
read -p "Job name of this log file (apache logs,ssh logs,...) : " jobname
read -p "Location (set what you want, ex: Home infra) : " location

echo -e "Creating config-promtail.yaml file \n"

tee /usr/local/bin/config-promtail.yml<<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://$lokiserver:3100/loki/api/v1/push
  
scrape_configs:
- job_name: system
  static_configs:

  - targets:
      - localhost
    labels:
      job: $jobname
      host: $host
      location: $location
      __path__: $logfilepath
EOF

echo -e "Creating promtail.service file \n"

tee /etc/systemd/system/promtail.service<<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=promtail
Group=promtail
ExecStart=/usr/local/bin/promtail -config.file /usr/local/bin/config-promtail.yml

[Install]
WantedBy=multi-user.target
EOF


echo "Reloading daemons"
systemctl daemon-reload
echo "Enabling promtail service"
systemctl enable promtail.service
echo "Starting promtail service"
systemctl start promtail.service
echo "Status of promtail service"
systemctl status promtail.service

echo "End of configuration"
