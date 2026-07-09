Use inversion;
CREATE TABLE raw_inversion_mop (
  anio INT,
  region VARCHAR(60),
  servicio VARCHAR(100),
  provincia VARCHAR(60),
  comuna VARCHAR(60),
  bip VARCHAR(20),
  nombre VARCHAR(500),
  inversion_miles BIGINT
);

LOAD DATA LOCAL INFILE 'detalleinversionhistoricamop2011-2018.xlsx - Hoja1.csv'
INTO TABLE raw_inversion_mop
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(anio, region, @servicio, provincia, comuna, bip, nombre, @inversion)
SET
  servicio = TRIM(@servicio),
  inversion_miles = CAST(REPLACE(@inversion, '.', '') AS UNSIGNED);
  
SELECT COUNT(*) FROM raw_inversion_mop;
SELECT * FROM raw_inversion_mop LIMIT 5;
SELECT MIN(anio), MAX(anio) FROM raw_inversion_mop;
SELECT SUM(inversion_miles) FROM raw_inversion_mop;

SELECT DISTINCT servicio FROM raw_inversion_mop ORDER BY servicio;

CREATE TABLE dim_tiempo (
  tiempo_id INT PRIMARY KEY,
  anio INT,
  decada INT
);

INSERT INTO dim_tiempo (tiempo_id, anio, decada)
SELECT DISTINCT anio, anio, FLOOR(anio/10)*10
FROM raw_inversion_mop;

DROP TABLE dim_territorio;

CREATE TABLE dim_territorio (
  territorio_id INT AUTO_INCREMENT PRIMARY KEY,
  comuna VARCHAR(300),
  provincia VARCHAR(60),
  region VARCHAR(60),
  pais VARCHAR(20) DEFAULT 'Chile',
  UNIQUE KEY uq_territorio (comuna, provincia, region)
);

INSERT INTO dim_territorio (comuna, provincia, region, pais)
SELECT DISTINCT comuna, provincia, region, 'Chile'
FROM raw_inversion_mop;


CREATE TABLE dim_servicio (
  servicio_id INT AUTO_INCREMENT PRIMARY KEY,
  servicio VARCHAR(100) UNIQUE,
  area VARCHAR(50)
);

INSERT INTO dim_servicio (servicio, area) VALUES
('Administración Sistema Concesiones', 'Concesiones'),
('Dirección General de Concesiones', 'Concesiones'),
('Agua Potable Rural', 'Recursos Hídricos'),
('Dirección de Obras Hidráulicas', 'Recursos Hídricos'),
('Dirección General de Aguas', 'Recursos Hídricos'),
('I. N. de Hidráulica', 'Recursos Hídricos'),
('Dirección de Aeropuertos', 'Infraestructura de Transporte'),
('Dirección de Obras Portuarias', 'Infraestructura de Transporte'),
('Dirección de Vialidad', 'Infraestructura de Transporte'),
('Dirección de Arquitectura', 'Edificación Pública'),
('Dirección de Planeamiento', 'Gestión y Planificación'),
('Dirección General de Obras Públicas', 'Gestión y Planificación'),
('Secretaría y Administración General', 'Gestión y Planificación');

CREATE TABLE dim_region (
  region_id INT AUTO_INCREMENT PRIMARY KEY,
  region VARCHAR(60) UNIQUE
);

INSERT INTO dim_region (region)
SELECT DISTINCT region FROM raw_inversion_mop;


CREATE TABLE hechos_inversion_proyecto (
  tiempo_id INT,
  territorio_id INT,
  servicio_id INT,
  bip VARCHAR(20),
  nombre VARCHAR(500),
  inversion_miles BIGINT,
  FOREIGN KEY (tiempo_id) REFERENCES dim_tiempo(tiempo_id),
  FOREIGN KEY (territorio_id) REFERENCES dim_territorio(territorio_id),
  FOREIGN KEY (servicio_id) REFERENCES dim_servicio(servicio_id)
);

INSERT INTO hechos_inversion_proyecto (tiempo_id, territorio_id, servicio_id, bip, nombre, inversion_miles)
SELECT
  r.anio,
  t.territorio_id,
  s.servicio_id,
  r.bip,
  r.nombre,
  r.inversion_miles
FROM raw_inversion_mop r
JOIN dim_territorio t
  ON t.comuna = r.comuna AND t.provincia = r.provincia AND t.region = r.region
JOIN dim_servicio s ON s.servicio = r.servicio;


CREATE TABLE hechos_resumen_regional_anual (
  tiempo_id INT,
  region_id INT,
  monto_total_invertido BIGINT,
  cantidad_proyectos INT,
  monto_promedio_proyecto DECIMAL(15,2),
  FOREIGN KEY (tiempo_id) REFERENCES dim_tiempo(tiempo_id),
  FOREIGN KEY (region_id) REFERENCES dim_region(region_id)
);

INSERT INTO hechos_resumen_regional_anual (tiempo_id, region_id, monto_total_invertido, cantidad_proyectos, monto_promedio_proyecto)
SELECT
  r.anio,
  dr.region_id,
  SUM(r.inversion_miles),
  COUNT(*),
  SUM(r.inversion_miles) / COUNT(*)
FROM raw_inversion_mop r
JOIN dim_region dr ON dr.region = r.region
GROUP BY r.anio, dr.region_id;

CREATE VIEW vw_promedio_inversion_regional AS
SELECT
  dt.anio,
  dr.region,
  h.cantidad_proyectos,
  h.monto_total_invertido,
  h.monto_promedio_proyecto
FROM hechos_resumen_regional_anual h
JOIN dim_tiempo dt ON dt.tiempo_id = h.tiempo_id
JOIN dim_region dr ON dr.region_id = h.region_id;

CREATE VIEW vw_participacion_servicio_anual AS
SELECT
  dt.anio,
  ds.servicio,
  ds.area,
  SUM(h.inversion_miles) AS monto_servicio,
  ROUND(SUM(h.inversion_miles) / tot.monto_total_anio * 100, 2) AS porcentaje_participacion
FROM hechos_inversion_proyecto h
JOIN dim_tiempo dt ON dt.tiempo_id = h.tiempo_id
JOIN dim_servicio ds ON ds.servicio_id = h.servicio_id
JOIN (
  SELECT tiempo_id, SUM(inversion_miles) AS monto_total_anio
  FROM hechos_inversion_proyecto
  GROUP BY tiempo_id
) tot ON tot.tiempo_id = dt.tiempo_id
GROUP BY dt.anio, ds.servicio, ds.area, tot.monto_total_anio;

SELECT * FROM vw_promedio_inversion_regional ORDER BY anio DESC LIMIT 10;
SELECT * FROM vw_participacion_servicio_anual ORDER BY anio DESC, porcentaje_participacion DESC LIMIT 10;

