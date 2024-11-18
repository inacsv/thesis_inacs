
/* VISTA ESTUDIANTE CRITERIO ID ALERTA */  
CREATE VIEW estudiante_criterioidalerta AS
SELECT 
    e.pidm,
    t.rut_est, 
    e.periodo,
    e.id_sede,
    s.nombre_sede, 
    a.id_alerta,
    a.nombre_alerta,
    a.criterio_alerta
FROM 
    hechos_semestre e
INNER JOIN 
	sedes s ON e.id_sede = s.id_sede
INNER JOIN 
	estudiantes t ON e.pidm = t.pidm 
JOIN 
    alertas_academicas a 
ON 
    (
        (a.id_alerta = '1' AND e.alerta_reprobacion2 = 1) OR
        (a.id_alerta = '2' AND e.alerta_ppa = 1) OR
        (a.id_alerta = '3' AND e.alerta_reprobacion50 = 1) OR
        (a.id_alerta = '4' AND e.alerta_vcme = 1) OR
        (a.id_alerta = '5' AND e.alerta_nee = 1) OR
        (a.id_alerta = '6' AND e.alerta_ccarrera = 1) OR
        (a.id_alerta = '7' AND e.alerta_reintegro = 1) OR
        (a.id_alerta = '8' AND e.alerta_diagniv = 1)
    )
GROUP BY 
    e.periodo, e.id_sede, e.pidm, t.rut_est, s.nombre_sede, a.id_alerta
ORDER BY 
    e.pidm, e.periodo, e.id_sede, a.id_alerta;


/* VISTA TODOS ESTUDIANTES CON ALERTA */
CREATE VIEW todos_estudiantes_conalerta AS
SELECT h.periodo, 
h.pidm,
e.rut_est,
h.id_sede, 
s.nombre_sede,
e.id_carrera,
c.nombre_carrera 
FROM 
hechos_semestre h
INNER JOIN sedes s ON h.id_sede = s.id_sede
INNER JOIN estudiantes e ON h.pidm = e.pidm
INNER JOIN carreras c ON e.id_carrera = c.id_carrera
WHERE h.alerta_activa = 1;

/* VISTA EST TUTORIAS ALERTAS */
CREATE VIEW est_tutorias_alertas AS
SELECT
e.rut_est, e.nombres_est, h.periodo, t.id_tutoria, h.alerta_activa, h.mejora_situacion, t.porcentaje_asistencia, tt.nombre_tutoria 
FROM hechos_semestre h 
INNER JOIN estudiantes e 
ON e.pidm = h.pidm 
INNER JOIN tutorias_asistencia t
ON t.pidm = e.pidm 
INNER JOIN tutorias tt
ON t.id_tutoria = tt.id_tutoria 
WHERE h.alerta_activa = 1;

