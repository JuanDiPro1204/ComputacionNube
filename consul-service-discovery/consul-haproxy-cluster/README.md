# 🚀 Cluster Consul + HAProxy + Node.js Service Mesh

## 📋 Objetivos del Proyecto
- Implementar un service mesh completo con **HashiCorp Consul**
- Configurar balanceado de carga dinámico con **HAProxy** integrado con Consul
- Desplegar aplicaciones **Node.js** con registro automático de servicios
- Realizar pruebas de carga exhaustivas con **Artillery**
- Demostrar escalabilidad, alta disponibilidad y recuperación ante fallos

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Machine                              │
│  http://localhost:8080  │ http://localhost:8404  │ :8500    │
└─────────────┬───────────┴────────────────┬──────────────────┘
              │                             │
┌─────────────▼─────────────────────────────▼──────────────────┐
│          Load Balancer VM (192.168.50.10)                   │
│  ┌─────────────────┐ ┌──────────────────┐ ┌──────────────┐  │
│  │  Consul Server  │ │     HAProxy      │ │ consul-template│  │
│  │     :8500       │ │  Frontend :80    │ │   Integration  │  │
│  │    (Leader)     │ │   Stats :8404    │ │               │  │
│  └─────────────────┘ └──────────────────┘ └──────────────┘  │
└──────────────────────────────┬───────────────────────────────┘
                               │ Service Discovery
              ┌────────────────┼────────────────┐
              │                │                │
┌─────────────▼──────────────┐ │ ┌─────────────▼──────────────┐
│   Web1 VM (192.168.50.11) │ │ │   Web2 VM (192.168.50.12) │
│  ┌─────────────────────────┴─▼─┴─────────────────────────┐  │
│  │           Consul Agent + Node.js App                │  │
│  │  - Service Registration                             │  │
│  │  - Health Checks                                    │  │
│  │  │  - Express Server :3000                          │  │
│  │  - PM2 Process Management                           │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
consul-haproxy-cluster/
├── Vagrantfile                    # Configuración de 3 VMs
├── start-cluster.sh              # Script de inicio rápido
├── README.md                     # Esta documentación
├── apps/
│   ├── app.js                    # Aplicación Node.js principal
│   └── package.json              # Dependencias Node.js
├── scripts/
│   ├── install_base.sh           # Instalación base (Consul, consul-template)
│   ├── setup_consul_server.sh    # Configuración servidor Consul
│   ├── setup_consul_agent.sh     # Configuración agentes Consul
│   ├── setup_nodejs.sh           # Instalación Node.js y PM2
│   ├── setup_web_service.sh      # Configuración servicio web
│   ├── setup_haproxy.sh          # Configuración HAProxy
│   ├── setup_consul_template.sh  # Configuración consul-template
│   └── cluster_utils.sh          # Utilidades de gestión
├── configs/
│   └── haproxy.ctmpl             # Template dinámico HAProxy
└── artillery/
    ├── basic-load-test.yml       # Prueba de carga básica
    ├── stress-test.yml           # Prueba de estrés
    ├── failover-test.yml         # Prueba de failover
    └── functions.js              # Funciones auxiliares Artillery
```

## 🚀 Instalación y Configuración

### Requisitos Previos
- **Vagrant** >= 2.3.0
- **VirtualBox** >= 6.1
- **12GB RAM** disponible (4GB para el cluster)
- **Node.js** (para Artillery en host, opcional)

### Instalación Automática

#### Opción 1: Script de Inicio Rápido (Recomendado)
```bash
cd consul-haproxy-cluster/
chmod +x start-cluster.sh
./start-cluster.sh
```

#### Opción 2: Manual
```bash
# Iniciar todas las VMs
vagrant up

# O iniciar una por una
vagrant up loadbalancer
vagrant up web1  
vagrant up web2
```

### Verificación de Instalación
```bash
# Conectar al load balancer
vagrant ssh loadbalancer

# Verificar estado del cluster
/vagrant/scripts/cluster_utils.sh status

