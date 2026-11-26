-- =====================================================================
-- PRUEBAS: Clima-Salud-México
-- Ejemplos listos para ejecutar de TODAS las funciones y procedimientos.
-- Se puede ejecutar completo (rayo grande) cuantas veces quieras:
-- al final borra los datos de prueba que creó.
-- Ejecutar con la misma conexión con la que se creó la base.
-- =====================================================================
USE clima_salud_mx;
SET NAMES utf8mb4;

-- =====================================================================
-- 1. FUNCIONES
-- =====================================================================
SELECT fn_temp_promedio(35.0, 21.0)        AS temp_promedio;      -- 28.0
SELECT fn_nivel_riesgo_calor(42.5)         AS riesgo_calor;       -- extremo
SELECT fn_tasa_letalidad(200, 3)           AS letalidad_pct;      -- 1.50
SELECT fn_tasa_100k(150, 1922000)          AS casos_por_100k;     -- 7.80

-- Funciones aplicadas a los datos reales de la base
SELECT r.fecha, r.temp_max, r.temp_min,
       fn_temp_promedio(r.temp_max, r.temp_min) AS temp_prom,
       fn_nivel_riesgo_calor(r.temp_max)        AS riesgo
FROM registros_clima r
WHERE r.id_estacion = 3 AND r.fecha BETWEEN '2025-07-01' AND '2025-07-07';

-- =====================================================================
-- 2. CREAR (cada procedimiento devuelve el id nuevo en una variable @)
-- =====================================================================
CALL sp_estado_crear('33', 'Estado de Prueba', 'Sur', @id_estado);
CALL sp_municipio_crear(@id_estado, 'Municipio de Prueba', 50000, @id_municipio);
CALL sp_estacion_crear(@id_municipio, 'Estación de Prueba', 20.500000, -100.400000, 1800, 'activa', @id_estacion);
CALL sp_registro_clima_crear(@id_estacion, '2025-06-15', 31.5, 18.2, 55, 4.5, 9.0, 60, @id_registro);
CALL sp_enfermedad_crear('Enfermedad de Prueba', 'otra', 'Ejemplo de factor climático', @id_enfermedad);
CALL sp_unidad_salud_crear(@id_municipio, 'Clínica de Prueba', 'clinica', 'IMSS', 12, @id_unidad);
CALL sp_caso_salud_crear(@id_unidad, @id_enfermedad, '2025-06-01', '15-44', 25, 1, @id_caso);

SELECT @id_estado AS id_estado, @id_municipio AS id_municipio, @id_estacion AS id_estacion,
       @id_registro AS id_registro, @id_enfermedad AS id_enfermedad, @id_unidad AS id_unidad, @id_caso AS id_caso;

-- =====================================================================
-- 3. LEER (uno) y LISTAR (varios; el número es el máximo de filas, NULL = 1000)
-- =====================================================================
CALL sp_estado_leer(@id_estado);
CALL sp_municipio_leer(@id_municipio);
CALL sp_estacion_leer(@id_estacion);
CALL sp_registro_clima_leer(@id_registro);
CALL sp_enfermedad_leer(@id_enfermedad);
CALL sp_unidad_salud_leer(@id_unidad);
CALL sp_caso_salud_leer(@id_caso);

CALL sp_estado_listar(10);
CALL sp_municipio_listar(10);
CALL sp_estacion_listar(NULL);
CALL sp_registro_clima_listar(10);
CALL sp_enfermedad_listar(NULL);
CALL sp_unidad_salud_listar(10);
CALL sp_caso_salud_listar(10);

-- =====================================================================
-- 4. ACTUALIZAR  (NULL en un campo = dejarlo como está)
-- =====================================================================
CALL sp_estado_actualizar(@id_estado, NULL, 'Estado de Prueba (editado)', NULL);
CALL sp_municipio_actualizar(@id_municipio, NULL, NULL, 52000);
CALL sp_estacion_actualizar(@id_estacion, NULL, NULL, NULL, NULL, NULL, 'mantenimiento');
CALL sp_registro_clima_actualizar(@id_registro, NULL, NULL, 33.0, NULL, NULL, NULL, NULL, NULL);
CALL sp_enfermedad_actualizar(@id_enfermedad, NULL, NULL, 'Factor climático actualizado');
CALL sp_unidad_salud_actualizar(@id_unidad, NULL, NULL, NULL, NULL, 15);
CALL sp_caso_salud_actualizar(@id_caso, NULL, NULL, NULL, NULL, 30, NULL);

