-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Funciones de la base "museo"
-- Motor: PostgreSQL
--
-- Una función por cada consulta de la propuesta (A a F). Las funciones
-- de las consultas A, B y D reciben el dato particular como parámetro;
-- las de las consultas C, E y F no reciben parámetros y devuelven el
-- contenido de la vista que resuelve la consulta.
--
-- Ejecutar sobre la base "museo" después de 03_vistas.sql. Se puede
-- volver a ejecutar: elimina las funciones existentes antes de crearlas.
--
-- Uso: SELECT * FROM nombre_funcion(parámetros);
-- =====================================================================

-- ---------------------------------------------------------------------
-- A) fn_obras_restauradas_en_anio
-- Entrada: p_anio, año a consultar.
-- Salida:  una fila por cada obra que ingresó a restauración ese año,
--          con sus datos y los de su autor.
-- Lógica:  une OBRA, AUTOR y RESTAURACION y filtra por el año de
--          fecha_ingreso. DISTINCT evita repetir una obra restaurada
--          más de una vez en el año.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_obras_restauradas_en_anio(INTEGER);
CREATE FUNCTION fn_obras_restauradas_en_anio(p_anio INTEGER)
RETURNS TABLE (
    id_obra        INTEGER,
    obra           VARCHAR,
    nombre_autor   VARCHAR,
    apellido_autor VARCHAR,
    sensibilidad   VARCHAR
)
LANGUAGE sql
AS $$
    SELECT DISTINCT
           o.id_obra,
           o.nombre,
           a.nombre,
           a.apellido,
           o.sensibilidad
      FROM obra o, autor a, restauracion r
     WHERE a.id_autor = o.id_autor
       AND r.id_obra  = o.id_obra
       AND EXTRACT(YEAR FROM r.fecha_ingreso) = p_anio
     ORDER BY o.id_obra;
$$;

-- ---------------------------------------------------------------------
-- B) fn_obras_por_sector_de_restaurador
-- Entrada: p_dni, documento del restaurador.
-- Salida:  una fila por sector (sensibilidad de la obra) con la
--          cantidad de obras distintas que restauró el empleado.
-- Lógica:  une EMPLEADO, RESTAURACION y OBRA, filtra por el DNI y
--          agrupa por la sensibilidad de la obra.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_obras_por_sector_de_restaurador(INTEGER);
CREATE FUNCTION fn_obras_por_sector_de_restaurador(p_dni INTEGER)
RETURNS TABLE (
    dni            INTEGER,
    nombre         VARCHAR,
    apellido       VARCHAR,
    sector         VARCHAR,
    cantidad_obras BIGINT
)
LANGUAGE sql
AS $$
    SELECT e.dni,
           e.nombre,
           e.apellido,
           o.sensibilidad,
           COUNT(DISTINCT r.id_obra)
      FROM empleado e, restauracion r, obra o
     WHERE r.dni_empleado = e.dni
       AND o.id_obra      = r.id_obra
       AND e.dni = p_dni
     GROUP BY e.dni, e.nombre, e.apellido, o.sensibilidad
     ORDER BY o.sensibilidad;
$$;

-- ---------------------------------------------------------------------
-- C) fn_restauradores_ultimos_6_meses
-- Entrada: ninguna.
-- Salida:  empleados que restauraron por lo menos 5 obras en los
--          últimos 6 meses, con la cantidad de obras.
-- Lógica:  devuelve la vista vw_restauradores_ultimos_6_meses ordenada
--          por cantidad de obras.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_restauradores_ultimos_6_meses();
CREATE FUNCTION fn_restauradores_ultimos_6_meses()
RETURNS TABLE (
    dni               INTEGER,
    nombre            VARCHAR,
    apellido          VARCHAR,
    email             VARCHAR,
    obras_restauradas BIGINT
)
LANGUAGE sql
AS $$
    SELECT v.dni,
           v.nombre,
           v.apellido,
           v.email,
           v.obras_restauradas
      FROM vw_restauradores_ultimos_6_meses v
     ORDER BY v.obras_restauradas DESC, v.apellido;
$$;

-- ---------------------------------------------------------------------
-- D) fn_copias_de_autor
-- Entrada: p_nombre y p_apellido del autor.
-- Salida:  una fila por cada copia de las obras del autor, con sus
--          datos y la sala donde se encuentra. El tipo de sala indica
--          si está exhibida ('muestra') o almacenada ('almacenamiento').
-- Lógica:  une COPIA, OBRA, AUTOR y SALA y filtra por nombre y apellido
--          del autor.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_copias_de_autor(VARCHAR, VARCHAR);
CREATE FUNCTION fn_copias_de_autor(p_nombre VARCHAR, p_apellido VARCHAR)
RETURNS TABLE (
    id_copia       INTEGER,
    fecha_creacion DATE,
    obra_original  VARCHAR,
    sala_actual    VARCHAR,
    tipo_sala      VARCHAR
)
LANGUAGE sql
AS $$
    SELECT c.id_copia,
           c.fecha_creacion,
           o.nombre,
           s.nombre,
           s.tipo
      FROM copia c, obra o, autor a, sala s
     WHERE o.id_obra  = c.id_obra
       AND a.id_autor = o.id_autor
       AND s.id_sala  = c.id_sala
       AND a.nombre   = p_nombre
       AND a.apellido = p_apellido
     ORDER BY o.nombre, c.id_copia;
$$;

-- ---------------------------------------------------------------------
-- E) fn_originales_por_sala
-- Entrada: ninguna.
-- Salida:  una fila por sala de almacenamiento con la cantidad de
--          obras originales que guarda (no cuenta las copias).
-- Lógica:  devuelve la vista vw_originales_por_sala ordenada por sala.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_originales_por_sala();
CREATE FUNCTION fn_originales_por_sala()
RETURNS TABLE (
    id_sala             INTEGER,
    nombre              VARCHAR,
    especializacion     VARCHAR,
    cantidad_originales BIGINT
)
LANGUAGE sql
AS $$
    SELECT v.id_sala,
           v.nombre,
           v.especializacion,
           v.cantidad_originales
      FROM vw_originales_por_sala v
     ORDER BY v.id_sala;
$$;

-- ---------------------------------------------------------------------
-- F) fn_restauradores_antiguos_ultimo_anio
-- Entrada: ninguna.
-- Salida:  datos de los empleados con más de 5 años de antigüedad que
--          restauraron por lo menos 5 obras en el último año.
-- Lógica:  devuelve la vista vw_restauradores_antiguos_ultimo_anio
--          ordenada por cantidad de obras.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_restauradores_antiguos_ultimo_anio();
CREATE FUNCTION fn_restauradores_antiguos_ultimo_anio()
RETURNS TABLE (
    dni               INTEGER,
    nombre            VARCHAR,
    apellido          VARCHAR,
    fecha_nac         DATE,
    telefono          VARCHAR,
    email             VARCHAR,
    fecha_ingreso     DATE,
    obras_restauradas BIGINT
)
LANGUAGE sql
AS $$
    SELECT v.dni,
           v.nombre,
           v.apellido,
           v.fecha_nac,
           v.telefono,
           v.email,
           v.fecha_ingreso,
           v.obras_restauradas
      FROM vw_restauradores_antiguos_ultimo_anio v
     ORDER BY v.obras_restauradas DESC, v.apellido;
$$;
