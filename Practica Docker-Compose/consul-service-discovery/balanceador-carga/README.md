# Práctica de Balanceo de Carga con HAProxy y LXD

## 📋 Objetivos
- Comprender el funcionamiento del Balanceador de Carga HAProxy
- Construir un balanceador de carga usando HAProxy y Linux Containers LXD/LXC
- Realizar pruebas de carga y análisis de rendimiento

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                Máquina Virtual Ubuntu                    │
│  IP: 192.168.100.3                                      │
│                                                         │
│  ┌─────────────────┐    ┌──────────────────────────────┐ │
│  │  Contenedor     │    │       Contenedores           │ │
│  │    HAProxy      │    │        Backend               │ │
│  │                 ├────┤                              │ │
│  │ - Frontend :80  │    │  ┌─────────┐  ┌─────────┐    │ │
│  │ - Stats :8404   │    │  │  web1   │  │  web2   │    │ │
│  │ - Round Robin   │    │  │ Apache  │  │ Apache  │    │ │
│  └─────────────────┘    │  └─────────┘  └─────────┘    │ │
│                         └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Host Machine  │
                    │                 │
                    │ http://localhost:8080  │
                    │ http://localhost:8404  │
                    └─────────────────┘
```

## 📁 Estructura del Proyecto

```
balanceador-carga/
├── Vagrantfile                 # Configuración de VMs
├── scripts/
│   ├── install_lxd.sh         # Instalación de LXD
│   ├── setup_containers.sh    # Creación de contenedores
│   ├── configure_haproxy.sh   # Configuración de HAProxy
│   ├── load_test.sh          # Pruebas de carga
│   └── container_utils.sh     # Utilidades de gestión
├── configs/
│   ├── haproxy.cfg           # Configuración de HAProxy
│   └── jmeter_test_plan.jmx  # Plan de pruebas JMeter
└── README.md                 # Esta documentación
```

## 🚀 Instalación y Configuración

### Requisitos Previos
- **Vagrant** instalado
- **VirtualBox** instalado
- Al menos **8GB RAM** disponible (4GB para la VM)
- **4 CPU cores** recomendado

### Instalación Automática

1. **Clonar y ejecutar**:
   ```bash
   cd balanceador-carga/
   vagrant up servidorUbuntu
   ```

2. **Proceso automático**:
   - ✅ Instalación de LXD
   - ✅ Creación de contenedores (web1, web2, haproxy)
   - ✅ Configuración de Apache en backends
   - ✅ Configuración de HAProxy
   - ✅ Port forwarding automático

3. **Verificar instalación**:
   ```bash
   vagrant ssh servidorUbuntu
   lxc list
   ```

## 🔧 Configuración Detallada

### HAProxy Configuration
El archivo `haproxy.cfg` incluye:

- **Global Section**: Configuración del daemon
- **Defaults Section**: Timeouts y configuración por defecto
- **Frontend Section**: Recepción de peticiones en puerto 80
- **Backend Section**: Distribución round-robin entre web1 y web2
- **Stats Section**: Interface web en puerto 8404

### Contenedores LXD

| Contenedor | Servicio | IP Dinámica | Puerto |
|------------|----------|-------------|---------|
| `web1` | Apache | Auto-asignada | 80 |
| `web2` | Apache | Auto-asignada | 80 |
| `haproxy` | HAProxy | Auto-asignada | 80, 8404 |

## 📊 Acceso y URLs

### Desde el Host (tu máquina)
- **Balanceador**: http://localhost:8080
- **Estadísticas**: http://localhost:8404
  - Usuario: `admin`
  - Contraseña: `admin`

### Desde la VM
- **Balanceador**: http://192.168.100.3
- **Estadísticas**: http://192.168.100.3:8404
- **Estadísticas alternativa**: http://192.168.100.3/haproxy?stats

## 🛠️ Scripts de Utilidades

### Script Principal de Utilidades
```bash
vagrant ssh servidorUbuntu
cd /vagrant/scripts
chmod +x container_utils.sh
./container_utils.sh help
```

### Comandos Disponibles
```bash
# Verificar estado
./container_utils.sh status

# Probar conectividad
./container_utils.sh test

# Gestión de servidores web
./container_utils.sh stop-web1
./container_utils.sh start-web1
./container_utils.sh stop-all-web