/* VISTA VICERRECTORIA SEGUIMIENTO CARRERAS */
CREATE VIEW vicerrectoria_seguimiento_carreras AS
WITH periodos_sedes AS (
    SELECT DISTINCT 
        dt.semestre AS periodo,
        s.id_sede
    FROM dimension_tiempo dt
    CROSS JOIN (SELECT DISTINCT id_sede FROM hechos_semestre) s
    WHERE dt.semestre IN (SELECT DISTINCT periodo FROM hechos_semestre)
),
totales_originales AS (
    SELECT 
        a.periodo,
        e.id_carrera,
        CASE 
            WHEN RIGHT(e.id_carrera::TEXT, 1) = '3' THEN '1' 
            WHEN RIGHT(e.id_carrera::TEXT, 1) = '6' THEN '2' 
            ELSE NULL
        END AS id_sede,
        SUM(a.seguimiento) AS seguimiento_total,
        SUM(a.mejora_situacion) AS mejoras_total,
        SUM(a.alerta_activa) AS alertas_total_estudiantes
    FROM hechos_semestre a
    INNER JOIN estudiantes e ON a.pidm = e.pidm
    INNER JOIN dimension_tiempo b ON a.periodo = b.semestre
    GROUP BY a.periodo, e.id_carrera,
             CASE 
                 WHEN RIGHT(e.id_carrera::TEXT, 1) = '3' THEN '1'
                 WHEN RIGHT(e.id_carrera::TEXT, 1) = '6' THEN '2'
                 ELSE NULL
             END
),
resultado AS (
    SELECT 
        ps.periodo,
        ps.id_sede,
        t.id_carrera,
        COALESCE(t.seguimiento_total, 0) AS seguimiento_total,
        COALESCE(t.mejoras_total, 0) AS mejoras_total,
        COALESCE(t.alertas_total_estudiantes, 0) AS alertas_total_estudiantes
    FROM periodos_sedes ps
    LEFT JOIN totales_originales t 
        ON ps.periodo = t.periodo 
        AND ps.id_sede::TEXT = t.id_sede 
)
SELECT 
    periodo,
    id_sede,
    id_carrera,
    SUM(seguimiento_total) AS seguimiento_total,
    SUM(mejoras_total) AS mejoras_total,
    SUM(alertas_total_estudiantes) AS alertas_total_estudiantes
FROM resultado
GROUP BY periodo, id_sede, id_carrera
ORDER BY periodo, id_sede, id_carrera;


/* VISTA VICERRECTORIA ALERTAS CARRERAS */
CREATE VIEW vicerrectoria_alertas_carreras AS
WITH periodos_sedes_alertas AS (
    SELECT DISTINCT
        dt.semestre as periodo,
        s.id_sede,
        a.id_alerta,
        e.id_carrera
    FROM dimension_tiempo dt
    CROSS JOIN (SELECT DISTINCT id_sede FROM hechos_semestre) s
    CROSS JOIN alertas_academicas a
    CROSS JOIN (SELECT DISTINCT id_carrera FROM estudiantes) e
    WHERE dt.semestre IN (SELECT DISTINCT periodo FROM hechos_semestre)
    AND (
        (RIGHT(e.id_carrera::text, 1) = '3' AND s.id_sede = '1') OR
        (RIGHT(e.id_carrera::text, 1) = '6' AND s.id_sede = '2')
    )
),
totales_originales AS (
    SELECT
        hs.periodo,
        hs.id_sede,
        e.id_carrera,
        CASE
            WHEN aa.criterio_alerta LIKE '%Estudiante con PPA menor o igual a nota 4.0.%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE'%Estudiante con reprobación de una asignatura en dos o más oportunidades%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE '%Estudiante con Porcentaje de aprobación menor al 50% de las asignaturas inscritas.%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE'%Estudiante proveniente de programas de VcME%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE '%Estudiante con NEE%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE '%Estudiante con cambios de carrera%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE '%Estudiante con reintegro a su carrera, como resultado de apelación por causal de eliminación%' THEN aa.id_alerta
            WHEN aa.criterio_alerta LIKE '%Estudiante con reprobación de diagnóstico y/o nivelación%' THEN aa.id_alerta
        END as id_alerta,
        CASE
            WHEN aa.criterio_alerta LIKE '%Estudiante con PPA menor o igual a nota 4.0.%' THEN SUM(hs.alerta_ppa)
            WHEN aa.criterio_alerta LIKE'%Estudiante con reprobación de una asignatura en dos o más oportunidades%' THEN SUM(hs.alerta_reprobacion2)
            WHEN aa.criterio_alerta LIKE '%Estudiante con Porcentaje de aprobación menor al 50% de las asignaturas inscritas.%' THEN SUM(hs.alerta_reprobacion50)
            WHEN aa.criterio_alerta LIKE'%Estudiante proveniente de programas de VcME%' THEN SUM(hs.alerta_vcme)
            WHEN aa.criterio_alerta LIKE '%Estudiante con NEE%' THEN SUM(hs.alerta_nee)
            WHEN aa.criterio_alerta LIKE '%Estudiante con cambios de carrera%' THEN SUM(hs.alerta_ccarrera)
            WHEN aa.criterio_alerta LIKE '%Estudiante con reintegro a su carrera, como resultado de apelación por causal de eliminación%' THEN SUM(hs.alerta_reintegro)
            WHEN aa.criterio_alerta LIKE '%Estudiante con reprobación de diagnóstico y/o nivelación%' THEN SUM(hs.alerta_diagniv)
        END as alertas_total
    FROM hechos_semestre hs
    JOIN estudiantes e ON e.pidm = hs.pidm
    CROSS JOIN alertas_academicas aa
    WHERE (RIGHT(e.id_carrera::text, '1') = '3' AND hs.id_sede = '1')
       OR (RIGHT(e.id_carrera::text, '1') = '6' AND hs.id_sede = '2')
    GROUP BY hs.periodo, hs.id_sede, e.id_carrera, aa.criterio_alerta, aa.id_alerta
)
SELECT
    psa.periodo,
    psa.id_sede,
    psa.id_carrera,
    psa.id_alerta,
    COALESCE(t.alertas_total, 0) as alertas_total
