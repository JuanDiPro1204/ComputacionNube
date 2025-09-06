#!/bin/bash

# Script de validación para verificar que todo esté correcto

echo "=== Validación del Proyecto Balanceador de Carga ==="
echo ""

ERRORS=0
WARNINGS=0

# Función para reportar errores
report_error() {
    echo "❌ ERROR: $1"
    ((ERRORS++))
}

# Función para reportar advertencias
report_warning() {
    echo "⚠️  WARNING: $1"
    ((WARNINGS++))
}

# Función para reportar éxito
report_ok() {
    echo "✅ $1"
}

echo "1. Verificando estructura de archivos..."

# Verificar archivos principales
if [ -f "Vagrantfile" ]; then
    report_ok "Vagrantfile existe"
else
    report_error "Vagrantfile no encontrado"
fi

if [ -f "README.md" ]; then
    report_ok "README.md existe"
else
    report_error "README.md no encontrado"
fi

# Verificar directorio configs
if [ -d "configs" ]; then
    report_ok "Directorio configs/ existe"
    
    if [ -f "configs/haproxy.cfg" ]; then
        report_ok "configs/haproxy.cfg existe"
        
        # Verificar que tenga placeholders
        if grep -q "WEB1_IP_PLACEHOLDER" configs/haproxy.cfg && grep -q "WEB2_IP_PLACEHOLDER" configs/haproxy.cfg; then
            report_ok "HAProxy config tiene placeholders correctos"
        else
            report_error "HAProxy config no tiene los placeholders necesarios"
        fi
    else
        report_error "configs/haproxy.cfg no encontrado"
    fi
    
    if [ -f "configs/jmeter_test_plan.jmx" ]; then
        report_ok "configs/jmeter_test_plan.jmx existe"
    else
        report_warning "configs/jmeter_test_plan.jmx no encontrado"
    fi
else
    report_error "Directorio configs/ no encontrado"
fi

# Verificar directorio scripts
if [ -d "scripts" ]; then
    report_ok "Directorio scripts/ existe"
    
    SCRIPTS=("install_lxd.sh" "setup_containers.sh" "configure_haproxy.sh" "container_utils.sh" "load_test.sh")
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "scripts/$script" ]; then
            report_ok "scripts/$script existe"
            
            # Verificar que sea ejecutable (en sistemas Unix)
            if [ -x "scripts/$script" ]; then
                report_ok "scripts/$script es ejecutable"
            else
                report_warning "scripts/$script no es ejecutable (usar chmod +x si es necesario)"
            fi
            
            # Verificar shebang
            if head -1 "scripts/$script" | grep -q "#!/bin/bash"; then
                report_ok "scripts/$script tiene shebang correcto"
            else
                report_warning "scripts/$script no tiene shebang #!/bin/bash"
            fi
        else
            report_error "scripts/$script no encontrado"
        fi
    done
else
    report_error "Directorio scripts/ no encontrado"
fi

echo ""
echo "2. Verificando sintaxis de Vagrantfile..."

# Verificar sintaxis básica de Vagrantfile
if grep -q "Vagrant.configure" Vagrantfile; then
    report_ok "Vagrantfile tiene configuración Vagrant válida"
else
    report_error "Vagrantfile no tiene configuración Vagrant válida"
fi

if grep -q "servidorUbuntu" Vagrantfile; then
    report_ok "Vagrantfile define servidorUbuntu"
else
    report_error "Vagrantfile no define servidorUbuntu"
fi

if grep -q "provision.*install_lxd.sh" Vagrantfile; then
    report_ok "Vagrantfile incluye aprovisionamiento install_lxd.sh"
else
    report_error "Vagrantfile no incluye aprovisionamiento install_lxd.sh"
fi

echo ""
echo "3. Verificando configuración de HAProxy..."

if [ -f "configs/haproxy.cfg" ]; then
    # Verificar secciones principales
    if grep -q "global" configs/haproxy.cfg; then
        report_ok "HAProxy config tiene sección global"
    else
        report_error "HAProxy config no tiene sección global"
    fi
    
    if grep -q "defaults" configs/haproxy.cfg; then
        report_ok "HAProxy config tiene sección defaults"
    else
        report_error "HAProxy config no tiene sección defaults"
    fi
    
    if grep -q "frontend" configs/haproxy.cfg; then
        report_ok "HAProxy config tiene sección frontend"
    else
        report_error "HAProxy config no tiene sección frontend"
    fi
    
    if grep -q "backend" configs/haproxy.cfg; then
        report_ok "HAProxy config tiene sección backend"
    else
        report_error "HAProxy config no tiene sección backend"
    fi
    
    if grep -q "stats" configs/haproxy.cfg; then
        report_ok "HAProxy config tiene configuración de stats"
    else
        report_warning "HAProxy config no tiene configuración de stats"
    fi
fi

echo ""
echo "4. Verificando configuración de red..."

if grep -q "192.168.100.3" Vagrantfile; then
    report_ok "Vagrantfile configura IP 192.168.100.3 para servidorUbuntu"
else
    report_error "Vagrantfile no configura IP correcta para servidorUbuntu"
fi

if grep -q "forwarded_port.*80.*8080" Vagrantfile; then
    report_ok "Vagrantfile configura port forwarding 80->8080"
else
    report_error "Vagrantfile no configura port forwarding para puerto 80"
fi

if grep -q "forwarded_port.*8404" Vagrantfile; then
    report_ok "Vagrantfile configura port forwarding para estadísticas (8404)"
else
    report_error "Vagrantfile no configura port forwarding para estadísticas"
fi

echo ""
echo "5. Verificando recursos de VM..."

if grep -q "vb.memory.*4096" Vagrantfile; then
    report_ok "VM configurada con 4GB RAM"
else
    report_warning "VM podría necesitar más RAM para LXD"
fi

if grep -q "vb.cpus.*4" Vagrantfile; then
    report_ok "VM configurada con 4 CPUs"
else
    report_warning "VM podría necesitar más CPUs para mejor rendimiento"
fi

echo ""
echo "=== Resumen de Validación ==="
echo "✅ Éxitos: $(grep -c "✅" <<< "$(history)")" 
echo "⚠️  Advertencias: $WARNINGS"
echo "❌ Errores: $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "🎉 ¡Validación completada exitosamente!"
    echo "El proyecto está listo para usar. Ejecuta:"
    echo "   vagrant up servidorUbuntu"
    exit 0
else
    echo "💥 Se encontraron $ERRORS errores que deben corregirse antes de ejecutar."
    exit 1
fi
