#!/bin/bash
# Esperamos 10 segundos para asegurar que los workers estén listos
sleep 10

# 1. Habilitar la extensión de Citus en tu base de datos
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS citus;"

# 2. Agregar nodo master
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT citus_set_coordinator_host('citus_master', 5432);"

# 3. Agregar los nodos trabajadores
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT citus_add_node('citus_worker_ushuaia', 5432);"
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT citus_add_node('citus_worker_riogrande', 5432);"