# Gestión de HAProxy
./container_utils.sh restart-haproxy
./container_utils.sh logs-haproxy

# Escalabilidad
./container_utils.sh add-web3    # Agregar tercer servidor
./container_utils.sh remove-web3 # Remover tercer servidor

# Limpieza
./container_utils.sh cleanup     # Eliminar todos los contenedores
```

## 🧪 Pruebas y Experimentación

### Pruebas Básicas de Balanceador

1. **Verificar distribución de carga**:
   ```bash
   # Desde la VM
   for i in {1..10}; do curl http://192.168.100.3; sleep 1; done
   
   # O usar el script de utilidades
   ./container_utils.sh test
   ```

2. **Ver estadísticas en tiempo real**:
   - Abrir: http://localhost:8404
   - Observar contadores de peticiones por servidor

### Pruebas de Carga Automatizadas

#### Con el script incluido:
```bash
cd /vagrant/scripts
chmod +x load_test.sh

# Ejecutar 100 peticiones con 10 concurrentes
./load_test.sh 100 10

# Ejecutar 500 peticiones con 50 concurrentes
./load_test.sh 500 50
```

#### Con JMeter (en tu máquina host):
1. **Descargar JMeter**:
   - URL: https://jmeter.apache.org/download_jmeter.cgi
   - Descargar binarios ZIP (apache-jmeter-5.6.3.zip)
   - Extraer y ejecutar `bin/jmeter.bat` (Windows) o `bin/jmeter` (Linux/Mac)

2. **Cargar plan de pruebas**:
   - Abrir JMeter
   - File → Open → Seleccionar `configs/jmeter_test_plan.jmx`
   - Configurar parámetros si es necesario
   - Ejecutar con el botón "Play"

### Escenarios de Prueba Recomendados

#### Escenario 1: Alta Disponibilidad
```bash
# Detener un servidor y verificar que el balanceador sigue funcionando
./container_utils.sh stop-web1
./container_utils.sh test

# Todas las peticiones deberían ir a web2
```

#### Escenario 2: Escalabilidad
```bash
# Agregar un tercer servidor
./container_utils.sh add-web3
./container_utils.sh test

# Verificar distribución entre 3 servidores
```

#### Escenario 3: Recuperación de Fallos
```bash
# Detener todos los servidores web
./container_utils.sh stop-all-web
curl http://192.168.100.3  # Debería mostrar error 503

# Reiniciar servidores
./container_utils.sh start-all-web
./container_utils.sh test   # Debería funcionar normalmente
```

## 📈 Análisis de Estadísticas HAProxy

### Interface Web de Estadísticas (http://localhost:8404)

Las estadísticas de HAProxy proporcionan información valiosa:

#### Métricas Principales:
- **Queue**: Cola de peticiones pendientes
- **Session Rate**: Tasa de sesiones por segundo
- **Sessions**: 
  - Current: Sesiones activas actuales
  - Max: Máximo de sesiones concurrentes
  - Total: Total acumulado de sesiones
- **Bytes**: Transferencia de datos In/Out
- **Response Time**: Tiempo de respuesta promedio
- **Status**: Estado del servidor (UP/DOWN)
- **Health Checks**: Resultado de verificaciones de salud

#### Análisis de Rendimiento:
1. **Distribución de Carga**: Verificar que las peticiones se distribuyan equitativamente
2. **Tiempo de Respuesta**: Monitorear latencia de los backends
3. **Availability**: Verificar uptime de los servidores
4. **Error Rate**: Detectar fallos en los backends

## 🔧 Configuraciones Avanzadas

### Algoritmos de Balanceo

En `haproxy.cfg`, se puede modificar el algoritmo de balanceo:

```haproxy
backend web-backend
    # Round Robin (por defecto)
    balance roundrobin
    
    # Least Connections
    # balance leastconn
    
    # Source IP Hash
    # balance source
    
    # URI Hash
    # balance uri
```

### Health Checks Personalizados

```haproxy
backend web-backend
    option httpchk GET /health
    server web1 10.x.x.x:80 check inter 5s fall 3 rise 2
    server web2 10.x.x.x:80 check inter 5s fall 3 rise 2
```

### SSL Termination

```haproxy
frontend https
    bind *:443 ssl crt /path/to/certificate.pem
    redirect scheme https if !{ ssl_fc }
    default_backend web-backend