# Probar load balancer
/vagrant/scripts/cluster_utils.sh test-loadbalancer
```

## 🔧 Componentes del Sistema

### 1. **Consul Cluster**
- **Servidor**: VM loadbalancer (192.168.50.10)
- **Agentes**: web1 y web2 con registro automático de servicios
- **Funcionalidades**:
  - Service discovery automático
  - Health checking cada 10 segundos
  - UI web en puerto 8500
  - Encriptación de comunicaciones

### 2. **HAProxy Load Balancer**
- **Configuración dinámica** via consul-template
- **Algoritmo**: Round-robin
- **Health checks**: GET /health cada 5 segundos
- **Página 503 personalizada** cuando no hay servicios
- **Stats interface**: Puerto 8404 (admin/admin)

### 3. **Aplicaciones Node.js**
- **Framework**: Express.js
- **Gestión de procesos**: PM2
- **Endpoints disponibles**:
  - `GET /` - Información del nodo y estadísticas
  - `GET /health` - Health check para Consul
  - `GET /info` - Información detallada del sistema
  - `GET /work?duration=X` - Simula trabajo CPU intensivo
  - `GET /status/X` - Respuesta con código específico

### 4. **consul-template**
- **Actualización automática** de HAProxy config
- **Reload** automático de HAProxy cuando cambian servicios
- **Templating dinámico** basado en estado de Consul

## 📊 URLs de Acceso

### Desde el Host
- **🌐 Load Balancer**: http://localhost:8080
- **📊 HAProxy Stats**: http://localhost:8404/stats (admin/admin)  
- **🎛️ Consul UI**: http://localhost:8500

### Desde las VMs
- **Load Balancer**: http://192.168.50.10
- **HAProxy Stats**: http://192.168.50.10:8404/stats
- **Consul UI**: http://192.168.50.10:8500
- **Web1 Direct**: http://192.168.50.11:3000
- **Web2 Direct**: http://192.168.50.12:3000

## 🛠️ Scripts de Gestión

### Script Principal de Utilidades
```bash
# Conectar al load balancer
vagrant ssh loadbalancer
cd /vagrant/scripts
chmod +x cluster_utils.sh

# Ver todos los comandos disponibles
./cluster_utils.sh help
```

### Comandos Principales

#### Monitoreo y Estado
```bash
./cluster_utils.sh status              # Estado general
./cluster_utils.sh consul-status       # Estado Consul
./cluster_utils.sh haproxy-status      # Estado HAProxy
./cluster_utils.sh services            # Servicios registrados
./cluster_utils.sh nodes               # Nodos del cluster
./cluster_utils.sh health              # Verificar salud
```

#### Gestión de Servicios
```bash
./cluster_utils.sh stop-service web1   # Detener servicio web1
./cluster_utils.sh start-service web1  # Iniciar servicio web1
./cluster_utils.sh reload-haproxy      # Recargar HAProxy
```

#### Escalabilidad
```bash
./cluster_utils.sh scale-up web1       # Escalar web1 (+1 instancia)
./cluster_utils.sh scale-down web1     # Reducir web1 (-1 instancia)
```

#### Pruebas
```bash
./cluster_utils.sh test-loadbalancer   # Prueba básica del LB
./cluster_utils.sh artillery-basic     # Prueba básica Artillery
./cluster_utils.sh artillery-stress    # Prueba de estrés
./cluster_utils.sh artillery-failover  # Prueba de failover
```

## 🧪 Pruebas de Carga con Artillery

### Instalación de Artillery (en host)
```bash
npm install -g artillery
```

### Tipos de Pruebas Disponibles

#### 1. **Prueba Básica** (`basic-load-test.yml`)
- **Duración**: 4 minutos total
- **Fases**: Warm-up → Normal → High load
- **Máx concurrent**: 20 usuarios
- **Escenarios**: Funcionalidad básica, health checks, info endpoints

#### 2. **Prueba de Estrés** (`stress-test.yml`)  
- **Duración**: 5 minutos total
- **Pico máximo**: 100 usuarios concurrentes
- **Incluye**: Trabajo CPU intensivo, ramp up/down
- **Objetivo**: Encontrar límites del sistema

#### 3. **Prueba de Failover** (`failover-test.yml`)
- **Duración**: 4 minutos total
- **Objetivo**: Probar comportamiento durante fallos
- **Acepta**: Códigos 200 y 503
- **Monitorea**: Distribución de respuestas

### Ejecución Manual de Artillery
```bash
cd artillery/

# Prueba básica
artillery run basic-load-test.yml

# Prueba de estrés  
artillery run stress-test.yml

