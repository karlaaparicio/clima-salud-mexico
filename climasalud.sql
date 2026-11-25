-- ################ CLIMA Y SALUD  ################
-- =====================================================================
-- PROYECTO: Clima-Salud-México (Base de Datos, UABC)
-- Elaborado por: Zoe Crespo, Ingrid Montesinos, Karla Aparicio. 
-- =====================================================================
DROP DATABASE IF EXISTS clima_salud_mx;
CREATE DATABASE clima_salud_mx CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE clima_salud_mx;

-- ---------- 1. estados ----------
CREATE TABLE estados (
  id_estado INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  clave     CHAR(2)     NOT NULL UNIQUE,
  nombre    VARCHAR(60) NOT NULL UNIQUE,
  region    VARCHAR(20) NOT NULL,
  CONSTRAINT ck_estados_region CHECK (region IN ('Noroeste','Noreste','Occidente','Centro','Sur','Sureste'))
) ENGINE=InnoDB;

-- ---------- 2. municipios ----------
CREATE TABLE municipios (
  id_municipio INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_estado    INT UNSIGNED NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,
  poblacion    INT UNSIGNED NOT NULL,
  UNIQUE KEY uq_municipio_estado (id_estado, nombre),
  CONSTRAINT fk_mun_estado FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_mun_poblacion CHECK (poblacion > 0)
) ENGINE=InnoDB;

-- ---------- 3. estaciones meteorológicas ----------
CREATE TABLE estaciones_meteorologicas (
  id_estacion  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_municipio INT UNSIGNED NOT NULL,
  nombre       VARCHAR(100) NOT NULL,
  latitud      DECIMAL(9,6) NOT NULL,
  longitud     DECIMAL(9,6) NOT NULL,
  altitud_m    INT NOT NULL,
  estatus      ENUM('activa','inactiva','mantenimiento') NOT NULL DEFAULT 'activa',
  UNIQUE KEY uq_estacion_nombre (nombre),
  CONSTRAINT fk_est_municipio FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_est_lat CHECK (latitud BETWEEN 14 AND 33),
  CONSTRAINT ck_est_lon CHECK (longitud BETWEEN -119 AND -86)
) ENGINE=InnoDB;

