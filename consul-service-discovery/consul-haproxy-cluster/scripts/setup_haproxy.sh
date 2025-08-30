#!/bin/bash

echo "=== Configurando HAProxy ==="

# Instalar HAProxy
apt-get install -y haproxy

# Crear directorio de configuración
mkdir -p /etc/haproxy/templates

# Crear página de error personalizada en formato HAProxy
cat > /etc/haproxy/errors/503-no-servers.html <<'EOF'
HTTP/1.1 503 Service Unavailable
Content-Type: text/html
Connection: close

<!DOCTYPE html>
<html>
<head>
    <title>Service Temporarily Unavailable</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
        }
        h1 {
            color: #e74c3c;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
        .icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🚫</div>
        <h1>Service Temporarily Unavailable</h1>
        <p>We're sorry, but our web services are currently unavailable. Our team is working to restore service as quickly as possible.</p>
        <p><strong>Error Code:</strong> 503</p>
        <p><strong>Reason:</strong> No backend servers available</p>
        <div class="footer">
            <p>Consul + HAProxy Service Mesh</p>
            <p>Please try again in a few moments.</p>
        </div>
    </div>
</body>
</html>
EOF

# Crear configuración inicial de HAProxy
cat > /etc/haproxy/haproxy.cfg <<EOF
global
    daemon
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    log stdout local0

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    log global
    errorfile 503 /etc/haproxy/errors/503-no-servers.html

# Stats interface
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    stats auth admin:admin

# Frontend
frontend web_frontend
    bind *:80
    default_backend web_servers
    
    # Add headers for debugging
    http-request add-header X-Forwarded-Proto http
    http-request add-header X-Load-Balancer HAProxy

# Backend - será actualizado dinámicamente por consul-template
backend web_servers
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    
    # Servidores serán agregados dinámicamente por consul-template
    # Esta línea será reemplazada:
    # server web1 192.168.50.11:3000 check
    # server web2 192.168.50.12:3000 check
EOF

# Crear directorio para runtime
mkdir -p /var/lib/haproxy
chown haproxy:haproxy /var/lib/haproxy

# Habilitar HAProxy
systemctl enable haproxy

echo "=== HAProxy configurado ==="
