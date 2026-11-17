-- =====================================================================
-- TP Final - Base de Datos (FCyT - UADER)
-- Usuarios de la base "museo"
-- Motor: PostgreSQL
--
-- Crea dos usuarios con distinto nivel de permisos:
--   museo_admin    : lee y modifica los datos de todas las tablas.
--   museo_consulta : solo lee las tablas y las vistas.
--
-- Ejecutar sobre la base "museo", con un usuario administrador (por
-- ejemplo postgres), después de 01_creacion_bd.sql y 03_vistas.sql.
-- Se puede volver a ejecutar: elimina los usuarios existentes antes de
-- crearlos. Si se vuelve a ejecutar 01_creacion_bd.sql, hay que ejecutar
-- este script de nuevo para otorgar los permisos sobre las tablas nuevas.
--
-- Las contraseñas son de prueba: cambiarlas antes de un uso real.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Elimina los usuarios si ya existen, junto con sus permisos
-- ---------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'museo_admin') THEN
        DROP OWNED BY museo_admin;
        DROP USER museo_admin;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'museo_consulta') THEN
        DROP OWNED BY museo_consulta;
        DROP USER museo_consulta;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- Creación de los usuarios
-- ---------------------------------------------------------------------
CREATE USER museo_admin    WITH PASSWORD 'admin123';
CREATE USER museo_consulta WITH PASSWORD 'consulta123';

-- ---------------------------------------------------------------------
-- museo_admin: lectura y modificación de datos.
-- Necesita las secuencias para insertar filas con id autoincremental.
-- ---------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO museo_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO museo_admin;

-- ---------------------------------------------------------------------
-- museo_consulta: solo lectura de tablas y vistas.
-- ---------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO museo_consulta;
