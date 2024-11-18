/* CARGA HECHOS SEMESTRE */

/* AGREGAR LLAVE FORANEA A ASIGNATURAS_SEMESTRE */
ALTER TABLE asignaturas_semestre
ADD CONSTRAINT asignaturas_semestre_fkey
FOREIGN KEY (periodo, pidm)
REFERENCES hechos_semestre (periodo, pidm);


/* ACTUALIZAR ALERTA VCME */
UPDATE hechos_semestre
SET alerta_vcme = 1
WHERE id_programa <> 'NC';

/* ACTUALIZAR ESTUDIANTES CON CAMPOS NULL EN DIAGNOSTICO Y NIVELACION */ 
UPDATE estudiantes
SET diag_ingles = 'REPROBADO'
WHERE diag_ingles IS NULL;


/* TRANSFORMACION TABLA DE HECHOS SEMESTRE SQL */
WITH conteo_calificaciones AS (
    SELECT
        a.pidm,
        a.periodo,
        SUM(a.creditos) AS c_inscritos,
        SUM(CASE WHEN a.calificacion > 4.0 THEN a.creditos ELSE 0 END) AS c_aprobados,
        COUNT(*) AS total_asignaturas,
        COUNT(CASE WHEN calificacion < 4 THEN 1 END) AS asignaturas_reprobadas,
        CASE
            WHEN a.periodo = TO_CHAR(CURRENT_DATE, 'YYYY') ||
                CASE
                    WHEN EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 1 AND 7 THEN '10'
                    WHEN EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 8 AND 12 THEN '20'
                END
            THEN NULL
            ELSE ROUND(
                SUM(a.calificacion * a.creditos) / NULLIF(SUM(a.creditos), 0)
            , 2)
        END AS ppa
    FROM asignaturas_semestre a
    GROUP BY a.pidm, a.periodo
),
estudiantes_alertas AS (
    SELECT
        pidm,
        rut_est,
        cohorte_est,
        tipo_ingreso,
        CASE
            WHEN tipo_ingreso = 'IEP-Propedeutico' OR tipo_ingreso = 'IEP-Ingreso Cupo PACE' THEN 1
            ELSE 0
        END AS alerta_vcme,
        CASE
            WHEN tipo_ingreso = 'IEP-Inclusión' THEN 1
            ELSE 0
        END AS alerta_nee,
        CASE
            WHEN (diag_matematica = 'REPROBADO'
                OR diag_lenguaje = 'REPROBADO'
                OR diag_ingles = 'REPROBADO'
                OR niv_matematica = 'REPROBADO'
                OR niv_lenguaje = 'REPROBADO') THEN 1
            ELSE 0
        END AS alerta_diagniv
    FROM estudiantes
)
SELECT
    c.pidm,
    c.periodo,
    c.c_inscritos,
    c.c_aprobados,
    CASE
        WHEN c.periodo = TO_CHAR(CURRENT_DATE, 'YYYY') ||
            CASE
                WHEN EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 1 AND 7 THEN '10'
                WHEN EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 8 AND 12 THEN '20'
            END
        THEN 0
        WHEN c.total_asignaturas > 0 AND  -- Aseguramos que haya asignaturas inscritas
             (c.asignaturas_reprobadas::DECIMAL * 100 / NULLIF(c.total_asignaturas, 0)) > 50 
        THEN 1
        ELSE 0
    END AS alerta_reprobacion50,
    m.id_sede,
    m.id_matricula,
    m.alerta_ccarrera,
    m.alerta_reintegro,
    CASE 
        WHEN e.alerta_diagniv = 1 AND c.periodo = e.cohorte_est THEN 1
        ELSE 0 
    END as alerta_diagniv,
    COALESCE(e.alerta_vcme, 0) as alerta_vcme,
    COALESCE(e.alerta_nee, 0) as alerta_nee,
    e.rut_est,
    e.cohorte_est,
    e.tipo_ingreso,
    c.ppa,
    CASE
        WHEN c.ppa IS NULL THEN 0
        WHEN c.ppa <= 4 THEN 1
        ELSE 0
    END AS alerta_ppa,
    -- Campos adicionales para verificación del cálculo
    c.total_asignaturas,
    c.asignaturas_reprobadas,
    ROUND((c.asignaturas_reprobadas::DECIMAL * 100 / NULLIF(c.total_asignaturas, 0))::DECIMAL, 2) as porcentaje_reprobacion
FROM conteo_calificaciones c
LEFT JOIN (
    SELECT
        a.periodo,
        a.pidm,
        b.id_sede,
        MAX(a.id_matricula) AS id_matricula,
        CASE
            WHEN a.cod_programa != LAG(a.cod_programa) OVER (PARTITION BY a.pidm ORDER BY a.periodo) THEN 1
            ELSE 0
        END AS alerta_ccarrera,
        CASE
            WHEN MAX(CASE WHEN a.cod_estado = 'I' THEN 1 ELSE 0 END) = 1 THEN 1
            ELSE 0
        END AS alerta_reintegro
    FROM matriculas a
    JOIN sedes b ON (
        CASE
            WHEN RIGHT(a.cod_programa::TEXT, 1) = '6' THEN 'Coquimbo'
            WHEN RIGHT(a.cod_programa::TEXT, 1) = '3' THEN 'Antofagasta'
            ELSE 'OTRO'
        END
    ) = b.nombre_sede
    GROUP BY a.periodo, a.pidm, a.cod_programa, b.id_sede
) m ON c.pidm = m.pidm AND c.periodo = m.periodo
LEFT JOIN estudiantes_alertas e ON c.pidm = e.pidm
ORDER BY c.pidm, c.periodo;