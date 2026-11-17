-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Carga de datos de prueba de la base "museo"
-- Motor: PostgreSQL
--
-- Ejecutar sobre la base "museo" después de 01_creacion_bd.sql,
-- 02_triggers.sql y 03_vistas.sql. Se puede volver a ejecutar: vacía las
-- tablas antes de cargarlas.
--
-- Cada tabla se carga con al menos 15 filas. Los ids autoincrementales no
-- se indican: se asignan en el orden de inserción (1, 2, 3, ...), y las
-- claves foráneas de las tablas siguientes usan esos valores.
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

-- Reinicia los contadores autoincrementales para que los ids vuelvan a
-- empezar en 1.
ALTER TABLE autor            ALTER COLUMN id_autor        RESTART WITH 1;
ALTER TABLE sala             ALTER COLUMN id_sala         RESTART WITH 1;
ALTER TABLE obra             ALTER COLUMN id_obra         RESTART WITH 1;
ALTER TABLE copia            ALTER COLUMN id_copia        RESTART WITH 1;
ALTER TABLE funcion_empleado ALTER COLUMN id_funcion      RESTART WITH 1;
ALTER TABLE restauracion     ALTER COLUMN id_restauracion RESTART WITH 1;

-- ---------------------------------------------------------------------
-- AUTOR
-- ---------------------------------------------------------------------
INSERT INTO autor (nombre, apellido) VALUES
    ('Leonardo',      'da Vinci'),
    ('Vincent',       'van Gogh'),
    ('Claude',        'Monet'),
    ('Rembrandt',     'van Rijn'),
    ('Johannes',      'Vermeer'),
    ('Eugène',        'Delacroix'),
    ('Jacques-Louis', 'David'),
    ('Théodore',      'Géricault'),
    ('Jean-Auguste',  'Ingres'),
    ('Paolo',         'Veronese'),
    ('Rafael',        'Sanzio'),
    ('Tiziano',       'Vecellio'),
    ('Michelangelo',  'Caravaggio'),
    ('Nicolas',       'Poussin'),
    ('Antoine',       'Watteau');

-- ---------------------------------------------------------------------
-- SALA
-- ---------------------------------------------------------------------
INSERT INTO sala (nombre, tipo, especializacion) VALUES
    ('Depósito Seco Denon',        'almacenamiento', 'humedad'),
    ('Depósito Oscuro Richelieu',  'almacenamiento', 'fotosensibilidad'),
    ('Depósito Seco Sully',        'almacenamiento', 'humedad'),
    ('Gran Galería',               'muestra',        'humedad'),
    ('Sala de los Estados',        'muestra',        'fotosensibilidad'),
    ('Depósito Oscuro Sully',      'almacenamiento', 'fotosensibilidad'),
    ('Depósito de Reserva',        'almacenamiento', 'humedad'),
    ('Depósito Oscuro Denon',      'almacenamiento', 'fotosensibilidad'),
    ('Depósito Seco Richelieu',    'almacenamiento', 'humedad'),
    ('Sala Mollien',               'muestra',        'humedad'),
    ('Sala Daru',                  'muestra',        'fotosensibilidad'),
    ('Galería de Apolo',           'muestra',        'humedad'),
    ('Sala Rubens',                'muestra',        'fotosensibilidad'),
    ('Sala de Pintura Francesa',   'muestra',        'humedad'),
    ('Depósito de Tránsito',       'almacenamiento', 'fotosensibilidad');

