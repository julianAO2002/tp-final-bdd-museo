# TP Final - Base de Datos: Museo

Trabajo práctico final de **Base de Datos** — Licenciatura en Sistemas de la Información,
Facultad de Ciencia y Tecnología (UADER), Sede Concepción del Uruguay.

- **Docente:** Ing. Esteban Schab
- **Alumnos:** Pereyra Claudio David, Olivera Julián

## Contenido

| Archivo | Descripción |
|---------|-------------|
| [`01_creacion_bd.sql`](01_creacion_bd.sql) | Creación de la base `museo`: dominios, tablas, claves y restricciones. |
| [`02_triggers.sql`](02_triggers.sql) | Funciones y los 10 triggers definidos en el informe. |
| [`03_vistas.sql`](03_vistas.sql) | Vistas que resuelven las consultas C, E y F del enunciado. |
| [`04_carga_datos.sql`](04_carga_datos.sql) | Datos de prueba, con al menos 15 filas por tabla. |
| [`05_consultas.sql`](05_consultas.sql) | Consultas A a F del enunciado. |
| [`06_funciones.sql`](06_funciones.sql) | Una función por cada consulta del enunciado. |
| [`07_usuarios.sql`](07_usuarios.sql) | Usuarios `museo_admin` y `museo_consulta`, con distinto nivel de permisos. |
| [`08_pruebas.sql`](08_pruebas.sql) | Pruebas de triggers, usuarios, vistas y funciones. |
| [`backup/museo_backup.sql`](backup/museo_backup.sql) | Backup de la base con los datos de prueba cargados. |
| [`docs/BDD_TP_final_E1.pdf`](docs/BDD_TP_final_E1.pdf) | Informe: modelo relacional, diccionario de datos, dominios y triggers. |

## Modelo

Tablas: `autor`, `sala`, `obra`, `copia`, `empleado`, `funcion_empleado`,
`empleado_funcion` y `restauracion`.

Dominios: `t_id`, `t_dni`, `t_tipo_sala` (`muestra`, `almacenamiento`) y
`t_sensibilidad` (`humedad`, `fotosensibilidad`).

Vistas: `vw_restauradores_ultimos_6_meses` (consulta C), `vw_originales_por_sala`
(consulta E) y `vw_restauradores_antiguos_ultimo_anio` (consulta F).

## Triggers

| Trigger | Tabla | Qué controla |
|---------|-------|--------------|
| `trg_copia_fecha_creacion` | `copia` | La fecha de creación de la copia es la fecha de recuperación del original más 1 mes. |
| `trg_obra_actualiza_copia` | `obra` | Si cambia la fecha de recuperación, se recalcula la fecha de la copia. |
| `trg_obra_sala_valida` | `obra` | Los originales se guardan en salas de almacenamiento aptas para su sensibilidad. |
| `trg_copia_ubicacion` | `copia` | Una copia almacenada se guarda en la misma sala que su original. |
| `trg_restauracion_restaurador` | `restauracion` | El responsable tiene la función de restauración y ya había ingresado al museo. |
| `trg_restauracion_superposicion` | `restauracion` | Una obra no está en dos restauraciones a la vez. |
| `trg_obra_fechas` | `obra` | La fecha de recuperación no es futura. |
| `trg_copia_unica` | `copia` | Cada obra tiene una sola copia a la vez. |
| `trg_empleado_fechas` | `empleado` | La fecha de nacimiento es pasada y la fecha de ingreso no es futura. |
| `trg_restauracion_fecha_obra` | `restauracion` | Una obra no entra a restauración antes de ser recuperada. |

## Cómo ejecutarlo (PostgreSQL)

1. Crear la base (una sola vez), desde la base `postgres`:

   ```sql
   CREATE DATABASE museo ENCODING 'UTF8';
   ```

2. Conectarse a `museo` y ejecutar los scripts en orden:

   ```bash
   psql -U postgres -d museo -f 01_creacion_bd.sql
   psql -U postgres -d museo -f 02_triggers.sql
   psql -U postgres -d museo -f 03_vistas.sql
   psql -U postgres -d museo -f 04_carga_datos.sql
   psql -U postgres -d museo -f 05_consultas.sql
   psql -U postgres -d museo -f 06_funciones.sql
   psql -U postgres -d museo -f 07_usuarios.sql
   psql -U postgres -d museo -f 08_pruebas.sql
   ```

   En pgAdmin: abrir el Query Tool sobre `museo`, cargar cada archivo y ejecutarlo (F5).

Todos los scripts se pueden volver a ejecutar. `01_creacion_bd.sql` elimina las tablas,
los dominios y las vistas existentes, por lo que después hay que ejecutar nuevamente
los demás.

## Restaurar el backup

Como alternativa a ejecutar los scripts, el backup recrea las tablas, los triggers, las
vistas, las funciones y los datos en una base vacía:

```bash
psql -U postgres -d museo -f backup/museo_backup.sql
```

El backup no incluye los usuarios: se crean con `07_usuarios.sql`.

## Funciones

| Función | Consulta | Parámetros |
|---------|----------|------------|
| `fn_obras_restauradas_en_anio` | A | Año |
| `fn_obras_por_sector_de_restaurador` | B | DNI del restaurador |
| `fn_restauradores_ultimos_6_meses` | C | Ninguno |
| `fn_copias_de_autor` | D | Nombre y apellido del autor |
| `fn_originales_por_sala` | E | Ninguno |
| `fn_restauradores_antiguos_ultimo_anio` | F | Ninguno |

Uso: `SELECT * FROM fn_obras_restauradas_en_anio(2023);`

## Usuarios

| Usuario | Permisos |
|---------|----------|
| `museo_admin` | Lee y modifica los datos de todas las tablas. |
| `museo_consulta` | Solo lee las tablas y las vistas. |

## Pruebas

`08_pruebas.sql` prueba cada trigger con operaciones `INSERT`, `UPDATE` y `DELETE`, y los
permisos de cada usuario. Cada prueba informa el resultado esperado y el obtenido en un
mensaje, y todo se ejecuta dentro de una transacción que termina en `ROLLBACK`, por lo
que los datos no se modifican. Al final consulta las vistas y las funciones, con el
resultado esperado indicado en un comentario.

## Consultas

Las consultas A, B y D reciben un dato particular (año, restaurador o autor): se cambia
el valor indicado en el `WHERE` de cada una. Las consultas C, E y F se resuelven con
las vistas; C y F se calculan respecto de la fecha actual.
