#!/bin/bash

echo "=== Configurando HAProxy ==="

# Cargar IPs de los contenedores
source /home/vagrant/container_ips.txt

echo "Configurando HAProxy con las siguientes IPs:"
echo "WEB1: $WEB1_IP"
echo "WEB2: $WEB2_IP"
echo "HAProxy: $HAPROXY_IP"

# Copiar y configurar haproxy.cfg
echo "Copiando configuración de HAProxy..."

# Crear configuración personalizada con las IPs reales
sed -e "s/WEB1_IP_PLACEHOLDER/$WEB1_IP/g" \
    -e "s/WEB2_IP_PLACEHOLDER/$WEB2_IP/g" \
    /vagrant/configs/haproxy.cfg > /tmp/haproxy.cfg

# Copiar al contenedor HAProxy
lxc file push /tmp/haproxy.cfg haproxy/etc/haproxy/haproxy.cfg

# Reiniciar HAProxy
echo "Reiniciando HAProxy..."
lxc exec haproxy -- systemctl restart haproxy

# Verificar que HAProxy esté funcionando
echo "Verificando HAProxy..."
sleep 5
lxc exec haproxy -- systemctl status haproxy --no-pager

# Configurar port forwarding del contenedor HAProxy
echo "Configurando port forwarding..."

# Remover devices existentes si existen (ignorar errores)
lxc config device remove haproxy http 2>/dev/null || true
lxc config device remove haproxy stats 2>/dev/null || true

# Agregar nuevos devices
lxc config device add haproxy http proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
lxc config device add haproxy stats proxy listen=tcp:0.0.0.0:8404 connect=tcp:127.0.0.1:8404

echo "=== Pruebas de funcionamiento ==="

# Probar el balanceador varias veces
echo "Probando balanceador de carga (5 peticiones):"
for i in {1..5}; do
    echo "Petición $i:"
    curl -s http://$HAPROXY_IP | grep -E "(web1|web2)" || echo "Error en petición $i"
    sleep 1
done

echo ""
echo "=== Configuración completada ==="
echo "URLs de acceso:"
echo "  - Balanceador: http://192.168.100.3/ o http://localhost:8080"
echo "  - Estadísticas: http://192.168.100.3:8404/ o http://localhost:8404"
echo "  - Estadísticas alt: http://192.168.100.3/haproxy?stats"
echo ""
echo "Credenciales para estadísticas:"
echo "  Usuario: admin"
echo "  Contraseña: admin"
echo ""
echo "=== Lista de contenedores ==="
lxc list
