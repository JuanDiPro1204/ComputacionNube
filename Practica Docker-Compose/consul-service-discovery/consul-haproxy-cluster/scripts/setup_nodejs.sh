#!/bin/bash

echo "=== Instalando Node.js ==="

# Instalar Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Verificar instalación
node --version
npm --version

# Instalar PM2 para gestión de procesos
npm install -g pm2

# Crear directorio para aplicaciones
mkdir -p /opt/webapp
chown vagrant:vagrant /opt/webapp

echo "=== Node.js instalado exitosamente ==="
