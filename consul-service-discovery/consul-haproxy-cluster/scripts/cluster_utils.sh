#!/bin/bash

# Script de utilidades para gestionar el cluster Consul + HAProxy

show_help() {
    echo "=== Utilidades del Cluster Consul + HAProxy ==="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status              - Estado general del cluster"
    echo "  consul-status       - Estado del cluster Consul"
    echo "  haproxy-status      - Estado de HAProxy y balanceador"
    echo "  services            - Listar servicios registrados"
    echo "  nodes               - Listar nodos del cluster"
    echo "  health              - Verificar salud de servicios"
    echo "  scale-up <node>     - Escalar servicio en un nodo"
    echo "  scale-down <node>   - Reducir instancias en un nodo"
    echo "  stop-service <node> - Detener servicio web en un nodo"
    echo "  start-service <node> - Iniciar servicio web en un nodo"
    echo "  reload-haproxy      - Recargar configuración HAProxy"
    echo "  test-loadbalancer   - Probar balanceador de carga"
    echo "  artillery-basic     - Ejecutar prueba básica con Artillery"
    echo "  artillery-stress    - Ejecutar prueba de estrés"
    echo "  artillery-failover  - Ejecutar prueba de failover"
    echo "  cleanup             - Limpiar y reiniciar todo"
    echo ""
}

show_status() {
    echo "=== Estado General del Cluster ==="
    echo ""
    echo "📊 Consul Cluster:"
    consul members 2>/dev/null || echo "  ❌ Consul no disponible"
    echo ""
    echo "🌐 HAProxy Status:"
    systemctl is-active haproxy || echo "  ❌ HAProxy no disponible"
    echo ""
    echo "🔧 Consul-Template:"
    systemctl is-active consul-template || echo "  ❌ Consul-template no disponible"
    echo ""
    echo "📈 Load Balancer URL: http://192.168.50.10"
    echo "📊 HAProxy Stats: http://192.168.50.10:8404/stats"
    echo "🎛️  Consul UI: http://192.168.50.10:8500"
}

consul_status() {
    echo "=== Estado del Cluster Consul ==="
    echo ""
    consul members
    echo ""
    echo "Leader:"
    consul operator raft list-peers
}

haproxy_status() {
    echo "=== Estado de HAProxy ==="
    echo ""
    systemctl status haproxy --no-pager
    echo ""
    echo "Configuración actual:"
    grep -A 20 "backend web_servers" /etc/haproxy/haproxy.cfg
}

list_services() {
    echo "=== Servicios Registrados ==="
    consul catalog services
    echo ""
    echo "Detalles del servicio web:"
    consul catalog service web
}

list_nodes() {
    echo "=== Nodos del Cluster ==="
    consul catalog nodes
}

check_health() {
    echo "=== Verificación de Salud ==="
    echo ""
    echo "🔍 Health checks en Consul:"
    consul catalog service web | jq '.[].Checks[] | select(.Status != "passing") | {Node: .Node, Status: .Status, Output: .Output}'
    
    echo ""
    echo "🌐 Test directo a load balancer:"
    for i in {1..5}; do
        echo -n "Petición $i: "
        curl -s http://192.168.50.10 | jq -r '.node.name' 2>/dev/null || echo "Error"
        sleep 1
    done
}

scale_up() {
    local node=$1
    echo "=== Escalando servicio en $node ==="
    
    vagrant ssh $node -c "
        cd /opt/webapp
        sudo -u vagrant pm2 scale web-service +1
        sudo -u vagrant pm2 save
    "
}

scale_down() {
    local node=$1
    echo "=== Reduciendo instancias en $node ==="
    
    vagrant ssh $node -c "
        cd /opt/webapp
        sudo -u vagrant pm2 scale web-service -1
        sudo -u vagrant pm2 save
    "
}

stop_service() {
    local node=$1
    echo "=== Deteniendo servicio web en $node ==="
    
    vagrant ssh $node -c "
        sudo -u vagrant pm2 stop web-service
    "
    
    echo "Esperando a que Consul detecte el cambio..."
    sleep 15
    check_health
}

