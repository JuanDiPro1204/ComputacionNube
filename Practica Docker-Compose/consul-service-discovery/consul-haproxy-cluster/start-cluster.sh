#!/bin/bash

# Script de inicio rápido para el cluster Consul + HAProxy

echo "🚀 Iniciando Cluster Consul + HAProxy + Node.js"
echo "================================================"
echo ""

# Verificar si estamos en el directorio correcto
if [ ! -f "Vagrantfile" ]; then
    echo "❌ Error: No se encuentra Vagrantfile. Ejecutar desde el directorio del proyecto."
    exit 1
fi

# Función para mostrar progress
show_progress() {
    local message="$1"
    echo "📊 $message"
}

# Función para mostrar success
show_success() {
    local message="$1"
    echo "✅ $message"
}

# Función para mostrar error
show_error() {
    local message="$1"
    echo "❌ $message"
}

echo "Verificando requisitos..."

# Verificar Vagrant
if ! command -v vagrant &> /dev/null; then
    show_error "Vagrant no está instalado. Instalar desde: https://www.vagrantup.com/"
    exit 1
fi
show_success "Vagrant está disponible"

# Verificar VirtualBox
if ! VBoxManage --version &> /dev/null; then
    show_error "VirtualBox no está disponible. Instalar desde: https://www.virtualbox.org/"
    exit 1
fi
show_success "VirtualBox está disponible"

echo ""
show_progress "Iniciando máquinas virtuales..."
echo "Esto puede tomar 10-15 minutos la primera vez..."
echo ""

# Iniciar VMs en orden
echo "📡 Iniciando Load Balancer (Consul Server + HAProxy)..."
if vagrant up loadbalancer; then
    show_success "Load Balancer iniciado"
else
    show_error "Error al iniciar Load Balancer"
    exit 1
fi

echo ""
echo "🌐 Iniciando Web Node 1..."
if vagrant up web1; then
    show_success "Web Node 1 iniciado"
else
    show_error "Error al iniciar Web Node 1"
    exit 1
fi

echo ""
echo "🌐 Iniciando Web Node 2..."
if vagrant up web2; then
    show_success "Web Node 2 iniciado"
else
    show_error "Error al iniciar Web Node 2"
    exit 1
fi

echo ""
show_progress "Esperando a que todos los servicios estén listos..."
sleep 30

echo ""
echo "🔍 Verificando estado del cluster..."
vagrant ssh loadbalancer -c "/vagrant/scripts/cluster_utils.sh status"

echo ""
echo "🎉 ¡Cluster iniciado exitosamente!"
echo "================================="
echo ""
echo "📋 URLs de acceso:"
echo "   🌐 Load Balancer:     http://localhost:8080"
echo "   📊 HAProxy Stats:     http://localhost:8404/stats (admin/admin)"
echo "   🎛️  Consul UI:        http://localhost:8500"
echo ""
echo "🔧 Comandos útiles:"
echo "   ./scripts/cluster_utils.sh status          # Ver estado del cluster"
echo "   ./scripts/cluster_utils.sh health          # Verificar salud"
echo "   ./scripts/cluster_utils.sh test-loadbalancer # Probar load balancer"
echo ""
echo "🧪 Pruebas de carga con Artillery:"
echo "   ./scripts/cluster_utils.sh artillery-basic   # Prueba básica"
echo "   ./scripts/cluster_utils.sh artillery-stress  # Prueba de estrés"
echo "   ./scripts/cluster_utils.sh artillery-failover # Prueba de failover"
echo ""
echo "📊 Escalabilidad:"
echo "   ./scripts/cluster_utils.sh scale-up web1     # Escalar web1"
echo "   ./scripts/cluster_utils.sh stop-service web2 # Simular falla"
echo ""
echo "⏹️  Para detener el cluster:"
echo "   vagrant halt      # Pausar todas las VMs"
echo "   vagrant destroy   # Eliminar completamente"
echo ""

# Opcional: Realizar prueba básica automáticamente
echo "🔧 ¿Realizar prueba básica del load balancer? (y/N)"
read -r -n 1 response
echo
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    show_progress "Ejecutando prueba básica..."
    vagrant ssh loadbalancer -c "/vagrant/scripts/cluster_utils.sh test-loadbalancer"
fi

echo ""
echo "✨ ¡Disfruta experimentando con el service mesh!"
echo "📚 Consulta el README.md para más información"
