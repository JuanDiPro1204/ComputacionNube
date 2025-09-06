#!/bin/bash

echo "=== Instalando LXD y dependencias ==="

# Actualizar sistema
apt-get update -y
apt-get upgrade -y

# Instalar snap si no está disponible
if ! command -v snap &> /dev/null; then
    echo "Instalando snapd..."
    apt-get install -y snapd
fi

# Instalar LXD via snap (método recomendado)
echo "Instalando LXD..."
snap install lxd

# Agregar el usuario vagrant al grupo lxd
usermod -a -G lxd vagrant

# Instalar herramientas útiles
apt-get install -y curl jq tree htop

echo "=== Instalación de LXD completada ==="
echo "NOTA: El usuario vagrant debe reloguearse para usar LXD sin sudo"
