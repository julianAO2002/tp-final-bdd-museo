--
-- PostgreSQL database dump
--

\restrict J715Q5bq3Xl4Pk4ZQxuB5d6pd5Y9QMxDPP1gfQYWbi6AT2wUaKGhN8hk5OCTnPM

-- Dumped from database version 17.11
-- Dumped by pg_dump version 17.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: t_dni; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.t_dni AS integer
	CONSTRAINT ck_t_dni CHECK (((VALUE >= 0) AND (VALUE <= 99999999)));


--
-- Name: t_id; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.t_id AS integer
	CONSTRAINT ck_t_id CHECK ((VALUE > 0));


--
-- Name: t_sensibilidad; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.t_sensibilidad AS character varying(20)
	CONSTRAINT ck_t_sensibilidad CHECK (((VALUE)::text = ANY ((ARRAY['humedad'::character varying, 'fotosensibilidad'::character varying])::text[])));


--
-- Name: t_tipo_sala; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.t_tipo_sala AS character varying(20)
	CONSTRAINT ck_t_tipo_sala CHECK (((VALUE)::text = ANY ((ARRAY['muestra'::character varying, 'almacenamiento'::character varying])::text[])));


--
-- Name: fn_copia_fecha_creacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_copia_fecha_creacion() RETURNS trigger
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


--
-- Name: fn_copia_ubicacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_copia_ubicacion() RETURNS trigger
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


