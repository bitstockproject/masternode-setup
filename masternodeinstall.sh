#!/bin/bash

PORT=8316
RPCPORT=8317
CONF_DIR=~/.bitstock
COINZIP='https://github.com/bitstockproject/bitstock-core/releases/download/1.0/bitstock-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/bitstock.service
[Unit]
Description=Bitstock Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/bitstockd
ExecStop=-/usr/local/bin/bitstock-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable bitstock.service
  systemctl start bitstock.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm bitstock-qt bitstock-tx bitstock-linux.zip
  chmod +x bitstock*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget http://cdn.delion.xyz/bsck.zip
  unzip bsck.zip
  rm bsck.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> bitstock.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> bitstock.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> bitstock.conf_TEMP
  echo "rpcport=$RPCPORT" >> bitstock.conf_TEMP
  echo "listen=1" >> bitstock.conf_TEMP
  echo "server=1" >> bitstock.conf_TEMP
  echo "daemon=1" >> bitstock.conf_TEMP
  echo "maxconnections=250" >> bitstock.conf_TEMP
  echo "masternode=1" >> bitstock.conf_TEMP
  echo "" >> bitstock.conf_TEMP
  echo "port=$PORT" >> bitstock.conf_TEMP
  echo "externalip=$IP:$PORT" >> bitstock.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> bitstock.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> bitstock.conf_TEMP
  mv bitstock.conf_TEMP bitstock.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Bitstock Service: ${GREEN}systemctl start bitstock${NC}"
echo -e "Check Bitstock Status Service: ${GREEN}systemctl status bitstock${NC}"
echo -e "Stop Bitstock Service: ${GREEN}systemctl stop bitstock${NC}"
echo -e "Check Masternode Status: ${GREEN}bitstock-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Bitstock Masternode Installation Done${NC}"
exec bash
exit
