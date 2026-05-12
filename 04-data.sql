-- ==============================================================================
-- 1. TABLAS DE REFERENCIA (Replicación Total en todos los workers)
-- ==============================================================================

INSERT INTO pluses_hijo (id, descripcion, importe) VALUES
(1, 'Sin carga de familia', 0.00),
(2, 'Hasta 2 hijos', 25000.50),
(3, 'Familia numerosa (3 o más)', 45000.00);

INSERT INTO clasificaciones (id, categoria, num_horas_max, max_salario) VALUES
(1, 'Profesor Titular', 40, 1500000.00),
(2, 'Profesor Adjunto', 30, 1100000.00),
(3, 'Jefe de Trabajos Prácticos', 20, 800000.00);

-- ==============================================================================
-- 2. TABLAS DISTRIBUIDAS (Fragmentación Horizontal y Co-ubicación)
-- ==============================================================================

-- Titulaciones distribuidas por campus
INSERT INTO titulaciones (id, nombre, creditos, nota_minima, campus) VALUES
(1, 'Licenciatura en Sistemas', 240, 4.00, 'Ushuaia'),
(2, 'Ingeniería Industrial', 260, 4.00, 'Río Grande');

-- Cursos (Co-ubicados con Titulaciones mediante el campus)
INSERT INTO cursos (id, titulacion_id, campus, max_alumnos) VALUES
(1, 1, 'Ushuaia', 40),    -- 1er Año Sistemas (Worker Ushuaia)
(2, 1, 'Ushuaia', 35),    -- 2do Año Sistemas (Worker Ushuaia)
(1, 2, 'Río Grande', 50); -- 1er Año Industrial (Worker Río Grande)

-- Grupos (Heredan id_curso, id_titulacion y campus)
INSERT INTO grupos (id, curso_id, titulacion_id, campus, turno) VALUES
(1, 1, 1, 'Ushuaia', 'mañana'), -- Grupo 1, 1er año Sistemas
(2, 1, 1, 'Ushuaia', 'noche'),  -- Grupo 2, 1er año Sistemas
(1, 1, 2, 'Río Grande', 'tarde'); -- Grupo 1, 1er año Industrial

-- Asignaturas (Co-ubicadas con su curso y titulación en el mismo campus)
INSERT INTO asignaturas (id, curso_id, titulacion_id, campus, nombre, horas_semanal) VALUES
(1, 1, 1, 'Ushuaia', 'Introducción a la Programación', 6),
(2, 1, 1, 'Ushuaia', 'Bases de Datos', 8),
(3, 1, 2, 'Río Grande', 'Física I', 6);

-- Profesores (Distribuidos por campus_principal, referencian catálogos globales)
INSERT INTO profesores (id, nombre, direccion, telefono, email, despacho, clasificacion_id, plus_hijo_id, campus_principal) VALUES
(1, 'Alan Turing', 'Magallanes 123', 2901445566, 'aturing@untdf.edu.ar', 'A-101', 1, 2, 'Ushuaia'),
(2, 'Ada Lovelace', 'San Martin 456', 2901556677, 'alovelace@untdf.edu.ar', 'B-202', 2, 1, 'Ushuaia'),
(3, 'Grace Hopper', 'Gdor. Paz 789', 2964112233, 'ghopper@untdf.edu.ar', 'C-303', 3, 3, 'Río Grande');

-- Tabla Intermedia (N:M)
-- Relaciona Asignatura y Profesor. Usa el 'campus' para asegurar que el JOIN 
-- con asignaturas ocurra localmente en el nodo correspondiente.
INSERT INTO asignaturas_profesores (asignatura_id, profesor_id, campus, num_horas) VALUES
(1, 2, 'Ushuaia', 6), -- Ada Lovelace dicta Intro a la Programación
(2, 1, 'Ushuaia', 8), -- Alan Turing dicta Bases de Datos
(3, 3, 'Río Grande', 6); -- Grace Hopper dicta Física I
