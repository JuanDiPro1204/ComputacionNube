#!/bin/bash

echo "=== Actualizando sistema ==="
sudo apt-get update -y

echo "=== Instalando Python 3 y pip ==="
sudo apt-get install -y python3 python3-pip python3-venv

echo "=== Instalando dependencias del sistema ==="
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev

echo "=== Creando usuario jupyter ==="
sudo useradd -m -s /bin/bash jupyter || true

echo "=== Instalando Jupyter y librerías científicas ==="
sudo -u jupyter python3 -m pip install --user jupyter jupyterlab numpy pandas matplotlib seaborn scikit-learn

echo "=== Configurando Jupyter ==="
sudo -u jupyter mkdir -p /home/jupyter/.jupyter

# Generar configuración de Jupyter
sudo -u jupyter /home/jupyter/.local/bin/jupyter notebook --generate-config

# Configurar Jupyter para acceso remoto
cat << 'EOF' | sudo tee /home/jupyter/.jupyter/jupyter_notebook_config.py
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.allow_root = False
c.NotebookApp.token = ''
c.NotebookApp.password = ''
c.NotebookApp.notebook_dir = '/home/jupyter/notebooks'
EOF

echo "=== Creando directorio de notebooks ==="
sudo -u jupyter mkdir -p /home/jupyter/notebooks

echo "=== Creando notebook de ejemplo ==="
cat << 'EOF' | sudo tee /home/jupyter/notebooks/ejemplo.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Bienvenido a Jupyter Notebooks\n",
    "\n",
    "Este notebook ha sido creado automáticamente durante el aprovisionamiento con Vagrant."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "\n",
    "print(\"¡Jupyter está funcionando correctamente!\")\n",
    "print(f\"Versión de NumPy: {np.__version__}\")\n",
    "print(f\"Versión de Pandas: {pd.__version__}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Ejemplo de gráfico simple\n",
    "x = np.linspace(0, 10, 100)\n",
    "y = np.sin(x)\n",
    "\n",
    "plt.figure(figsize=(10, 6))\n",
    "plt.plot(x, y, 'b-', linewidth=2, label='sin(x)')\n",
    "plt.xlabel('x')\n",
    "plt.ylabel('sin(x)')\n",
    "plt.title('Gráfico de ejemplo - Función Seno')\n",
    "plt.legend()\n",
    "plt.grid(True)\n",
    "plt.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.5"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

sudo chown jupyter:jupyter /home/jupyter/notebooks/ejemplo.ipynb

echo "=== Creando servicio systemd para Jupyter ==="
cat << 'EOF' | sudo tee /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
User=jupyter
ExecStart=/home/jupyter/.local/bin/jupyter notebook
WorkingDirectory=/home/jupyter
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== Habilitando y iniciando servicio Jupyter ==="
sudo systemctl daemon-reload
sudo systemctl enable jupyter
sudo systemctl start jupyter

echo "=== Verificando estado del servicio ==="
sudo systemctl status jupyter --no-pager

echo "=== Configuración completada ==="
echo "Jupyter Notebooks estará disponible en:"
echo "  - Desde la VM: http://localhost:8888"
echo "  - Desde el host: http://localhost:8888"
echo "  - IP de la VM: http://192.168.100.10:8888"
echo ""
echo "Directorio de notebooks: /home/jupyter/notebooks"
echo "Usuario: jupyter"
