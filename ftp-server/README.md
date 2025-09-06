# Servidor FTP con Docker Compose

Este proyecto configura un servidor FTP usando Docker Compose con la imagen `fauria/vsftpd`.

## Configuración

### Variables de entorno:
- **FTP_USER**: user
- **FTP_PASS**: 123
- **PASV_ADDRESS**: 192.168.100.3 (IP del servidor Ubuntu)
- **PASV_MIN_PORT**: 21100
- **PASV_MAX_PORT**: 21110

### Puertos expuestos:
- 20: Puerto de datos FTP
- 21: Puerto de control FTP
- 21100-21110: Rango de puertos pasivos

### Volumen:
- `/home/vagrant/ftp:/srv` - Directorio compartido para archivos FTP

## Instrucciones de uso

### 1. Preparar el directorio FTP (en la VM Ubuntu)
```bash
# Crear directorio
sudo mkdir -p /home/vagrant/ftp

# Dar permisos
sudo chmod 777 /home/vagrant/ftp

# Verificar que vsftpd esté detenido en el host
sudo service vsftpd stop
```

### 2. Ejecutar el servidor FTP
```bash
sudo docker compose up -d
```

### 3. Verificar el estado
```bash
sudo docker compose ps
```

### 4. Probar conexión FTP
```bash
# Desde otra máquina o cliente FTP
ftp 192.168.100.3

# Credenciales:
# Usuario: user
# Contraseña: 123
```

### 5. Detener el servidor
```bash
sudo docker compose down
```

## Notas importantes

- Asegurar que el puerto 21 no esté siendo usado por otro servicio
- El directorio `/home/vagrant/ftp` debe tener permisos 777
- La IP `192.168.100.3` debe corresponder a la IP del servidor Ubuntu en Vagrant
