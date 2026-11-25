SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS clima_salud_mexico
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clima_salud_mexico;

DROP VIEW IF EXISTS vista_clima_salud;
DROP TABLE IF EXISTS casos_salud;
DROP TABLE IF EXISTS clima_mensual;
DROP TABLE IF EXISTS enfermedad;
DROP TABLE IF EXISTS ciudad;
DROP TABLE IF EXISTS estado;

CREATE TABLE estado (
  id_estado TINYINT UNSIGNED PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE ciudad (
  id_ciudad INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE,
  latitud DECIMAL(8,5) NOT NULL,
  longitud DECIMAL(8,5) NOT NULL,
  id_estado TINYINT UNSIGNED NOT NULL,
  FOREIGN KEY (id_estado) REFERENCES estado(id_estado)
);

CREATE TABLE clima_mensual (
  id_clima INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_ciudad INT UNSIGNED NOT NULL,
  anio SMALLINT NOT NULL,
  mes TINYINT NOT NULL,
  temp_max_prom DECIMAL(5,2),
  temp_max_abs DECIMAL(5,2),
  temp_min_prom DECIMAL(5,2),
  precipitacion_total DECIMAL(8,2),
  humedad_prom DECIMAL(5,2),
  dias_calor_extremo TINYINT UNSIGNED,
  dias_registrados TINYINT UNSIGNED,
  CONSTRAINT chk_mes_clima CHECK (mes BETWEEN 1 AND 12),
  UNIQUE (id_ciudad, anio, mes),
  FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad)
);

CREATE TABLE enfermedad (
  id_enfermedad TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE casos_salud (
  id_caso INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_estado TINYINT UNSIGNED NOT NULL,
  id_enfermedad TINYINT UNSIGNED NOT NULL,
  anio SMALLINT NOT NULL,
  mes TINYINT NOT NULL,
  casos_confirmados INT UNSIGNED NOT NULL,
  defunciones INT UNSIGNED NOT NULL,
  CONSTRAINT chk_mes_salud CHECK (mes BETWEEN 1 AND 12),
  UNIQUE (id_estado, id_enfermedad, anio, mes),
  FOREIGN KEY (id_estado) REFERENCES estado(id_estado),
  FOREIGN KEY (id_enfermedad) REFERENCES enfermedad(id_enfermedad)
);

INSERT INTO estado (id_estado, nombre) VALUES
(1,'Aguascalientes'),(2,'Baja California'),(3,'Baja California Sur'),
(4,'Campeche'),(5,'Coahuila'),(6,'Colima'),(7,'Chiapas'),(8,'Chihuahua'),
(9,'Ciudad de México'),(10,'Durango'),(11,'Guanajuato'),(12,'Guerrero'),
(13,'Hidalgo'),(14,'Jalisco'),(15,'México'),(16,'Michoacán'),
(17,'Morelos'),(18,'Nayarit'),(19,'Nuevo León'),(20,'Oaxaca'),
(21,'Puebla'),(22,'Querétaro'),(23,'Quintana Roo'),(24,'San Luis Potosí'),
(25,'Sinaloa'),(26,'Sonora'),(27,'Tabasco'),(28,'Tamaulipas'),
(29,'Tlaxcala'),(30,'Veracruz'),(31,'Yucatán'),(32,'Zacatecas');

INSERT INTO enfermedad (nombre) VALUES ('Dengue');

-- Cruce clima-salud por estado y mes (solo estados con ciudades de clima)
CREATE VIEW vista_clima_salud AS
SELECT e.id_estado, e.nombre AS estado, cs.anio, cs.mes,
       cl.temp_max_prom, cl.precipitacion_total, cl.humedad_prom,
       cl.dias_calor_extremo, cs.casos_confirmados, cs.defunciones
FROM casos_salud cs
JOIN estado e ON e.id_estado = cs.id_estado
JOIN (
  SELECT c.id_estado, m.anio, m.mes,
         ROUND(AVG(m.temp_max_prom), 2) AS temp_max_prom,
         ROUND(AVG(m.precipitacion_total), 2) AS precipitacion_total,
         ROUND(AVG(m.humedad_prom), 2) AS humedad_prom,
         SUM(m.dias_calor_extremo) AS dias_calor_extremo
  FROM clima_mensual m
  JOIN ciudad c ON c.id_ciudad = m.id_ciudad
  GROUP BY c.id_estado, m.anio, m.mes
) cl ON cl.id_estado = cs.id_estado AND cl.anio = cs.anio AND cl.mes = cs.mes;