-- ---------------------------------------------------------------------
-- OBRA (originales: siempre en salas de almacenamiento de su
-- sensibilidad, lo controla trg_obra_sala_valida)
-- ---------------------------------------------------------------------
INSERT INTO obra (nombre, fecha_creacion, fecha_rec, descripcion,
                  sensibilidad, id_autor, id_sala) VALUES
    ('La Gioconda',                    '1503-10-01', '2010-04-12',
         'Retrato de Lisa Gherardini, óleo sobre tabla de álamo.',      'humedad',          1, 1),
    ('La Virgen de las Rocas',         '1483-04-25', '2011-06-03',
         'Óleo sobre tabla trasladado a lienzo.',                       'fotosensibilidad', 1, 2),
    ('San Juan Bautista',              '1513-01-01', '2012-09-20',
         'Último cuadro conocido de Leonardo.',                         'humedad',          1, 1),
    ('Autorretrato con sombrero de fieltro', '1887-01-01', '2013-02-14',
         'Autorretrato de su etapa en París.',                          'fotosensibilidad', 2, 2),
    ('La iglesia de Auvers',           '1890-06-01', '2014-05-30',
         'Pintado en Auvers-sur-Oise.',                                 'humedad',          2, 3),
    ('Impresión, sol naciente',        '1872-11-13', '2015-03-08',
         'Obra que dio nombre al impresionismo.',                       'fotosensibilidad', 3, 6),
    ('Nenúfares',                      '1906-01-01', '2015-11-22',
         'Serie del estanque de Giverny.',                              'humedad',          3, 3),
    ('Los peregrinos de Emaús',        '1648-01-01', '2016-07-19',
         'Escena bíblica con luz dorada característica.',               'fotosensibilidad', 4, 2),
    ('Betsabé en el baño',             '1654-01-01', '2017-01-10',
         'Óleo sobre lienzo de gran formato.',                          'humedad',          4, 1),
    ('La encajera',                    '1669-01-01', '2017-08-05',
         'Pequeño óleo sobre lienzo montado en tabla.',                 'fotosensibilidad', 5, 6),
    ('El astrónomo',                   '1668-01-01', '2018-03-27',
         'Erudito estudiando un globo celeste.',                        'humedad',          5, 3),
    ('La libertad guiando al pueblo',  '1830-01-01', '2019-10-02',
         'Alegoría de la Revolución de Julio.',                         'fotosensibilidad', 6, 6),
    ('La muerte de Sardanápalo',       '1827-01-01', '2020-05-15',
         'Escena orientalista de gran tamaño.',                         'humedad',          6, 1),
    ('La coronación de Napoleón',      '1807-01-01', '2021-02-11',
         'Consagración del emperador en Notre-Dame.',                   'fotosensibilidad', 7, 2),
    ('El juramento de los Horacios',   '1784-01-01', '2022-08-30',
         'Obra emblemática del neoclasicismo.',                         'humedad',          7, 3),
    ('La balsa de la Medusa',          '1819-01-01', '2016-04-18',
         'Naufragio de la fragata Méduse.',                             'humedad',          8, 9),
    ('La gran odalisca',               '1814-01-01', '2017-11-06',
         'Desnudo de inspiración orientalista.',                        'fotosensibilidad', 9, 8),
    ('Las bodas de Caná',              '1563-01-01', '2018-09-14',
         'El lienzo de mayor tamaño del museo.',                        'humedad',          10, 9),
    ('Retrato de Baltasar Castiglione', '1515-01-01', '2019-03-22',
         'Retrato del diplomático y humanista.',                        'fotosensibilidad', 11, 8),
    ('Concierto campestre',            '1509-01-01', '2020-10-09',
         'Escena pastoral veneciana.',                                  'humedad',          12, 7),
    ('La muerte de la Virgen',         '1606-01-01', '2021-06-28',
         'Óleo de fuerte claroscuro.',                                  'fotosensibilidad', 13, 15),
    ('Los pastores de Arcadia',        '1638-01-01', '2022-01-17',
         'Pastores ante una tumba en un paisaje clásico.',              'humedad',          14, 9),
    ('Peregrinación a la isla de Citera', '1717-01-01', '2023-04-03',
         'Fiesta galante en un paisaje idealizado.',                    'fotosensibilidad', 15, 8);

