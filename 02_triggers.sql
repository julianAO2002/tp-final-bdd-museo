-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Triggers de la base "museo"
-- Motor: PostgreSQL
--
-- Ejecutar sobre la base "museo" después de 01_creacion_bd.sql.
-- Se puede volver a ejecutar: reemplaza funciones y triggers existentes.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. trg_copia_fecha_creacion
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- Asigna fecha_creacion = OBRA.fecha_rec + 1 mes, ignorando el valor
-- enviado.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_copia_fecha_creacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_rec obra.fecha_rec%TYPE;
BEGIN
    SELECT o.fecha_rec
      INTO v_fecha_rec
      FROM obra o
     WHERE o.id_obra = NEW.id_obra;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La obra original no existe';
    END IF;

    NEW.fecha_creacion := (v_fecha_rec + INTERVAL '1 month')::DATE;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_copia_fecha_creacion ON copia;
CREATE TRIGGER trg_copia_fecha_creacion
    BEFORE INSERT OR UPDATE ON copia
    FOR EACH ROW
    EXECUTE FUNCTION fn_copia_fecha_creacion();

-- ---------------------------------------------------------------------
-- 2. trg_obra_actualiza_copia
-- Tabla: OBRA - AFTER UPDATE
-- Si cambió la fecha de recuperación, recalcula fecha_creacion de las
-- copias de la obra. Si no cambió, no hace nada.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obra_actualiza_copia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_rec IS DISTINCT FROM OLD.fecha_rec THEN
        UPDATE copia
           SET fecha_creacion = (NEW.fecha_rec + INTERVAL '1 month')::DATE
         WHERE id_obra = NEW.id_obra;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_obra_actualiza_copia ON obra;
CREATE TRIGGER trg_obra_actualiza_copia
    AFTER UPDATE ON obra
    FOR EACH ROW
    EXECUTE FUNCTION fn_obra_actualiza_copia();

-- ---------------------------------------------------------------------
-- 3. trg_obra_sala_valida
-- Tabla: OBRA - BEFORE INSERT OR UPDATE
-- Los originales solo se guardan en salas de almacenamiento cuya
-- especialización coincida con la sensibilidad de la obra.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obra_sala_valida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo            sala.tipo%TYPE;
    v_especializacion sala.especializacion%TYPE;
BEGIN
    SELECT s.tipo, s.especializacion
      INTO v_tipo, v_especializacion
      FROM sala s
     WHERE s.id_sala = NEW.id_sala;

    -- Sala inexistente: la rechaza la clave foránea fk_obra_sala.
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF v_tipo <> 'almacenamiento' THEN
        RAISE EXCEPTION 'Los originales solo pueden guardarse en salas de almacenamiento';
    END IF;

    IF v_especializacion <> NEW.sensibilidad THEN
        RAISE EXCEPTION 'La sala no corresponde a la sensibilidad de la obra';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obra_sala_valida ON obra;
CREATE TRIGGER trg_obra_sala_valida
    BEFORE INSERT OR UPDATE ON obra
    FOR EACH ROW
    EXECUTE FUNCTION fn_obra_sala_valida();

-- ---------------------------------------------------------------------
-- 4. trg_copia_ubicacion
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- Una copia en una sala de almacenamiento debe estar en la misma sala
-- que su original; en una sala de muestra se acepta.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_copia_ubicacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo          sala.tipo%TYPE;
    v_sala_original obra.id_sala%TYPE;
BEGIN
    SELECT s.tipo
      INTO v_tipo
      FROM sala s
     WHERE s.id_sala = NEW.id_sala;

    -- Sala inexistente: la rechaza la clave foránea fk_copia_sala.
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF v_tipo = 'almacenamiento' THEN
        SELECT o.id_sala
          INTO v_sala_original
          FROM obra o
         WHERE o.id_obra = NEW.id_obra;

        IF v_sala_original IS DISTINCT FROM NEW.id_sala THEN
            RAISE EXCEPTION 'Una copia almacenada debe guardarse en la misma sala que su original';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_copia_ubicacion ON copia;
CREATE TRIGGER trg_copia_ubicacion
    BEFORE INSERT OR UPDATE ON copia
    FOR EACH ROW
    EXECUTE FUNCTION fn_copia_ubicacion();

