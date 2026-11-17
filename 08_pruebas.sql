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
-- Los triggers se activan con INSERT y UPDATE. Para cada uno se prueba
-- la operación inválida (se espera el mensaje del trigger) y, cuando
-- corresponde, la operación válida. Las pruebas de DELETE están al final.
-- =====================================================================

-- Datos de prueba: dos obras nuevas sin copia, en la sala 1
-- (almacenamiento, humedad).
SELECT probar('0.1 INSERT obra válida', 'operación aceptada',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (100, 'Obra de prueba 100', '2019-01-01', '2020-01-15', 'humedad', 1, 1)$$);
SELECT probar('0.2 INSERT obra válida', 'operación aceptada',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (101, 'Obra de prueba 101', '2019-01-01', '2020-01-15', 'humedad', 1, 1)$$);

-- ---------------------------------------------------------------------
-- 1. trg_copia_fecha_creacion
-- ---------------------------------------------------------------------
SELECT probar('1.1 INSERT copia de una obra inexistente',
    'La obra original no existe',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (100, 9999, 1)$$);

SELECT probar('1.2 INSERT copia válida con fecha enviada 1900-01-01',
    'operación aceptada',
    $$INSERT INTO copia (id_copia, fecha_creacion, id_obra, id_sala)
      VALUES (100, '1900-01-01', 100, 1)$$);
