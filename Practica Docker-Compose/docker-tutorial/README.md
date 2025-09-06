# Docker Tutorial - Flask + MySQL

Este proyecto demuestra cómo usar Docker Compose para orquestar una aplicación Flask con una base de datos MySQL.

## Estructura del proyecto

```
docker-tutorial/
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── db/
│   └── init.sql
├── docker-compose.yml
└── README.md
```

## Instrucciones de uso

### 1. Construir y ejecutar los contenedores
```bash
sudo docker compose up -d
```

### 2. Verificar que los contenedores estén corriendo
```bash
sudo docker ps
```

### 3. Probar la aplicación
Abrir en el navegador: http://localhost:5000

### 4. Conectarse directamente a MySQL
```bash
mysql --host=127.0.0.1 --port=32000 -u root -p
```
(Password: root)

### 5. Detener la aplicación
```bash
sudo docker compose down
```

## Servicios

- **app**: Aplicación Flask que consulta la base de datos
- **db**: Base de datos MySQL con datos de ejemplo

## Puertos

- Flask: 5000
- MySQL: 32000 (mapeado desde 3306)
