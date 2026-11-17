-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Carga de datos de prueba de la base "museo"
-- Motor: PostgreSQL
--
-- Ejecutar sobre la base "museo" después de 01_creacion_bd.sql,
-- 02_triggers.sql y 03_vistas.sql. Se puede volver a ejecutar: vacía las
-- tablas antes de cargarlas.
--
-- Cada tabla se carga con al menos 15 filas.
--
-- Las restauraciones recientes usan fechas relativas a CURRENT_DATE para
-- que las consultas C y F (últimos 6 meses / último año) devuelvan
-- resultados sin importar el día en que se ejecute el script.
-- =====================================================================

-- Vacía las tablas, primero las que referencian a otras.
DELETE FROM restauracion;
DELETE FROM empleado_funcion;
DELETE FROM funcion_empleado;
DELETE FROM empleado;
DELETE FROM copia;
DELETE FROM obra;
DELETE FROM sala;
DELETE FROM autor;

-- ---------------------------------------------------------------------
-- AUTOR
-- ---------------------------------------------------------------------
INSERT INTO autor (id_autor, nombre, apellido) VALUES
    (1,  'Leonardo',      'da Vinci'),
    (2,  'Vincent',       'van Gogh'),
    (3,  'Claude',        'Monet'),
    (4,  'Rembrandt',     'van Rijn'),
    (5,  'Johannes',      'Vermeer'),
    (6,  'Eugène',        'Delacroix'),
    (7,  'Jacques-Louis', 'David'),
    (8,  'Théodore',      'Géricault'),
    (9,  'Jean-Auguste',  'Ingres'),
    (10, 'Paolo',         'Veronese'),
    (11, 'Rafael',        'Sanzio'),
    (12, 'Tiziano',       'Vecellio'),
    (13, 'Michelangelo',  'Caravaggio'),
    (14, 'Nicolas',       'Poussin'),
    (15, 'Antoine',       'Watteau');

-- ---------------------------------------------------------------------
-- SALA
-- ---------------------------------------------------------------------
INSERT INTO sala (id_sala, nombre, tipo, especializacion) VALUES
    (1,  'Depósito Seco Denon',        'almacenamiento', 'humedad'),
    (2,  'Depósito Oscuro Richelieu',  'almacenamiento', 'fotosensibilidad'),
    (3,  'Depósito Seco Sully',        'almacenamiento', 'humedad'),
    (4,  'Gran Galería',               'muestra',        'humedad'),
    (5,  'Sala de los Estados',        'muestra',        'fotosensibilidad'),
    (6,  'Depósito Oscuro Sully',      'almacenamiento', 'fotosensibilidad'),
    (7,  'Depósito de Reserva',        'almacenamiento', 'humedad'),
    (8,  'Depósito Oscuro Denon',      'almacenamiento', 'fotosensibilidad'),
    (9,  'Depósito Seco Richelieu',    'almacenamiento', 'humedad'),
    (10, 'Sala Mollien',               'muestra',        'humedad'),
    (11, 'Sala Daru',                  'muestra',        'fotosensibilidad'),
    (12, 'Galería de Apolo',           'muestra',        'humedad'),
    (13, 'Sala Rubens',                'muestra',        'fotosensibilidad'),
    (14, 'Sala de Pintura Francesa',   'muestra',        'humedad'),
    (15, 'Depósito de Tránsito',       'almacenamiento', 'fotosensibilidad');

