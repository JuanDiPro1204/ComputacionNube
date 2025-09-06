#!/bin/bash

echo "=== Configurando Consul Server ==="

# Generar clave de encriptación
CONSUL_ENCRYPT_KEY=$(consul keygen)

# Crear archivo de configuración del servidor
sudo tee /etc/consul.d/consul.hcl > /dev/null <<EOF
datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
server = true
bootstrap_expect = 1
bind_addr = "192.168.50.10"
client_addr = "0.0.0.0"
retry_join = ["192.168.50.10"]
encrypt = "$CONSUL_ENCRYPT_KEY"

ui_config {
  enabled = true
}

connect {
  enabled = true
}

acl = {
  enabled = false
  default_policy = "allow"
}

ports {
  grpc = 8502
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

# Guardar clave para otros nodos
echo "$CONSUL_ENCRYPT_KEY" | sudo tee /vagrant/consul_encrypt_key > /dev/null

# Configurar permisos
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

# Iniciar y habilitar Consul
sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl start consul

# Esperar a que Consul esté listo
echo "Esperando a que Consul esté listo..."
sleep 10

# Verificar estado
sudo systemctl status consul --no-pager
consul members

echo "=== Consul Server configurado exitosamente ==="
echo "UI disponible en: http://192.168.50.10:8500"
