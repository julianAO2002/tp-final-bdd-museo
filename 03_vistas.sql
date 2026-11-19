-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Vistas de la base "museo"
-- Motor: PostgreSQL
--
-- Cada vista corresponde a una de las consultas de la propuesta (C, E y
-- F), que son las que no reciben datos particulares. Las vistas de C y F
-- muestran la cantidad de obras restauradas por cada empleado en el
-- período; el filtro de por lo menos 5 obras lo aplican las funciones
-- de 06_funciones.sql y las consultas de 05_consultas.sql.
--
-- Ejecutar sobre la base "museo" después de 01_creacion_bd.sql y
-- 02_triggers.sql. Se puede volver a ejecutar: elimina las vistas
-- existentes antes de crearlas.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. vw_restauradores_ultimos_6_meses
-- Consulta C: cantidad de obras restauradas por cada empleado en los
-- últimos 6 meses (180 días).
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_restauradores_ultimos_6_meses;
CREATE VIEW vw_restauradores_ultimos_6_meses AS
SELECT e.dni,
       e.nombre,
       e.apellido,
       e.email,
       COUNT(DISTINCT r.id_obra) AS obras_restauradas
  FROM empleado e, restauracion r
 WHERE r.dni_empleado = e.dni
   AND r.fecha_ingreso >= CURRENT_DATE - 180
 GROUP BY e.dni, e.nombre, e.apellido, e.email;

-- ---------------------------------------------------------------------
-- 2. vw_originales_por_sala
-- Consulta E: cantidad de obras almacenadas en cada sala de
-- almacenamiento, sin contar las copias.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_originales_por_sala;
CREATE VIEW vw_originales_por_sala AS
SELECT s.id_sala,
       s.nombre,
       s.especializacion,
       COUNT(o.id_obra) AS cantidad_originales
  FROM sala s, obra o
 WHERE o.id_sala = s.id_sala
   AND s.tipo = 'almacenamiento'
 GROUP BY s.id_sala, s.nombre, s.especializacion;

-- ---------------------------------------------------------------------
-- 3. vw_restauradores_antiguos_ultimo_anio
-- Consulta F: cantidad de obras restauradas en el último año (365 días)
-- por cada empleado con más de 5 años de antigüedad (1825 días).
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_restauradores_antiguos_ultimo_anio;
CREATE VIEW vw_restauradores_antiguos_ultimo_anio AS
SELECT e.dni,
       e.nombre,
       e.apellido,
       e.fecha_nac,
       e.telefono,
       e.email,
       e.fecha_ingreso,
       COUNT(DISTINCT r.id_obra) AS obras_restauradas
  FROM empleado e, restauracion r
 WHERE r.dni_empleado = e.dni
   AND e.fecha_ingreso < CURRENT_DATE - 1825
   AND r.fecha_ingreso >= CURRENT_DATE - 365
 GROUP BY e.dni, e.nombre, e.apellido, e.fecha_nac, e.telefono,
          e.email, e.fecha_ingreso;
