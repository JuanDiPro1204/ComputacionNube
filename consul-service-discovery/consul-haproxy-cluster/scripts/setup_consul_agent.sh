#!/bin/bash

NODE_NAME=$1
NODE_IP=$2

echo "=== Configurando Consul Agent en $NODE_NAME ==="

# Esperar a que esté disponible la clave de encriptación
echo "Esperando clave de encriptación..."
while [ ! -f /vagrant/consul_encrypt_key ]; do
    sleep 2
done

CONSUL_ENCRYPT_KEY=$(cat /vagrant/consul_encrypt_key)

# Crear archivo de configuración del agente
sudo tee /etc/consul.d/consul.hcl > /dev/null <<EOF
datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
node_name = "$NODE_NAME"
bind_addr = "$NODE_IP"
client_addr = "127.0.0.1"
retry_join = ["192.168.50.10"]
encrypt = "$CONSUL_ENCRYPT_KEY"

services {
  name = "web"
  tags = ["nodejs", "web", "$NODE_NAME"]
  port = 3000
  check {
    http = "http://localhost:3000/health"
    interval = "10s"
  }
}

connect {
  enabled = true
}
EOF

# Crear archivo de servicio systemd
sudo tee /etc/systemd/system/consul.service > /dev/null <<EOF
[Unit]
Description=Consul
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Configurar permisos
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

# Iniciar y habilitar Consul
sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl start consul

# Esperar y verificar
echo "Esperando a que el agente se conecte..."
sleep 10
sudo systemctl status consul --no-pager

echo "=== Consul Agent configurado en $NODE_NAME ==="
