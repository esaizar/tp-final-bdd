#!/bin/bash

echo "🚀 [1/4] Limpiando clúster anterior..."
docker compose down -v #> /dev/null 2>&1

echo "📦 [2/4] Levantando contenedores de Citus..."
docker compose up -d #> /dev/null 2>&1

echo "⏳ [3/4] Esperando a que el clúster inicialice la red y el esquema (20 segundos)..."
# PostgreSQL necesita unos segundos para salir del modo seguro y abrir la red TCP
sleep 20

echo "🌍 [4/4] Aplicando aislamiento geográfico y cargando datos..."

# 1. Ejecutamos distribute.sql capturando salida (stdout y stderr)
OUT_DIST=$(docker exec -i citus_master psql -v ON_ERROR_STOP=1 -U ezequiel -d universidad_distribuida < 03-distribute.sql 2>&1)

# Comprobamos si el comando falló
if [ $? -ne 0 ]; then
    echo "❌ ERROR durante el aislamiento geográfico (03-distribute.sql):"
    echo "$OUT_DIST"
    exit 1 # Abortamos el script
fi

# 2. Ejecutamos data.sql capturando salida
OUT_DATA=$(docker exec -i citus_master psql -v ON_ERROR_STOP=1 -U ezequiel -d universidad_distribuida < 04-data.sql 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ ERROR durante la carga de datos (04-data.sql):"
    echo "$OUT_DATA"
    exit 1 # Abortamos el script
fi

echo "✅ ¡Clúster distribuido desplegado y configurado con éxito!"
