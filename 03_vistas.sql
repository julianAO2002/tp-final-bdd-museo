-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Vistas de la base "museo"
-- Motor: PostgreSQL
--
-- Ejecutar sobre la base "museo" después de 01_creacion_bd.sql y
-- 02_triggers.sql. Se puede volver a ejecutar: elimina las vistas
-- existentes antes de crearlas.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. vw_obras_detalle
-- Información detallada de las obras: datos de la obra, su autor y la
-- sala donde se almacena el original.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_obras_detalle;
CREATE VIEW vw_obras_detalle AS
SELECT o.id_obra,
       o.nombre     AS obra,
       o.fecha_creacion,
       o.fecha_rec,
       o.sensibilidad,
       a.nombre     AS nombre_autor,
       a.apellido   AS apellido_autor,
       s.nombre     AS sala,
       s.tipo       AS tipo_sala
  FROM obra o, autor a, sala s
 WHERE a.id_autor = o.id_autor
   AND s.id_sala  = o.id_sala;

-- ---------------------------------------------------------------------
-- 2. vw_copias_detalle
-- Información detallada de las copias: obra original, autor y la sala
-- donde se exhibe o almacena la copia.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_copias_detalle;
CREATE VIEW vw_copias_detalle AS
SELECT c.id_copia,
       o.nombre     AS obra_original,
       a.nombre     AS nombre_autor,
       a.apellido   AS apellido_autor,
       c.fecha_creacion,
       s.nombre     AS sala_copia,
       s.tipo       AS tipo_sala
  FROM copia c, obra o, autor a, sala s
 WHERE o.id_obra  = c.id_obra
   AND a.id_autor = o.id_autor
   AND s.id_sala  = c.id_sala;

-- ---------------------------------------------------------------------
-- 3. vw_restauraciones_detalle
-- Información detallada de las restauraciones: obra restaurada, empleado
-- responsable y período (fecha_fin NULL = en curso).
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_restauraciones_detalle;
CREATE VIEW vw_restauraciones_detalle AS
SELECT r.id_restauracion,
       o.id_obra,
       o.nombre     AS obra,
       e.dni        AS dni_empleado,
       e.nombre     AS nombre_empleado,
       e.apellido   AS apellido_empleado,
       r.fecha_ingreso,
       r.fecha_fin
  FROM restauracion r, obra o, empleado e
 WHERE o.id_obra = r.id_obra
   AND e.dni     = r.dni_empleado;
