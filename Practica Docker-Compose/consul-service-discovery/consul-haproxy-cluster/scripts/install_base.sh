#!/bin/bash

echo "=== Instalando dependencias base ==="

# Actualizar sistema
apt-get update -y
apt-get upgrade -y

# Instalar herramientas básicas
apt-get install -y curl wget unzip jq htop tree net-tools

# Instalar Consul
CONSUL_VERSION="1.17.0"
echo "Instalando Consul $CONSUL_VERSION..."

cd /tmp
wget -q "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
unzip -q "consul_${CONSUL_VERSION}_linux_amd64.zip"
sudo mv consul /usr/local/bin/
sudo chmod +x /usr/local/bin/consul

# Crear usuario y directorios para Consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /opt/consul /etc/consul.d
sudo chown --recursive consul:consul /opt/consul /etc/consul.d

# Verificar instalación
consul --version

# Instalar consul-template para HAProxy integration
echo "Instalando consul-template..."
CONSUL_TEMPLATE_VERSION="0.34.0"
wget -q "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip"
unzip -q "consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip"
sudo mv consul-template /usr/local/bin/
sudo chmod +x /usr/local/bin/consul-template

# Limpiar archivos temporales
rm -f /tmp/consul_*.zip /tmp/consul-template_*.zip

echo "=== Instalación base completada ==="