start_service() {
    local node=$1
    echo "=== Iniciando servicio web en $node ==="
    
    vagrant ssh $node -c "
        sudo -u vagrant pm2 start web-service
    "
    
    echo "Esperando a que Consul detecte el cambio..."
    sleep 15
    check_health
}

reload_haproxy() {
    echo "=== Recargando HAProxy ==="
    vagrant ssh loadbalancer -c "sudo systemctl reload haproxy"
    echo "HAProxy recargado"
}

test_loadbalancer() {
    echo "=== Prueba del Balanceador de Carga ==="
    echo ""
    
    echo "Realizando 20 peticiones al load balancer:"
    for i in {1..20}; do
        response=$(curl -s http://192.168.50.10)
        node_name=$(echo $response | jq -r '.node.name' 2>/dev/null)
        echo "Petición $i: $node_name"
        sleep 0.5
    done
    
    echo ""
    echo "Verificando distribución..."
    curl -s http://192.168.50.10 | jq .
}

artillery_basic() {
    echo "=== Ejecutando Prueba Básica con Artillery ==="
    
    if ! command -v artillery &> /dev/null; then
        echo "❌ Artillery no está instalado. Instalando..."
        npm install -g artillery
    fi
    
    cd /vagrant/artillery
    artillery run basic-load-test.yml
}

artillery_stress() {
    echo "=== Ejecutando Prueba de Estrés con Artillery ==="
    
    if ! command -v artillery &> /dev/null; then
        echo "❌ Artillery no está instalado. Instalando..."
        npm install -g artillery
    fi
    
    cd /vagrant/artillery
    artillery run stress-test.yml
}

artillery_failover() {
    echo "=== Ejecutando Prueba de Failover con Artillery ==="
    
    if ! command -v artillery &> /dev/null; then
        echo "❌ Artillery no está instalado. Instalando..."
        npm install -g artillery
    fi
    
    cd /vagrant/artillery
    artillery run failover-test.yml
}

cleanup() {
    echo "=== Limpieza y Reinicio del Cluster ==="
    echo "⚠️  Esto reiniciará todos los servicios"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Reiniciando servicios..."
        
        # Reiniciar en load balancer
        vagrant ssh loadbalancer -c "
            sudo systemctl restart consul
            sleep 10
            sudo systemctl restart consul-template
            sudo systemctl restart haproxy
        "
        
        # Reiniciar en nodos web
        for node in web1 web2; do
            vagrant ssh $node -c "
                sudo systemctl restart consul
                sudo -u vagrant pm2 restart all
            "
        done
        
        echo "✅ Servicios reiniciados"
        sleep 10
        show_status
    else
        echo "Operación cancelada"
    fi
}

# Procesar comando
case "${1:-help}" in
    status)
        show_status
        ;;
    consul-status)
        consul_status
        ;;
    haproxy-status)
        haproxy_status
        ;;
    services)
        list_services
        ;;
    nodes)
        list_nodes
        ;;
    health)
        check_health
        ;;
    scale-up)
        if [ -z "$2" ]; then
            echo "❌ Error: Especificar nodo (web1 o web2)"
            exit 1
        fi
        scale_up $2
        ;;
    scale-down)
        if [ -z "$2" ]; then
            echo "❌ Error: Especificar nodo (web1 o web2)"
            exit 1
        fi
        scale_down $2
        ;;
    stop-service)
        if [ -z "$2" ]; then
            echo "❌ Error: Especificar nodo (web1 o web2)"
            exit 1
        fi
        stop_service $2
        ;;
    start-service)
        if [ -z "$2" ]; then
            echo "❌ Error: Especificar nodo (web1 o web2)"
            exit 1
        fi
        start_service $2
        ;;
    reload-haproxy)
        reload_haproxy
        ;;
    test-loadbalancer)
        test_loadbalancer
        ;;
    artillery-basic)
        artillery_basic
        ;;
    artillery-stress)
        artillery_stress
        ;;
    artillery-failover)
        artillery_failover
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Comando no reconocido: $1"
        show_help
        exit 1
        ;;
esac
