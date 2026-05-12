-- ==============================================================================
-- 1. TABLAS DE REFERENCIA (Se replican en todos los nodos)
-- ==============================================================================

CREATE TABLE pluses_hijo (
    id SERIAL PRIMARY KEY,
    descripcion TEXT NOT NULL,
    importe NUMERIC(10,2) NOT NULL
);

CREATE TABLE clasificaciones (
    id SERIAL PRIMARY KEY,
    categoria VARCHAR(100) UNIQUE NOT NULL,
    num_horas_max INT,
    max_salario NUMERIC(12,2)
);

-- ==============================================================================
-- 2. TABLAS DISTRIBUIDAS (Se fragmentan por campus)
-- ==============================================================================

CREATE TABLE titulaciones (
    id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    creditos INT NOT NULL,
    nota_minima NUMERIC(4,2),
    campus VARCHAR(100) NOT NULL,
    PRIMARY KEY (id, campus) -- Citus requiere la columna de distribución en la PK
);

CREATE TABLE cursos (
    id INT NOT NULL,
    titulacion_id INT NOT NULL,
    campus VARCHAR(100) NOT NULL,
    max_alumnos INT,
    PRIMARY KEY (id, titulacion_id, campus),
    FOREIGN KEY (titulacion_id, campus) REFERENCES titulaciones(id, campus)
);

CREATE TABLE grupos (
    id INT NOT NULL,
    curso_id INT NOT NULL,
    titulacion_id INT NOT NULL,
    campus VARCHAR(100) NOT NULL,
    turno VARCHAR(20),
    PRIMARY KEY (id, curso_id, titulacion_id, campus),
    FOREIGN KEY (curso_id, titulacion_id, campus) REFERENCES cursos(id, titulacion_id, campus)
);

CREATE TABLE asignaturas (
    id INT NOT NULL,
    curso_id INT NOT NULL,
    titulacion_id INT NOT NULL,
    campus VARCHAR(100) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    horas_semanal INT NOT NULL,
    PRIMARY KEY (id, campus), -- PK mínima necesaria para distribución
    FOREIGN KEY (curso_id, titulacion_id, campus) REFERENCES cursos(id, titulacion_id, campus)
);

CREATE TABLE profesores (
    id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    direccion VARCHAR(255),
    telefono INT8,
    email VARCHAR(150),
    despacho VARCHAR(7),
    clasificacion_id INT REFERENCES clasificaciones(id),
    plus_hijo_id INT REFERENCES pluses_hijo(id),
    campus_principal VARCHAR(100) NOT NULL,
    PRIMARY KEY (id, campus_principal)
);

-- TABLA INTERMEDIA (N:M)
-- Se distribuye por campus para permitir JOINs locales con asignaturas
CREATE TABLE asignaturas_profesores (
    asignatura_id INT NOT NULL,
    profesor_id INT NOT NULL,
    campus VARCHAR(100) NOT NULL,
    num_horas INT NOT NULL,
    PRIMARY KEY (asignatura_id, profesor_id, campus),
    FOREIGN KEY (asignatura_id, campus) REFERENCES asignaturas(id, campus)
);