# Prueba de failover
artillery run failover-test.yml
```

## 📈 Escenarios de Prueba Recomendados

### **Escenario 1: Operación Normal**
1. Iniciar cluster completo
2. Ejecutar prueba básica
3. Verificar distribución 50/50 en estadísticas HAProxy
4. Monitorear métricas en Consul UI

```bash
./cluster_utils.sh status
./cluster_utils.sh artillery-basic
# Observar HAProxy stats en http://localhost:8404/stats
```

### **Escenario 2: Simulación de Falla**
1. Detener un servicio durante carga
2. Verificar que todo el tráfico va al servicio restante
3. Verificar página 503 cuando no hay servicios
4. Probar recuperación automática

```bash
# Terminal 1: Ejecutar prueba continua
./cluster_utils.sh artillery-failover

# Terminal 2: Simular fallos
./cluster_utils.sh stop-service web1   # Detener web1
# Esperar 30 segundos
./cluster_utils.sh stop-service web2   # Detener web2 (ambos down)
# Esperar 30 segundos  
./cluster_utils.sh start-service web1  # Recuperar web1
./cluster_utils.sh start-service web2  # Recuperar web2
```

### **Escenario 3: Escalabilidad Dinámica**
1. Escalar servicios bajo carga
2. Verificar que consul-template actualiza HAProxy automáticamente
3. Observar distribución de carga ajustarse dinámicamente

```bash
# Terminal 1: Carga sostenida
./cluster_utils.sh artillery-stress

# Terminal 2: Escalar dinámicamente
./cluster_utils.sh scale-up web1      # +1 instancia en web1
sleep 30
./cluster_utils.sh scale-up web2      # +1 instancia en web2
sleep 30
./cluster_utils.sh scale-down web1    # -1 instancia en web1
```

### **Escenario 4: Prueba de Capacidad Máxima**
1. Incrementar gradualmente la carga
2. Monitorear métricas de sistema (CPU, memoria)
3. Identificar punto de saturación

```bash
# Modificar stress-test.yml para aumentar usuarios
# arrivalRate: 100 → 200 → 500
artillery run stress-test.yml
```

## 📊 Métricas y Monitoreo

### **HAProxy Stats Dashboard**
Acceder a http://localhost:8404/stats para ver:
- **Session Rate**: Sesiones por segundo
- **Queue**: Peticiones en cola  
- **Response Time**: Latencia promedio
- **Health Status**: Estado de cada backend
- **Bytes In/Out**: Tráfico transferido
- **Error Rate**: Porcentaje de errores

### **Consul UI Dashboard** 
Acceder a http://localhost:8500 para ver:
- **Nodes**: Estado de todos los nodos
- **Services**: Servicios registrados y su salud
- **Health Checks**: Resultados de verificaciones
- **Key/Value**: Configuración distribuida

### **Node.js App Metrics**
Cada aplicación expone métricas en `/info`:
- **CPU Usage**: Carga del procesador
- **Memory Usage**: Uso de memoria
- **Uptime**: Tiempo de actividad
- **Request Count**: Contador de peticiones
- **System Load**: Carga del sistema

## 🚨 Troubleshooting

### **Problemas Comunes**

#### 1. **Consul no inicia**
```bash
# Verificar logs
vagrant ssh loadbalancer
sudo journalctl -u consul -f

# Verificar configuración
sudo consul configtest -config-dir=/etc/consul.d/

# Reiniciar
sudo systemctl restart consul
```

#### 2. **HAProxy no descubre servicios**
```bash
# Verificar consul-template
sudo systemctl status consul-template

# Verificar conectividad a Consul
curl http://127.0.0.1:8500/v1/catalog/service/web

# Forzar regeneración de config
sudo systemctl restart consul-template
```

#### 3. **Aplicaciones Node.js no responden**
```bash
vagrant ssh web1
sudo -u vagrant pm2 status
sudo -u vagrant pm2 logs
sudo -u vagrant pm2 restart all
```

#### 4. **Health checks fallan**
```bash
# Verificar endpoint de health
curl http://192.168.50.11:3000/health
curl http://192.168.50.12:3000/health

# Verificar en Consul
consul catalog service web
```

### **Comandos de Diagnóstico**
```bash
# Estado completo del cluster
./cluster_utils.sh status

# Logs de todos los servicios
vagrant ssh loadbalancer -c "
    sudo journalctl -u consul --no-pager -n 20
    sudo journalctl -u haproxy --no-pager -n 20  
    sudo journalctl -u consul-template --no-pager -n 20
"

