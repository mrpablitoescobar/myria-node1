#!/bin/bash
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi
echo "Checking system requirements , please wait."
CORE=$(grep -c ^processor /proc/cpuinfo)
MEM=$(grep -oP '^MemTotal:\s+\K\d+' /proc/meminfo)
if (( $CORE < 2 )) ;then
  echo ">>>[ERROR] Your CPU cores must be greater than 2"
  exit 1
fi

if (( MEM < 2621440 )) ;then
  echo ">>>[ERROR] Your RAM must be greater than 3GB"
  exit 1
fi
echo ">>>[INFO] Installing requirements packages"
sudo apt install curl -y

echo ">>>[INFO] Downloading Myria Node Software package"
MYRIA_DIR=/home/myria
if [ ! -d "$MYRIA_DIR" ]
    then
        sudo mkdir /home/myria
fi

DESCRIPTION="Myria Node Service"
SERVICE_NAME="myria-node"
SERVICE_PATH="/home/myria/myria-node"

echo ">>>[INFO] Installing Myria Node Software"
# check if service is active
service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

if service_exists $SERVICE_NAME; then
  sudo systemctl daemon-reload
  sudo systemctl stop $SERVICE_NAME
  sudo systemctl disable $SERVICE_NAME
fi

sudo wget -O /home/myria/myria-node "https://downloads-builds.myria.com/node/myria-node"
sudo chmod +x /home/myria/myria-node

sudo wget -O /usr/local/bin/myria-node "https://downloads-builds.myria.com/node/myria-node.sh"
sudo chmod +x /usr/local/bin/myria-node

if [ ! -d "/etc/sysconfig" ]; then
  sudo mkdir /etc/sysconfig
fi
cat > /etc/sysconfig/myria-node-service << EOF
EOF

sudo cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=$DESCRIPTION
After=network.target
[Service]
EnvironmentFile=/etc/sysconfig/myria-node-service
ExecStart=$SERVICE_PATH \${MYRIA_ARG1}
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
# restart daemon, enable and start service
echo ">>>[INFO] Enabling service"
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME//'.service'/} # remove the extension
echo ">>>[INFO] Install Completed!"
echo ">>>[INFO] See \"myria-node -h or myria-node --help\" for usage."

exit 0
