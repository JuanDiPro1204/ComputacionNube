# Laboratorio de Aprovisionamiento con Vagrant

## Objetivos
- Comprender el funcionamiento de los Aprovisionadores SHELL y Puppet con Vagrant.
- Implementar aprovisionamiento automatizado de servicios.

## Estructura del Proyecto
```
lab-aprovisionamiento/
├── shell/                    # Sección 3: Aprovisionamiento con Shell
│   ├── Vagrantfile
│   └── script.sh
├── puppet/                   # Sección 4: Aprovisionamiento con Puppet
│   ├── Vagrantfile
│   └── puppet/
│       ├── manifests/
│       │   └── site.pp
│       └── modules/
│           └── apacheWeb/
│               ├── manifests/
│               │   └── init.pp
│               └── templates/
│                   └── index.html.erb
├── jupyter/                  # Sección 5: Jupyter Notebooks
│   ├── Vagrantfile
│   └── install_jupyter.sh
└── README.md
```

## Sección 3: Aprovisionamiento con Shell

### Funcionamiento
El aprovisionamiento con Shell utiliza scripts bash para automatizar la configuración de servidores. En este caso:

1. **Configuración de DNS**: 
   ```bash
   cat <<TEST> /etc/resolv.conf
   nameserver 8.8.8.8
   TEST
   ```
   - Utiliza un heredoc para escribir la configuración DNS directamente al archivo `/etc/resolv.conf`
   - Configura Google DNS (8.8.8.8) como servidor de nombres

2. **Instalación de vsftpd**:
   ```bash
   sudo apt-get install vsftpd -y
   ```
   - Instala el servidor FTP vsftpd de forma automática (-y acepta todas las confirmaciones)

3. **Configuración de vsftpd**:
   ```bash
   sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
   ```
   - Utiliza sed para editar el archivo de configuración in-place (-i)
   - Descomenta la línea que habilita escritura en FTP

4. **Habilitación de IP Forwarding**:
   ```bash
   sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
   ```
   - Añade la configuración de reenvío de IP al archivo sysctl.conf

### Para ejecutar:
```bash
cd shell/
vagrant up servidorUbuntu
```

## Sección 4: Aprovisionamiento con Puppet

### Funcionamiento
Puppet utiliza un lenguaje declarativo para definir el estado deseado del sistema:

1. **Instalación de Puppet**:
   - El Vagrantfile incluye un script inline que instala Puppet antes de ejecutar los manifiestos

2. **Estructura declarativa**:
   - `site.pp`: Define qué nodos deben incluir qué clases
   - `init.pp`: Define la clase apacheWeb con todos sus recursos

3. **Recursos gestionados**:
   - **Package**: Asegura que apache2 esté instalado
   - **Service**: Garantiza que apache2 esté corriendo y habilitado
   - **File**: Gestiona el archivo index.html usando un template

4. **Templates ERB**:
   - Utiliza variables de Puppet (facts) como `@fqdn`, `@operatingsystem`
   - Genera contenido dinámico basado en el sistema

### Ventajas de Puppet vs Shell:
- **Idempotencia**: Se puede ejecutar múltiples veces sin efectos negativos
- **Declarativo**: Define QUÉ debe hacerse, no CÓMO
- **Gestión de dependencias**: Puppet maneja automáticamente el orden de ejecución
- **Reporting**: Proporciona información detallada de cambios

### Para ejecutar:
```bash
cd puppet/
vagrant up
```

## Sección 5: Jupyter Notebooks

### Funcionamiento
Implementé el aprovisionamiento usando Shell por su simplicidad y control directo:

1. **Instalación del stack Python**:
   - Python 3, pip, y herramientas de desarrollo
   - Librerías científicas: numpy, pandas, matplotlib, seaborn, scikit-learn

2. **Configuración de usuario**:
   - Crea un usuario dedicado `jupyter` para mayor seguridad
   - Instala Jupyter en el entorno del usuario

3. **Configuración de Jupyter**:
   - Permite acceso remoto (ip = '0.0.0.0')
   - Desactiva autenticación para facilitar acceso (solo para desarrollo)
   - Configura directorio de trabajo

4. **Servicio systemd**:
   - Crea un servicio que inicia Jupyter automáticamente
   - Configura reinicio automático en caso de fallos

5. **Notebook de ejemplo**:
   - Crea un notebook con ejemplos básicos de NumPy, Pandas y Matplotlib

### Para ejecutar:
```bash
cd jupyter/
vagrant up
```
Acceder a: http://localhost:8888

## Comandos Útiles

### Para todas las secciones:
```bash
vagrant up          # Iniciar VMs
vagrant provision    # Re-ejecutar aprovisionamiento
vagrant ssh <name>   # Conectar por SSH
vagrant destroy      # Eliminar VMs
vagrant status       # Ver estado
```

### Verificación de servicios:

#### Shell (servidor FTP):
```bash
vagrant ssh servidorUbuntu
sudo systemctl status vsftpd
netstat -tlnp | grep :21
```

#### Puppet (servidor web):
```bash
vagrant ssh puppetServer
sudo systemctl status apache2
curl http://localhost
```

#### Jupyter:
```bash
vagrant ssh jupyter-server
sudo systemctl status jupyter
curl http://localhost:8888
```

## Comparación de Aproximaciones

| Aspecto | Shell | Puppet |
|---------|-------|---------|
| Complejidad | Baja | Media-Alta |
| Curva de aprendizaje | Baja | Alta |
| Idempotencia | Manual | Automática |
| Gestión de dependencias | Manual | Automática |
| Escalabilidad | Limitada | Excelente |
| Reporting | Básico | Avanzado |
| Flexibilidad | Alta | Media |

## Conclusiones

1. **Shell**: Ideal para tareas simples y rápidas, control total sobre la ejecución
2. **Puppet**: Mejor para entornos complejos, múltiples servidores, y gestión a largo plazo
3. **Jupyter**: Ejemplo práctico de aprovisionamiento de entorno de desarrollo científico

Cada método tiene sus ventajas dependiendo del caso de uso, complejidad del entorno y requisitos de mantenimiento.
