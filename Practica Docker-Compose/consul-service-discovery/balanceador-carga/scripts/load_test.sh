#!/bin/bash

# Script para realizar pruebas de carga simple sin JMeter

HAPROXY_IP="192.168.100.3"
REQUESTS=${1:-100}
CONCURRENT=${2:-10}

echo "=== Prueba de Carga Simple ==="
echo "Servidor: $HAPROXY_IP"
echo "Peticiones totales: $REQUESTS"
echo "Peticiones concurrentes: $CONCURRENT"
echo ""

# Función para realizar una petición
make_request() {
    local id=$1
    local start_time=$(date +%s.%3N)
    local response=$(curl -s -w "%{http_code}|%{time_total}" http://$HAPROXY_IP)
    local end_time=$(date +%s.%3N)
    
    local http_code=$(echo $response | cut -d'|' -f2)
    local time_total=$(echo $response | cut -d'|' -f3)
    local server=$(echo $response | cut -d'|' -f1 | grep -oE "web[12]" | head -1)
    
    echo "$id,$server,$http_code,$time_total"
}

# Crear archivo de resultados
RESULTS_FILE="load_test_results_$(date +%Y%m%d_%H%M%S).csv"
echo "request_id,server,http_code,response_time" > $RESULTS_FILE

echo "Ejecutando $REQUESTS peticiones con $CONCURRENT hilos concurrentes..."
echo "Resultados guardándose en: $RESULTS_FILE"

# Ejecutar peticiones
for ((i=1; i<=$REQUESTS; i++)); do
    # Controlar concurrencia
    while [ $(jobs -r | wc -l) -ge $CONCURRENT ]; do
        sleep 0.1
    done
    
    # Lanzar petición en background
    make_request $i >> $RESULTS_FILE &
    
    # Mostrar progreso
    if [ $((i % 10)) -eq 0 ]; then
        echo "Completadas $i/$REQUESTS peticiones..."
    fi
done

# Esperar a que terminen todas las peticiones
wait

echo ""
echo "=== Análisis de Resultados ==="

# Contar respuestas por servidor
web1_count=$(grep ",web1," $RESULTS_FILE | wc -l)
web2_count=$(grep ",web2," $RESULTS_FILE | wc -l)
total_responses=$((web1_count + web2_count))

echo "Respuestas de web1: $web1_count"
echo "Respuestas de web2: $web2_count"
echo "Total de respuestas exitosas: $total_responses"

# Calcular distribución porcentual
if [ $total_responses -gt 0 ]; then
    web1_percent=$(echo "scale=2; $web1_count * 100 / $total_responses" | bc -l 2>/dev/null || echo "N/A")
    web2_percent=$(echo "scale=2; $web2_count * 100 / $total_responses" | bc -l 2>/dev/null || echo "N/A")
    
    echo "Distribución web1: $web1_percent%"
    echo "Distribución web2: $web2_percent%"
fi

# Verificar códigos de error
error_count=$(grep -v ",200," $RESULTS_FILE | grep -v "request_id" | wc -l)
echo "Respuestas con error: $error_count"

echo ""
echo "Resultados detallados guardados en: $RESULTS_FILE"