-- ---------------------------------------------------------------------
-- OBRA (originales: siempre en salas de almacenamiento de su
-- sensibilidad, lo controla trg_obra_sala_valida)
-- ---------------------------------------------------------------------
INSERT INTO obra (id_obra, nombre, fecha_creacion, fecha_rec, descripcion,
                  sensibilidad, id_autor, id_sala) VALUES
    (1,  'La Gioconda',                    '1503-10-01', '2010-04-12',
         'Retrato de Lisa Gherardini, óleo sobre tabla de álamo.',      'humedad',          1, 1),
    (2,  'La Virgen de las Rocas',         '1483-04-25', '2011-06-03',
         'Óleo sobre tabla trasladado a lienzo.',                       'fotosensibilidad', 1, 2),
    (3,  'San Juan Bautista',              '1513-01-01', '2012-09-20',
         'Último cuadro conocido de Leonardo.',                         'humedad',          1, 1),
    (4,  'Autorretrato con sombrero de fieltro', '1887-01-01', '2013-02-14',
         'Autorretrato de su etapa en París.',                          'fotosensibilidad', 2, 2),
    (5,  'La iglesia de Auvers',           '1890-06-01', '2014-05-30',
         'Pintado en Auvers-sur-Oise.',                                 'humedad',          2, 3),
    (6,  'Impresión, sol naciente',        '1872-11-13', '2015-03-08',
         'Obra que dio nombre al impresionismo.',                       'fotosensibilidad', 3, 6),
    (7,  'Nenúfares',                      '1906-01-01', '2015-11-22',
         'Serie del estanque de Giverny.',                              'humedad',          3, 3),
    (8,  'Los peregrinos de Emaús',        '1648-01-01', '2016-07-19',
         'Escena bíblica con luz dorada característica.',               'fotosensibilidad', 4, 2),
    (9,  'Betsabé en el baño',             '1654-01-01', '2017-01-10',
         'Óleo sobre lienzo de gran formato.',                          'humedad',          4, 1),
    (10, 'La encajera',                    '1669-01-01', '2017-08-05',
         'Pequeño óleo sobre lienzo montado en tabla.',                 'fotosensibilidad', 5, 6),
    (11, 'El astrónomo',                   '1668-01-01', '2018-03-27',
         'Erudito estudiando un globo celeste.',                        'humedad',          5, 3),
    (12, 'La libertad guiando al pueblo',  '1830-01-01', '2019-10-02',
         'Alegoría de la Revolución de Julio.',                         'fotosensibilidad', 6, 6),
    (13, 'La muerte de Sardanápalo',       '1827-01-01', '2020-05-15',
         'Escena orientalista de gran tamaño.',                         'humedad',          6, 1),
    (14, 'La coronación de Napoleón',      '1807-01-01', '2021-02-11',
         'Consagración del emperador en Notre-Dame.',                   'fotosensibilidad', 7, 2),
    (15, 'El juramento de los Horacios',   '1784-01-01', '2022-08-30',
         'Obra emblemática del neoclasicismo.',                         'humedad',          7, 3),
    (16, 'La balsa de la Medusa',          '1819-01-01', '2016-04-18',
         'Naufragio de la fragata Méduse.',                             'humedad',          8, 9),
    (17, 'La gran odalisca',               '1814-01-01', '2017-11-06',
         'Desnudo de inspiración orientalista.',                        'fotosensibilidad', 9, 8),
    (18, 'Las bodas de Caná',              '1563-01-01', '2018-09-14',
         'El lienzo de mayor tamaño del museo.',                        'humedad',          10, 9),
    (19, 'Retrato de Baltasar Castiglione', '1515-01-01', '2019-03-22',
         'Retrato del diplomático y humanista.',                        'fotosensibilidad', 11, 8),
    (20, 'Concierto campestre',            '1509-01-01', '2020-10-09',
         'Escena pastoral veneciana.',                                  'humedad',          12, 7),
    (21, 'La muerte de la Virgen',         '1606-01-01', '2021-06-28',
         'Óleo de fuerte claroscuro.',                                  'fotosensibilidad', 13, 15),
    (22, 'Los pastores de Arcadia',        '1638-01-01', '2022-01-17',
         'Pastores ante una tumba en un paisaje clásico.',              'humedad',          14, 9),
    (23, 'Peregrinación a la isla de Citera', '1717-01-01', '2023-04-03',
         'Fiesta galante en un paisaje idealizado.',                    'fotosensibilidad', 15, 8);

