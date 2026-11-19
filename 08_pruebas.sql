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
-- Para cada trigger hay una prueba por cada operación que lo activa
-- (INSERT, UPDATE) y por cada resultado posible (operación aceptada o
-- cada una de sus excepciones). Las pruebas se ejecutan en orden: las
-- operaciones aceptadas quedan hechas dentro de la transacción y las
-- pruebas siguientes parten de ese estado.
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
-- =====================================================================

-- Datos de prueba: dos obras nuevas en la sala 1 (almacenamiento,
-- humedad), todavía sin copia.
INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
VALUES (100, 'Obra de prueba 100', '2019-01-01', '2020-01-15', 'humedad', 1, 1),
       (101, 'Obra de prueba 101', '2019-01-01', '2020-06-01', 'humedad', 1, 1);

-- ---------------------------------------------------------------------
-- 1. trg_copia_fecha_creacion
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- ---------------------------------------------------------------------

-- 1.1 INSERT correcto: la fecha enviada se reemplaza por fecha_rec + 1 mes.
INSERT INTO copia (id_copia, fecha_creacion, id_obra, id_sala)
VALUES (100, '1900-01-01', 100, 1);
SELECT verificar('1.1 INSERT copia: fecha = fecha_rec de la obra 100 + 1 mes', '2020-02-15',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- 1.2 INSERT incorrecto: la obra no existe.
SELECT probar('1.2 INSERT copia de una obra inexistente',
    'La obra original no existe',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (101, 999, 4)$$);

-- 1.3 UPDATE correcto: la copia pasa a la obra 101 y se recalcula la fecha.
UPDATE copia SET id_obra = 101 WHERE id_copia = 100;
SELECT verificar('1.3 UPDATE copia: fecha = fecha_rec de la obra 101 + 1 mes', '2020-07-01',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- 1.4 UPDATE incorrecto: la obra no existe.
SELECT probar('1.4 UPDATE copia hacia una obra inexistente',
    'La obra original no existe',
    $$UPDATE copia SET id_obra = 999 WHERE id_copia = 100$$);

-- ---------------------------------------------------------------------
-- 2. trg_obra_actualiza_copia
-- Tabla: OBRA - AFTER UPDATE
-- (la copia 100 es ahora de la obra 101)
-- ---------------------------------------------------------------------

-- 2.1 UPDATE con una fecha distinta: se recalcula la fecha de la copia.
UPDATE obra SET fecha_rec = '2020-03-10' WHERE id_obra = 101;
SELECT verificar('2.1 UPDATE fecha_rec distinta: fecha de la copia recalculada', '2020-04-10',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- 2.2 UPDATE que no cambia la fecha de recuperación (se modifica solo la
-- descripción): el trigger se activa pero no hace nada.
UPDATE obra SET descripcion = 'Descripción modificada' WHERE id_obra = 101;
SELECT verificar('2.2 UPDATE sin cambiar fecha_rec: la copia no cambia', '2020-04-10',
    (SELECT CAST(fecha_creacion AS TEXT) FROM copia WHERE id_copia = 100));

-- ---------------------------------------------------------------------
-- 3. trg_obra_sala_valida
-- Tabla: OBRA - BEFORE INSERT OR UPDATE
-- Salas: 2 almacenamiento/fotosensibilidad, 3 y 7 almacenamiento/humedad,
-- 4 muestra.
-- ---------------------------------------------------------------------

SELECT probar('3.1 INSERT obra de humedad en un depósito de humedad',
    'operación aceptada',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (102, 'Obra de prueba 102', '2019-01-01', '2020-01-15', 'humedad', 1, 3)$$);

SELECT probar('3.2 INSERT obra en una sala de muestra',
    'Los originales solo pueden guardarse en salas de almacenamiento',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (103, 'Obra de prueba 103', '2019-01-01', '2020-01-15', 'humedad', 1, 4)$$);

SELECT probar('3.3 INSERT obra de humedad en un depósito de fotosensibilidad',
    'La sala no corresponde a la sensibilidad de la obra',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (103, 'Obra de prueba 103', '2019-01-01', '2020-01-15', 'humedad', 1, 2)$$);

SELECT probar('3.4 UPDATE obra hacia otro depósito de humedad',
    'operación aceptada',
    $$UPDATE obra SET id_sala = 7 WHERE id_obra = 102$$);

SELECT probar('3.5 UPDATE obra hacia una sala de muestra',
    'Los originales solo pueden guardarse en salas de almacenamiento',
    $$UPDATE obra SET id_sala = 4 WHERE id_obra = 102$$);

SELECT probar('3.6 UPDATE sensibilidad que no coincide con la sala',
    'La sala no corresponde a la sensibilidad de la obra',
    $$UPDATE obra SET sensibilidad = 'fotosensibilidad' WHERE id_obra = 102$$);

-- ---------------------------------------------------------------------
-- 4. trg_copia_ubicacion
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- (la obra 100 está en la sala 1 y no tiene copia; la obra 102 está en
-- la sala 7 y no tiene copia)
-- ---------------------------------------------------------------------

SELECT probar('4.1 INSERT copia almacenada en la sala de su original',
    'operación aceptada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (101, 100, 1)$$);

SELECT probar('4.2 INSERT copia almacenada en otro depósito',
    'Una copia almacenada debe guardarse en la misma sala que su original',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (102, 102, 3)$$);

SELECT probar('4.3 INSERT copia en una sala de muestra',
    'operación aceptada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (102, 102, 4)$$);

SELECT probar('4.4 UPDATE copia hacia otra sala de muestra',
    'operación aceptada',
    $$UPDATE copia SET id_sala = 5 WHERE id_copia = 102$$);

SELECT probar('4.5 UPDATE copia hacia un depósito distinto al de su original',
    'Una copia almacenada debe guardarse en la misma sala que su original',
    $$UPDATE copia SET id_sala = 3 WHERE id_copia = 102$$);

-- ---------------------------------------------------------------------
-- 5. trg_restauracion_restaurador
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- Empleados: 30111222 Ana Martínez y 28999000 Marta Gómez (restauradoras,
-- ingresaron en 2012 y 2010), 35666777 Diego Ruiz (seguridad) y 32444555
-- Lucas Fernández (restaurador, ingresó hace 3 años).
-- ---------------------------------------------------------------------

SELECT probar('5.1 INSERT restauración con una restauradora',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (100, '2021-01-01', '2021-02-01', 100, 30111222)$$);

SELECT probar('5.2 INSERT restauración con un empleado de seguridad',
    'El empleado no tiene la función de restaurador',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-06-01', '2021-07-01', 100, 35666777)$$);

SELECT probar('5.3 INSERT restauración anterior al ingreso del restaurador',
    'La restauración es anterior al ingreso del empleado',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-06-01', '2021-07-01', 100, 32444555)$$);

SELECT probar('5.4 UPDATE responsable por otra restauradora',
    'operación aceptada',
    $$UPDATE restauracion SET dni_empleado = 28999000 WHERE id_restauracion = 100$$);

SELECT probar('5.5 UPDATE responsable por un empleado de seguridad',
    'El empleado no tiene la función de restaurador',
    $$UPDATE restauracion SET dni_empleado = 35666777 WHERE id_restauracion = 100$$);

SELECT probar('5.6 UPDATE responsable por uno que ingresó después de la restauración',
    'La restauración es anterior al ingreso del empleado',
    $$UPDATE restauracion SET dni_empleado = 32444555 WHERE id_restauracion = 100$$);

-- ---------------------------------------------------------------------
-- 6. trg_restauracion_superposicion
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- (la obra 100 estuvo en restauración del 2021-01-01 al 2021-02-01)
-- ---------------------------------------------------------------------

SELECT probar('6.1 INSERT restauración sin superposición',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (101, '2021-03-01', '2021-04-01', 100, 30111222)$$);

SELECT probar('6.2 INSERT restauración superpuesta con otra',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (102, '2021-01-15', '2021-03-01', 100, 30111222)$$);

SELECT probar('6.3 INSERT restauración en curso (sin fecha de fin)',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (102, '2022-01-01', NULL, 100, 30111222)$$);

SELECT probar('6.4 INSERT restauración mientras otra sigue en curso',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (103, '2023-01-01', '2023-02-01', 100, 30111222)$$);

SELECT probar('6.5 UPDATE fecha de fin sin superposición',
    'operación aceptada',
    $$UPDATE restauracion SET fecha_fin = '2021-05-01' WHERE id_restauracion = 101$$);

SELECT probar('6.6 UPDATE fecha de ingreso que se superpone con otra',
    'La obra ya tiene una restauración en curso o superpuesta en esas fechas',
    $$UPDATE restauracion SET fecha_ingreso = '2021-01-20' WHERE id_restauracion = 101$$);

-- ---------------------------------------------------------------------
-- 7. trg_obra_fechas
-- Tabla: OBRA - BEFORE INSERT OR UPDATE
-- ---------------------------------------------------------------------

SELECT probar('7.1 INSERT obra recuperada hoy',
    'operación aceptada',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (103, 'Obra de prueba 103', '2019-01-01', CURRENT_DATE, 'humedad', 1, 3)$$);

SELECT probar('7.2 INSERT obra con fecha de recuperación futura',
    'La fecha de recuperación no puede ser posterior a la fecha actual',
    $$INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
      VALUES (104, 'Obra de prueba 104', '2019-01-01', CURRENT_DATE + 1, 'humedad', 1, 3)$$);

SELECT probar('7.3 UPDATE fecha de recuperación pasada',
    'operación aceptada',
    $$UPDATE obra SET fecha_rec = '2020-01-01' WHERE id_obra = 103$$);

SELECT probar('7.4 UPDATE fecha de recuperación futura',
    'La fecha de recuperación no puede ser posterior a la fecha actual',
    $$UPDATE obra SET fecha_rec = CURRENT_DATE + 1 WHERE id_obra = 103$$);

-- ---------------------------------------------------------------------
-- 8. trg_copia_unica
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- (la obra 1 ya tiene la copia 1; las obras 103 y 104 no tienen copia)
-- ---------------------------------------------------------------------

INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, sensibilidad, id_autor, id_sala)
VALUES (104, 'Obra de prueba 104', '2019-01-01', '2020-01-01', 'humedad', 1, 3);

SELECT probar('8.1 INSERT primera copia de una obra',
    'operación aceptada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (103, 103, 4)$$);

SELECT probar('8.2 INSERT segunda copia de una obra',
    'La obra ya tiene una copia registrada',
    $$INSERT INTO copia (id_copia, id_obra, id_sala) VALUES (104, 1, 4)$$);

SELECT probar('8.3 UPDATE copia hacia una obra sin copia',
    'operación aceptada',
    $$UPDATE copia SET id_obra = 104 WHERE id_copia = 103$$);

SELECT probar('8.4 UPDATE copia hacia una obra que ya tiene copia',
    'La obra ya tiene una copia registrada',
    $$UPDATE copia SET id_obra = 1 WHERE id_copia = 103$$);

-- ---------------------------------------------------------------------
-- 9. trg_empleado_fechas
-- Tabla: EMPLEADO - BEFORE INSERT OR UPDATE
-- ---------------------------------------------------------------------

SELECT probar('9.1 INSERT empleado con fechas pasadas',
    'operación aceptada',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (1, 'Empleado', 'De Prueba', '1990-01-01', '2020-01-01')$$);

SELECT probar('9.2 INSERT empleado con fecha de nacimiento futura',
    'La fecha de nacimiento debe ser anterior a la fecha actual',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (2, 'Empleado', 'De Prueba', CURRENT_DATE + 1, CURRENT_DATE + 2)$$);

SELECT probar('9.3 INSERT empleado con fecha de ingreso futura',
    'La fecha de ingreso no puede ser posterior a la fecha actual',
    $$INSERT INTO empleado (dni, nombre, apellido, fecha_nac, fecha_ingreso)
      VALUES (2, 'Empleado', 'De Prueba', '1990-01-01', CURRENT_DATE + 1)$$);

SELECT probar('9.4 UPDATE fecha de ingreso pasada',
    'operación aceptada',
    $$UPDATE empleado SET fecha_ingreso = '2021-01-01' WHERE dni = 1$$);

SELECT probar('9.5 UPDATE fecha de nacimiento futura',
    'La fecha de nacimiento debe ser anterior a la fecha actual',
    $$UPDATE empleado SET fecha_nac = CURRENT_DATE + 1 WHERE dni = 1$$);

SELECT probar('9.6 UPDATE fecha de ingreso futura',
    'La fecha de ingreso no puede ser posterior a la fecha actual',
    $$UPDATE empleado SET fecha_ingreso = CURRENT_DATE + 1 WHERE dni = 1$$);

-- ---------------------------------------------------------------------
-- 10. trg_restauracion_fecha_obra
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- (la obra 101 fue recuperada el 2020-03-10 y no tiene restauraciones)
-- ---------------------------------------------------------------------

SELECT probar('10.1 INSERT restauración el día de la recuperación',
    'operación aceptada',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (103, '2020-03-10', '2020-04-01', 101, 30111222)$$);

SELECT probar('10.2 INSERT restauración anterior a la recuperación',
    'La restauración no puede ser anterior a la recuperación de la obra',
    $$INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado)
      VALUES (104, '2020-01-01', '2020-02-01', 101, 30111222)$$);

SELECT probar('10.3 UPDATE fecha de ingreso posterior a la recuperación',
    'operación aceptada',
    $$UPDATE restauracion SET fecha_ingreso = '2020-03-15' WHERE id_restauracion = 103$$);

SELECT probar('10.4 UPDATE fecha de ingreso anterior a la recuperación',
    'La restauración no puede ser anterior a la recuperación de la obra',
    $$UPDATE restauracion SET fecha_ingreso = '2020-01-01' WHERE id_restauracion = 103$$);

-- ---------------------------------------------------------------------
-- 11. DELETE: ningún trigger se activa con DELETE; una obra con copia y
-- restauraciones no se puede borrar por la clave foránea.
-- ---------------------------------------------------------------------
SELECT probar('11 DELETE de una obra con copia y restauraciones',
    'rechazo de la clave foránea (la obra está referenciada)',
    $$DELETE FROM obra WHERE id_obra = 1$$);

-- =====================================================================
-- PARTE 2: USUARIOS
-- =====================================================================

SET ROLE museo_consulta;
SELECT probar('12.1 museo_consulta lee la tabla autor',
    'operación aceptada',
    $$SELECT * FROM autor$$);
SELECT probar('12.2 museo_consulta intenta insertar un autor',
    'permiso denegado sobre la tabla autor',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
RESET ROLE;

SET ROLE museo_admin;
SELECT probar('13.1 museo_admin inserta un autor',
    'operación aceptada',
    $$INSERT INTO autor (nombre, apellido) VALUES ('Autor', 'De Prueba')$$);
SELECT probar('13.2 museo_admin intenta eliminar la tabla autor',
    'debe ser dueño de la tabla autor',
    $$DROP TABLE autor$$);
RESET ROLE;

ROLLBACK;

-- =====================================================================
-- PARTE 3: VISTAS, FUNCIONES Y CONSULTAS
-- Resultados esperados con los datos de 04_carga_datos.sql.
-- =====================================================================

-- Vista de la consulta C. Esperado: 3 filas (Ana Martínez y Lucas
-- Fernández con 5 obras, Marta Gómez con 1).
SELECT * FROM vw_restauradores_ultimos_6_meses;

-- Vista de la consulta E. Esperado: 8 filas; salas 1, 2 y 3 con 4
-- originales, salas 6, 8 y 9 con 3, salas 7 y 15 con 1.
SELECT * FROM vw_originales_por_sala;

-- Vista de la consulta F. Esperado: 3 filas (Ana Martínez con 6 obras,
-- Marta Gómez con 2, Pablo Díaz con 1).
SELECT * FROM vw_restauradores_antiguos_ultimo_anio;

-- Función de la consulta A. Esperado para 2023: 3 filas (obras 5, 8 y 12).
SELECT * FROM fn_obras_restauradas_en_anio(2023);

-- Función de la consulta B. Esperado para Ana Martínez: 2 filas
-- (fotosensibilidad 3, humedad 4).
SELECT * FROM fn_obras_por_sector_de_restaurador(30111222);

-- Función de la consulta C. Esperado: 2 filas (Ana Martínez y Lucas
-- Fernández, 5 obras cada uno).
SELECT * FROM fn_restauradores_ultimos_6_meses();

-- Función de la consulta D. Esperado para Leonardo da Vinci (id 1):
-- 3 filas (copias 1 y 2 en salas de muestra, copia 3 almacenada).
SELECT * FROM fn_copias_de_autor(1);

-- Función de la consulta E. Esperado: igual que la vista (8 filas).
SELECT * FROM fn_originales_por_sala();

-- Función de la consulta F. Esperado: 1 fila (Ana Martínez, 6 obras).
SELECT * FROM fn_restauradores_antiguos_ultimo_anio();
