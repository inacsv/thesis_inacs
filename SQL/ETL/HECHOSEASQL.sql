/* SEGUIMIENTO, MEJORA, SEDE, PERIODO HECHOS EA */
WITH periodos_sedes AS (
    SELECT DISTINCT 
        dt.semestre as periodo,
        s.id_sede
    FROM dimension_tiempo dt
    CROSS JOIN (SELECT DISTINCT id_sede FROM hechos_semestre) s
    WHERE dt.semestre IN (SELECT DISTINCT periodo FROM hechos_semestre)
),
totales_originales AS (
    SELECT 
        a.periodo,
        a.id_sede,
        SUM(a.seguimiento) AS seguimiento_total,
        SUM(a.mejora_situacion) AS mejoras_total,
        SUM(alerta_activa) AS alertas_total_estudiantes
    FROM hechos_semestre a
    INNER JOIN dimension_tiempo b ON a.periodo = b.semestre
    GROUP BY a.periodo, a.id_sede
)
SELECT 
    ps.periodo,
    ps.id_sede,
    COALESCE(t.seguimiento_total, 0) as seguimiento_total,
    COALESCE(t.mejoras_total, 0) as mejoras_total,
    COALESCE(t.alertas_total_estudiantes, 0) as alertas_total_estudiantes
FROM periodos_sedes ps
LEFT JOIN totales_originales t 
    ON ps.periodo = t.periodo 
    AND ps.id_sede = t.id_sede
ORDER BY ps.periodo, ps.id_sede;


/* ALERTAS, SEDE, PERIODO, ID_ALERTA HECHOS EA */ 
WITH periodos_sedes_alertas AS (
    SELECT DISTINCT 
        dt.semestre as periodo,
        s.id_sede,
        a.id_alerta
    FROM dimension_tiempo dt
    CROSS JOIN (SELECT DISTINCT id_sede FROM hechos_semestre) s
    CROSS JOIN alertas_academicas a
    WHERE dt.semestre IN (SELECT DISTINCT periodo FROM hechos_semestre)
),
totales_originales AS (
    SELECT 
        hs.periodo,
        hs.id_sede,
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
            WHEN aa.criterio_alerta LIKE'%Estudiante con reprobación de una asignatura en dos o más oportunidades%'  THEN SUM(hs.alerta_reprobacion2)
            WHEN aa.criterio_alerta LIKE '%Estudiante con Porcentaje de aprobación menor al 50% de las asignaturas inscritas.%' THEN SUM(hs.alerta_reprobacion50)
            WHEN aa.criterio_alerta LIKE'%Estudiante proveniente de programas de VcME%' THEN SUM(hs.alerta_vcme)
            WHEN aa.criterio_alerta LIKE '%Estudiante con NEE%' THEN SUM(hs.alerta_nee)
         	WHEN aa.criterio_alerta LIKE '%Estudiante con cambios de carrera%' THEN SUM(hs.alerta_ccarrera)
         	WHEN aa.criterio_alerta LIKE '%Estudiante con reintegro a su carrera, como resultado de apelación por causal de eliminación%' THEN SUM(hs.alerta_reintegro)
         	WHEN aa.criterio_alerta LIKE '%Estudiante con reprobación de diagnóstico y/o nivelación%' THEN SUM(hs.alerta_diagniv)
        END as alertas_total
    FROM hechos_semestre hs
    CROSS JOIN alertas_academicas aa
    GROUP BY hs.periodo, hs.id_sede, aa.criterio_alerta, aa.id_alerta
)
SELECT 
    psa.periodo,
    psa.id_sede,
    psa.id_alerta,
    COALESCE(t.alertas_total, 0) as alertas_total
FROM periodos_sedes_alertas psa
LEFT JOIN totales_originales t
    ON psa.periodo = t.periodo
    AND psa.id_sede = t.id_sede
    AND psa.id_alerta = t.id_alerta
ORDER BY psa.periodo, psa.id_sede, psa.id_alerta; 