-- ---------------------------------------------------------------------
-- COPIA (fecha_creacion la calcula trg_copia_fecha_creacion; las copias
-- almacenadas van en la sala del original, lo controla trg_copia_ubicacion;
-- una sola copia por obra, lo controla trg_copia_unica)
-- ---------------------------------------------------------------------
INSERT INTO copia (id_copia, id_obra, id_sala) VALUES
    (1,  1,  4),    -- exhibida
    (2,  2,  5),    -- exhibida
    (3,  3,  1),    -- almacenada con su original
    (4,  4,  5),    -- exhibida
    (5,  5,  3),    -- almacenada con su original
    (6,  6,  5),    -- exhibida
    (7,  7,  3),    -- almacenada con su original
    (8,  8,  5),    -- exhibida
    (9,  9,  1),    -- almacenada con su original
    (10, 10, 5),    -- exhibida
    (11, 11, 4),    -- exhibida
    (12, 12, 6),    -- almacenada con su original
    (13, 13, 4),    -- exhibida
    (14, 14, 2),    -- almacenada con su original
    (15, 15, 4),    -- exhibida
    (16, 16, 10),   -- exhibida
    (17, 17, 11),   -- exhibida
    (18, 18, 9),    -- almacenada con su original
    (19, 19, 13),   -- exhibida
    (20, 20, 12),   -- exhibida
    (21, 21, 15),   -- almacenada con su original
    (22, 22, 14),   -- exhibida
    (23, 23, 8);    -- almacenada con su original

-- ---------------------------------------------------------------------
-- FUNCION_EMPLEADO
-- ---------------------------------------------------------------------
INSERT INTO funcion_empleado (id_funcion, descripcion) VALUES
    (1,  'seguridad'),
    (2,  'restauracion'),
    (3,  'administracion'),
    (4,  'guia'),
    (5,  'limpieza'),
    (6,  'mantenimiento'),
    (7,  'curaduria'),
    (8,  'conservacion'),
    (9,  'educacion'),
    (10, 'boleteria'),
    (11, 'catalogacion'),
    (12, 'iluminacion'),
    (13, 'transporte'),
    (14, 'prensa'),
    (15, 'direccion');

-- ---------------------------------------------------------------------
-- EMPLEADO
-- ---------------------------------------------------------------------
INSERT INTO empleado (dni, nombre, apellido, fecha_nac, telefono, email,
                      fecha_ingreso) VALUES
    (30111222, 'Ana',       'Martínez',  '1980-05-14', '3442-411111', 'amartinez@museo.org',  '2012-03-01'),
    (32444555, 'Lucas',     'Fernández', '1992-09-03', '3442-422222', 'lfernandez@museo.org',
               CURRENT_DATE - 1095),   -- 3 años de antigüedad
    (28999000, 'Marta',     'Gómez',     '1975-01-22', '3442-433333', 'mgomez@museo.org',     '2010-07-15'),
    (29888777, 'Pablo',     'Díaz',      '1978-11-30', NULL,          'pdiaz@museo.org',      '2015-02-01'),
    (35666777, 'Diego',     'Ruiz',      '1990-04-18', '3442-455555', NULL,                   '2018-06-10'),
    (33222111, 'Laura',     'Sosa',      '1985-12-05', '3442-466666', 'lsosa@museo.org',      '2016-09-01'),
    (36777888, 'Sofía',     'Pereyra',   '1995-07-07', '3442-477777', 'spereyra@museo.org',   '2021-04-01'),
    (27555444, 'Carlos',    'Benítez',   '1972-03-11', '3442-488888', 'cbenitez@museo.org',   '2009-05-04'),
    (31222333, 'Valeria',   'Acosta',    '1984-08-27', '3442-499999', 'vacosta@museo.org',    '2014-10-20'),
    (34111999, 'Martín',    'Ríos',      '1989-02-15', NULL,          'mrios@museo.org',      '2019-03-18'),
    (37888222, 'Camila',    'Vega',      '1996-10-09', '3442-412345', 'cvega@museo.org',      '2022-07-01'),
    (26444111, 'Jorge',     'Molina',    '1970-06-30', '3442-423456', NULL,                   '2008-02-11'),
    (38555666, 'Julieta',   'Navarro',   '1998-01-19', '3442-434567', 'jnavarro@museo.org',   '2023-09-04'),
    (29333888, 'Hernán',    'Castro',    '1977-12-02', '3442-445678', 'hcastro@museo.org',    '2013-06-17'),
    (33999444, 'Florencia', 'Luna',      '1987-05-23', '3442-456789', 'fluna@museo.org',      '2017-11-27');

