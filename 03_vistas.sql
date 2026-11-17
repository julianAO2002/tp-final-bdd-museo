-- Vista 1: información detallada de las obras

CREATE OR REPLACE VIEW vw_obras_detalle AS
SELECT
    o.id_obra,
    o.nombre AS obra,
    o.fecha_creacion,
    o.fecha_rec,
    o.sensibilidad,
    a.nombre AS nombre_autor,
    a.apellido AS apellido_autor,
    s.nombre AS sala,
    s.tipo AS tipo_sala
FROM obra o
JOIN autor a
    ON o.id_autor = a.id_autor
JOIN sala s
    ON o.id_sala = s.id_sala;



-- Vista 2: información detallada de las copias

CREATE OR REPLACE VIEW vw_copias_detalle AS
SELECT
    c.id_copia,
    o.nombre AS obra_original,
    a.nombre AS nombre_autor,
    a.apellido AS apellido_autor,
    c.fecha_creacion,
    s.nombre AS sala_copia,
    s.tipo AS tipo_sala
FROM copia c
JOIN obra o
    ON c.id_obra = o.id_obra
JOIN autor a
    ON o.id_autor = a.id_autor
JOIN sala s
    ON c.id_sala = s.id_sala; 

-- Vista 3: información detallada de las restauraciones

CREATE OR REPLACE VIEW vw_restauraciones_detalle AS
SELECT
    r.id_restauracion,
    o.nombre AS obra,
    e.nombre AS nombre_empleado,
    e.apellido AS apellido_empleado,
    r.fecha_ingreso AS fecha_inicio,
    r.fecha_fin
FROM restauracion r
JOIN obra o
    ON r.id_obra = o.id_obra
JOIN empleado e
    ON r.dni_empleado = e.dni;