-- ---------------------------------------------------------------------
-- 5. trg_restauracion_restaurador
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- El responsable debe tener la función 'restauracion' y la restauración
-- no puede ser anterior a su ingreso al museo.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_restauracion_restaurador()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_ingreso_empleado empleado.fecha_ingreso%TYPE;
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM empleado_funcion ef
          JOIN funcion_empleado f ON f.id_funcion = ef.id_funcion
         WHERE ef.dni_empleado = NEW.dni_empleado
           AND LOWER(f.descripcion) = 'restauracion'
    ) THEN
        RAISE EXCEPTION 'El empleado no tiene la función de restaurador';
    END IF;

    SELECT e.fecha_ingreso
      INTO v_fecha_ingreso_empleado
      FROM empleado e
     WHERE e.dni = NEW.dni_empleado;

    IF NEW.fecha_ingreso < v_fecha_ingreso_empleado THEN
        RAISE EXCEPTION 'La restauración es anterior al ingreso del empleado';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restauracion_restaurador ON restauracion;
CREATE TRIGGER trg_restauracion_restaurador
    BEFORE INSERT OR UPDATE ON restauracion
    FOR EACH ROW
    EXECUTE FUNCTION fn_restauracion_restaurador();

-- ---------------------------------------------------------------------
-- 6. trg_restauracion_superposicion
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- Una obra no puede estar en dos restauraciones a la vez. Una
-- restauración con fecha_fin NULL se considera abierta hasta hoy.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_restauracion_superposicion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM restauracion r
         WHERE r.id_obra = NEW.id_obra
           AND r.id_restauracion IS DISTINCT FROM NEW.id_restauracion
           AND r.fecha_ingreso <= GREATEST(COALESCE(NEW.fecha_fin, CURRENT_DATE),
                                           NEW.fecha_ingreso)
           AND NEW.fecha_ingreso <= GREATEST(COALESCE(r.fecha_fin, CURRENT_DATE),
                                             r.fecha_ingreso)
    ) THEN
        RAISE EXCEPTION 'La obra ya tiene una restauración en curso o superpuesta en esas fechas';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restauracion_superposicion ON restauracion;
CREATE TRIGGER trg_restauracion_superposicion
    BEFORE INSERT OR UPDATE ON restauracion
    FOR EACH ROW
    EXECUTE FUNCTION fn_restauracion_superposicion();

-- ---------------------------------------------------------------------
-- 7. trg_obra_fechas
-- Tabla: OBRA - BEFORE INSERT OR UPDATE
-- La fecha de recuperación no puede ser futura.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_obra_fechas()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_rec > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de recuperación no puede ser posterior a la fecha actual';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obra_fechas ON obra;
CREATE TRIGGER trg_obra_fechas
    BEFORE INSERT OR UPDATE ON obra
    FOR EACH ROW
    EXECUTE FUNCTION fn_obra_fechas();

-- ---------------------------------------------------------------------
-- 8. trg_copia_unica
-- Tabla: COPIA - BEFORE INSERT OR UPDATE
-- Cada obra tiene una sola copia a la vez.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_copia_unica()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM copia c
         WHERE c.id_obra = NEW.id_obra
           AND c.id_copia <> NEW.id_copia
    ) THEN
        RAISE EXCEPTION 'La obra ya tiene una copia registrada';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_copia_unica ON copia;
CREATE TRIGGER trg_copia_unica
    BEFORE INSERT OR UPDATE ON copia
    FOR EACH ROW
    EXECUTE FUNCTION fn_copia_unica();

-- ---------------------------------------------------------------------
-- 9. trg_empleado_fechas
-- Tabla: EMPLEADO - BEFORE INSERT OR UPDATE
-- La fecha de nacimiento debe ser pasada y la fecha de ingreso no puede
-- ser futura.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_empleado_fechas()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.fecha_nac >= CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento debe ser anterior a la fecha actual';
    END IF;

    IF NEW.fecha_ingreso > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de ingreso no puede ser posterior a la fecha actual';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_empleado_fechas ON empleado;
CREATE TRIGGER trg_empleado_fechas
    BEFORE INSERT OR UPDATE ON empleado
    FOR EACH ROW
    EXECUTE FUNCTION fn_empleado_fechas();

-- ---------------------------------------------------------------------
-- 10. trg_restauracion_fecha_obra
-- Tabla: RESTAURACION - BEFORE INSERT OR UPDATE
-- Una obra no entra a restauración antes de haber sido recuperada por
-- el museo.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_restauracion_fecha_obra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_rec obra.fecha_rec%TYPE;
BEGIN
    SELECT o.fecha_rec
      INTO v_fecha_rec
      FROM obra o
     WHERE o.id_obra = NEW.id_obra;

    IF NEW.fecha_ingreso < v_fecha_rec THEN
        RAISE EXCEPTION 'La restauración no puede ser anterior a la recuperación de la obra';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restauracion_fecha_obra ON restauracion;
CREATE TRIGGER trg_restauracion_fecha_obra
    BEFORE INSERT OR UPDATE ON restauracion
    FOR EACH ROW
    EXECUTE FUNCTION fn_restauracion_fecha_obra();
