-- Convertir tablas pequeñas en Tablas de Referencia (Replicación Total)
SELECT create_reference_table('pluses_hijo');
SELECT create_reference_table('clasificaciones');

-- Distribuir tablas por Campus (Fragmentación Horizontal)
-- Esto asegura que los datos de 'Ushuaia' vayan a ciertos shards y 'Río Grande' a otros.
SELECT create_distributed_table('titulaciones', 'campus');
SELECT create_distributed_table('cursos', 'campus');
SELECT create_distributed_table('grupos', 'campus');
SELECT create_distributed_table('asignaturas', 'campus');
SELECT create_distributed_table('profesores', 'campus_principal');
SELECT create_distributed_table('asignaturas_profesores', 'campus');

-- REUBICACIÓN GEOGRÁFICA ESTRICTA
SELECT citus_set_coordinator_host('citus_master', 5432);

-- ----------------------------------------------------------
-- SEDE USHUAIA
-- ----------------------------------------------------------
-- A. Aislar todos los datos de Ushuaia en un fragmento único
SELECT isolate_tenant_to_new_shard('titulaciones', 'Ushuaia'::varchar, 'CASCADE');

-- B. Mudar físicamente el fragmento al Worker de Ushuaia
SELECT citus_move_shard_placement(
    get_shard_id_for_distribution_column('titulaciones', 'Ushuaia'),
    nodename,
    5432,
    'citus_worker_ushuaia',
    5432
)
FROM citus_shards
WHERE shardid = get_shard_id_for_distribution_column('titulaciones', 'Ushuaia')
  AND nodename != 'citus_worker_ushuaia'
LIMIT 1;

-- ----------------------------------------------------------
-- SEDE RÍO GRANDE
-- ----------------------------------------------------------
-- A. Aislar todos los datos de Río Grande en un fragmento único
SELECT isolate_tenant_to_new_shard('titulaciones', 'Río Grande'::varchar, 'CASCADE');

-- B. Mudar físicamente el fragmento al Worker de Río Grande
SELECT citus_move_shard_placement(
    get_shard_id_for_distribution_column('titulaciones', 'Río Grande'),
    nodename,
    5432,
    'citus_worker_riogrande',
    5432
)
FROM citus_shards
WHERE shardid = get_shard_id_for_distribution_column('titulaciones', 'Río Grande')
  AND nodename != 'citus_worker_riogrande'
LIMIT 1;
