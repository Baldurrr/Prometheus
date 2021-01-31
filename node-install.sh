#!/bin/sh

echo -e "Creating group prometheus \n"
groupadd --system prometheus

echo -e "Creating user prometheus \n"
useradd -s /sbin/nologin --system -g prometheus prometheus

wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz

echo -e "Extracting node exporter \n"
tar xvf node_exporter-*linux-amd64.tar.gz
cd node_exporter*/

echo -e "Moving node exporter config in /usr/local/bin/ \n"
mv node_exporter /usr/local/bin

cd ..

echo -e "Creating node_exporter.service \n"
mv node-config.txt /etc/systemd/system/node_exporter.service

echo -e "Starting node service \n"
systemctl start node_exporter
echo -e "Enabling node service \n"
systemctl enable node_exporter

# Si besoin d'ouvrir un port =>
# echo -e "Opening port 9100 \n" 
# iptables -A INPUT -p tcp -m tcp --dport 9100 -j ACCEPT
# iptables -A OUTPUT -p tcp -m tcp --dport 9100 -j ACCEPT

# echo -e "Saving rules \n"
# iptables-save > /etc/iptables.up.rules
# mv iptables.txt /etc/network/if-pre-up.d/iptables
# chmod +x /etc/network/if-pre-up.d/iptables
echo "End of configuration"
rm -rf node_exporter*/
rm node_exporter-1.0.1.linux-amd64.tar.gz


