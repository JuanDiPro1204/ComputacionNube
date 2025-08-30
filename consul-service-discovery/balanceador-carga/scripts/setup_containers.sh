#!/bin/bash

echo "=== Configurando LXD y creando contenedores ==="

# Función para esperar a que LXD esté listo
wait_for_lxd() {
    echo "Esperando a que LXD esté listo..."
    for i in {1..30}; do
        if lxc list &> /dev/null; then
            echo "LXD está listo"
            return 0
        fi
        echo "Intentando conectar a LXD... ($i/30)"
        sleep 2
    done
    echo "Error: LXD no está respondiendo"
    return 1
}

# Inicializar LXD con configuración automática
echo "Inicializando LXD..."
lxd init --auto

# Esperar a que LXD esté completamente listo
wait_for_lxd

echo "=== Creando contenedores backend (web1, web2) ==="

# Crear contenedores web
lxc launch ubuntu:20.04 web1
lxc launch ubuntu:20.04 web2

# Esperar a que los contenedores estén completamente iniciados
echo "Esperando a que los contenedores estén listos..."
sleep 30

# Configurar web1
echo "Configurando web1..."
lxc exec web1 -- bash -c "
    apt update && apt install -y apache2
    systemctl enable apache2
    echo '<h1>Hello from web1</h1><p>Servidor backend 1</p><p>IP: \$(hostname -I)</p><p>Hostname: \$(hostname)</p>' > /var/www/html/index.html
    systemctl start apache2
"

# Configurar web2
echo "Configurando web2..."
lxc exec web2 -- bash -c "
    apt update && apt install -y apache2
    systemctl enable apache2
    echo '<h1>Hello from web2</h1><p>Servidor backend 2</p><p>IP: \$(hostname -I)</p><p>Hostname: \$(hostname)</p>' > /var/www/html/index.html
    systemctl start apache2
"

echo "=== Creando contenedor HAProxy ==="

# Crear contenedor HAProxy
lxc launch ubuntu:20.04 haproxy

# Esperar un poco más
sleep 20

# Configurar HAProxy básico
echo "Configurando HAProxy..."
lxc exec haproxy -- bash -c "
    apt update && apt install -y haproxy
    systemctl enable haproxy
"

# Función para obtener IP de contenedor con reintentos
get_container_ip() {
    local container=$1
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Obteniendo IP de $container (intento $attempt/$max_attempts)..."
        local ip=$(lxc list $container -c 4 --format csv | grep -v '^$' | head -1)
        
        if [ -n "$ip" ] && [ "$ip" != "" ]; then
            echo "$ip"
            return 0
        fi
        
        echo "Esperando a que $container obtenga IP..."
        sleep 3
        ((attempt++))
    done
    
    echo "Error: No se pudo obtener IP para $container"
    return 1
}

# Obtener IPs de los contenedores con reintentos
echo "Obteniendo IPs de contenedores..."
WEB1_IP=$(get_container_ip web1)
WEB2_IP=$(get_container_ip web2)
HAPROXY_IP=$(get_container_ip haproxy)

echo "=== Información de contenedores ==="
echo "WEB1 IP: $WEB1_IP"
echo "WEB2 IP: $WEB2_IP"
echo "HAProxy IP: $HAPROXY_IP"

# Guardar IPs en archivo para uso posterior
cat > /home/vagrant/container_ips.txt << EOF
WEB1_IP=$WEB1_IP
WEB2_IP=$WEB2_IP
HAPROXY_IP=$HAPROXY_IP
EOF

echo "=== Contenedores creados exitosamente ==="
lxc list

echo "=== Probando conectividad a servidores web ==="
echo "Probando web1..."
curl -s http://$WEB1_IP || echo "Error conectando a web1"

echo "Probando web2..."
curl -s http://$WEB2_IP || echo "Error conectando a web2"