-- ---------- 4. registros de clima (diarios) ----------
CREATE TABLE registros_clima (
  id_registro      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_estacion      INT UNSIGNED NOT NULL,
  fecha            DATE NOT NULL,
  temp_max         DECIMAL(4,1) NOT NULL,
  temp_min         DECIMAL(4,1) NOT NULL,
  humedad_pct      TINYINT UNSIGNED NOT NULL,
  precipitacion_mm DECIMAL(6,1) NOT NULL DEFAULT 0,
  indice_uv        DECIMAL(3,1) NOT NULL,
  ica              SMALLINT UNSIGNED NOT NULL COMMENT 'Índice de calidad del aire',
  UNIQUE KEY uq_registro_dia (id_estacion, fecha),
  KEY ix_registro_fecha (fecha),
  CONSTRAINT fk_reg_estacion FOREIGN KEY (id_estacion) REFERENCES estaciones_meteorologicas(id_estacion)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_reg_temp CHECK (temp_max >= temp_min AND temp_max BETWEEN -20 AND 60),
  CONSTRAINT ck_reg_hum  CHECK (humedad_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_reg_prec CHECK (precipitacion_mm >= 0),
  CONSTRAINT ck_reg_uv   CHECK (indice_uv BETWEEN 0 AND 15)
) ENGINE=InnoDB;

-- ---------- 5. enfermedades ----------
CREATE TABLE enfermedades (
  id_enfermedad    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(80) NOT NULL UNIQUE,
  categoria        ENUM('respiratoria','vectorial','gastrointestinal','cardiovascular','golpe_de_calor','otra') NOT NULL,
  factor_climatico VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

-- ---------- 6. unidades de salud ----------
CREATE TABLE unidades_salud (
  id_unidad    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_municipio INT UNSIGNED NOT NULL,
  nombre       VARCHAR(120) NOT NULL,
  tipo         ENUM('hospital','centro_de_salud','clinica') NOT NULL,
  institucion  ENUM('IMSS','ISSSTE','SSA','Privada') NOT NULL,
  camas        INT NOT NULL DEFAULT 0,
  UNIQUE KEY uq_unidad_nombre (nombre),
  CONSTRAINT fk_uni_municipio FOREIGN KEY (id_municipio) REFERENCES municipios(id_municipio)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_uni_camas CHECK (camas >= 0)
) ENGINE=InnoDB;

-- ---------- 7. casos de salud (registro mensual por unidad) ----------
CREATE TABLE casos_salud (
  id_caso       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_unidad     INT UNSIGNED NOT NULL,
  id_enfermedad INT UNSIGNED NOT NULL,
  fecha         DATE NOT NULL COMMENT 'Primer día del mes reportado',
  grupo_edad    ENUM('0-14','15-44','45-64','65+') NOT NULL,
  num_casos     INT NOT NULL,
  defunciones   INT NOT NULL DEFAULT 0,
  UNIQUE KEY uq_caso (id_unidad, id_enfermedad, fecha, grupo_edad),
  KEY ix_caso_fecha (fecha),
  CONSTRAINT fk_caso_unidad FOREIGN KEY (id_unidad) REFERENCES unidades_salud(id_unidad)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_caso_enf FOREIGN KEY (id_enfermedad) REFERENCES enfermedades(id_enfermedad)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_caso_num CHECK (num_casos >= 0),
  CONSTRAINT ck_caso_def CHECK (defunciones >= 0 AND defunciones <= num_casos)
) ENGINE=InnoDB;

-- ---------- Tabla de apoyo del proceso mensual ----------
CREATE TABLE resumen_mensual (
  id_resumen      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_estado       INT UNSIGNED NOT NULL,
  anio            SMALLINT NOT NULL,
  mes             TINYINT NOT NULL,
  temp_prom       DECIMAL(4,1),
  precipitacion_mm DECIMAL(8,1),
  total_casos     INT NOT NULL DEFAULT 0,
  defunciones     INT NOT NULL DEFAULT 0,
  generado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_resumen (id_estado, anio, mes),
  CONSTRAINT fk_res_estado FOREIGN KEY (id_estado) REFERENCES estados(id_estado)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Tabla de auditoría (se llena con triggers, archivo 04) ----------
CREATE TABLE auditoria (
  id_auditoria     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tabla            VARCHAR(40) NOT NULL,
  operacion        ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  id_registro      VARCHAR(40) NOT NULL,
  datos_anteriores JSON NULL,
  datos_nuevos     JSON NULL,
  usuario_mysql    VARCHAR(100) NOT NULL,
  fecha_hora       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_aud_tabla (tabla, fecha_hora)
) ENGINE=InnoDB;

-- =====================================================================
-- DATOS: catálogos
-- =====================================================================
INSERT INTO estados (clave, nombre, region) VALUES
('01','Aguascalientes','Occidente'),('02','Baja California','Noroeste'),('03','Baja California Sur','Noroeste'),
('04','Campeche','Sureste'),('05','Coahuila','Noreste'),('06','Colima','Occidente'),('07','Chiapas','Sur'),
('08','Chihuahua','Noroeste'),('09','Ciudad de México','Centro'),('10','Durango','Noroeste'),
('11','Guanajuato','Centro'),('12','Guerrero','Sur'),('13','Hidalgo','Centro'),('14','Jalisco','Occidente'),
('15','México','Centro'),('16','Michoacán','Occidente'),('17','Morelos','Centro'),('18','Nayarit','Occidente'),
('19','Nuevo León','Noreste'),('20','Oaxaca','Sur'),('21','Puebla','Centro'),('22','Querétaro','Centro'),
('23','Quintana Roo','Sureste'),('24','San Luis Potosí','Centro'),('25','Sinaloa','Noroeste'),
('26','Sonora','Noroeste'),('27','Tabasco','Sureste'),('28','Tamaulipas','Noreste'),('29','Tlaxcala','Centro'),
('30','Veracruz','Sureste'),('31','Yucatán','Sureste'),('32','Zacatecas','Occidente');

-- Población aproximada (redondeada, orden de magnitud del Censo 2020; verificar con INEGI si se requiere exactitud)
INSERT INTO municipios (id_estado, nombre, poblacion)
SELECT e.id_estado, m.nombre, m.poblacion FROM (
  SELECT '02' c,'Tijuana' nombre,1922000 poblacion UNION ALL
  SELECT '02','Mexicali',1050000 UNION ALL
  SELECT '26','Hermosillo',936000 UNION ALL
  SELECT '19','Monterrey',1143000 UNION ALL
  SELECT '14','Guadalajara',1386000 UNION ALL
  SELECT '09','Cuauhtémoc',545000 UNION ALL
  SELECT '31','Mérida',995000 UNION ALL
  SELECT '30','Veracruz',607000 UNION ALL
  SELECT '27','Centro',684000 UNION ALL
  SELECT '07','Tapachula',354000 UNION ALL
  SELECT '23','Benito Juárez',912000 UNION ALL
  SELECT '03','La Paz',292000 UNION ALL
  SELECT '08','Chihuahua',938000 UNION ALL
  SELECT '05','Saltillo',880000 UNION ALL
  SELECT '21','Puebla',1692000 UNION ALL
  SELECT '11','León',1722000 UNION ALL
  SELECT '25','Culiacán',1004000 UNION ALL
  SELECT '12','Acapulco de Juárez',779000 UNION ALL
  SELECT '20','Oaxaca de Juárez',271000 UNION ALL
  SELECT '15','Toluca',910000
) m JOIN estados e ON e.clave = m.c;

INSERT INTO estaciones_meteorologicas (id_municipio, nombre, latitud, longitud, altitud_m)
SELECT mu.id_municipio, x.nombre, x.lat, x.lon, x.alt FROM (
  SELECT 'Tijuana' mun,'02' c,'Estación Tijuana' nombre, 32.5149 lat,-117.0382 lon,20 alt UNION ALL
  SELECT 'Mexicali','02','Estación Mexicali',32.6639,-115.4678,8 UNION ALL
  SELECT 'Hermosillo','26','Estación Hermosillo',29.0729,-110.9559,210 UNION ALL
  SELECT 'Monterrey','19','Estación Monterrey',25.6866,-100.3161,540 UNION ALL
  SELECT 'Guadalajara','14','Estación Guadalajara',20.6597,-103.3496,1566 UNION ALL
  SELECT 'Cuauhtémoc','09','Estación CDMX Centro',19.4326,-99.1332,2240 UNION ALL
  SELECT 'Mérida','31','Estación Mérida',20.9674,-89.5926,10 UNION ALL
  SELECT 'Veracruz','30','Estación Veracruz',19.1738,-96.1342,10 UNION ALL
  SELECT 'Centro','27','Estación Villahermosa',17.9892,-92.9475,10 UNION ALL
  SELECT 'Tapachula','07','Estación Tapachula',14.9082,-92.2573,170 UNION ALL
  SELECT 'Benito Juárez','23','Estación Cancún',21.1619,-86.8515,10 UNION ALL
  SELECT 'La Paz','03','Estación La Paz',24.1426,-110.3128,10
) x
JOIN estados e ON e.clave = x.c
JOIN municipios mu ON mu.id_estado = e.id_estado AND mu.nombre = x.mun;

INSERT INTO enfermedades (nombre, categoria, factor_climatico) VALUES
('Dengue','vectorial','Lluvia y temperatura cálida favorecen la reproducción del mosquito Aedes aegypti'),
('Chikungunya','vectorial','Lluvia y temperatura cálida favorecen la reproducción del mosquito Aedes'),
('Golpe de calor','golpe_de_calor','Temperaturas máximas extremas y humedad alta'),
('Infección respiratoria aguda','respiratoria','Temperaturas bajas y cambios bruscos de temperatura'),
('Enfermedad diarreica aguda','gastrointestinal','Calor que acelera la descomposición de alimentos y contaminación del agua'),
('Asma','respiratoria','Frío y mala calidad del aire'),
('Influenza','respiratoria','Temporada invernal y temperaturas bajas');

-- Dos unidades de salud por cada municipio que tiene estación meteorológica
INSERT INTO unidades_salud (id_municipio, nombre, tipo, institucion, camas)
SELECT m.id_municipio, CONCAT('Hospital General de ', m.nombre), 'hospital', 'SSA', 120 + (m.id_municipio * 17 MOD 180)
FROM municipios m WHERE m.id_municipio IN (SELECT id_municipio FROM estaciones_meteorologicas)
UNION ALL
SELECT m.id_municipio, CONCAT('Centro de Salud ', m.nombre), 'centro_de_salud', 'IMSS', 10 + (m.id_municipio MOD 15)
FROM municipios m WHERE m.id_municipio IN (SELECT id_municipio FROM estaciones_meteorologicas);

-- =====================================================================
-- DATOS SINTÉTICOS: clima diario del año 2025 por estación
-- =====================================================================
CREATE TEMPORARY TABLE tmp_param (
  nombre VARCHAR(100), temp_media DECIMAL(4,1), amplitud DECIMAL(4,1), rango_diurno DECIMAL(4,1),
  lluvia_idx DECIMAL(3,2), hum_base TINYINT, uv_base DECIMAL(3,1), ica_base SMALLINT
);
INSERT INTO tmp_param VALUES
('Estación Mexicali',23.0,10.5,16,0.02,30,7.0,80),('Estación Tijuana',17.5,4.5,9,0.20,68,6.0,70),
('Estación Hermosillo',24.5,8.5,15,0.25,40,7.5,60),('Estación Monterrey',22.5,7.5,11,0.30,55,6.5,85),
('Estación Guadalajara',20.5,4.0,14,0.70,55,7.0,75),('Estación CDMX Centro',17.0,3.0,13,0.60,55,7.5,95),
('Estación Mérida',26.5,3.5,11,0.50,70,8.0,45),('Estación Veracruz',25.5,3.5,7,0.70,75,7.5,50),
('Estación Villahermosa',26.5,3.5,9,0.90,80,7.5,50),('Estación Tapachula',26.5,1.5,10,1.00,80,8.0,40),
('Estación Cancún',26.5,3.0,8,0.70,75,9.0,40),('Estación La Paz',24.5,6.5,11,0.10,62,8.0,40);

CREATE TEMPORARY TABLE tmp_dias AS
WITH RECURSIVE d (fecha) AS (
  SELECT DATE '2025-01-01' UNION ALL SELECT fecha + INTERVAL 1 DAY FROM d WHERE fecha < '2025-12-31'
) SELECT fecha FROM d;

INSERT INTO registros_clima (id_estacion, fecha, temp_max, temp_min, humedad_pct, precipitacion_mm, indice_uv, ica)
SELECT id_estacion, fecha,
       ROUND(tp + rango_diurno/2 + (r1-0.5)*2, 1),
       ROUND(tp - rango_diurno/2 + (r1-0.5)*2, 1),
       LEAST(100, GREATEST(10, ROUND(hum_base + 20*lluvia*lluvia_idx + (r2-0.5)*10))),
       IF(r3 < 0.55*lluvia*lluvia_idx, ROUND(r4*45*lluvia, 1), 0),
       ROUND(LEAST(14, GREATEST(1, uv_base + 3*estac + (r2-0.5)*2)), 1),
       GREATEST(15, ROUND(ica_base + (r4-0.5)*40))
FROM (
  SELECT e.id_estacion, d.fecha, p.rango_diurno, p.lluvia_idx, p.hum_base, p.uv_base, p.ica_base,
         p.temp_media + p.amplitud * SIN(2*PI()*(DAYOFYEAR(d.fecha)-110)/365) + (RAND(e.id_estacion*1000+DAYOFYEAR(d.fecha))-0.5)*3 AS tp,
         GREATEST(0, SIN(2*PI()*(DAYOFYEAR(d.fecha)-130)/365)) AS lluvia,
         SIN(2*PI()*(DAYOFYEAR(d.fecha)-110)/365) AS estac,
         RAND(e.id_estacion*1000+DAYOFYEAR(d.fecha)+1) r1,
         RAND(e.id_estacion*1000+DAYOFYEAR(d.fecha)+2) r2,
         RAND(e.id_estacion*1000+DAYOFYEAR(d.fecha)+3) r3,
         RAND(e.id_estacion*1000+DAYOFYEAR(d.fecha)+4) r4
  FROM estaciones_meteorologicas e
  JOIN tmp_param p ON p.nombre = e.nombre
  CROSS JOIN tmp_dias d
) t;

-- =====================================================================
-- DATOS SINTÉTICOS: casos de salud mensuales 2025 (dependen del clima del mes)
-- =====================================================================
CREATE TEMPORARY TABLE tmp_clima_mes AS
SELECT e.id_municipio, MONTH(r.fecha) mes,
       AVG((r.temp_max + r.temp_min)/2) t_prom, AVG(r.temp_max) t_max,
       SUM(r.precipitacion_mm) lluvia, AVG(r.ica) ica
FROM registros_clima r JOIN estaciones_meteorologicas e ON e.id_estacion = r.id_estacion
GROUP BY e.id_municipio, MONTH(r.fecha);

CREATE TEMPORARY TABLE tmp_edades (grupo ENUM('0-14','15-44','45-64','65+'), peso DECIMAL(3,2));
INSERT INTO tmp_edades VALUES ('0-14',0.9),('15-44',1.0),('45-64',0.8),('65+',0.7);

INSERT INTO casos_salud (id_unidad, id_enfermedad, fecha, grupo_edad, num_casos, defunciones)
SELECT id_unidad, id_enfermedad, fecha, grupo, n,
       LEAST(n, FLOOR(n * letalidad * RAND(id_unidad*7919+id_enfermedad*104729+mes*13+9)))
FROM (
  SELECT u.id_unidad, en.id_enfermedad, MAKEDATE(2025,1) + INTERVAL (c.mes-1) MONTH AS fecha, c.mes, ed.grupo,
    CASE en.nombre
      WHEN 'Dengue' THEN 0.010 WHEN 'Chikungunya' THEN 0.005 WHEN 'Golpe de calor' THEN 0.030
      WHEN 'Infección respiratoria aguda' THEN 0.005 WHEN 'Enfermedad diarreica aguda' THEN 0.003
      WHEN 'Asma' THEN 0.002 ELSE 0.010 END AS letalidad,
    GREATEST(0, ROUND(
      (u.camas/12) * ed.peso *
      CASE en.nombre
        WHEN 'Dengue'        THEN IF(c.t_prom>=22, 0.1 + c.lluvia/90, 0.02)
        WHEN 'Chikungunya'   THEN IF(c.t_prom>=22, 0.05 + c.lluvia/150, 0.01)
        WHEN 'Golpe de calor' THEN GREATEST(0, c.t_max-32)/3
        WHEN 'Infección respiratoria aguda' THEN 0.3 + GREATEST(0, 24-c.t_prom)/5
        WHEN 'Enfermedad diarreica aguda'   THEN 0.2 + GREATEST(0, c.t_prom-15)/12
        WHEN 'Asma'          THEN 0.2 + GREATEST(0, 22-c.t_prom)/10 + c.ica/250
        ELSE GREATEST(0, 20-c.t_prom)/6 END
      * (0.6 + 0.8*RAND(u.id_unidad*7919+en.id_enfermedad*104729+c.mes*13))
    )) AS n
  FROM unidades_salud u
  JOIN tmp_clima_mes c ON c.id_municipio = u.id_municipio
  CROSS JOIN enfermedades en
  CROSS JOIN tmp_edades ed
) x
WHERE n > 0;

DROP TEMPORARY TABLE tmp_param, tmp_dias, tmp_clima_mes, tmp_edades;

-- ################ 02_funciones.sql ################
-- Archivo 02: funciones almacenadas
USE clima_salud_mx;
DROP FUNCTION IF EXISTS fn_temp_promedio;
DROP FUNCTION IF EXISTS fn_nivel_riesgo_calor;
DROP FUNCTION IF EXISTS fn_tasa_letalidad;
DROP FUNCTION IF EXISTS fn_tasa_100k;
DELIMITER $$
CREATE FUNCTION fn_temp_promedio(p_max DECIMAL(4,1), p_min DECIMAL(4,1))
RETURNS DECIMAL(4,1) DETERMINISTIC
BEGIN
  RETURN ROUND((p_max + p_min) / 2, 1);
END$$

CREATE FUNCTION fn_nivel_riesgo_calor(p_temp_max DECIMAL(4,1))
RETURNS VARCHAR(10) DETERMINISTIC
BEGIN
  RETURN CASE WHEN p_temp_max < 30 THEN 'bajo'
              WHEN p_temp_max < 35 THEN 'moderado'
              WHEN p_temp_max < 40 THEN 'alto'
              ELSE 'extremo' END;
END$$

-- Porcentaje de defunciones sobre casos
CREATE FUNCTION fn_tasa_letalidad(p_casos INT, p_defunciones INT)
RETURNS DECIMAL(5,2) DETERMINISTIC
BEGIN
  IF p_casos IS NULL OR p_casos = 0 THEN RETURN 0; END IF;
  RETURN ROUND(p_defunciones * 100 / p_casos, 2);
END$$

-- Casos por cada 100,000 habitantes
CREATE FUNCTION fn_tasa_100k(p_casos INT, p_poblacion INT)
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
  IF p_poblacion IS NULL OR p_poblacion = 0 THEN RETURN 0; END IF;
  RETURN ROUND(p_casos * 100000 / p_poblacion, 2);
END$$
DELIMITER ;

-- ################ 03_procedimientos_crud.sql ################
-- Archivo 03: procedimientos almacenados CRUD (generado)
USE clima_salud_mx;

DROP PROCEDURE IF EXISTS sp_estado_crear;
DROP PROCEDURE IF EXISTS sp_estado_leer;
DROP PROCEDURE IF EXISTS sp_estado_listar;
DROP PROCEDURE IF EXISTS sp_estado_actualizar;
DROP PROCEDURE IF EXISTS sp_estado_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_estado_crear(
  IN p_clave CHAR(2),
  IN p_nombre VARCHAR(60),
  IN p_region VARCHAR(20),
  OUT p_id_estado INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO estados (clave, nombre, region) VALUES (p_clave, p_nombre, p_region);
  SET p_id_estado = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_estado_leer(IN p_id_estado INT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM estados WHERE id_estado = p_id_estado) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en estados';
  END IF;
  SELECT * FROM estados WHERE id_estado = p_id_estado;
END$$

CREATE PROCEDURE sp_estado_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM estados ORDER BY id_estado LIMIT v_limite;
END$$

CREATE PROCEDURE sp_estado_actualizar(
  IN p_id_estado INT UNSIGNED,
  IN p_clave CHAR(2),
  IN p_nombre VARCHAR(60),
  IN p_region VARCHAR(20)
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM estados WHERE id_estado = p_id_estado) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en estados';
  END IF;
  UPDATE estados SET clave = p_clave, nombre = p_nombre, region = p_region WHERE id_estado = p_id_estado;
END$$

CREATE PROCEDURE sp_estado_eliminar(IN p_id_estado INT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM estados WHERE id_estado = p_id_estado) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en estados';
  END IF;
  DELETE FROM estados WHERE id_estado = p_id_estado;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_municipio_crear;
DROP PROCEDURE IF EXISTS sp_municipio_leer;
DROP PROCEDURE IF EXISTS sp_municipio_listar;
DROP PROCEDURE IF EXISTS sp_municipio_actualizar;
DROP PROCEDURE IF EXISTS sp_municipio_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_municipio_crear(
  IN p_id_estado INT UNSIGNED,
  IN p_nombre VARCHAR(80),
  IN p_poblacion INT UNSIGNED,
  OUT p_id_municipio INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO municipios (id_estado, nombre, poblacion) VALUES (p_id_estado, p_nombre, p_poblacion);
  SET p_id_municipio = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_municipio_leer(IN p_id_municipio INT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM municipios WHERE id_municipio = p_id_municipio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en municipios';
  END IF;
  SELECT * FROM municipios WHERE id_municipio = p_id_municipio;
END$$

CREATE PROCEDURE sp_municipio_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM municipios ORDER BY id_municipio LIMIT v_limite;
END$$

CREATE PROCEDURE sp_municipio_actualizar(
  IN p_id_municipio INT UNSIGNED,
  IN p_id_estado INT UNSIGNED,
  IN p_nombre VARCHAR(80),
  IN p_poblacion INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM municipios WHERE id_municipio = p_id_municipio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en municipios';
  END IF;
  UPDATE municipios SET id_estado = p_id_estado, nombre = p_nombre, poblacion = p_poblacion WHERE id_municipio = p_id_municipio;
END$$

CREATE PROCEDURE sp_municipio_eliminar(IN p_id_municipio INT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM municipios WHERE id_municipio = p_id_municipio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en municipios';
  END IF;
  DELETE FROM municipios WHERE id_municipio = p_id_municipio;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_estacion_crear;
DROP PROCEDURE IF EXISTS sp_estacion_leer;
DROP PROCEDURE IF EXISTS sp_estacion_listar;
DROP PROCEDURE IF EXISTS sp_estacion_actualizar;
DROP PROCEDURE IF EXISTS sp_estacion_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_estacion_crear(
  IN p_id_municipio INT UNSIGNED,
  IN p_nombre VARCHAR(100),
  IN p_latitud DECIMAL(9,6),
  IN p_longitud DECIMAL(9,6),
  IN p_altitud_m INT,
  IN p_estatus VARCHAR(15),
  OUT p_id_estacion INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO estaciones_meteorologicas (id_municipio, nombre, latitud, longitud, altitud_m, estatus) VALUES (p_id_municipio, p_nombre, p_latitud, p_longitud, p_altitud_m, p_estatus);
  SET p_id_estacion = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_estacion_leer(IN p_id_estacion INT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM estaciones_meteorologicas WHERE id_estacion = p_id_estacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en estaciones_meteorologicas';
  END IF;
  SELECT * FROM estaciones_meteorologicas WHERE id_estacion = p_id_estacion;
END$$

CREATE PROCEDURE sp_estacion_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM estaciones_meteorologicas ORDER BY id_estacion LIMIT v_limite;
END$$

CREATE PROCEDURE sp_estacion_actualizar(
  IN p_id_estacion INT UNSIGNED,
  IN p_id_municipio INT UNSIGNED,
  IN p_nombre VARCHAR(100),
  IN p_latitud DECIMAL(9,6),
  IN p_longitud DECIMAL(9,6),
  IN p_altitud_m INT,
  IN p_estatus VARCHAR(15)
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM estaciones_meteorologicas WHERE id_estacion = p_id_estacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en estaciones_meteorologicas';
  END IF;
  UPDATE estaciones_meteorologicas SET id_municipio = p_id_municipio, nombre = p_nombre, latitud = p_latitud, longitud = p_longitud, altitud_m = p_altitud_m, estatus = p_estatus WHERE id_estacion = p_id_estacion;
END$$

CREATE PROCEDURE sp_estacion_eliminar(IN p_id_estacion INT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM estaciones_meteorologicas WHERE id_estacion = p_id_estacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en estaciones_meteorologicas';
  END IF;
  DELETE FROM estaciones_meteorologicas WHERE id_estacion = p_id_estacion;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_registro_clima_crear;
DROP PROCEDURE IF EXISTS sp_registro_clima_leer;
DROP PROCEDURE IF EXISTS sp_registro_clima_listar;
DROP PROCEDURE IF EXISTS sp_registro_clima_actualizar;
DROP PROCEDURE IF EXISTS sp_registro_clima_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_registro_clima_crear(
  IN p_id_estacion INT UNSIGNED,
  IN p_fecha DATE,
  IN p_temp_max DECIMAL(4,1),
  IN p_temp_min DECIMAL(4,1),
  IN p_humedad_pct TINYINT UNSIGNED,
  IN p_precipitacion_mm DECIMAL(6,1),
  IN p_indice_uv DECIMAL(3,1),
  IN p_ica SMALLINT UNSIGNED,
  OUT p_id_registro BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO registros_clima (id_estacion, fecha, temp_max, temp_min, humedad_pct, precipitacion_mm, indice_uv, ica) VALUES (p_id_estacion, p_fecha, p_temp_max, p_temp_min, p_humedad_pct, p_precipitacion_mm, p_indice_uv, p_ica);
  SET p_id_registro = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_registro_clima_leer(IN p_id_registro BIGINT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM registros_clima WHERE id_registro = p_id_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en registros_clima';
  END IF;
  SELECT * FROM registros_clima WHERE id_registro = p_id_registro;
END$$

CREATE PROCEDURE sp_registro_clima_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM registros_clima ORDER BY id_registro LIMIT v_limite;
END$$

CREATE PROCEDURE sp_registro_clima_actualizar(
  IN p_id_registro BIGINT UNSIGNED,
  IN p_id_estacion INT UNSIGNED,
  IN p_fecha DATE,
  IN p_temp_max DECIMAL(4,1),
  IN p_temp_min DECIMAL(4,1),
  IN p_humedad_pct TINYINT UNSIGNED,
  IN p_precipitacion_mm DECIMAL(6,1),
  IN p_indice_uv DECIMAL(3,1),
  IN p_ica SMALLINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM registros_clima WHERE id_registro = p_id_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en registros_clima';
  END IF;
  UPDATE registros_clima SET id_estacion = p_id_estacion, fecha = p_fecha, temp_max = p_temp_max, temp_min = p_temp_min, humedad_pct = p_humedad_pct, precipitacion_mm = p_precipitacion_mm, indice_uv = p_indice_uv, ica = p_ica WHERE id_registro = p_id_registro;
END$$

CREATE PROCEDURE sp_registro_clima_eliminar(IN p_id_registro BIGINT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM registros_clima WHERE id_registro = p_id_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en registros_clima';
  END IF;
  DELETE FROM registros_clima WHERE id_registro = p_id_registro;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_enfermedad_crear;
DROP PROCEDURE IF EXISTS sp_enfermedad_leer;
DROP PROCEDURE IF EXISTS sp_enfermedad_listar;
DROP PROCEDURE IF EXISTS sp_enfermedad_actualizar;
DROP PROCEDURE IF EXISTS sp_enfermedad_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_enfermedad_crear(
  IN p_nombre VARCHAR(80),
  IN p_categoria VARCHAR(20),
  IN p_factor_climatico VARCHAR(150),
  OUT p_id_enfermedad INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO enfermedades (nombre, categoria, factor_climatico) VALUES (p_nombre, p_categoria, p_factor_climatico);
  SET p_id_enfermedad = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_enfermedad_leer(IN p_id_enfermedad INT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM enfermedades WHERE id_enfermedad = p_id_enfermedad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en enfermedades';
  END IF;
  SELECT * FROM enfermedades WHERE id_enfermedad = p_id_enfermedad;
END$$

CREATE PROCEDURE sp_enfermedad_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM enfermedades ORDER BY id_enfermedad LIMIT v_limite;
END$$

CREATE PROCEDURE sp_enfermedad_actualizar(
  IN p_id_enfermedad INT UNSIGNED,
  IN p_nombre VARCHAR(80),
  IN p_categoria VARCHAR(20),
  IN p_factor_climatico VARCHAR(150)
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM enfermedades WHERE id_enfermedad = p_id_enfermedad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en enfermedades';
  END IF;
  UPDATE enfermedades SET nombre = p_nombre, categoria = p_categoria, factor_climatico = p_factor_climatico WHERE id_enfermedad = p_id_enfermedad;
END$$

CREATE PROCEDURE sp_enfermedad_eliminar(IN p_id_enfermedad INT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM enfermedades WHERE id_enfermedad = p_id_enfermedad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en enfermedades';
  END IF;
  DELETE FROM enfermedades WHERE id_enfermedad = p_id_enfermedad;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_unidad_salud_crear;
DROP PROCEDURE IF EXISTS sp_unidad_salud_leer;
DROP PROCEDURE IF EXISTS sp_unidad_salud_listar;
DROP PROCEDURE IF EXISTS sp_unidad_salud_actualizar;
DROP PROCEDURE IF EXISTS sp_unidad_salud_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_unidad_salud_crear(
  IN p_id_municipio INT UNSIGNED,
  IN p_nombre VARCHAR(120),
  IN p_tipo VARCHAR(20),
  IN p_institucion VARCHAR(10),
  IN p_camas INT,
  OUT p_id_unidad INT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO unidades_salud (id_municipio, nombre, tipo, institucion, camas) VALUES (p_id_municipio, p_nombre, p_tipo, p_institucion, p_camas);
  SET p_id_unidad = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_unidad_salud_leer(IN p_id_unidad INT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM unidades_salud WHERE id_unidad = p_id_unidad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en unidades_salud';
  END IF;
  SELECT * FROM unidades_salud WHERE id_unidad = p_id_unidad;
END$$

CREATE PROCEDURE sp_unidad_salud_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM unidades_salud ORDER BY id_unidad LIMIT v_limite;
END$$

CREATE PROCEDURE sp_unidad_salud_actualizar(
  IN p_id_unidad INT UNSIGNED,
  IN p_id_municipio INT UNSIGNED,
  IN p_nombre VARCHAR(120),
  IN p_tipo VARCHAR(20),
  IN p_institucion VARCHAR(10),
  IN p_camas INT
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM unidades_salud WHERE id_unidad = p_id_unidad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en unidades_salud';
  END IF;
  UPDATE unidades_salud SET id_municipio = p_id_municipio, nombre = p_nombre, tipo = p_tipo, institucion = p_institucion, camas = p_camas WHERE id_unidad = p_id_unidad;
END$$

CREATE PROCEDURE sp_unidad_salud_eliminar(IN p_id_unidad INT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM unidades_salud WHERE id_unidad = p_id_unidad) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en unidades_salud';
  END IF;
  DELETE FROM unidades_salud WHERE id_unidad = p_id_unidad;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_caso_salud_crear;
DROP PROCEDURE IF EXISTS sp_caso_salud_leer;
DROP PROCEDURE IF EXISTS sp_caso_salud_listar;
DROP PROCEDURE IF EXISTS sp_caso_salud_actualizar;
DROP PROCEDURE IF EXISTS sp_caso_salud_eliminar;
DELIMITER $$

CREATE PROCEDURE sp_caso_salud_crear(
  IN p_id_unidad INT UNSIGNED,
  IN p_id_enfermedad INT UNSIGNED,
  IN p_fecha DATE,
  IN p_grupo_edad VARCHAR(5),
  IN p_num_casos INT,
  IN p_defunciones INT,
  OUT p_id_caso BIGINT UNSIGNED
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  INSERT INTO casos_salud (id_unidad, id_enfermedad, fecha, grupo_edad, num_casos, defunciones) VALUES (p_id_unidad, p_id_enfermedad, p_fecha, p_grupo_edad, p_num_casos, p_defunciones);
  SET p_id_caso = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_caso_salud_leer(IN p_id_caso BIGINT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM casos_salud WHERE id_caso = p_id_caso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro solicitado no existe en casos_salud';
  END IF;
  SELECT * FROM casos_salud WHERE id_caso = p_id_caso;
END$$

CREATE PROCEDURE sp_caso_salud_listar(IN p_limite INT)
BEGIN
  DECLARE v_limite INT DEFAULT 1000;
  IF p_limite IS NOT NULL AND p_limite > 0 THEN SET v_limite = p_limite; END IF;
  SELECT * FROM casos_salud ORDER BY id_caso LIMIT v_limite;
END$$

CREATE PROCEDURE sp_caso_salud_actualizar(
  IN p_id_caso BIGINT UNSIGNED,
  IN p_id_unidad INT UNSIGNED,
  IN p_id_enfermedad INT UNSIGNED,
  IN p_fecha DATE,
  IN p_grupo_edad VARCHAR(5),
  IN p_num_casos INT,
  IN p_defunciones INT
)
BEGIN
  DECLARE EXIT HANDLER FOR 1062 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Registro duplicado: ya existe un valor único igual';
  DECLARE EXIT HANDLER FOR 1452 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Referencia inválida: el registro relacionado no existe';
  DECLARE EXIT HANDLER FOR 3819 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor fuera de rango: no cumple una restricción CHECK';
  DECLARE EXIT HANDLER FOR 1265 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para una columna de tipo lista (ENUM)';
  DECLARE EXIT HANDLER FOR 1366 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para el tipo de dato de la columna';
  IF NOT EXISTS (SELECT 1 FROM casos_salud WHERE id_caso = p_id_caso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede actualizar: el registro no existe en casos_salud';
  END IF;
  UPDATE casos_salud SET id_unidad = p_id_unidad, id_enfermedad = p_id_enfermedad, fecha = p_fecha, grupo_edad = p_grupo_edad, num_casos = p_num_casos, defunciones = p_defunciones WHERE id_caso = p_id_caso;
END$$

CREATE PROCEDURE sp_caso_salud_eliminar(IN p_id_caso BIGINT UNSIGNED)
BEGIN
  DECLARE EXIT HANDLER FOR 1451 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene registros relacionados en otras tablas';
  IF NOT EXISTS (SELECT 1 FROM casos_salud WHERE id_caso = p_id_caso) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: el registro no existe en casos_salud';
  END IF;
  DELETE FROM casos_salud WHERE id_caso = p_id_caso;
END$$

DELIMITER ;

-- ################ 04_triggers_auditoria.sql ################
-- Archivo 04: triggers de auditoría (generado)
-- Registran INSERT, UPDATE y DELETE de las 7 entidades en la tabla auditoria
USE clima_salud_mx;

DROP TRIGGER IF EXISTS trg_estados_insert;
DROP TRIGGER IF EXISTS trg_estados_update;
DROP TRIGGER IF EXISTS trg_estados_delete;
DELIMITER $$

CREATE TRIGGER trg_estados_insert AFTER INSERT ON estados FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estados', 'INSERT', NEW.id_estado, NULL, JSON_OBJECT('id_estado', NEW.id_estado, 'clave', NEW.clave, 'nombre', NEW.nombre, 'region', NEW.region), USER());
END$$

CREATE TRIGGER trg_estados_update AFTER UPDATE ON estados FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estados', 'UPDATE', NEW.id_estado, JSON_OBJECT('id_estado', OLD.id_estado, 'clave', OLD.clave, 'nombre', OLD.nombre, 'region', OLD.region), JSON_OBJECT('id_estado', NEW.id_estado, 'clave', NEW.clave, 'nombre', NEW.nombre, 'region', NEW.region), USER());
END$$

CREATE TRIGGER trg_estados_delete AFTER DELETE ON estados FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estados', 'DELETE', OLD.id_estado, JSON_OBJECT('id_estado', OLD.id_estado, 'clave', OLD.clave, 'nombre', OLD.nombre, 'region', OLD.region), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_municipios_insert;
DROP TRIGGER IF EXISTS trg_municipios_update;
DROP TRIGGER IF EXISTS trg_municipios_delete;
DELIMITER $$

CREATE TRIGGER trg_municipios_insert AFTER INSERT ON municipios FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('municipios', 'INSERT', NEW.id_municipio, NULL, JSON_OBJECT('id_municipio', NEW.id_municipio, 'id_estado', NEW.id_estado, 'nombre', NEW.nombre, 'poblacion', NEW.poblacion), USER());
END$$

CREATE TRIGGER trg_municipios_update AFTER UPDATE ON municipios FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('municipios', 'UPDATE', NEW.id_municipio, JSON_OBJECT('id_municipio', OLD.id_municipio, 'id_estado', OLD.id_estado, 'nombre', OLD.nombre, 'poblacion', OLD.poblacion), JSON_OBJECT('id_municipio', NEW.id_municipio, 'id_estado', NEW.id_estado, 'nombre', NEW.nombre, 'poblacion', NEW.poblacion), USER());
END$$

CREATE TRIGGER trg_municipios_delete AFTER DELETE ON municipios FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('municipios', 'DELETE', OLD.id_municipio, JSON_OBJECT('id_municipio', OLD.id_municipio, 'id_estado', OLD.id_estado, 'nombre', OLD.nombre, 'poblacion', OLD.poblacion), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_estaciones_meteorologicas_insert;
DROP TRIGGER IF EXISTS trg_estaciones_meteorologicas_update;
DROP TRIGGER IF EXISTS trg_estaciones_meteorologicas_delete;
DELIMITER $$

CREATE TRIGGER trg_estaciones_meteorologicas_insert AFTER INSERT ON estaciones_meteorologicas FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estaciones_meteorologicas', 'INSERT', NEW.id_estacion, NULL, JSON_OBJECT('id_estacion', NEW.id_estacion, 'id_municipio', NEW.id_municipio, 'nombre', NEW.nombre, 'latitud', NEW.latitud, 'longitud', NEW.longitud, 'altitud_m', NEW.altitud_m, 'estatus', NEW.estatus), USER());
END$$

CREATE TRIGGER trg_estaciones_meteorologicas_update AFTER UPDATE ON estaciones_meteorologicas FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estaciones_meteorologicas', 'UPDATE', NEW.id_estacion, JSON_OBJECT('id_estacion', OLD.id_estacion, 'id_municipio', OLD.id_municipio, 'nombre', OLD.nombre, 'latitud', OLD.latitud, 'longitud', OLD.longitud, 'altitud_m', OLD.altitud_m, 'estatus', OLD.estatus), JSON_OBJECT('id_estacion', NEW.id_estacion, 'id_municipio', NEW.id_municipio, 'nombre', NEW.nombre, 'latitud', NEW.latitud, 'longitud', NEW.longitud, 'altitud_m', NEW.altitud_m, 'estatus', NEW.estatus), USER());
END$$

CREATE TRIGGER trg_estaciones_meteorologicas_delete AFTER DELETE ON estaciones_meteorologicas FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('estaciones_meteorologicas', 'DELETE', OLD.id_estacion, JSON_OBJECT('id_estacion', OLD.id_estacion, 'id_municipio', OLD.id_municipio, 'nombre', OLD.nombre, 'latitud', OLD.latitud, 'longitud', OLD.longitud, 'altitud_m', OLD.altitud_m, 'estatus', OLD.estatus), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_registros_clima_insert;
DROP TRIGGER IF EXISTS trg_registros_clima_update;
DROP TRIGGER IF EXISTS trg_registros_clima_delete;
DELIMITER $$

CREATE TRIGGER trg_registros_clima_insert AFTER INSERT ON registros_clima FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('registros_clima', 'INSERT', NEW.id_registro, NULL, JSON_OBJECT('id_registro', NEW.id_registro, 'id_estacion', NEW.id_estacion, 'fecha', NEW.fecha, 'temp_max', NEW.temp_max, 'temp_min', NEW.temp_min, 'humedad_pct', NEW.humedad_pct, 'precipitacion_mm', NEW.precipitacion_mm, 'indice_uv', NEW.indice_uv, 'ica', NEW.ica), USER());
END$$

CREATE TRIGGER trg_registros_clima_update AFTER UPDATE ON registros_clima FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('registros_clima', 'UPDATE', NEW.id_registro, JSON_OBJECT('id_registro', OLD.id_registro, 'id_estacion', OLD.id_estacion, 'fecha', OLD.fecha, 'temp_max', OLD.temp_max, 'temp_min', OLD.temp_min, 'humedad_pct', OLD.humedad_pct, 'precipitacion_mm', OLD.precipitacion_mm, 'indice_uv', OLD.indice_uv, 'ica', OLD.ica), JSON_OBJECT('id_registro', NEW.id_registro, 'id_estacion', NEW.id_estacion, 'fecha', NEW.fecha, 'temp_max', NEW.temp_max, 'temp_min', NEW.temp_min, 'humedad_pct', NEW.humedad_pct, 'precipitacion_mm', NEW.precipitacion_mm, 'indice_uv', NEW.indice_uv, 'ica', NEW.ica), USER());
END$$

CREATE TRIGGER trg_registros_clima_delete AFTER DELETE ON registros_clima FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('registros_clima', 'DELETE', OLD.id_registro, JSON_OBJECT('id_registro', OLD.id_registro, 'id_estacion', OLD.id_estacion, 'fecha', OLD.fecha, 'temp_max', OLD.temp_max, 'temp_min', OLD.temp_min, 'humedad_pct', OLD.humedad_pct, 'precipitacion_mm', OLD.precipitacion_mm, 'indice_uv', OLD.indice_uv, 'ica', OLD.ica), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_enfermedades_insert;
DROP TRIGGER IF EXISTS trg_enfermedades_update;
DROP TRIGGER IF EXISTS trg_enfermedades_delete;
DELIMITER $$

CREATE TRIGGER trg_enfermedades_insert AFTER INSERT ON enfermedades FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('enfermedades', 'INSERT', NEW.id_enfermedad, NULL, JSON_OBJECT('id_enfermedad', NEW.id_enfermedad, 'nombre', NEW.nombre, 'categoria', NEW.categoria, 'factor_climatico', NEW.factor_climatico), USER());
END$$

CREATE TRIGGER trg_enfermedades_update AFTER UPDATE ON enfermedades FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('enfermedades', 'UPDATE', NEW.id_enfermedad, JSON_OBJECT('id_enfermedad', OLD.id_enfermedad, 'nombre', OLD.nombre, 'categoria', OLD.categoria, 'factor_climatico', OLD.factor_climatico), JSON_OBJECT('id_enfermedad', NEW.id_enfermedad, 'nombre', NEW.nombre, 'categoria', NEW.categoria, 'factor_climatico', NEW.factor_climatico), USER());
END$$

CREATE TRIGGER trg_enfermedades_delete AFTER DELETE ON enfermedades FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('enfermedades', 'DELETE', OLD.id_enfermedad, JSON_OBJECT('id_enfermedad', OLD.id_enfermedad, 'nombre', OLD.nombre, 'categoria', OLD.categoria, 'factor_climatico', OLD.factor_climatico), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_unidades_salud_insert;
DROP TRIGGER IF EXISTS trg_unidades_salud_update;
DROP TRIGGER IF EXISTS trg_unidades_salud_delete;
DELIMITER $$

CREATE TRIGGER trg_unidades_salud_insert AFTER INSERT ON unidades_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('unidades_salud', 'INSERT', NEW.id_unidad, NULL, JSON_OBJECT('id_unidad', NEW.id_unidad, 'id_municipio', NEW.id_municipio, 'nombre', NEW.nombre, 'tipo', NEW.tipo, 'institucion', NEW.institucion, 'camas', NEW.camas), USER());
END$$

CREATE TRIGGER trg_unidades_salud_update AFTER UPDATE ON unidades_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('unidades_salud', 'UPDATE', NEW.id_unidad, JSON_OBJECT('id_unidad', OLD.id_unidad, 'id_municipio', OLD.id_municipio, 'nombre', OLD.nombre, 'tipo', OLD.tipo, 'institucion', OLD.institucion, 'camas', OLD.camas), JSON_OBJECT('id_unidad', NEW.id_unidad, 'id_municipio', NEW.id_municipio, 'nombre', NEW.nombre, 'tipo', NEW.tipo, 'institucion', NEW.institucion, 'camas', NEW.camas), USER());
END$$

CREATE TRIGGER trg_unidades_salud_delete AFTER DELETE ON unidades_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('unidades_salud', 'DELETE', OLD.id_unidad, JSON_OBJECT('id_unidad', OLD.id_unidad, 'id_municipio', OLD.id_municipio, 'nombre', OLD.nombre, 'tipo', OLD.tipo, 'institucion', OLD.institucion, 'camas', OLD.camas), NULL, USER());
END$$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_casos_salud_insert;
DROP TRIGGER IF EXISTS trg_casos_salud_update;
DROP TRIGGER IF EXISTS trg_casos_salud_delete;
DELIMITER $$

CREATE TRIGGER trg_casos_salud_insert AFTER INSERT ON casos_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('casos_salud', 'INSERT', NEW.id_caso, NULL, JSON_OBJECT('id_caso', NEW.id_caso, 'id_unidad', NEW.id_unidad, 'id_enfermedad', NEW.id_enfermedad, 'fecha', NEW.fecha, 'grupo_edad', NEW.grupo_edad, 'num_casos', NEW.num_casos, 'defunciones', NEW.defunciones), USER());
END$$

CREATE TRIGGER trg_casos_salud_update AFTER UPDATE ON casos_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('casos_salud', 'UPDATE', NEW.id_caso, JSON_OBJECT('id_caso', OLD.id_caso, 'id_unidad', OLD.id_unidad, 'id_enfermedad', OLD.id_enfermedad, 'fecha', OLD.fecha, 'grupo_edad', OLD.grupo_edad, 'num_casos', OLD.num_casos, 'defunciones', OLD.defunciones), JSON_OBJECT('id_caso', NEW.id_caso, 'id_unidad', NEW.id_unidad, 'id_enfermedad', NEW.id_enfermedad, 'fecha', NEW.fecha, 'grupo_edad', NEW.grupo_edad, 'num_casos', NEW.num_casos, 'defunciones', NEW.defunciones), USER());
END$$

CREATE TRIGGER trg_casos_salud_delete AFTER DELETE ON casos_salud FOR EACH ROW
BEGIN
  INSERT INTO auditoria (tabla, operacion, id_registro, datos_anteriores, datos_nuevos, usuario_mysql)
  VALUES ('casos_salud', 'DELETE', OLD.id_caso, JSON_OBJECT('id_caso', OLD.id_caso, 'id_unidad', OLD.id_unidad, 'id_enfermedad', OLD.id_enfermedad, 'fecha', OLD.fecha, 'grupo_edad', OLD.grupo_edad, 'num_casos', OLD.num_casos, 'defunciones', OLD.defunciones), NULL, USER());
END$$

DELIMITER ;

-- ################ 05_reportes_y_procesos.sql ################
-- Archivo 05: reportes (2 de lista + 1 dinámico) y proceso mensual
USE clima_salud_mx;
DROP PROCEDURE IF EXISTS sp_reporte_clima_por_estado;
DROP PROCEDURE IF EXISTS sp_reporte_casos_por_municipio;
DROP PROCEDURE IF EXISTS sp_reporte_dinamico;
DROP PROCEDURE IF EXISTS sp_proceso_resumen_mensual;
DELIMITER $$

-- REPORTE 1 (lista): clima promedio por estado durante el periodo registrado
CREATE PROCEDURE sp_reporte_clima_por_estado()
BEGIN
  SELECT es.nombre AS estado,
         COUNT(DISTINCT ec.id_estacion)                      AS estaciones,
         ROUND(AVG(r.temp_max),1)                            AS temp_max_prom,
         ROUND(AVG(r.temp_min),1)                            AS temp_min_prom,
         ROUND(AVG(r.humedad_pct),0)                         AS humedad_prom_pct,
         ROUND(SUM(r.precipitacion_mm),1)                    AS precipitacion_total_mm,
         SUM(fn_nivel_riesgo_calor(r.temp_max) = 'extremo')  AS dias_calor_extremo
  FROM registros_clima r
  JOIN estaciones_meteorologicas ec ON ec.id_estacion = r.id_estacion
  JOIN municipios mu ON mu.id_municipio = ec.id_municipio
  JOIN estados es ON es.id_estado = mu.id_estado
  GROUP BY es.id_estado, es.nombre
  ORDER BY temp_max_prom DESC;
END$$

-- REPORTE 2 (lista): casos por municipio y enfermedad con tasa por 100 mil habitantes
CREATE PROCEDURE sp_reporte_casos_por_municipio()
BEGIN
  SELECT mu.nombre AS municipio, es.nombre AS estado, en.nombre AS enfermedad,
         SUM(c.num_casos)    AS total_casos,
         SUM(c.defunciones)  AS defunciones,
         fn_tasa_letalidad(SUM(c.num_casos), SUM(c.defunciones)) AS letalidad_pct,
         fn_tasa_100k(SUM(c.num_casos), mu.poblacion)            AS casos_por_100k
  FROM casos_salud c
  JOIN unidades_salud u ON u.id_unidad = c.id_unidad
  JOIN municipios mu ON mu.id_municipio = u.id_municipio
  JOIN estados es ON es.id_estado = mu.id_estado
  JOIN enfermedades en ON en.id_enfermedad = c.id_enfermedad
  GROUP BY mu.id_municipio, mu.nombre, mu.poblacion, es.nombre, en.id_enfermedad, en.nombre
  ORDER BY casos_por_100k DESC;
END$$

-- REPORTE 3 (dinámico): relación clima-salud mensual según los filtros que se pidan.
-- Cualquier parámetro en NULL significa "todos".  Ej.: CALL sp_reporte_dinamico('Sonora','golpe_de_calor',NULL,NULL);
CREATE PROCEDURE sp_reporte_dinamico(
  IN p_estado    VARCHAR(60),
  IN p_categoria VARCHAR(20),
  IN p_fecha_ini DATE,
  IN p_fecha_fin DATE
)
BEGIN
  IF p_fecha_ini IS NOT NULL AND p_fecha_fin IS NOT NULL AND p_fecha_ini > p_fecha_fin THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha inicial no puede ser mayor que la final';
  END IF;
  SELECT cl.estado, cl.mes,
         cl.temp_max_prom, cl.humedad_prom_pct, cl.precipitacion_mm,
         fn_nivel_riesgo_calor(cl.temp_max_prom) AS riesgo_calor,
         IFNULL(sa.total_casos, 0)   AS total_casos,
         IFNULL(sa.defunciones, 0)   AS defunciones
  FROM (
    SELECT es.id_estado, es.nombre AS estado, DATE_FORMAT(r.fecha,'%Y-%m') AS mes,
           ROUND(AVG(r.temp_max),1) AS temp_max_prom, ROUND(AVG(r.humedad_pct),0) AS humedad_prom_pct,
           ROUND(SUM(r.precipitacion_mm),1) AS precipitacion_mm
    FROM registros_clima r
    JOIN estaciones_meteorologicas ec ON ec.id_estacion = r.id_estacion
    JOIN municipios mu ON mu.id_municipio = ec.id_municipio
    JOIN estados es ON es.id_estado = mu.id_estado
    WHERE (p_estado IS NULL OR es.nombre = p_estado)
      AND (p_fecha_ini IS NULL OR r.fecha >= p_fecha_ini)
      AND (p_fecha_fin IS NULL OR r.fecha <= p_fecha_fin)
    GROUP BY es.id_estado, es.nombre, DATE_FORMAT(r.fecha,'%Y-%m')
  ) cl
  LEFT JOIN (
    SELECT mu.id_estado, DATE_FORMAT(c.fecha,'%Y-%m') AS mes,
           SUM(c.num_casos) AS total_casos, SUM(c.defunciones) AS defunciones
    FROM casos_salud c
    JOIN unidades_salud u ON u.id_unidad = c.id_unidad
    JOIN municipios mu ON mu.id_municipio = u.id_municipio
    JOIN enfermedades en ON en.id_enfermedad = c.id_enfermedad
    WHERE (p_categoria IS NULL OR en.categoria = p_categoria)
    GROUP BY mu.id_estado, DATE_FORMAT(c.fecha,'%Y-%m')
  ) sa ON sa.id_estado = cl.id_estado AND sa.mes = cl.mes
  ORDER BY cl.estado, cl.mes;
END$$

-- PROCESO: recalcula el resumen mensual de un año dentro de una transacción
CREATE PROCEDURE sp_proceso_resumen_mensual(IN p_anio INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  IF p_anio IS NULL OR p_anio < 2000 OR p_anio > 2100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Año inválido (use un año entre 2000 y 2100)';
  END IF;
  START TRANSACTION;
    DELETE FROM resumen_mensual WHERE anio = p_anio;
    INSERT INTO resumen_mensual (id_estado, anio, mes, temp_prom, precipitacion_mm, total_casos, defunciones)
    SELECT cl.id_estado, p_anio, cl.mes, cl.temp_prom, cl.precip, IFNULL(sa.casos,0), IFNULL(sa.def,0)
    FROM (
      SELECT mu.id_estado, MONTH(r.fecha) mes,
             ROUND(AVG(fn_temp_promedio(r.temp_max, r.temp_min)),1) temp_prom,
             ROUND(SUM(r.precipitacion_mm),1) precip
      FROM registros_clima r
      JOIN estaciones_meteorologicas ec ON ec.id_estacion = r.id_estacion
      JOIN municipios mu ON mu.id_municipio = ec.id_municipio
      WHERE YEAR(r.fecha) = p_anio
      GROUP BY mu.id_estado, MONTH(r.fecha)
    ) cl
    LEFT JOIN (
      SELECT mu.id_estado, MONTH(c.fecha) mes, SUM(c.num_casos) casos, SUM(c.defunciones) def
      FROM casos_salud c
      JOIN unidades_salud u ON u.id_unidad = c.id_unidad
      JOIN municipios mu ON mu.id_municipio = u.id_municipio
      WHERE YEAR(c.fecha) = p_anio
      GROUP BY mu.id_estado, MONTH(c.fecha)
    ) sa ON sa.id_estado = cl.id_estado AND sa.mes = cl.mes;
  COMMIT;
  SELECT p_anio AS anio, COUNT(*) AS filas_generadas FROM resumen_mensual WHERE anio = p_anio;
END$$
DELIMITER ;

-- ################ 06_roles_y_permisos.sql ################
-- Archivo 06: roles y permisos (MySQL 8)
-- administrador: todo | analista: solo lectura + reportes | usuario: captura (sin eliminar)
USE clima_salud_mx;
CREATE ROLE IF NOT EXISTS 'rol_administrador', 'rol_analista', 'rol_usuario';

-- ---- Administrador ----
GRANT ALL PRIVILEGES ON clima_salud_mx.* TO 'rol_administrador';

-- ---- Analista: SELECT en tablas (sin auditoría), reportes, lectura y funciones ----
GRANT SELECT ON clima_salud_mx.estados TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.municipios TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.estaciones_meteorologicas TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.registros_clima TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.enfermedades TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.unidades_salud TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.casos_salud TO 'rol_analista';
GRANT SELECT ON clima_salud_mx.resumen_mensual TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_leer TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_listar TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_clima_por_estado TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_casos_por_municipio TO 'rol_analista';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_dinamico TO 'rol_analista';
GRANT EXECUTE ON FUNCTION clima_salud_mx.fn_temp_promedio TO 'rol_analista';
GRANT EXECUTE ON FUNCTION clima_salud_mx.fn_nivel_riesgo_calor TO 'rol_analista';
GRANT EXECUTE ON FUNCTION clima_salud_mx.fn_tasa_letalidad TO 'rol_analista';
GRANT EXECUTE ON FUNCTION clima_salud_mx.fn_tasa_100k TO 'rol_analista';

-- ---- Usuario: crear, leer, listar y actualizar mediante procedimientos; reportes; NO eliminar ----
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estado_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_municipio_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_estacion_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_registro_clima_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_enfermedad_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_unidad_salud_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_crear TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_leer TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_listar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_caso_salud_actualizar TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_clima_por_estado TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_casos_por_municipio TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE clima_salud_mx.sp_reporte_dinamico TO 'rol_usuario';

-- ---- Cuentas de ejemplo (cambiar contraseñas en un entorno real) ----
CREATE USER IF NOT EXISTS 'admin_clima'@'localhost'    IDENTIFIED BY 'Admin#Clima2026';
CREATE USER IF NOT EXISTS 'analista_clima'@'localhost' IDENTIFIED BY 'Analista#Clima2026';
CREATE USER IF NOT EXISTS 'usuario_clima'@'localhost'  IDENTIFIED BY 'Usuario#Clima2026';
GRANT 'rol_administrador' TO 'admin_clima'@'localhost';
GRANT 'rol_analista'      TO 'analista_clima'@'localhost';
GRANT 'rol_usuario'       TO 'usuario_clima'@'localhost';
SET DEFAULT ROLE 'rol_administrador' TO 'admin_clima'@'localhost';
SET DEFAULT ROLE 'rol_analista'      TO 'analista_clima'@'localhost';
SET DEFAULT ROLE 'rol_usuario'       TO 'usuario_clima'@'localhost';
FLUSH PRIVILEGES;