--
-- Name: fn_copia_unica(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_copia_unica() RETURNS trigger
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


--
-- Name: fn_copias_de_autor(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_copias_de_autor(p_nombre character varying, p_apellido character varying) RETURNS TABLE(id_copia integer, fecha_creacion date, obra_original character varying, sala_actual character varying, tipo_sala character varying)
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


--
-- Name: fn_empleado_fechas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_empleado_fechas() RETURNS trigger
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


--
-- Name: fn_obra_actualiza_copia(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obra_actualiza_copia() RETURNS trigger
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


--
-- Name: fn_obra_fechas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obra_fechas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.fecha_rec > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de recuperación no puede ser posterior a la fecha actual';
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: fn_obra_sala_valida(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obra_sala_valida() RETURNS trigger
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


--
-- Name: fn_obras_por_sector_de_restaurador(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obras_por_sector_de_restaurador(p_dni integer) RETURNS TABLE(dni integer, nombre character varying, apellido character varying, sector character varying, cantidad_obras bigint)
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


--
-- Name: fn_obras_restauradas_en_anio(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_obras_restauradas_en_anio(p_anio integer) RETURNS TABLE(id_obra integer, obra character varying, nombre_autor character varying, apellido_autor character varying, sensibilidad character varying)
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


--
-- Name: fn_originales_por_sala(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_originales_por_sala() RETURNS TABLE(id_sala integer, nombre character varying, especializacion character varying, cantidad_originales bigint)
    LANGUAGE sql
    AS $$
    SELECT v.id_sala,
           v.nombre,
           v.especializacion,
           v.cantidad_originales
      FROM vw_originales_por_sala v
     ORDER BY v.id_sala;
$$;


--
-- Name: fn_restauracion_fecha_obra(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_restauracion_fecha_obra() RETURNS trigger
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


--
-- Name: fn_restauracion_restaurador(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_restauracion_restaurador() RETURNS trigger
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


--
-- Name: fn_restauracion_superposicion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_restauracion_superposicion() RETURNS trigger
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


--
-- Name: fn_restauradores_antiguos_ultimo_anio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_restauradores_antiguos_ultimo_anio() RETURNS TABLE(dni integer, nombre character varying, apellido character varying, fecha_nac date, telefono character varying, email character varying, fecha_ingreso date, obras_restauradas bigint)
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


--
-- Name: fn_restauradores_ultimos_6_meses(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_restauradores_ultimos_6_meses() RETURNS TABLE(dni integer, nombre character varying, apellido character varying, email character varying, obras_restauradas bigint)
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: autor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.autor (
    id_autor integer NOT NULL,
    nombre character varying(40) NOT NULL,
    apellido character varying(40) NOT NULL,
    CONSTRAINT ck_autor_id CHECK ((id_autor > 0))
);


--
-- Name: autor_id_autor_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.autor ALTER COLUMN id_autor ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.autor_id_autor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: copia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.copia (
    id_copia integer NOT NULL,
    fecha_creacion date NOT NULL,
    id_obra public.t_id NOT NULL,
    id_sala public.t_id NOT NULL,
    CONSTRAINT ck_copia_id CHECK ((id_copia > 0))
);


--
-- Name: copia_id_copia_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.copia ALTER COLUMN id_copia ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.copia_id_copia_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: empleado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empleado (
    dni public.t_dni NOT NULL,
    nombre character varying(40) NOT NULL,
    apellido character varying(40) NOT NULL,
    fecha_nac date NOT NULL,
    telefono character varying(20),
    email character varying(40),
    fecha_ingreso date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT chk_empleado_fechas CHECK ((fecha_ingreso > fecha_nac))
);


--
-- Name: empleado_funcion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empleado_funcion (
    dni_empleado public.t_dni NOT NULL,
    id_funcion public.t_id NOT NULL
);


--
-- Name: funcion_empleado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.funcion_empleado (
    id_funcion integer NOT NULL,
    descripcion character varying(40) NOT NULL,
    CONSTRAINT ck_funcion_empleado_id CHECK ((id_funcion > 0))
);


--
-- Name: funcion_empleado_id_funcion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.funcion_empleado ALTER COLUMN id_funcion ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.funcion_empleado_id_funcion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: obra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.obra (
    id_obra integer NOT NULL,
    nombre character varying(200) NOT NULL,
    fecha_creacion date NOT NULL,
    fecha_rec date DEFAULT CURRENT_DATE NOT NULL,
    descripcion text,
    sensibilidad public.t_sensibilidad NOT NULL,
    id_autor public.t_id NOT NULL,
    id_sala public.t_id NOT NULL,
    CONSTRAINT chk_obra_fechas CHECK ((fecha_creacion <= fecha_rec)),
    CONSTRAINT ck_obra_id CHECK ((id_obra > 0))
);


--
-- Name: obra_id_obra_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.obra ALTER COLUMN id_obra ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.obra_id_obra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: restauracion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restauracion (
    id_restauracion integer NOT NULL,
    fecha_ingreso date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date,
    id_obra public.t_id NOT NULL,
    dni_empleado public.t_dni NOT NULL,
    CONSTRAINT chk_restauracion_fechas CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_ingreso))),
    CONSTRAINT ck_restauracion_id CHECK ((id_restauracion > 0))
);


--
-- Name: restauracion_id_restauracion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.restauracion ALTER COLUMN id_restauracion ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.restauracion_id_restauracion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sala; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sala (
    id_sala integer NOT NULL,
    nombre character varying(200) NOT NULL,
    tipo public.t_tipo_sala DEFAULT 'almacenamiento'::character varying NOT NULL,
    especializacion public.t_sensibilidad NOT NULL,
    CONSTRAINT ck_sala_id CHECK ((id_sala > 0))
);


--
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.sala ALTER COLUMN id_sala ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sala_id_sala_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vw_originales_por_sala; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_originales_por_sala AS
 SELECT s.id_sala,
    s.nombre,
    s.especializacion,
    count(o.id_obra) AS cantidad_originales
   FROM public.sala s,
    public.obra o
  WHERE (((o.id_sala)::integer = s.id_sala) AND ((s.tipo)::text = 'almacenamiento'::text))
  GROUP BY s.id_sala, s.nombre, s.especializacion;


--
-- Name: vw_restauradores_antiguos_ultimo_anio; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_restauradores_antiguos_ultimo_anio AS
 SELECT e.dni,
    e.nombre,
    e.apellido,
    e.fecha_nac,
    e.telefono,
    e.email,
    e.fecha_ingreso,
    count(DISTINCT r.id_obra) AS obras_restauradas
   FROM public.empleado e,
    public.restauracion r
  WHERE (((r.dni_empleado)::integer = (e.dni)::integer) AND (e.fecha_ingreso < (CURRENT_DATE - 1825)) AND (r.fecha_ingreso >= (CURRENT_DATE - 365)))
  GROUP BY e.dni, e.nombre, e.apellido, e.fecha_nac, e.telefono, e.email, e.fecha_ingreso
 HAVING (count(DISTINCT r.id_obra) >= 5);


--
-- Name: vw_restauradores_ultimos_6_meses; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_restauradores_ultimos_6_meses AS
 SELECT e.dni,
    e.nombre,
    e.apellido,
    e.email,
    count(DISTINCT r.id_obra) AS obras_restauradas
   FROM public.empleado e,
    public.restauracion r
  WHERE (((r.dni_empleado)::integer = (e.dni)::integer) AND (r.fecha_ingreso >= (CURRENT_DATE - 180)))
  GROUP BY e.dni, e.nombre, e.apellido, e.email
 HAVING (count(DISTINCT r.id_obra) >= 5);


--
-- Data for Name: autor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.autor (id_autor, nombre, apellido) FROM stdin;
1	Leonardo	da Vinci
2	Vincent	van Gogh
3	Claude	Monet
4	Rembrandt	van Rijn
5	Johannes	Vermeer
6	Eugène	Delacroix
7	Jacques-Louis	David
8	Théodore	Géricault
9	Jean-Auguste	Ingres
10	Paolo	Veronese
11	Rafael	Sanzio
12	Tiziano	Vecellio
13	Michelangelo	Caravaggio
14	Nicolas	Poussin
15	Antoine	Watteau
\.


--
-- Data for Name: copia; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.copia (id_copia, fecha_creacion, id_obra, id_sala) FROM stdin;
1	2010-05-12	1	4
2	2011-07-03	2	5
3	2012-10-20	3	1
4	2013-03-14	4	5
5	2014-06-30	5	3
6	2015-04-08	6	5
7	2015-12-22	7	3
8	2016-08-19	8	5
9	2017-02-10	9	1
10	2017-09-05	10	5
11	2018-04-27	11	4
12	2019-11-02	12	6
13	2020-06-15	13	4
14	2021-03-11	14	2
15	2022-09-30	15	4
16	2016-05-18	16	10
17	2017-12-06	17	11
18	2018-10-14	18	9
19	2019-04-22	19	13
20	2020-11-09	20	12
21	2021-07-28	21	15
22	2022-02-17	22	14
23	2023-05-03	23	8
\.


--
-- Data for Name: empleado; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.empleado (dni, nombre, apellido, fecha_nac, telefono, email, fecha_ingreso) FROM stdin;
30111222	Ana	Martínez	1980-05-14	3442-411111	amartinez@museo.org	2012-03-01
32444555	Lucas	Fernández	1992-09-03	3442-422222	lfernandez@museo.org	2023-11-18
28999000	Marta	Gómez	1975-01-22	3442-433333	mgomez@museo.org	2010-07-15
29888777	Pablo	Díaz	1978-11-30	\N	pdiaz@museo.org	2015-02-01
35666777	Diego	Ruiz	1990-04-18	3442-455555	\N	2018-06-10
33222111	Laura	Sosa	1985-12-05	3442-466666	lsosa@museo.org	2016-09-01
36777888	Sofía	Pereyra	1995-07-07	3442-477777	spereyra@museo.org	2021-04-01
27555444	Carlos	Benítez	1972-03-11	3442-488888	cbenitez@museo.org	2009-05-04
31222333	Valeria	Acosta	1984-08-27	3442-499999	vacosta@museo.org	2014-10-20
34111999	Martín	Ríos	1989-02-15	\N	mrios@museo.org	2019-03-18
37888222	Camila	Vega	1996-10-09	3442-412345	cvega@museo.org	2022-07-01
26444111	Jorge	Molina	1970-06-30	3442-423456	\N	2008-02-11
38555666	Julieta	Navarro	1998-01-19	3442-434567	jnavarro@museo.org	2023-09-04
29333888	Hernán	Castro	1977-12-02	3442-445678	hcastro@museo.org	2013-06-17
33999444	Florencia	Luna	1987-05-23	3442-456789	fluna@museo.org	2017-11-27
\.


--
-- Data for Name: empleado_funcion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.empleado_funcion (dni_empleado, id_funcion) FROM stdin;
30111222	2
32444555	2
28999000	2
29888777	2
29888777	3
35666777	1
33222111	3
36777888	4
36777888	1
27555444	1
31222333	2
34111999	4
37888222	3
26444111	6
38555666	4
38555666	10
29333888	7
33999444	8
33999444	2
\.


--
-- Data for Name: funcion_empleado; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.funcion_empleado (id_funcion, descripcion) FROM stdin;
1	seguridad
2	restauracion
3	administracion
4	guia
5	limpieza
6	mantenimiento
7	curaduria
8	conservacion
9	educacion
10	boleteria
11	catalogacion
12	iluminacion
13	transporte
14	prensa
15	direccion
\.


--
-- Data for Name: obra; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.obra (id_obra, nombre, fecha_creacion, fecha_rec, descripcion, sensibilidad, id_autor, id_sala) FROM stdin;
1	La Gioconda	1503-10-01	2010-04-12	Retrato de Lisa Gherardini, óleo sobre tabla de álamo.	humedad	1	1
2	La Virgen de las Rocas	1483-04-25	2011-06-03	Óleo sobre tabla trasladado a lienzo.	fotosensibilidad	1	2
3	San Juan Bautista	1513-01-01	2012-09-20	Último cuadro conocido de Leonardo.	humedad	1	1
4	Autorretrato con sombrero de fieltro	1887-01-01	2013-02-14	Autorretrato de su etapa en París.	fotosensibilidad	2	2
5	La iglesia de Auvers	1890-06-01	2014-05-30	Pintado en Auvers-sur-Oise.	humedad	2	3
6	Impresión, sol naciente	1872-11-13	2015-03-08	Obra que dio nombre al impresionismo.	fotosensibilidad	3	6
7	Nenúfares	1906-01-01	2015-11-22	Serie del estanque de Giverny.	humedad	3	3
8	Los peregrinos de Emaús	1648-01-01	2016-07-19	Escena bíblica con luz dorada característica.	fotosensibilidad	4	2
9	Betsabé en el baño	1654-01-01	2017-01-10	Óleo sobre lienzo de gran formato.	humedad	4	1
10	La encajera	1669-01-01	2017-08-05	Pequeño óleo sobre lienzo montado en tabla.	fotosensibilidad	5	6
11	El astrónomo	1668-01-01	2018-03-27	Erudito estudiando un globo celeste.	humedad	5	3
12	La libertad guiando al pueblo	1830-01-01	2019-10-02	Alegoría de la Revolución de Julio.	fotosensibilidad	6	6
13	La muerte de Sardanápalo	1827-01-01	2020-05-15	Escena orientalista de gran tamaño.	humedad	6	1
14	La coronación de Napoleón	1807-01-01	2021-02-11	Consagración del emperador en Notre-Dame.	fotosensibilidad	7	2
15	El juramento de los Horacios	1784-01-01	2022-08-30	Obra emblemática del neoclasicismo.	humedad	7	3
16	La balsa de la Medusa	1819-01-01	2016-04-18	Naufragio de la fragata Méduse.	humedad	8	9
17	La gran odalisca	1814-01-01	2017-11-06	Desnudo de inspiración orientalista.	fotosensibilidad	9	8
18	Las bodas de Caná	1563-01-01	2018-09-14	El lienzo de mayor tamaño del museo.	humedad	10	9
19	Retrato de Baltasar Castiglione	1515-01-01	2019-03-22	Retrato del diplomático y humanista.	fotosensibilidad	11	8
20	Concierto campestre	1509-01-01	2020-10-09	Escena pastoral veneciana.	humedad	12	7
21	La muerte de la Virgen	1606-01-01	2021-06-28	Óleo de fuerte claroscuro.	fotosensibilidad	13	15
22	Los pastores de Arcadia	1638-01-01	2022-01-17	Pastores ante una tumba en un paisaje clásico.	humedad	14	9
23	Peregrinación a la isla de Citera	1717-01-01	2023-04-03	Fiesta galante en un paisaje idealizado.	fotosensibilidad	15	8
\.


--
-- Data for Name: restauracion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.restauracion (id_restauracion, fecha_ingreso, fecha_fin, id_obra, dni_empleado) FROM stdin;
1	2019-02-01	2019-05-30	1	28999000
2	2022-08-01	2022-10-01	9	29888777
3	2023-03-10	2023-07-20	8	28999000
4	2023-05-02	2023-06-15	5	30111222
5	2023-11-15	2024-02-10	12	29888777
6	2026-01-21	2026-03-02	2	30111222
7	2026-05-31	2026-06-25	1	30111222
8	2026-06-30	2026-07-25	3	30111222
9	2026-07-30	2026-08-24	4	30111222
10	2026-08-29	2026-09-23	6	30111222
11	2026-10-28	\N	7	30111222
12	2026-06-10	2026-07-10	2	32444555
13	2026-07-15	2026-08-09	9	32444555
14	2026-08-14	2026-09-08	10	32444555
15	2026-09-13	2026-10-08	11	32444555
16	2026-10-13	2026-11-07	13	32444555
17	2026-05-01	2026-06-20	14	28999000
18	2026-10-18	\N	15	28999000
19	2025-12-22	2026-01-11	3	29888777
\.


--
-- Data for Name: sala; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sala (id_sala, nombre, tipo, especializacion) FROM stdin;
1	Depósito Seco Denon	almacenamiento	humedad
2	Depósito Oscuro Richelieu	almacenamiento	fotosensibilidad
3	Depósito Seco Sully	almacenamiento	humedad
4	Gran Galería	muestra	humedad
5	Sala de los Estados	muestra	fotosensibilidad
6	Depósito Oscuro Sully	almacenamiento	fotosensibilidad
7	Depósito de Reserva	almacenamiento	humedad
8	Depósito Oscuro Denon	almacenamiento	fotosensibilidad
9	Depósito Seco Richelieu	almacenamiento	humedad
10	Sala Mollien	muestra	humedad
11	Sala Daru	muestra	fotosensibilidad
12	Galería de Apolo	muestra	humedad
13	Sala Rubens	muestra	fotosensibilidad
14	Sala de Pintura Francesa	muestra	humedad
15	Depósito de Tránsito	almacenamiento	fotosensibilidad
\.


--
-- Name: autor_id_autor_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.autor_id_autor_seq', 17, true);


--
-- Name: copia_id_copia_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.copia_id_copia_seq', 23, true);


--
-- Name: funcion_empleado_id_funcion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.funcion_empleado_id_funcion_seq', 15, true);


--
-- Name: obra_id_obra_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.obra_id_obra_seq', 23, true);


--
-- Name: restauracion_id_restauracion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.restauracion_id_restauracion_seq', 19, true);


--
-- Name: sala_id_sala_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sala_id_sala_seq', 15, true);


--
-- Name: autor pk_autor; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.autor
    ADD CONSTRAINT pk_autor PRIMARY KEY (id_autor);


--
-- Name: copia pk_copia; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT pk_copia PRIMARY KEY (id_copia);


--
-- Name: empleado pk_empleado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (dni);


--
-- Name: empleado_funcion pk_empleado_funcion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado_funcion
    ADD CONSTRAINT pk_empleado_funcion PRIMARY KEY (dni_empleado, id_funcion);


--
-- Name: funcion_empleado pk_funcion_empleado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.funcion_empleado
    ADD CONSTRAINT pk_funcion_empleado PRIMARY KEY (id_funcion);


--
-- Name: obra pk_obra; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obra
    ADD CONSTRAINT pk_obra PRIMARY KEY (id_obra);


--
-- Name: restauracion pk_restauracion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restauracion
    ADD CONSTRAINT pk_restauracion PRIMARY KEY (id_restauracion);


--
-- Name: sala pk_sala; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sala
    ADD CONSTRAINT pk_sala PRIMARY KEY (id_sala);


--
-- Name: copia trg_copia_fecha_creacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_copia_fecha_creacion BEFORE INSERT OR UPDATE OF id_obra ON public.copia FOR EACH ROW EXECUTE FUNCTION public.fn_copia_fecha_creacion();


--
-- Name: copia trg_copia_ubicacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_copia_ubicacion BEFORE INSERT OR UPDATE OF id_sala ON public.copia FOR EACH ROW EXECUTE FUNCTION public.fn_copia_ubicacion();


--
-- Name: copia trg_copia_unica; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_copia_unica BEFORE INSERT OR UPDATE OF id_obra ON public.copia FOR EACH ROW EXECUTE FUNCTION public.fn_copia_unica();


--
-- Name: empleado trg_empleado_fechas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_empleado_fechas BEFORE INSERT OR UPDATE OF fecha_nac, fecha_ingreso ON public.empleado FOR EACH ROW EXECUTE FUNCTION public.fn_empleado_fechas();


--
-- Name: obra trg_obra_actualiza_copia; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_obra_actualiza_copia AFTER UPDATE OF fecha_rec ON public.obra FOR EACH ROW EXECUTE FUNCTION public.fn_obra_actualiza_copia();


--
-- Name: obra trg_obra_fechas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_obra_fechas BEFORE INSERT OR UPDATE OF fecha_rec ON public.obra FOR EACH ROW EXECUTE FUNCTION public.fn_obra_fechas();


--
-- Name: obra trg_obra_sala_valida; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_obra_sala_valida BEFORE INSERT OR UPDATE OF id_sala, sensibilidad ON public.obra FOR EACH ROW EXECUTE FUNCTION public.fn_obra_sala_valida();


--
-- Name: restauracion trg_restauracion_fecha_obra; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_restauracion_fecha_obra BEFORE INSERT OR UPDATE OF fecha_ingreso, id_obra ON public.restauracion FOR EACH ROW EXECUTE FUNCTION public.fn_restauracion_fecha_obra();


--
-- Name: restauracion trg_restauracion_restaurador; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_restauracion_restaurador BEFORE INSERT OR UPDATE OF dni_empleado, fecha_ingreso ON public.restauracion FOR EACH ROW EXECUTE FUNCTION public.fn_restauracion_restaurador();


--
-- Name: restauracion trg_restauracion_superposicion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_restauracion_superposicion BEFORE INSERT OR UPDATE OF fecha_ingreso, fecha_fin, id_obra ON public.restauracion FOR EACH ROW EXECUTE FUNCTION public.fn_restauracion_superposicion();


--
-- Name: copia fk_copia_obra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT fk_copia_obra FOREIGN KEY (id_obra) REFERENCES public.obra(id_obra);


--
-- Name: copia fk_copia_sala; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT fk_copia_sala FOREIGN KEY (id_sala) REFERENCES public.sala(id_sala);


--
-- Name: empleado_funcion fk_empleado_funcion_empleado; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado_funcion
    ADD CONSTRAINT fk_empleado_funcion_empleado FOREIGN KEY (dni_empleado) REFERENCES public.empleado(dni);


--
-- Name: empleado_funcion fk_empleado_funcion_funcion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleado_funcion
    ADD CONSTRAINT fk_empleado_funcion_funcion FOREIGN KEY (id_funcion) REFERENCES public.funcion_empleado(id_funcion);


--
-- Name: obra fk_obra_autor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obra
    ADD CONSTRAINT fk_obra_autor FOREIGN KEY (id_autor) REFERENCES public.autor(id_autor);


--
-- Name: obra fk_obra_sala; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obra
    ADD CONSTRAINT fk_obra_sala FOREIGN KEY (id_sala) REFERENCES public.sala(id_sala);


--
-- Name: restauracion fk_restauracion_empleado; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restauracion
    ADD CONSTRAINT fk_restauracion_empleado FOREIGN KEY (dni_empleado) REFERENCES public.empleado(dni);


--
-- Name: restauracion fk_restauracion_obra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restauracion
    ADD CONSTRAINT fk_restauracion_obra FOREIGN KEY (id_obra) REFERENCES public.obra(id_obra);


--
-- PostgreSQL database dump complete
--

\unrestrict J715Q5bq3Xl4Pk4ZQxuB5d6pd5Y9QMxDPP1gfQYWbi6AT2wUaKGhN8hk5OCTnPM

