# Universidad Distribuida — Clúster Citus (BDD Integrador)

Proyecto integrador de Bases de Datos Distribuidas. Implementa un clúster **PostgreSQL + Citus** con dos sedes universitarias (Ushuaia y Río Grande) usando Docker Compose.

## Arquitectura

```
              ┌─────────────────────────────────┐
              │     citus_master (coordinador)  │
              │     Puerto host: 5532           │
              └──────────┬──────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
 ┌────────┴──────────┐       ┌──────────┴────────┐
 │  citus_worker_    │       │  citus_worker_    │
 │  ushuaia          │       │  riogrande        │
 │  (Sede Ushuaia)   │       │  (Sede Río Grande)│
 └───────────────────┘       └───────────────────┘
```

- **Coordinador (`citus_master`)**: punto de entrada único. Acepta consultas y las enruta a los workers. Expuesto en `localhost:5532`.
- **Worker Ushuaia**: almacena shards de datos de la sede Ushuaia.
- **Worker Río Grande**: almacena shards de datos de la sede Río Grande.

## Estrategia de distribución

| Tabla | Tipo | Columna de distribución |
|---|---|---|
| `pluses_hijo` | Referencia (replicada) | — |
| `clasificaciones` | Referencia (replicada) | — |
| `titulaciones` | Distribuida | `campus` |
| `cursos` | Distribuida | `campus` |
| `grupos` | Distribuida | `campus` |
| `asignaturas` | Distribuida | `campus` |
| `profesores` | Distribuida | `campus_principal` |
| `asignaturas_profesores` | Distribuida | `campus` |

Los datos de cada sede quedan físicamente aislados en su worker mediante `isolate_tenant_to_new_shard` + `citus_move_shard_placement`.

## Requisitos

- [Docker](https://docs.docker.com/get-docker/) y Docker Compose v2

## Levantar el clúster

```bash
chmod +x start.sh
./start.sh
```

El script realiza:
1. Elimina cualquier clúster previo (`docker compose down -v`).
2. Levanta los tres contenedores.
3. Espera 20 segundos para que Postgres inicialice la red y el esquema.
4. Aplica la distribución geográfica (`03-distribute.sql`).
5. Carga los datos de ejemplo (`04-data.sql`).

## Conectarse al clúster

```bash
psql -h localhost -p 5532 -U ezequiel -d universidad_distribuida
```

O con DBeaver / pgAdmin apuntando a `localhost:5532`.

## Estructura del proyecto

```
.
├── docker-compose.yml          # Definición de los tres nodos Citus
├── start.sh                    # Script de arranque completo
├── init-db/                    # Se ejecuta automáticamente al iniciar el contenedor
│   ├── 01-setup-cluster.sh     # Registra coordinator y workers en Citus
│   └── 02-schema.sql           # DDL: tablas de referencia y distribuidas
└── post-init/                  # Se ejecuta manualmente desde start.sh (requiere cluster activo)
    ├── 03-distribute.sql       # Distribución y aislamiento geográfico por campus
    └── 04-data.sql             # Datos de ejemplo para ambas sedes
```

## Verificar la distribución de datos

Conectate al coordinador y ejecutá estas consultas para confirmar que los shards y datos están donde corresponde.

### Ver todos los nodos del clúster
```sql
SELECT * FROM citus_get_active_worker_nodes();
```

### Ver cómo están distribuidos los shards por tabla y nodo
```sql
SELECT
    table_name AS tabla,
    shardid,
    nodename AS worker,
    nodeport
FROM citus_shards
ORDER BY tabla, shardid;
```

### Ver qué campus vive en cada worker
```sql
SELECT 'Ushuaia' AS campus, nodename AS worker
FROM citus_shards
WHERE shardid = get_shard_id_for_distribution_column('titulaciones', 'Ushuaia'::varchar)
UNION ALL
SELECT 'Río Grande' AS campus, nodename AS worker
FROM citus_shards
WHERE shardid = get_shard_id_for_distribution_column('titulaciones', 'Río Grande'::varchar);
```

### Contar registros por campus desde el coordinador
```sql
-- Titulaciones por sede
SELECT campus, COUNT(*) FROM titulaciones GROUP BY campus;

-- Profesores por sede
SELECT campus_principal, COUNT(*) FROM profesores GROUP BY campus_principal;

-- Asignaturas por sede
SELECT campus, COUNT(*) FROM asignaturas GROUP BY campus;
```

### Consultar plan de query
```sql
EXPLAIN SELECT * FROM asignaturas where campus = 'Ushuaia';
```

### Verificar que las tablas de referencia están replicadas en ambos workers
```bash
# Debe devolver los mismos 3 registros en ambos workers
docker exec -it citus_worker_ushuaia psql -U ezequiel -d universidad_distribuida \
  -c "SELECT * FROM clasificaciones;"

docker exec -it citus_worker_riogrande psql -U ezequiel -d universidad_distribuida \
  -c "SELECT * FROM clasificaciones;"
```

## Apagar el clúster

```bash
# Detener sin borrar datos
docker compose down

# Detener y borrar volúmenes (reset completo)
docker compose down -v
```