FROM periodos_sedes_alertas psa
LEFT JOIN totales_originales t
    ON psa.periodo = t.periodo
    AND psa.id_sede = t.id_sede
    AND psa.id_alerta = t.id_alerta
    AND psa.id_carrera = t.id_carrera
ORDER BY psa.periodo, psa.id_sede, psa.id_carrera, psa.id_alerta;

/* VISTA TITURIAS CAMPOS GENERAL */
CREATE VIEW tutoria_campos_general AS
WITH columnas AS (
         SELECT tutorias.id_tutoria,
            tutorias.nombre_tutoria,
            TRIM(BOTH FROM split_part(tutorias.nombre_tutoria::text, '-'::text, 1)) AS asignatura,
            TRIM(BOTH FROM split_part(tutorias.nombre_tutoria::text, '-'::text, 2)) AS carrera,
            SUBSTRING(tutorias.periodo_sede FROM 1 FOR 6) AS periodo,
            SUBSTRING(tutorias.periodo_sede FROM 8) AS sede
           FROM tutorias
        ), carrera_transformada AS (
         SELECT c.periodo,
            c.id_tutoria,
            c.asignatura,
            c.sede,
                CASE
                    WHEN c.carrera = 'INGECO'::text THEN 'INGENIERIA COMERCIAL'::text
                    WHEN c.carrera = 'IICG'::text THEN 'INGENIERIA EN INFORMACION Y CONTROL DE GESTION'::text
                    ELSE c.carrera
                END AS carrera
           FROM columnas c
        )
 SELECT d.ano,
    t.periodo,
    t.id_tutoria,
    m.id_sede,
    m.nombre_sede,
    t.asignatura,
    t.carrera,
    cr.id_carrera
   FROM carrera_transformada t
     JOIN sedes m ON lower(t.sede) = lower(m.nombre_sede::text)
     JOIN dimension_tiempo d ON t.periodo = d.semestre::text
     JOIN carreras cr ON lower(t.carrera) = lower(cr.nombre_carrera::text) AND (m.nombre_sede::text = 'Coquimbo'::text AND cr.id_carrera::text ~~ '%6'::text OR m.nombre_sede::text = 'Antofagasta'::text AND cr.id_carrera::text ~~ '%3'::text);


/* VISTA TITULADOS RENUNCIAS */
CREATE VIEW titulados_renuncias AS
SELECT
e.pidm,
m.periodo,
m.cod_estado,
e.id_carrera,
h.id_sede,
h.seguimiento
FROM matriculas m
INNER JOIN estudiantes e
ON m.pidm = e.pidm
LEFT JOIN hechos_semestre h ON 
h.pidm = m.pidm AND h.periodo = m.periodo
WHERE m.cod_estado = 'U' OR m.cod_estado = 'B';