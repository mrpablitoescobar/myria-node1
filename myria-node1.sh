#!/bin/bash
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi
echo "Checking system requirements , please wait."
CORE=$(grep -c ^processor /proc/cpuinfo)
MEM=$(grep -oP '^MemTotal:\s+\K\d+' /proc/meminfo)
if (( $CORE < 2 )); then
  echo ">>>[ERROR] Your CPU cores must be greater than 2"
  exit 1
fi
if (( MEM < 2621440 )); then
  echo ">>>[ERROR] Your RAM must be greater than 3GB"
  exit 1
fi

echo ">>>[INFO] Installing requirements packages"
sudo apt install curl -y

echo ">>>[INFO] Downloading Myria Node Software package"
MYRIA_DIR=/home/myria1
if [ ! -d "$MYRIA_DIR" ]; then
    sudo mkdir -p "$MYRIA_DIR"
fi

DESCRIPTION="Myria Node Service 1"
SERVICE_NAME="myria-node1"
SERVICE_PATH="$MYRIA_DIR/myria-node"

echo ">>>[INFO] Installing Myria Node Software"
service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | awk '{print $1}') == "$n.service" ]]; then
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

sudo wget -O "$SERVICE_PATH" "https://downloads-builds.myria.com/node/myria-node"
sudo chmod +x "$SERVICE_PATH"

sudo wget -O /usr/local/bin/myria-node1 "https://downloads-builds.myria.com/node/myria-node.sh"
sudo chmod +x /usr/local/bin/myria-node1

sudo mkdir -p /etc/sysconfig
cat > /etc/sysconfig/myria-node1-service << EOF
# Add environment variables here if needed, e.g.:
# MYRIA_ARG1="--port 4001"
EOF

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=$DESCRIPTION
After=network.target
[Service]
EnvironmentFile=/etc/sysconfig/myria-node1-service
ExecStart=$SERVICE_PATH \$MYRIA_ARG1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo ">>>[INFO] Enabling service"
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
echo ">>>[INFO] Install Completed for $SERVICE_NAME!"
