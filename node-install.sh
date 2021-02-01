#!/bin/sh
echo -e "\n"
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
WHITE=`tput setaf 7`
RESET=`tput sgr0`

echo "${GREEN}################################################################"
echo "  _   _           _        _           _        _ _            #"
echo " | \ | |         | |      (_)         | |      | | |           #"
echo " |  \| | ___   __| | ___   _ _ __  ___| |_ __ _| | | ___ _ __  #"
echo " |     |/ _ \ / _  |/ _ \ | |  _ \/ __| __/ _  | | |/ _ \  __| #"
echo " | |\  | (_) | (_| |  __/ | | | | \__ \ || (_| | | |  __/ |    #"
echo " |_| \_|\___/ \__,_|\___| |_|_| |_|___/\__\__,_|_|_|\___|_|    #"
echo "################################################################${RESET}"

echo -e "Creating group prometheus \n"
groupadd --system prometheus

echo -e "Creating user prometheus \n"
useradd -s /sbin/nologin --system -g prometheus prometheus

wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz -P /tmp

echo -e "Extracting node exporter \n"
tar xvf /tmp/node_exporter-*linux-amd64.tar.gz -C /tmp/
cd /tmp/node_exporter*/

echo -e "Moving node exporter config in /usr/local/bin/ \n"
cp /tmp/node_exporter*/node_exporter /usr/local/bin

echo -e "Creating node_exporter.service \n"

tee /etc/systemd/system/node_exporter.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF

echo -e "Reloading daemons"
systemctl daemon-reload
echo -e "Starting node service \n"
systemctl start node_exporter
echo -e "Enabling node service \n"
systemctl enable node_exporter

# Open specific port with iptables
# echo -e "Opening port 9100 \n" 
# iptables -A INPUT -p tcp -m tcp --dport 9100 -j ACCEPT
# iptables -A OUTPUT -p tcp -m tcp --dport 9100 -j ACCEPT

# echo -e "Saving rules \n"
# iptables-save > /etc/iptables.up.rules
# mv iptables.txt /etc/network/if-pre-up.d/iptables
# chmod +x /etc/network/if-pre-up.d/iptables
echo "End of configuration"