# Reinicio completo
./cluster_utils.sh cleanup
```

## 🏆 Características Implementadas

### ✅ **Requerimientos Cumplidos**

1. **✅ Service Mesh con Consul**
   - Cluster con servidor y agentes
   - Service discovery automático
   - Health checking continuo
   - Comunicación encriptada

2. **✅ Load Balancing con HAProxy**  
   - Configuración dinámica via consul-template
   - Round-robin load balancing
   - Health checks integrados
   - Stats interface completa

3. **✅ Aplicaciones Node.js**
   - Auto-registro en Consul
   - Health endpoints
   - Métricas de sistema
   - Gestión con PM2

4. **✅ Escalabilidad**
   - Escalar instancias dinámicamente
   - Detección automática por Consul
   - Actualización automática de HAProxy
   - Sin downtime durante escalado

5. **✅ Alta Disponibilidad**
   - Página 503 personalizada sin servicios
   - Failover automático
   - Recovery automático de servicios
   - Monitoreo continuo

6. **✅ Pruebas de Carga con Artillery**
   - 3 tipos de pruebas configuradas
   - Métricas detalladas
   - Distribución por nodo
   - Escenarios de falla

### 🚀 **Características Adicionales**

- **Aprovisionamiento completamente automatizado**
- **Scripts de gestión avanzados** (18 comandos)  
- **Monitoreo en tiempo real**
- **Documentación exhaustiva**
- **Configuración de producción**
- **Manejo robusto de errores**
- **Logging estructurado**

## 📚 Comandos de Referencia Rápida

### **Gestión de VMs**
```bash
vagrant up                    # Iniciar todas las VMs
vagrant up loadbalancer       # Solo load balancer
vagrant halt                  # Pausar todas las VMs
vagrant destroy              # Eliminar todas las VMs
vagrant ssh loadbalancer     # Conectar al LB
vagrant status               # Estado de VMs
```

### **Gestión del Cluster**  
```bash
# Estado y monitoreo
./cluster_utils.sh status
./cluster_utils.sh health
./cluster_utils.sh consul-status
./cluster_utils.sh services

# Pruebas
./cluster_utils.sh test-loadbalancer
./cluster_utils.sh artillery-basic

# Gestión de servicios
./cluster_utils.sh stop-service web1
./cluster_utils.sh start-service web1
./cluster_utils.sh scale-up web2
```

### **Comandos Consul**
```bash
consul members               # Listar miembros
consul catalog services      # Listar servicios  
consul catalog service web   # Detalles servicio web
consul operator raft list-peers  # Estado del cluster
```

### **Comandos HAProxy**
```bash
sudo systemctl status haproxy
sudo systemctl reload haproxy  
sudo haproxy -c -f /etc/haproxy/haproxy.cfg  # Verificar config
```

## 🎯 Casos de Uso Demostrados

### **1. Service Discovery Automático**
- Los servicios Node.js se registran automáticamente en Consul al iniciarse
- HAProxy descubre nuevos servicios sin configuración manual
- Removal automático de servicios no saludables

### **2. Load Balancing Dinámico**
- Distribución equitativa de carga entre backends disponibles
- Failover automático cuando un backend falla
- Recovery automático cuando un backend se recupera

### **3. Escalabilidad Horizontal**
- Agregar/quitar instancias sin downtime
- Balanceador se ajusta automáticamente
- Métricas en tiempo real de distribución

### **4. Alta Disponibilidad**
- Sistema funciona con 1 o ambos nodos
- Páginas de error personalizadas
- Monitoreo continuo de salud

### **5. Observabilidad**
- Métricas detalladas en HAProxy y Consul
- Logs estructurados de todos los componentes
- Dashboards web para monitoreo

## 🏁 Conclusiones

Este microproyecto demuestra una implementación completa y funcional de:

- **Service Mesh** moderno con Consul
- **Load Balancing** dinámico con HAProxy
- **Microservicios** Node.js autoregistrados
- **Pruebas de carga** profesionales con Artillery
- **DevOps automation** con Vagrant

### **Valor Educativo**
- Comprensión profunda de service discovery
- Experiencia práctica con load balancers modernos
- Manejo de clusters distribuidos
- Testing de performance y reliability
- Automation de infraestructura

### **Aplicabilidad Real**
- Arquitectura escalable para producción
- Patterns de observabilidad
- Estrategias de deployment
- Testing de cargas reales
- Operational excellence

---

**🎉 ¡Microproyecto Completado Exitosamente!** 

Este sistema demuestra una arquitectura de microservicios moderna, completa y funcional, lista para experimentos avanzados y aprendizaje hands-on.
