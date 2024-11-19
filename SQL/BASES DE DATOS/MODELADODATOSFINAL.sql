CREATE DATABASE deabd;

--1
CREATE TABLE facultad_escuela(
    id_fe varchar PRIMARY KEY,
    nombre_fe varchar
);

--2
CREATE TABLE carreras(
    id_carrera varchar PRIMARY KEY,
    id_fe varchar,
    nombre_carrera varchar,
    FOREIGN KEY(id_fe) REFERENCES facultad_escuela(id_fe)
);

--3
CREATE TABLE programas(
    id_programa varchar PRIMARY KEY,
    nombre_programa varchar
);

--4
CREATE TABLE sedes(
    id_sede varchar PRIMARY KEY,
    nombre_sede varchar
);

--5
CREATE TABLE tutorias(
    id_tutoria varchar PRIMARY KEY,
    nombre_tutoria varchar,
    periodo_sede varchar
);

--6
CREATE TABLE matriculas(
    id_matricula varchar(1000) PRIMARY KEY,
    pidm numeric (6),
    periodo char (6),
    cod_programa varchar,
    cod_estado varchar,
    nombre_estado varchar,
    fecha_estado date
);

--7 
CREATE TABLE alertas_academicas(
    id_alerta varchar PRIMARY KEY,
    nombre_alerta varchar,
    criterio_alerta varchar
);

--8
CREATE TABLE asignaturas(
    id_asignatura varchar PRIMARY KEY,
    nombre_asignatura varchar,
    asignatura_dpto varchar,
    semestre_asignatura varchar
);

--9
CREATE TABLE dimension_tiempo (
    semestre char(6) PRIMARY KEY,    
    ano integer,                     
    semestre_numero integer,         
    descripcion varchar(50),         
    semestre_anterior char(6),       
    fecha_inicio date,               
    fecha_fin date                   
);


DO $$ 
DECLARE
    año_inicio integer := 2019;  
    año_fin integer := 2030;     
    semestre_actual char(6);
    semestre_anterior char(6);
    semestre_numero integer;
    descripcion_semestre varchar(50);
BEGIN
    FOR año IN año_inicio..año_fin LOOP
        semestre_actual := TO_CHAR(año, 'FM9999') || '10';
        descripcion_semestre := 'Primer Semestre ' || año;
        semestre_anterior := TO_CHAR(año - 1, 'FM9999') || '20';  -- El semestre anterior
        INSERT INTO dimension_tiempo (semestre, ano, semestre_numero, descripcion, semestre_anterior, fecha_inicio, fecha_fin)
        VALUES (
            semestre_actual, 
            año, 
            1, 
            descripcion_semestre, 
            semestre_anterior, 
            TO_DATE(TO_CHAR(año, 'FM9999') || '-01-01', 'YYYY-MM-DD'),
            TO_DATE(TO_CHAR(año, 'FM9999') || '-07-31', 'YYYY-MM-DD')
        );
        semestre_actual := TO_CHAR(año, 'FM9999') || '20';
        descripcion_semestre := 'Segundo Semestre ' || año;
        semestre_anterior := TO_CHAR(año, 'FM9999') || '10';  -- El semestre anterior
        INSERT INTO dimension_tiempo (semestre, ano, semestre_numero, descripcion, semestre_anterior, fecha_inicio, fecha_fin)
        VALUES (
            semestre_actual, 
            año, 
            2, 
            descripcion_semestre, 
            semestre_anterior, 
            TO_DATE(TO_CHAR(año, 'FM9999') || '-08-01', 'YYYY-MM-DD'),
            TO_DATE(TO_CHAR(año, 'FM9999') || '-12-31', 'YYYY-MM-DD')
        );
    END LOOP;
END $$;


--10
CREATE TABLE estudiantes(
    pidm numeric (6) PRIMARY KEY,
    rut_est varchar (9),
    id_carrera varchar,
    nombres_est varchar,
    apellidos_est varchar,
    sexo_est varchar,
    cohorte_est varchar (6),
    tipo_ingreso varchar,
    comuna_est varchar,
    nacionalidad_est varchar,
    etnia_est varchar,
    diag_matematica varchar,
    diag_lenguaje varchar,
    diag_ingles varchar,
    niv_matematica varchar,
    niv_lenguaje varchar,
    FOREIGN KEY (id_carrera) REFERENCES carreras(id_carrera)
);


--11
CREATE TABLE tutorias_asistencia(
    pidm numeric (6),
    id_tutoria varchar,
    porcentaje_asistencia decimal (4, 2),
    FOREIGN KEY (id_tutoria) REFERENCES tutorias(id_tutoria), 
    FOREIGN KEY (pidm) REFERENCES estudiantes(pidm)
);
   
--12
CREATE TABLE hechos_semestre(
    periodo char(6),    
    pidm numeric (6),
    id_sede varchar, 
    id_matricula varchar(1000),
    id_programa varchar,
    c_aprobados integer,
    c_inscritos integer,
    n_reprobaciones2 integer,
    ppa decimal(3,1),
    alerta_activa integer,
    alerta_vcme integer,
    alerta_nee integer,
    alerta_diagniv integer,
    alerta_ccarrera integer,
    alerta_ppa integer,
    alerta_reprobacion50 integer,
    alerta_reprobacion2 integer,
    alerta_reintegro integer,
    seguimiento integer,
    mejora_situacion integer,
    PRIMARY KEY (periodo, pidm),
    FOREIGN KEY (pidm) REFERENCES estudiantes(pidm), 
    FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula),
    FOREIGN KEY (id_sede) REFERENCES sedes(id_sede),
    FOREIGN KEY (id_programa) REFERENCES programas(id_programa),
    FOREIGN KEY (periodo) REFERENCES dimension_tiempo(semestre) 
);


--13
CREATE TABLE asignaturas_semestre(
    id_asignatura varchar,
    periodo char(6),
    pidm numeric (6),
    calificacion decimal(3,1),
    creditos numeric (7,3),
 	PRIMARY KEY (id_asignatura, periodo, pidm),
    FOREIGN KEY (id_asignatura) REFERENCES asignaturas(id_asignatura)
    FOREIGN KEY (pidm, periodo) REFERENCES hechos_semestre(pidm, periodo));


CREATE TABLE hechos_ea(
    periodo char(6),
    id_alerta varchar,
    id_sede varchar,
    alertas_total_estudiantes integer,
    alertas_total integer,
    mejoras_total integer,
    seguimiento_total integer,
    FOREIGN KEY (id_alerta) REFERENCES alertas_academicas(id_alerta),
    FOREIGN KEY (id_sede) REFERENCES sedes(id_sede),
    FOREIGN KEY (periodo) REFERENCES dimension_tiempo(semestre) 
);