SELECT verificar('1.3 fecha de la copia = fecha_rec + 1 mes', '2020-02-15',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

SELECT probar('1.4 UPDATE copia hacia una obra inexistente',
    'La obra original no existe',
    $$UPDATE copia SET id_obra = 9999 WHERE id_copia = 100$$);

-- ---------------------------------------------------------------------
-- 2. trg_obra_actualiza_copia (solo UPDATE)
-- ---------------------------------------------------------------------
SELECT probar('2.1 UPDATE fecha_rec de la obra a 2020-03-10',
    'operación aceptada',
    $$UPDATE obra SET fecha_rec = '2020-03-10' WHERE id_obra = 100$$);
SELECT verificar('2.2 fecha de la copia recalculada', '2020-04-10',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- ---------------------------------------------------------------------
-- 3. trg_obra_sala_valida
-- ---------------------------------------------------------------------
SELECT probar('3.1 INSERT obra en una sala de muestra',
    'Los originales solo pueden guardarse en salas de almacenamiento',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (102, 'Obra de prueba 102', '2019-01-01', '2020-01-15', 'humedad', 1, 4)$$);

SELECT probar('3.2 INSERT obra fotosensible en una sala para humedad',
    'La sala no corresponde a la sensibilidad de la obra',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (102, 'Obra de prueba 102', '2019-01-01', '2020-01-15', 'fotosensibilidad', 1, 1)$$);

SELECT probar('3.3 UPDATE obra hacia una sala de muestra',
    'Los originales solo pueden guardarse en salas de almacenamiento',
    $$UPDATE obra SET id_sala = 4 WHERE id_obra = 101$$);

SELECT probar('3.4 UPDATE sensibilidad de la obra sin cambiar de sala',
    'La sala no corresponde a la sensibilidad de la obra',
    $$UPDATE obra SET sensibilidad = 'fotosensibilidad' WHERE id_obra = 101$$);

-- ---------------------------------------------------------------------
-- 4. trg_copia_ubicacion
-- ---------------------------------------------------------------------
SELECT probar('4.1 INSERT copia almacenada en otro depósito',
    'Una copia almacenada debe guardarse en la misma sala que su original',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (101, 101, 3)$$);

SELECT probar('4.2 UPDATE copia hacia otro depósito',
    'Una copia almacenada debe guardarse en la misma sala que su original',
    $$UPDATE copia SET id_sala = 3 WHERE id_copia = 100$$);

SELECT probar('4.3 UPDATE copia hacia una sala de muestra',
    'operación aceptada',
    $$UPDATE copia SET id_sala = 4 WHERE id_copia = 100$$);

-- ---------------------------------------------------------------------
-- 5. trg_restauracion_restaurador
-- Empleado 35666777: función 'seguridad'. Empleada 30111222: función
-- 'restauracion', ingresó al museo el 2012-03-01.
-- ---------------------------------------------------------------------
SELECT probar('5.1 INSERT restauración con un empleado de seguridad',
    'El empleado no tiene la función de restaurador',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (100, '2021-01-01', '2021-02-01', 100, 35666777)$$);

SELECT probar('5.2 INSERT restauración anterior al ingreso de la empleada',
    'La restauración es anterior al ingreso del empleado',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (100, '2011-01-01', '2011-02-01', 1, 30111222)$$);

SELECT probar('5.3 INSERT restauración válida',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (100, '2021-01-01', '2021-02-01', 100, 30111222)$$);

SELECT probar('5.4 UPDATE responsable por un empleado de seguridad',
    'El empleado no tiene la función de restaurador',
    $$UPDATE restauracion SET dni_empleado = 35666777 WHERE id_restauracion = 100$$);

-- ---------------------------------------------------------------------
-- 6. trg_restauracion_superposicion
-- La obra 100 tiene la restauración 100 (2021-01-01 a 2021-02-01).
-- La obra 7 tiene una restauración en curso (fecha_fin NULL).
-- ---------------------------------------------------------------------
SELECT probar('6.1 INSERT restauración superpuesta con otra',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-01-15', '2021-03-01', 100, 30111222)$$);

SELECT probar('6.2 INSERT restauración de una obra con otra en curso',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, id_obra, dni_empleado)
      VALUES (101, CURRENT_DATE, 7, 30111222)$$);

SELECT probar('6.3 INSERT restauración posterior, sin superposición',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-06-01', '2021-07-01', 100, 30111222)$$);

SELECT probar('6.4 UPDATE fecha de ingreso que la superpone con otra',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$UPDATE restauracion SET fecha_ingreso = '2021-01-20' WHERE id_restauracion = 101$$);

-- ---------------------------------------------------------------------
-- 7. trg_obra_fechas
-- ---------------------------------------------------------------------
SELECT probar('7.1 INSERT obra con fecha de recuperación futura',
    'La fecha de recuperación no puede ser posterior a la fecha actual',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (102, 'Obra de prueba 102', '2019-01-01', CURRENT_DATE + 1, 'humedad', 1, 1)$$);

SELECT probar('7.2 UPDATE fecha de recuperación a una fecha futura',
    'La fecha de recuperación no puede ser posterior a la fecha actual',
    $$UPDATE obra SET fecha_rec = CURRENT_DATE + 1 WHERE id_obra = 101$$);

-- ---------------------------------------------------------------------
-- 8. trg_copia_unica
-- La obra 1 ya tiene la copia 1.
-- ---------------------------------------------------------------------
SELECT probar('8.1 INSERT segunda copia de una obra',
    'La obra ya tiene una copia registrada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (101, 1, 4)$$);

SELECT probar('8.2 UPDATE copia hacia una obra que ya tiene copia',
    'La obra ya tiene una copia registrada',
    $$UPDATE copia SET id_obra = 1 WHERE id_copia = 100$$);

-- ---------------------------------------------------------------------
-- 9. trg_empleado_fechas
-- ---------------------------------------------------------------------
SELECT probar('9.1 INSERT empleado con fecha de nacimiento futura',
    'La fecha de nacimiento debe ser anterior a la fecha actual',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (1, 'Empleado', 'De Prueba', CURRENT_DATE + 1, CURRENT_DATE + 2)$$);

SELECT probar('9.2 INSERT empleado con fecha de ingreso futura',
    'La fecha de ingreso no puede ser posterior a la fecha actual',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (1, 'Empleado', 'De Prueba', '2000-01-01', CURRENT_DATE + 1)$$);

SELECT probar('9.3 UPDATE fecha de nacimiento a una fecha futura',
    'La fecha de nacimiento debe ser anterior a la fecha actual',
    $$UPDATE empleado SET fecha_nac = CURRENT_DATE + 1 WHERE dni = 30111222$$);

SELECT probar('9.4 UPDATE fecha de ingreso a una fecha futura',
    'La fecha de ingreso no puede ser posterior a la fecha actual',
    $$UPDATE empleado SET fecha_ingreso = CURRENT_DATE + 1 WHERE dni = 30111222$$);

-- ---------------------------------------------------------------------
-- 10. trg_restauracion_fecha_obra
-- La obra 100 fue recuperada el 2020-03-10.
-- ---------------------------------------------------------------------
SELECT probar('10.1 INSERT restauración anterior a la recuperación',
    'La restauración no puede ser anterior a la recuperación de la obra',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (102, '2019-01-01', '2019-02-01', 100, 30111222)$$);

SELECT probar('10.2 UPDATE fecha de ingreso anterior a la recuperación',
    'La restauración no puede ser anterior a la recuperación de la obra',
    $$UPDATE restauracion SET fecha_ingreso = '2019-06-01' WHERE id_restauracion = 100$$);

-- ---------------------------------------------------------------------
-- DELETE
-- Ningún trigger se activa con DELETE: la operación se acepta, salvo
-- que la rechace una clave foránea.
-- ---------------------------------------------------------------------
SELECT probar('11.1 DELETE de una restauración',
    'operación aceptada',
    $$DELETE FROM restauracion WHERE id_restauracion = 101$$);

SELECT probar('11.2 DELETE de una copia',
    'operación aceptada',
    $$DELETE FROM copia WHERE id_copia = 100$$);

SELECT probar('11.3 DELETE de una obra con copia y restauraciones',
    'rechazo de la clave foránea (la obra está referenciada)',
    $$DELETE FROM obra WHERE id_obra = 1$$);

-- =====================================================================
-- PARTE 2: USUARIOS
-- =====================================================================

SET ROLE museo_consulta;
SELECT verificar('12.1 museo_consulta lee la tabla obra', '25',
    (SELECT CAST(COUNT(*) AS TEXT) FROM obra));
SELECT probar('12.2 museo_consulta intenta insertar un autor',
    'permiso denegado sobre la tabla autor',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
SELECT probar('12.3 museo_consulta intenta borrar restauraciones',
    'permiso denegado sobre la tabla restauracion',
    $$DELETE FROM restauracion$$);
RESET ROLE;

SET ROLE museo_admin;
SELECT probar('12.4 museo_admin inserta un autor',
    'operación aceptada',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
SELECT probar('12.5 museo_admin modifica un autor',
    'operación aceptada',
    $$UPDATE autor SET nombre = 'Otro' WHERE apellido = 'De Prueba'$$);
SELECT probar('12.6 museo_admin intenta eliminar una tabla',
    'rechazo: no es el dueño de la tabla',
    $$DROP TABLE restauracion$$);
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

-- Esperado para 2019: 1 fila (obra 1). Esperado para 2000: sin filas.
SELECT * FROM fn_obras_restauradas_en_anio(2019);
SELECT * FROM fn_obras_restauradas_en_anio(2000);

-- Función de la consulta B. Esperado para Ana Martínez: 2 filas
-- (fotosensibilidad 3, humedad 4).
SELECT * FROM fn_obras_por_sector_de_restaurador(30111222);

-- Esperado para un empleado de seguridad: sin filas.
SELECT * FROM fn_obras_por_sector_de_restaurador(35666777);

-- Función de la consulta C. Esperado: igual que la vista (2 filas).
SELECT * FROM fn_restauradores_ultimos_6_meses();

-- Función de la consulta D. Esperado para Leonardo da Vinci: 3 filas
-- (copias 1 y 2 en salas de muestra, copia 3 almacenada).
SELECT * FROM fn_copias_de_autor('Leonardo', 'da Vinci');

-- Esperado para un autor inexistente: sin filas.
SELECT * FROM fn_copias_de_autor('Pablo', 'Picasso');

-- Función de la consulta E. Esperado: igual que la vista (8 filas).
SELECT * FROM fn_originales_por_sala();

-- Función de la consulta F. Esperado: igual que la vista (1 fila).
SELECT * FROM fn_restauradores_antiguos_ultimo_anio();