-- ---------------------------------------------------------------------
-- EMPLEADO_FUNCION
-- ---------------------------------------------------------------------
INSERT INTO empleado_funcion (dni_empleado, id_funcion) VALUES
    (30111222, 2),
    (32444555, 2),
    (28999000, 2),
    (29888777, 2),
    (29888777, 3),
    (35666777, 1),
    (33222111, 3),
    (36777888, 4),
    (36777888, 1),
    (27555444, 1),
    (31222333, 2),
    (34111999, 4),
    (37888222, 3),
    (26444111, 6),
    (38555666, 4),
    (38555666, 10),
    (29333888, 7),
    (33999444, 8),
    (33999444, 2);

-- ---------------------------------------------------------------------
-- RESTAURACION
-- Responsables con función 'restauracion' (trg_restauracion_restaurador),
-- sin períodos superpuestos por obra (trg_restauracion_superposicion) y
-- nunca anteriores a la recuperación de la obra (trg_restauracion_fecha_obra).
-- ---------------------------------------------------------------------

-- Restauraciones históricas (fechas fijas, usadas por la consulta A)
INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin,
                          id_obra, dni_empleado) VALUES
    (1, '2019-02-01', '2019-05-30', 1,  28999000),
    (2, '2022-08-01', '2022-10-01', 9,  29888777),
    (3, '2023-03-10', '2023-07-20', 8,  28999000),
    (4, '2023-05-02', '2023-06-15', 5,  30111222),
    (5, '2023-11-15', '2024-02-10', 12, 29888777);

-- Restauraciones recientes (fechas relativas a hoy, consultas B, C y F)
INSERT INTO restauracion (id_restauracion, fecha_ingreso, fecha_fin,
                          id_obra, dni_empleado) VALUES
    -- Ana Martínez: 6 obras en el último año, 5 de ellas en los últimos 6 meses
    (6,  CURRENT_DATE - 300, CURRENT_DATE - 260, 2,  30111222),
    (7,  CURRENT_DATE - 170, CURRENT_DATE - 145, 1,  30111222),
    (8,  CURRENT_DATE - 140, CURRENT_DATE - 115, 3,  30111222),
    (9,  CURRENT_DATE - 110, CURRENT_DATE - 85,  4,  30111222),
    (10, CURRENT_DATE - 80,  CURRENT_DATE - 55,  6,  30111222),
    (11, CURRENT_DATE - 20,  NULL,               7,  30111222),   -- en curso
    -- Lucas Fernández: 5 obras en los últimos 6 meses (menos de 5 años de antigüedad)
    (12, CURRENT_DATE - 160, CURRENT_DATE - 130, 2,  32444555),
    (13, CURRENT_DATE - 125, CURRENT_DATE - 100, 9,  32444555),
    (14, CURRENT_DATE - 95,  CURRENT_DATE - 70,  10, 32444555),
    (15, CURRENT_DATE - 65,  CURRENT_DATE - 40,  11, 32444555),
    (16, CURRENT_DATE - 35,  CURRENT_DATE - 10,  13, 32444555),
    -- Marta Gómez: 2 obras en el último año
    (17, CURRENT_DATE - 200, CURRENT_DATE - 150, 14, 28999000),
    (18, CURRENT_DATE - 30,  NULL,               15, 28999000),   -- en curso
    -- Pablo Díaz: 1 obra en el último año
    (19, CURRENT_DATE - 330, CURRENT_DATE - 310, 3,  29888777);

-- ---------------------------------------------------------------------
-- Sincroniza las secuencias de las columnas IDENTITY con los ids cargados
-- ---------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('autor', 'id_autor'),              (SELECT MAX(id_autor)        FROM autor));
SELECT setval(pg_get_serial_sequence('sala', 'id_sala'),                (SELECT MAX(id_sala)         FROM sala));
SELECT setval(pg_get_serial_sequence('obra', 'id_obra'),                (SELECT MAX(id_obra)         FROM obra));
SELECT setval(pg_get_serial_sequence('copia', 'id_copia'),              (SELECT MAX(id_copia)        FROM copia));
SELECT setval(pg_get_serial_sequence('funcion_empleado', 'id_funcion'), (SELECT MAX(id_funcion)      FROM funcion_empleado));
SELECT setval(pg_get_serial_sequence('restauracion', 'id_restauracion'), (SELECT MAX(id_restauracion) FROM restauracion));
