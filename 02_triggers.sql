-- Trigger 1: calcular la fecha de creación de una copia

CREATE OR REPLACE FUNCTION fn_copia_fecha_creacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT fecha_rec + INTERVAL '1 month'
    INTO NEW.fecha_creacion
    FROM obra
    WHERE id_obra = NEW.id_obra;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La obra original no existe';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_copia_fecha_creacion
BEFORE INSERT OR UPDATE OF id_obra
ON copia
FOR EACH ROW
EXECUTE FUNCTION fn_copia_fecha_creacion();

-- Trigger 2: actualizar la fecha de las copias

CREATE OR REPLACE FUNCTION fn_obra_actualiza_copia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE copia
    SET fecha_creacion = NEW.fecha_rec + INTERVAL '1 month'
    WHERE id_obra = NEW.id_obra;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_obra_actualiza_copia
AFTER UPDATE OF fecha_rec
ON obra
FOR EACH ROW
EXECUTE FUNCTION fn_obra_actualiza_copia();

-- Trigger 3: validar la sala de una obra

CREATE OR REPLACE FUNCTION fn_obra_sala_valida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    tipo_sala t_tipo_sala;
    sensibilidad_sala t_sensibilidad;
BEGIN
    SELECT tipo, especializacion
    INTO tipo_sala, sensibilidad_sala
    FROM sala
    WHERE id_sala = NEW.id_sala;

    IF tipo_sala IS DISTINCT FROM 'almacenamiento'
       OR sensibilidad_sala IS DISTINCT FROM NEW.sensibilidad THEN
        RAISE EXCEPTION 'La sala debe ser de almacenamiento y coincidir con la sensibilidad de la obra';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_obra_sala_valida
BEFORE INSERT OR UPDATE OF id_sala, sensibilidad
ON obra
FOR EACH ROW
EXECUTE FUNCTION fn_obra_sala_valida();

-- Trigger 4: validar la ubicación de una copia

CREATE OR REPLACE FUNCTION fn_copia_ubicacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    tipo_sala t_tipo_sala;
    sala_original INTEGER;
BEGIN
    SELECT tipo
    INTO tipo_sala
    FROM sala
    WHERE id_sala = NEW.id_sala;

    SELECT id_sala
    INTO sala_original
    FROM obra
    WHERE id_obra = NEW.id_obra;

    IF tipo_sala = 'almacenamiento'
       AND NEW.id_sala <> sala_original THEN
        RAISE EXCEPTION 'La copia debe estar en la misma sala de almacenamiento que la obra original';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_copia_ubicacion
BEFORE INSERT OR UPDATE OF id_sala, id_obra
ON copia
FOR EACH ROW
EXECUTE FUNCTION fn_copia_ubicacion();


-- Trigger 5: validar el empleado que realiza una restauración

CREATE OR REPLACE FUNCTION fn_restauracion_restaurador()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    ingreso_empleado DATE;
BEGIN
    SELECT fecha_ingreso
    INTO ingreso_empleado
    FROM empleado
    WHERE dni = NEW.dni_empleado;

    IF NEW.fecha_ingreso < ingreso_empleado THEN
        RAISE EXCEPTION 'La restauración no puede comenzar antes del ingreso del empleado';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM empleado_funcion ef
        JOIN funcion_empleado f
            ON ef.id_funcion = f.id_funcion
        WHERE ef.dni_empleado = NEW.dni_empleado
          AND f.descripcion = 'restauracion'
    ) THEN
        RAISE EXCEPTION 'El empleado no tiene asignada la función de restauración';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_restauracion_restaurador
BEFORE INSERT OR UPDATE OF dni_empleado, fecha_ingreso
ON restauracion
FOR EACH ROW
EXECUTE FUNCTION fn_restauracion_restaurador();


-- Trigger 6: evitar restauraciones superpuestas

CREATE OR REPLACE FUNCTION fn_restauracion_superposicion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM restauracion
        WHERE id_obra = NEW.id_obra
          AND id_restauracion <> NEW.id_restauracion
          AND fecha_ingreso <= COALESCE(NEW.fecha_fin, 'infinity'::date)
          AND COALESCE(fecha_fin, 'infinity'::date) >= NEW.fecha_ingreso
    ) THEN
        RAISE EXCEPTION 'La obra ya tiene una restauración en ese período';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_restauracion_superposicion
BEFORE INSERT OR UPDATE OF fecha_ingreso, fecha_fin, id_obra
ON restauracion
FOR EACH ROW
EXECUTE FUNCTION fn_restauracion_superposicion();


-- Trigger 7: validar la fecha de recuperación de una obra

CREATE OR REPLACE FUNCTION fn_obra_fechas()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_rec > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de recuperación no puede ser futura';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_obra_fechas
BEFORE INSERT OR UPDATE OF fecha_rec
ON obra
FOR EACH ROW
EXECUTE FUNCTION fn_obra_fechas();


-- Trigger 8: impedir más de una copia por obra original

CREATE OR REPLACE FUNCTION fn_copia_unica()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM copia
        WHERE id_obra = NEW.id_obra
          AND id_copia <> NEW.id_copia
    ) THEN
        RAISE EXCEPTION 'La obra original ya tiene una copia registrada';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_copia_unica
BEFORE INSERT OR UPDATE OF id_obra
ON copia
FOR EACH ROW
EXECUTE FUNCTION fn_copia_unica();


-- Trigger 9: validar las fechas de un empleado

CREATE OR REPLACE FUNCTION fn_empleado_fechas()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_nac >= CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento debe ser anterior a la fecha actual';
    END IF;

    IF NEW.fecha_ingreso > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de ingreso no puede ser futura';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_empleado_fechas
BEFORE INSERT OR UPDATE OF fecha_nac, fecha_ingreso
ON empleado
FOR EACH ROW
EXECUTE FUNCTION fn_empleado_fechas();

-- Trigger 10: validar la fecha de restauración de una obra

CREATE OR REPLACE FUNCTION fn_restauracion_fecha_obra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    fecha_recuperacion DATE;
BEGIN
    SELECT fecha_rec
    INTO fecha_recuperacion
    FROM obra
    WHERE id_obra = NEW.id_obra;

    IF NEW.fecha_ingreso < fecha_recuperacion THEN
        RAISE EXCEPTION 'La restauración no puede comenzar antes de la recuperación de la obra';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_restauracion_fecha_obra
BEFORE INSERT OR UPDATE OF fecha_ingreso, id_obra
ON restauracion
FOR EACH ROW
EXECUTE FUNCTION fn_restauracion_fecha_obra();


