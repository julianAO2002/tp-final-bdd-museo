# TP Final - Base de Datos: Museo

Trabajo práctico final de **Base de Datos** — Licenciatura en Sistemas de la Información,
Facultad de Ciencia y Tecnología (UADER), Sede Concepción del Uruguay.

- **Docente:** Ing. Esteban Schab
- **Alumnos:** Uriarte Agustín, Pereyra Claudio David, Olivera Julián

## Contenido

| Archivo | Descripción |
|---------|-------------|
| [`01_creacion_bd.sql`](01_creacion_bd.sql) | Script de creación de la base `museo` (punto 4): dominios, tablas, claves y restricciones. |
| [`docs/BDD_TP_final_E1.pdf`](docs/BDD_TP_final_E1.pdf) | Informe: modelo relacional, diccionario de datos, dominios y triggers. |

## Modelo

Tablas: `autor`, `sala`, `obra`, `copia`, `empleado`, `funcion_empleado`,
`empleado_funcion` y `restauracion`.

Dominios: `t_id`, `t_dni`, `t_tipo_sala` (`muestra`, `almacenamiento`) y
`t_sensibilidad` (`humedad`, `fotosensibilidad`).

## Cómo ejecutarlo (PostgreSQL)

1. Crear la base (una sola vez), desde la base `postgres`:

   ```sql
   CREATE DATABASE museo ENCODING 'UTF8';
   ```

2. Conectarse a `museo` y ejecutar el script:

   ```bash
   psql -U postgres -d museo -f 01_creacion_bd.sql
   ```

   En pgAdmin: abrir el Query Tool sobre `museo`, cargar el archivo y ejecutar (F5).

El script se puede volver a ejecutar: primero elimina las tablas y dominios existentes.
