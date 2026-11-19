-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Consultas A a F de la base "museo"
-- Motor: PostgreSQL
--
-- Ejecutar después de 03_vistas.sql y 04_carga_datos.sql: las consultas
-- C, E y F usan las vistas.
--
-- Las consultas A, B y D reciben un dato particular (año, restaurador,
-- autor): cambiar el valor indicado en el WHERE para consultar otro.
--
-- Criterio de período: una restauración pertenece a un año, a "los
-- últimos 6 meses" o a "el último año" cuando su fecha_ingreso cae
-- dentro de ese período. Los períodos relativos a hoy se calculan
-- restando días a CURRENT_DATE: 6 meses = 180 días, 1 año = 365 días,
-- 5 años = 1825 días.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A) Obras que hayan sufrido restauraciones en un año particular.
-- Año consultado: 2023.
-- ---------------------------------------------------------------------
SELECT DISTINCT
       o.id_obra,
       o.nombre       AS obra,
       a.nombre       AS nombre_autor,
       a.apellido     AS apellido_autor,
       o.sensibilidad
  FROM obra o, autor a, restauracion r
 WHERE a.id_autor = o.id_autor
   AND r.id_obra  = o.id_obra
   AND r.fecha_ingreso BETWEEN '2023-01-01' AND '2023-12-31'
 ORDER BY o.id_obra;

-- ---------------------------------------------------------------------
-- B) De un restaurador en particular, la cantidad de obras de cada
-- sector que ha restaurado (sector = sensibilidad de la obra).
-- Restaurador consultado: DNI 30111222.
-- ---------------------------------------------------------------------
SELECT o.sensibilidad            AS sector,
       COUNT(DISTINCT r.id_obra) AS cantidad_obras
  FROM restauracion r, obra o
 WHERE o.id_obra      = r.id_obra
   AND r.dni_empleado = 30111222
 GROUP BY o.sensibilidad
 ORDER BY o.sensibilidad;

-- ---------------------------------------------------------------------
-- C) Empleados que hayan restaurado por lo menos 5 obras en los
-- últimos 6 meses. Usa la vista vw_restauradores_ultimos_6_meses, que
-- tiene la cantidad de obras de cada empleado en ese período.
-- ---------------------------------------------------------------------
SELECT *
  FROM vw_restauradores_ultimos_6_meses
 WHERE obras_restauradas >= 5
 ORDER BY obras_restauradas DESC, apellido;

-- ---------------------------------------------------------------------
-- D) Datos y ubicación actual de las copias de las obras de un autor
-- en particular. El tipo de sala indica si la copia está exhibida
-- ('muestra') o almacenada ('almacenamiento').
-- Autor consultado: id_autor 1 (Leonardo da Vinci). Se filtra por el id
-- porque nombre y apellido no son clave y podrían repetirse.
-- ---------------------------------------------------------------------
SELECT c.id_copia,
       c.fecha_creacion,
       o.nombre AS obra_original,
       s.nombre AS sala_actual,
       s.tipo   AS tipo_sala
  FROM copia c, obra o, sala s
 WHERE o.id_obra  = c.id_obra
   AND s.id_sala  = c.id_sala
   AND o.id_autor = 1
 ORDER BY o.nombre, c.id_copia;

-- ---------------------------------------------------------------------
-- E) Cantidad de obras almacenadas en cada sala de almacenamiento, sin
-- contar las copias. La resuelve la vista vw_originales_por_sala.
-- ---------------------------------------------------------------------
SELECT *
  FROM vw_originales_por_sala
 ORDER BY id_sala;

-- ---------------------------------------------------------------------
-- F) Datos de los empleados con más de 5 años de antigüedad que hayan
-- restaurado, por lo menos, 5 obras en el último año. Usa la vista
-- vw_restauradores_antiguos_ultimo_anio, que tiene la cantidad de obras
-- del último año de cada empleado con más de 5 años de antigüedad.
-- ---------------------------------------------------------------------
SELECT *
  FROM vw_restauradores_antiguos_ultimo_anio
 WHERE obras_restauradas >= 5
 ORDER BY obras_restauradas DESC, apellido;
