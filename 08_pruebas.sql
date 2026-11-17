-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Pruebas de triggers, usuarios, vistas, funciones y consultas
-- Motor: PostgreSQL
--
-- Ejecutar sobre la base "museo", con un usuario administrador, después
-- de los scripts 01 a 07 (con los datos de 04_carga_datos.sql cargados).
--
-- Parte 1 y 2: se ejecutan dentro de una transacción que termina en
-- ROLLBACK, por lo que no modifican los datos. Cada prueba informa su
-- resultado con un mensaje (pestaña "Messages" de pgAdmin):
--
--     Prueba N | esperado: ... | obtenido: ...
--
-- Parte 3: consultas de solo lectura; el resultado esperado está en el
-- comentario de cada una.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- Funciones auxiliares de prueba (se eliminan con el ROLLBACK final)
-- ---------------------------------------------------------------------

-- Ejecuta una sentencia e informa si fue aceptada o el error obtenido.
CREATE FUNCTION probar(p_prueba TEXT, p_esperado TEXT, p_sentencia TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE p_sentencia;
    RAISE NOTICE 'Prueba % | esperado: % | obtenido: operación aceptada',
                 p_prueba, p_esperado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Prueba % | esperado: % | obtenido: %',
                     p_prueba, p_esperado, SQLERRM;
END;
$$;

-- Informa un valor obtenido junto al valor esperado.
CREATE FUNCTION verificar(p_prueba TEXT, p_esperado TEXT, p_obtenido TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Prueba % | esperado: % | obtenido: %',
                 p_prueba, p_esperado, p_obtenido;
END;
$$;

-- =====================================================================
-- PARTE 1: TRIGGERS
-- Una prueba por trigger, con la operación que lo activa. Al final, una
-- prueba de DELETE.
-- =====================================================================

-- Datos de prueba: una obra nueva en la sala 1 (almacenamiento, humedad),
-- su copia (con una fecha cualquiera, que el trigger 1 reemplaza) y una
-- restauración de la obra.
INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
VALUES (100, 'Obra de prueba 100', '2019-01-01', '2020-01-15', 'humedad', 1, 1);

INSERT INTO copia (id_copia, fecha_creacion, id_obra, id_sala)
VALUES (100, '1900-01-01', 100, 1);

INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
VALUES (100, '2021-01-01', '2021-02-01', 100, 30111222);

-- 1. trg_copia_fecha_creacion
SELECT verificar('1 fecha de la copia = fecha_rec + 1 mes', '2020-02-15',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- 2. trg_obra_actualiza_copia
UPDATE obra SET fecha_rec = '2020-03-10' WHERE id_obra = 100;
SELECT verificar('2 fecha de la copia recalculada', '2020-04-10',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- 3. trg_obra_sala_valida (la sala 4 es de muestra)
SELECT probar('3 INSERT obra en una sala de muestra',
    'Los originales solo pueden guardarse en salas de almacenamiento',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (101, 'Obra de prueba 101', '2019-01-01', '2020-01-15', 'humedad', 1, 4)$$);

-- 4. trg_copia_ubicacion (la obra 100 está en la sala 1)
SELECT probar('4 UPDATE copia hacia otro depósito',
    'Una copia almacenada debe guardarse en la misma sala que su original',
    $$UPDATE copia SET id_sala = 3 WHERE id_copia = 100$$);

-- 5. trg_restauracion_restaurador (el empleado 35666777 es de seguridad)
SELECT probar('5 INSERT restauración con un empleado de seguridad',
    'El empleado no tiene la función de restaurador',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-06-01', '2021-07-01', 100, 35666777)$$);

-- 6. trg_restauracion_superposicion (la obra 100 estuvo en restauración
-- del 2021-01-01 al 2021-02-01)
SELECT probar('6 INSERT restauración superpuesta con otra',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-01-15', '2021-03-01', 100, 30111222)$$);

-- 7. trg_obra_fechas
SELECT probar('7 INSERT obra con fecha de recuperación futura',
    'La fecha de recuperación no puede ser posterior a la fecha actual',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (101, 'Obra de prueba 101', '2019-01-01', CURRENT_DATE + 1, 'humedad', 1, 1)$$);

-- 8. trg_copia_unica (la obra 1 ya tiene la copia 1)
SELECT probar('8 INSERT segunda copia de una obra',
    'La obra ya tiene una copia registrada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (101, 1, 4)$$);

-- 9. trg_empleado_fechas
SELECT probar('9 INSERT empleado con fecha de nacimiento futura',
    'La fecha de nacimiento debe ser anterior a la fecha actual',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (1, 'Empleado', 'De Prueba', CURRENT_DATE + 1, CURRENT_DATE + 2)$$);

-- 10. trg_restauracion_fecha_obra (la obra 100 fue recuperada el 2020-03-10)
SELECT probar('10 INSERT restauración anterior a la recuperación',
    'La restauración no puede ser anterior a la recuperación de la obra',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2019-01-01', '2019-02-01', 100, 30111222)$$);

-- 11. DELETE: ningún trigger se activa con DELETE; una obra con copia y
-- restauraciones no se puede borrar por la clave foránea.
SELECT probar('11 DELETE de una obra con copia y restauraciones',
    'rechazo de la clave foránea (la obra está referenciada)',
    $$DELETE FROM obra WHERE id_obra = 1$$);

-- =====================================================================
-- PARTE 2: USUARIOS
-- =====================================================================

SET ROLE museo_consulta;
SELECT probar('12 museo_consulta intenta insertar un autor',
    'permiso denegado sobre la tabla autor',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
RESET ROLE;

SET ROLE museo_admin;
SELECT probar('13 museo_admin inserta un autor',
    'operación aceptada',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
RESET ROLE;

ROLLBACK;

-- =====================================================================
-- PARTE 3: VISTAS, FUNCIONES Y CONSULTAS
-- Resultados esperados con los datos de 04_carga_datos.sql.
-- =====================================================================

-- Vista de la consulta C. Esperado: 2 filas (Lucas Fernández y Ana
-- Martínez, 5 obras cada uno).
SELECT * FROM vw_restauradores_ultimos_6_meses;

-- Vista de la consulta E. Esperado: 8 filas; salas 1, 2 y 3 con 4
-- originales, salas 6, 8 y 9 con 3, salas 7 y 15 con 1.
SELECT * FROM vw_originales_por_sala;

-- Vista de la consulta F. Esperado: 1 fila (Ana Martínez, 6 obras).
SELECT * FROM vw_restauradores_antiguos_ultimo_anio;

-- Función de la consulta A. Esperado para 2023: 3 filas (obras 5, 8 y 12).
SELECT * FROM fn_obras_restauradas_en_anio(2023);

-- Función de la consulta B. Esperado para Ana Martínez: 2 filas
-- (fotosensibilidad 3, humedad 4).
SELECT * FROM fn_obras_por_sector_de_restaurador(30111222);

-- Función de la consulta C. Esperado: igual que la vista (2 filas).
SELECT * FROM fn_restauradores_ultimos_6_meses();

-- Función de la consulta D. Esperado para Leonardo da Vinci: 3 filas
-- (copias 1 y 2 en salas de muestra, copia 3 almacenada).
SELECT * FROM fn_copias_de_autor('Leonardo', 'da Vinci');

-- Función de la consulta E. Esperado: igual que la vista (8 filas).
SELECT * FROM fn_originales_por_sala();

-- Función de la consulta F. Esperado: igual que la vista (1 fila).
SELECT * FROM fn_restauradores_antiguos_ultimo_anio();
