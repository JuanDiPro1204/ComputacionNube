#!/bin/bash

# Script de inicio rápido para el proyecto de balanceador de carga

echo "🚀 Iniciando Laboratorio de Balanceo de Carga"
echo "=============================================="
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
if ! vagrant plugin list | grep -q vbguest && ! VBoxManage --version &> /dev/null; then
    show_error "VirtualBox no está disponible. Instalar desde: https://www.virtualbox.org/"
    exit 1
fi
show_success "VirtualBox está disponible"

echo ""
show_progress "Iniciando máquina virtual..."
echo "Esto puede tomar varios minutos la primera vez..."
echo ""

# Iniciar Vagrant
if vagrant up servidorUbuntu; then
    show_success "Máquina virtual iniciada correctamente"
else
    show_error "Error al iniciar la máquina virtual"
    echo ""
    echo "💡 Posibles soluciones:"
    echo "   - Verificar que VirtualBox esté instalado y funcionando"
    echo "   - Asegurar que el puerto 8080 y 8404 estén disponibles"
    echo "   - Ejecutar: vagrant destroy -f && vagrant up servidorUbuntu"
    exit 1
fi

echo ""
echo "🎉 ¡Laboratorio iniciado exitosamente!"
echo "======================================"
echo ""
echo "📋 URLs de acceso:"
echo "   🌐 Balanceador de carga: http://localhost:8080"
echo "   📊 Estadísticas HAProxy: http://localhost:8404"
echo "       Usuario: admin | Contraseña: admin"
echo ""
echo "🔧 Comandos útiles:"
echo "   vagrant ssh servidorUbuntu    # Conectar a la VM"
echo "   cd /vagrant/scripts          # Ir al directorio de scripts"
echo "   ./container_utils.sh help    # Ver comandos disponibles"
echo ""
echo "🧪 Para realizar pruebas de carga:"
echo "   ./load_test.sh 100 10        # 100 peticiones, 10 concurrentes"
echo ""
echo "⏹️  Para detener el laboratorio:"
echo "   vagrant halt servidorUbuntu  # Pausar"
echo "   vagrant destroy servidorUbuntu # Eliminar completamente"
echo ""

# Opcional: Abrir URLs automáticamente (comentado por defecto)
# echo "🌐 Abriendo URLs en el navegador..."
# if command -v start &> /dev/null; then
#     start http://localhost:8080
#     sleep 2
#     start http://localhost:8404
# elif command -v open &> /dev/null; then
#     open http://localhost:8080
#     sleep 2
#     open http://localhost:8404
# fi

echo "✨ ¡Disfruta experimentando con el balanceador de carga!"
