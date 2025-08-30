#!/bin/bash

NODE_NAME=$1
NODE_PORT=$2

echo "=== Configurando servicio web en $NODE_NAME ==="

# Copiar aplicación
cp -r /vagrant/apps/* /opt/webapp/

# Cambiar al directorio de la aplicación
cd /opt/webapp

# Instalar dependencias
npm install

# Crear archivo de configuración para PM2
cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'web-service',
    script: './app.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_NAME: '$NODE_NAME',
      PORT: 3000,
      NODE_IP: '$(hostname -I | awk '{print $1}')'
    },
    log_file: '/var/log/webapp.log',
    error_file: '/var/log/webapp-error.log',
    out_file: '/var/log/webapp-out.log',
    time: true
  }]
};
EOF

# Configurar permisos
chown -R vagrant:vagrant /opt/webapp
mkdir -p /var/log
touch /var/log/webapp.log /var/log/webapp-error.log /var/log/webapp-out.log
chown vagrant:vagrant /var/log/webapp*.log

# Iniciar aplicación con PM2
sudo -u vagrant pm2 start ecosystem.config.js
sudo -u vagrant pm2 save

# Configurar PM2 para iniciarse con el sistema
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u vagrant --hp /home/vagrant
sudo systemctl enable pm2-vagrant

echo "=== Servicio web configurado en $NODE_NAME ==="

# Verificar que esté corriendo
sleep 5
sudo -u vagrant pm2 status
curl -s http://localhost:3000/health | jq .
