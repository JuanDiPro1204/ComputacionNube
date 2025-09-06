#!/bin/bash

echo "=== Configurando consul-template ==="

# Copiar template
cp /vagrant/configs/haproxy.ctmpl /etc/haproxy/templates/

# Crear configuración de consul-template
cat > /etc/consul-template.hcl <<EOF
consul {
  address = "127.0.0.1:8500"
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
    max_backoff = "1m"
  }
}

template {
  source = "/etc/haproxy/templates/haproxy.ctmpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command = "systemctl reload haproxy"
  command_timeout = "30s"
  perms = 0644
  backup = true
  wait {
    min = "2s"
    max = "10s"
  }
}

log_level = "INFO"
pid_file = "/var/run/consul-template.pid"
EOF

# Crear servicio systemd para consul-template
cat > /etc/systemd/system/consul-template.service <<EOF
[Unit]
Description=Consul Template
Documentation=https://github.com/hashicorp/consul-template
Requires=network-online.target consul.service
After=network-online.target consul.service
Wants=consul.service

[Service]
Type=notify
User=root
Group=root
ExecStart=/usr/local/bin/consul-template -config=/etc/consul-template.hcl
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Habilitar servicios
systemctl daemon-reload
systemctl enable consul-template

# Iniciar HAProxy primero
systemctl start haproxy

# Esperar a que Consul esté disponible
echo "Esperando a que Consul esté disponible..."
while ! curl -s http://127.0.0.1:8500/v1/status/leader > /dev/null; do
    sleep 2
done

# Iniciar consul-template
systemctl start consul-template

echo "=== consul-template configurado ==="

# Verificar estado
sleep 5
systemctl status consul-template --no-pager
systemctl status haproxy --no-pager