-- ---------------------------------------------------------------------
-- COPIA (fecha_creacion la calcula trg_copia_fecha_creacion; las copias
-- almacenadas van en la sala del original, lo controla trg_copia_ubicacion;
-- una sola copia por obra, lo controla trg_copia_unica)
-- ---------------------------------------------------------------------
INSERT INTO copia (id_obra, id_sala) VALUES
    (1,  4),    -- exhibida
    (2,  5),    -- exhibida
    (3,  1),    -- almacenada con su original
    (4,  5),    -- exhibida
    (5,  3),    -- almacenada con su original
    (6,  5),    -- exhibida
    (7,  3),    -- almacenada con su original
    (8,  5),    -- exhibida
    (9,  1),    -- almacenada con su original
    (10, 5),    -- exhibida
    (11, 4),    -- exhibida
    (12, 6),    -- almacenada con su original
    (13, 4),    -- exhibida
    (14, 2),    -- almacenada con su original
    (15, 4),    -- exhibida
    (16, 10),   -- exhibida
    (17, 11),   -- exhibida
    (18, 9),    -- almacenada con su original
    (19, 13),   -- exhibida
    (20, 12),   -- exhibida
    (21, 15),   -- almacenada con su original
    (22, 14),   -- exhibida
    (23, 8);    -- almacenada con su original

-- ---------------------------------------------------------------------
-- FUNCION_EMPLEADO
-- ---------------------------------------------------------------------
INSERT INTO funcion_empleado (descripcion) VALUES
    ('seguridad'),
    ('restauracion'),
    ('administracion'),
    ('guia'),
    ('limpieza'),
    ('mantenimiento'),
    ('curaduria'),
    ('conservacion'),
    ('educacion'),
    ('boleteria'),
    ('catalogacion'),
    ('iluminacion'),
    ('transporte'),
    ('prensa'),
    ('direccion');

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
INSERT INTO restauracion (fecha_ingreso, fecha_fin,
                          id_obra, dni_empleado) VALUES
    ('2019-02-01', '2019-05-30', 1,  28999000),
    ('2022-08-01', '2022-10-01', 9,  29888777),
    ('2023-03-10', '2023-07-20', 8,  28999000),
    ('2023-05-02', '2023-06-15', 5,  30111222),
    ('2023-11-15', '2024-02-10', 12, 29888777);

-- Restauraciones recientes (fechas relativas a hoy, consultas B, C y F)
INSERT INTO restauracion (fecha_ingreso, fecha_fin,
                          id_obra, dni_empleado) VALUES
    -- Ana Martínez: 6 obras en el último año, 5 de ellas en los últimos 6 meses
    (CURRENT_DATE - 300, CURRENT_DATE - 260, 2,  30111222),
    (CURRENT_DATE - 170, CURRENT_DATE - 145, 1,  30111222),
    (CURRENT_DATE - 140, CURRENT_DATE - 115, 3,  30111222),
    (CURRENT_DATE - 110, CURRENT_DATE - 85,  4,  30111222),
    (CURRENT_DATE - 80,  CURRENT_DATE - 55,  6,  30111222),
    (CURRENT_DATE - 20,  NULL,               7,  30111222),   -- en curso
    -- Lucas Fernández: 5 obras en los últimos 6 meses (menos de 5 años de antigüedad)
    (CURRENT_DATE - 160, CURRENT_DATE - 130, 2,  32444555),
    (CURRENT_DATE - 125, CURRENT_DATE - 100, 9,  32444555),
    (CURRENT_DATE - 95,  CURRENT_DATE - 70,  10, 32444555),
    (CURRENT_DATE - 65,  CURRENT_DATE - 40,  11, 32444555),
    (CURRENT_DATE - 35,  CURRENT_DATE - 10,  13, 32444555),
    -- Marta Gómez: 2 obras en el último año
    (CURRENT_DATE - 200, CURRENT_DATE - 150, 14, 28999000),
    (CURRENT_DATE - 30,  NULL,               15, 28999000),   -- en curso
    -- Pablo Díaz: 1 obra en el último año
    (CURRENT_DATE - 330, CURRENT_DATE - 310, 3,  29888777);
