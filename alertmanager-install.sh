#!/bin/sh  
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
WHITE=`tput setaf 7`
RESET=`tput sgr0`

echo "${GREEN}###########################################################################"
echo "           _           _                                                  #"
echo "     /\   | |         | |                                                 #"
echo "    /  \  | | ___ _ __| |_   _ __ ___   __ _ _ __   __ _  __ _  ___ _ __  #"
echo "   / /\ \ | |/ _ \ '__| __| | '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \ '__| #"
echo "  / ____ \| |  __/ |  | |_  | | | | | | (_| | | | | (_| | (_| |  __/ |    #"
echo " /_/    \_\_|\___|_|   \__| |_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|_|    #"
echo "                                                          __/ |           #"
echo "                                                         |___/            #"
echo "###########################################################################${RESET}"

echo -e "Pulling alertmanager.tar \n"
wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz -P /tmp
tar xvf alertmanager-0.21.0.linux-amd64.tar.gz -C /tmp/
cd /tmp/alertmanager-*/

echo -e "Copying files \n"
cp alertmanager /usr/local/bin/
cp amtool /usr/local/bin/

echo -e "Creating dir /etc/alertmanager\n"
mkdir /etc/alertmanager
echo -e "Creating dir /var/lib/alertmanager\n"
mkdir /var/lib/alertmanager

echo -e "Creating alertmanager.yml  \n"
tee /etc/alertmanager/alertmanager.yml <<EOF
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'root@root.com'
  smtp_require_tls: false
  
route:
  receiver: 'alert-mails'
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 30m

receivers:
- name: 'alert-mails'
  email_configs:
  - to: 'root@root.com'
EOF

echo -e "Creating user alertmanager \n"
useradd --no-create-home --shell /bin/false alertmanager
chown alertmanager:alertmanager /etc/alertmanager/ -R
chown alertmanager:alertmanager /var/lib/alertmanager/ -R
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool

echo -e "Creating alertmanager.service \n"
tee /etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/

[Install]
WantedBy=multi-user.target
EOF

echo -e "Enabling alertmanager service \n"
systemctl daemon-reload
systemctl enable alertmanager.service
service alertmanager start


#/etc/prometheus/prometheus.yml
echo -e "Creating defaults alerts.yml : \n"
echo -e "Alert: InstanceDown \n"
echo -e "Alert: DiskFull \n"
read -p "Enter a group name: " groupname
tee /etc/prometheus/rules/alerts.yml <<EOF
groups:
  - name: $groupname
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "The server {{ $labels.instance }} is down"
        description: "The job: {{ $labels.job }} report that {{ $labels.instance}} is down since 1 min."
    
	- alert: DiskFull
      expr: node_filesystem_free_bytes{mountpoint ="/stockage",instance="192.168.195.89:9100"} / 1024 / 1024 / 1024 < 20
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "20Go left on disk {{ $labels.instance }}"
        description: "Actually at {{ $value }}"
EOF

read -p "Install camptocamp plugin for grafana ? (y or n)" pluginchoice
if [ $pluginchoice = "y" ] ; then
	echo -e "Pulling grafana plugin camptocamp-prometheus-alertmanager-datasource\n"
	grafana-cli plugins install camptocamp-prometheus-alertmanager-datasource
	systemctl restart grafana

elif [ $pluginchoice = "n" ] ; then
	echo -e "Not installing plugin\n"
	
fi

echo -e "End of configuration \n"
echo -e "Some lines need to be added in prometheus.yml config file: :)\n"
echo "
alerting: \
  alertmanagers: \
  - static_configs: \
    - targets: \
      - localhost:9093 \
    scheme: http \
    timeout: 10s \

rule_files: \
  - 'rules/*' "
echo -e "\n#######"
