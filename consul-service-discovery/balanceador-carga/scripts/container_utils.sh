#!/bin/bash

# Script de utilidades para gestionar contenedores LXD

show_help() {
    echo "=== Utilidades para Balanceador de Carga ==="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status           - Mostrar estado de todos los contenedores"
    echo "  test             - Probar conectividad al balanceador"
    echo "  stop-web1        - Detener servidor web1"
    echo "  stop-web2        - Detener servidor web2"
    echo "  stop-all-web     - Detener todos los servidores web"
    echo "  start-web1       - Iniciar servidor web1"
    echo "  start-web2       - Iniciar servidor web2"
    echo "  start-all-web    - Iniciar todos los servidores web"
    echo "  restart-haproxy  - Reiniciar HAProxy"
    echo "  logs-haproxy     - Ver logs de HAProxy"
    echo "  stats            - Abrir estadísticas en navegador"
    echo "  add-web3         - Agregar un tercer servidor web"
    echo "  remove-web3      - Eliminar el tercer servidor web"
    echo "  cleanup          - Limpiar todos los contenedores"
    echo ""
}

show_status() {
    echo "=== Estado de Contenedores ==="
    lxc list
    echo ""
    echo "=== Estado de Servicios ==="
    echo "HAProxy:"
    lxc exec haproxy -- systemctl is-active haproxy || echo "  HAProxy no está funcionando"
    echo "Web1 Apache:"
    lxc exec web1 -- systemctl is-active apache2 2>/dev/null || echo "  Web1 no está funcionando"
    echo "Web2 Apache:"
    lxc exec web2 -- systemctl is-active apache2 2>/dev/null || echo "  Web2 no está funcionando"
}

test_connectivity() {
    echo "=== Probando Conectividad ==="
    HAPROXY_IP=$(lxc list haproxy -c 4 | grep eth0 | awk '{print $2}')
    
    echo "Realizando 5 peticiones al balanceador ($HAPROXY_IP):"
    for i in {1..5}; do
        echo "Petición $i:"
        response=$(curl -s http://$HAPROXY_IP)
        echo "$response" | grep -E "(web1|web2)" | head -1
        sleep 1
    done
}

stop_web() {
    local web=$1
    echo "Deteniendo $web..."
    lxc stop $web
    echo "$web detenido"
}

start_web() {
    local web=$1
    echo "Iniciando $web..."
    lxc start $web
    sleep 5
    echo "$web iniciado"
}

restart_haproxy() {
    echo "Reiniciando HAProxy..."
    lxc exec haproxy -- systemctl restart haproxy
    sleep 3
    echo "HAProxy reiniciado"
}

show_haproxy_logs() {
    echo "=== Logs de HAProxy ==="
    lxc exec haproxy -- journalctl -u haproxy --no-pager -n 50
}

add_web3() {
    echo "=== Agregando servidor web3 ==="
    
    # Verificar si web3 ya existe
    if lxc list | grep -q web3; then
        echo "El contenedor web3 ya existe"
        return 1
    fi
    
    # Crear y configurar web3
    lxc launch ubuntu:20.04 web3
    sleep 20
    
    lxc exec web3 -- bash -c "
        apt update && apt install -y apache2
        systemctl enable apache2
        echo '<h1>Hello from web3</h1><p>Servidor backend 3</p><p>IP: \$(hostname -I)</p><p>Hostname: \$(hostname)</p>' > /var/www/html/index.html
        systemctl start apache2
    "
    
    # Obtener IP de web3
    WEB3_IP=$(lxc list web3 -c 4 | grep eth0 | awk '{print $2}')
    echo "Web3 IP: $WEB3_IP"
    
    # Actualizar configuración de HAProxy
    echo "Actualizando configuración de HAProxy..."
    
    # Crear nueva configuración con web3
    lxc exec haproxy -- bash -c "
        cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
        echo '    server web3 $WEB3_IP:80 check' >> /etc/haproxy/haproxy.cfg
        systemctl restart haproxy
    "
    
    echo "Web3 agregado exitosamente!"
}

remove_web3() {
    echo "=== Removiendo servidor web3 ==="
    
    if ! lxc list | grep -q web3; then
        echo "El contenedor web3 no existe"
        return 1
    fi
    
    # Restaurar configuración de HAProxy
    lxc exec haproxy -- bash -c "
        if [ -f /etc/haproxy/haproxy.cfg.backup ]; then
            cp /etc/haproxy/haproxy.cfg.backup /etc/haproxy/haproxy.cfg
            systemctl restart haproxy
        fi
    "
    
    # Eliminar web3
    lxc stop web3
    lxc delete web3
    
    echo "Web3 removido exitosamente!"
}

cleanup() {
    echo "=== Limpiando todos los contenedores ==="
    echo "¿Está seguro de que desea eliminar todos los contenedores? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        lxc stop web1 web2 haproxy 2>/dev/null || true
        lxc delete web1 web2 haproxy 2>/dev/null || true
        
        # Eliminar web3 si existe
        if lxc list | grep -q web3; then
            lxc stop web3 2>/dev/null || true
            lxc delete web3 2>/dev/null || true
        fi
        
        echo "Contenedores eliminados"
    else
        echo "Operación cancelada"
    fi
}

# Procesar argumentos
case "${1:-help}" in
    status)
        show_status
        ;;
    test)
        test_connectivity
        ;;
    stop-web1)
        stop_web web1
        ;;
    stop-web2)
        stop_web web2
        ;;
    stop-all-web)
        stop_web web1
        stop_web web2
        ;;
    start-web1)
        start_web web1
        ;;
    start-web2)
        start_web web2
        ;;
    start-all-web)
        start_web web1
        start_web web2
        ;;
    restart-haproxy)
        restart_haproxy
        ;;
    logs-haproxy)
        show_haproxy_logs
        ;;
    stats)
        echo "Abriendo estadísticas en:"
        echo "  http://192.168.100.3:8404/"
        echo "  http://192.168.100.3/haproxy?stats"
        ;;
    add-web3)
        add_web3
        ;;
    remove-web3)
        remove_web3
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Comando no reconocido: $1"
        show_help
        exit 1
        ;;
esac