CALL sp_registro_clima_leer(@id_registro);   -- temp_max ahora es 33.0

-- =====================================================================
-- 5. REPORTES
-- =====================================================================
CALL sp_reporte_clima_por_estado();
CALL sp_reporte_casos_por_municipio();

-- Reporte dinámico: (estado, categoría, fecha_inicio, fecha_fin). NULL = todos
CALL sp_reporte_dinamico(NULL, NULL, NULL, NULL);
CALL sp_reporte_dinamico('Sonora', 'golpe_de_calor', NULL, NULL);
CALL sp_reporte_dinamico('Chiapas', 'vectorial', '2025-06-01', '2025-10-31');
CALL sp_reporte_dinamico('Ciudad de Mexico', 'respiratoria', NULL, NULL);   -- funciona con o sin acento

-- =====================================================================
-- 6. PROCESO MENSUAL (llena la tabla resumen_mensual)
-- =====================================================================
CALL sp_proceso_resumen_mensual(2025);
SELECT e.nombre AS estado, r.mes, r.temp_prom, r.precipitacion_mm, r.total_casos, r.defunciones
FROM resumen_mensual r JOIN estados e ON e.id_estado = r.id_estado
WHERE r.anio = 2025 ORDER BY e.nombre, r.mes;

-- =====================================================================
-- 7. AUDITORÍA (lo que registraron los triggers en este archivo)
-- =====================================================================
SELECT id_auditoria, tabla, operacion, id_registro, usuario_mysql, fecha_hora
FROM auditoria ORDER BY id_auditoria DESC LIMIT 30;

-- =====================================================================
-- 8. ELIMINAR (de hijo a padre) — también deja todo listo para volver a ejecutar
-- =====================================================================
CALL sp_caso_salud_eliminar(@id_caso);
CALL sp_unidad_salud_eliminar(@id_unidad);
CALL sp_enfermedad_eliminar(@id_enfermedad);
CALL sp_registro_clima_eliminar(@id_registro);
CALL sp_estacion_eliminar(@id_estacion);
CALL sp_municipio_eliminar(@id_municipio);
CALL sp_estado_eliminar(@id_estado);

SELECT 'Todas las pruebas terminaron correctamente' AS resultado;

-- =====================================================================
-- 9. EJEMPLOS DE ERRORES CONTROLADOS (opcional)
-- Están comentados porque DEBEN marcar error: así se demuestra que la base
-- rechaza datos inválidos. Quita el "-- " de uno y ejecútalo solo (rayo con cursor).
-- =====================================================================
-- CALL sp_municipio_crear(2, 'Tijuana', 1000, @x);                               -- Registro duplicado
-- CALL sp_municipio_crear(999, 'X', 1000, @x);                                   -- Referencia inválida
-- CALL sp_registro_clima_crear(1, '2025-01-02', 10, 20, 50, 0, 5, 50, @x);        -- temp_max < temp_min
-- CALL sp_registro_clima_crear(1, '2030-01-01', 20, 10, 50, 0, 5, 50, @x);        -- fecha futura
-- CALL sp_caso_salud_crear(1, 1, '2025-02-15', '0-14', 5, 0, @x);                 -- fecha no es día 1
-- CALL sp_estacion_crear(1, 'E1', 20, -100, 1, 'rota', @x);                       -- estatus no permitido
-- CALL sp_estado_eliminar(2);                                                     -- tiene registros relacionados
-- CALL sp_reporte_dinamico('Narnia', NULL, NULL, NULL);                           -- estado no existe
-- DELETE FROM auditoria WHERE id_auditoria = 1;                                   -- auditoría de solo lectura