```

## 🚨 Troubleshooting

### Problemas Comunes

#### 1. Contenedores no se crean
```bash
# Verificar estado de LXD
sudo systemctl status snap.lxd.daemon

# Verificar inicialización
lxd init --auto
```

#### 2. HAProxy no inicia
```bash
# Verificar configuración
lxc exec haproxy -- haproxy -c -f /etc/haproxy/haproxy.cfg

# Ver logs
lxc exec haproxy -- journalctl -u haproxy -f
```

#### 3. Port forwarding no funciona
```bash
# Verificar devices en contenedor
lxc config show haproxy

# Recrear port forwarding
lxc config device remove haproxy http
lxc config device add haproxy http proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
```

#### 4. No se pueden obtener IPs de contenedores
```bash
# Esperar a que los contenedores tengan IP
sleep 30
lxc list

# Si persiste, reiniciar red LXD
sudo systemctl restart snap.lxd.daemon
```

### Logs Útiles
```bash
# Logs de HAProxy
lxc exec haproxy -- journalctl -u haproxy --no-pager

# Logs de Apache
lxc exec web1 -- tail -f /var/log/apache2/access.log

# Logs de LXD
sudo journalctl -u snap.lxd.daemon --no-pager
```

## 📚 Comandos de Referencia Rápida

### Gestión de Vagrant
```bash
vagrant up servidorUbuntu    # Iniciar VM
vagrant ssh servidorUbuntu   # Conectar SSH
vagrant reload servidorUbuntu # Reiniciar VM
vagrant destroy servidorUbuntu # Eliminar VM
vagrant provision servidorUbuntu # Re-ejecutar aprovisionamiento
```

### Gestión de Contenedores LXD
```bash
lxc list                     # Listar contenedores
lxc info <container>         # Información detallada
lxc exec <container> /bin/bash # Acceder al contenedor
lxc stop <container>         # Detener contenedor
lxc start <container>        # Iniciar contenedor
lxc restart <container>      # Reiniciar contenedor
lxc delete <container>       # Eliminar contenedor
```

### Verificación de Servicios
```bash
# Estado de servicios en contenedores
lxc exec <container> -- systemctl status <service>

# Verificar puertos
lxc exec <container> -- netstat -tlnp

# Verificar conectividad
curl -I http://<container-ip>
```

## 🎯 Ejercicios Propuestos

### Básico
1. ✅ Configurar balanceador con 2 backends
2. ✅ Realizar pruebas básicas de distribución de carga
3. ✅ Verificar alta disponibilidad deteniendo un servidor

### Intermedio
4. 🔄 Agregar un tercer servidor backend
5. 🔄 Cambiar algoritmo de balanceo a "least connections"
6. 🔄 Configurar health checks personalizados
7. 🔄 Realizar pruebas de carga con JMeter

### Avanzado
8. 🚀 Implementar SSL termination
9. 🚀 Configurar múltiples frontends (HTTP/HTTPS)
10. 🚀 Implementar sticky sessions
11. 🚀 Configurar logging avanzado
12. 🚀 Implementar rate limiting

## 🏆 Conclusiones

### Ventajas de HAProxy con LXD:
- **Alto rendimiento**: HAProxy puede manejar miles de conexiones concurrentes
- **Flexibilidad**: Múltiples algoritmos de balanceo disponibles
- **Monitoring**: Interface web rica en estadísticas
- **Alta disponibilidad**: Health checks automáticos
- **Escalabilidad**: Fácil agregar/quitar backends
- **Ligereza**: LXD containers consumen menos recursos que VMs

### Casos de Uso Reales:
- **Aplicaciones web** con múltiples instancias
- **APIs REST** distribuidas
- **Microservicios** con balance de carga
- **Entornos de desarrollo** y testing
- **Proof of concepts** de arquitecturas distribuidas

### Métricas Clave a Monitorear:
- **Throughput**: Peticiones por segundo
- **Latency**: Tiempo de respuesta
- **Error Rate**: Porcentaje de errores
- **Availability**: Tiempo de actividad de backends
- **Resource Usage**: CPU, memoria, red

---

**¡Laboratorio completado!** 🎉

Este proyecto proporciona una base sólida para comprender balanceadores de carga modernos y tecnologías de contenedores.
