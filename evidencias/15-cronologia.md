# Reconstruir la cronología y responder a Dirección

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente (línea o `id_evento`) |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-08 17:46:07 | PostgreSQL | Localhost | Configuración | El servidor PostgreSQL 18.6 inició y comenzó a escuchar en IPv4 `127.0.0.1` e IPv6 `::1`, puerto 5432. | Sí | 17:46:07.390 |
| 2 | 2026-11-08 17:48:25 | postgres | Local | Acceso | El administrador `postgres` se autenticó correctamente mediante el método Peer. | Sí | 17:48:25.966 |
| 3 | 2026-11-08 17:48:42 | postgres | Local | Error | Se intentó ejecutar el comando `ls` dentro de PostgreSQL, provocando un error de sintaxis. | No | 17:48:42.718 |
| 4 | 2026-11-08 17:49:04 | postgres | Local | Datos | Se insertó el cliente Pedro Ruiz con RFC `RUPE950101AAA`. | Sí | `id_evento = 2` |
| 5 | 2026-11-08 17:49:04 | postgres | Local | Datos | Se eliminó el registro de Pedro Ruiz de la tabla `clientes`. | Sí | `id_evento = 3` |
| 6 | 2026-11-08 17:52:51 | app_ventas | 127.0.0.1 | Acceso | El usuario `app_ventas` se autenticó correctamente, pero la conexión falló porque la base de datos `comercial` no existía. | No | 17:52:51.038 |
| 7 | 2026-11-08 17:52:55 | postgres | Local | Datos | Se ejecutó un `UPDATE` masivo para establecer el segmento de todos los clientes como `regular`. | Sí | 17:52:55.639 |
| 8 | 2026-11-08 17:53:29 | app_ventas | 127.0.0.1 | Privilegio | Se intentó eliminar los registros de auditoría, pero PostgreSQL rechazó la operación por falta de permisos sobre el esquema `auditoria`. | No | 17:53:29.932 |
| 9 | 2026-11-08 17:53:29 | app_ventas | 127.0.0.1 | Estructura | Se intentó desactivar el disparador `trg_auditoria_clientes`, pero PostgreSQL rechazó la operación porque el usuario no era propietario de la tabla. | No | 17:53:29.934 |
| 10 | 2026-11-08 18:02:48 | soporte_ana | 127.0.0.1 | Acceso | El usuario de soporte se autenticó correctamente mediante SCRAM-SHA-256. La lectura de datos sensibles no quedó registrada en la bitácora. | Sí (conexión) | 18:02:48.392 |
| 11 | 2026-11-08 18:06:44 | postgres | Local | Error | Falló un intento de autenticación Peer porque el usuario del sistema operativo `bryan` no coincidía con el usuario PostgreSQL `postgres`. | No | 18:06:44.421 |
| 12 | 2026-11-08 18:11:41 | postgres | Local | Acceso | El administrador se autenticó correctamente mediante Peer y accedió a la base `db_20406894_bryan_zavala`. | Sí | 18:11:41.349 |



## Respuestas a Dirección — Basadas en la evidencia

**1. ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**

- **Primera modificación registrada:** `app_ventas`, mediante la aplicación `app-ventas-web`, desde `127.0.0.1`.
- **Actividad 7:** No se dispone de evidencia suficiente para identificar al usuario.
- **Actividad 12:** No se dispone de evidencia suficiente para identificar al usuario.
- **Actividad 14:** `postgres`, quien desactivó el disparador de auditoría, modificó el RFC y posteriormente volvió a activarlo.

**2. ¿Quién cambió el teléfono?**

En la evidencia disponible no aparece un registro que permita identificar quién modificó el teléfono.

**3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**

Sí. La bitácora muestra los siguientes intentos:

| Usuario | Origen | Motivo |
|---|---|---|
| `app_ventas` | `127.0.0.1` | La autenticación SCRAM fue exitosa, pero intentó conectarse a bases de datos inexistentes (`comercial` y `db_20406894`). |
| `postgres` | Local (`[local]`) | Falló la autenticación Peer porque el usuario del sistema operativo era `bryan`. |
| `postgres` | Local (`[local]`) | Falló la autenticación Peer porque el usuario del sistema operativo era `root`. |

**4. ¿Qué valor tenía el RFC antes de cada cambio?**

| Modificación | RFC anterior | RFC nuevo | Evidencia |
|---|---|---|---|
| Primera modificación registrada | `GAMA780912XYZ` | `GAMA780912ZZZ` | Auditoría, `id_evento = 1` |
| Actividad 7 | No disponible | No disponible | Sin evidencia |
| Actividad 12 | No disponible | No disponible | Sin evidencia |
| Actividad 14 | `GAMA780912ZZZ` | `GAMA780912GHI` | Bitácora del servidor; disparador desactivado |

