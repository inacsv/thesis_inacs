CREATE DATABASE DAI;

CREATE TABLE DAI.dbo.BAN_ESTADOS_ACADEMICOS (
    RUT varchar(9) COLLATE Latin1_General_100_CI_AI NOT NULL,
    NOMBRE varchar(200) COLLATE Latin1_General_100_CI_AI NULL,
    SEXO varchar(10) COLLATE Latin1_General_100_CI_AI NULL,
    NACIONALIDAD varchar(50) COLLATE Latin1_General_100_CI_AI NULL,
    SORLCUR numeric(3,0) NULL,
    PERIODO varchar(6) COLLATE Latin1_General_100_CI_AI NULL,
    PLAN_ESTUDIOS numeric(2,0) NULL,
    CATALOGO varchar(6) COLLATE Latin1_General_100_CI_AI NULL,
    COD_ADMISION varchar(2) COLLATE Latin1_General_100_CI_AI NULL,
    ADMISION varchar(50) COLLATE Latin1_General_100_CI_AI NULL,
    PERIODO_ADMISION varchar(6) COLLATE Latin1_General_100_CI_AI NULL,
    COD_PROGRAMA varchar(4) COLLATE Latin1_General_100_CI_AI NULL,
    NOMBRE_BANNER varchar(100) COLLATE Latin1_General_100_CI_AI NULL,
    NOMBRE_ESTANDAR varchar(100) COLLATE Latin1_General_100_CI_AI NULL,
    COD_ESTADO varchar(1) COLLATE Latin1_General_100_CI_AI NULL,
    NOMBRE_ESTADO varchar(50) COLLATE Latin1_General_100_CI_AI NULL,
    FECHA_ESTADO datetime NULL,
    COD_CAUSAL varchar(2) COLLATE Latin1_General_100_CI_AI NULL,
    CAUSAL varchar(30) COLLATE Latin1_General_100_CI_AI NULL
);


  
   
