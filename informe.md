# Informe — Auditoría y gestión de bitácoras en PostgreSQL

## 1. Despliegue y situación inicial

El laboratorio se realizó sobre un servidor PostgreSQL en Linux Fedora. En la bitácora utilizada para reconstruir los eventos se identifica PostgreSQL 18.6. La base de datos de trabajo fue `db_20406894_bryan_zavala`.

Durante las pruebas también se intentaron conexiones a la base de datos `comercial`; la bitácora muestra que esa base de datos no existía en el servidor utilizado. Por ello, esos intentos no llegaron a establecer una sesión de trabajo.

La configuración inicial documentada en la práctica tenía los siguientes valores:

| Parámetro | Valor inicial | Efecto |
|---|---|---|
| `logging_collector` | `off` | PostgreSQL no administraba directamente la escritura en un archivo de bitácora. |
| `log_connections` | `off` | No se registraban los intentos de conexión mediante este parámetro. |
| `log_disconnections` | `off` | No se registraban las desconexiones mediante este parámetro. |
| `log_statement` | `none` | No se registraban las sentencias SQL por esta configuración. |
| `log_line_prefix` | `%m [%p]` | La línea incluía fecha y hora y PID, pero no identificaba directamente usuario, base de datos, aplicación ni cliente. |
| `log_timezone` | `Etc/UTC` | Los eventos se registraban en UTC. |

Con esta configuración inicial no era posible reconstruir adecuadamente quién realizó una modificación, desde qué equipo se conectó ni qué sentencia ejecutó. La Actividad 3 demostró esta limitación: se ejecutó un `UPDATE` del RFC como `app_ventas`, pero la consulta a la bitácora no devolvió registros del cambio ni de la conexión. La auditoría no puede recuperar posteriormente los eventos que no fueron registrados en el momento en que ocurrieron.


## 2. Configuración aplicada

Se activó el colector de bitácoras y se configuraron los parámetros de registro para identificar conexiones, desconexiones, sentencias de modificación y el origen de cada sesión.

| Parámetro | Configuración aplicada | Motivo |
|---|---|---|
| `logging_collector` | `on` | Permitir que PostgreSQL administre sus archivos de bitácora. Requiere reiniciar el servidor. |
| `log_connections` | `on` | Registrar conexiones recibidas, autenticadas y autorizadas, así como fallos relacionados. |
| `log_disconnections` | `on` | Registrar el cierre de las sesiones. |
| `log_line_prefix` | `%m [%p] user=%u db=%d app=%a client=%h ` | Añadir fecha, PID, usuario, base de datos, aplicación y dirección del cliente. |
| `log_statement` | `ddl` y posteriormente `mod` | Registrar primero operaciones de definición y cambios de privilegios; después, modificaciones de datos. |
| `log_min_error_statement` | `error` | Registrar la sentencia que produjo un error, independientemente del valor de `log_statement`. |

La configuración se aplicó mediante `ALTER SYSTEM`. Los parámetros que admiten recarga se aplicaron con `SELECT pg_reload_conf();`. `logging_collector` y `shared_preload_libraries` requieren reiniciar PostgreSQL porque intervienen en el arranque del servidor.

La verificación se realizó consultando `pg_settings`, incluyendo `setting`, `source`, `sourcefile` y `pending_restart`. Se observó que la recarga puede ser asíncrona: por ello, se verificaron los valores en una consulta posterior y no en el mismo bloque inmediatamente después de `pg_reload_conf()`.

También se creó el esquema `dba`, se revocó el acceso público y se creó la vista `dba.bitacora` para consultar el archivo vigente mediante SQL. Esta vista facilita la búsqueda y el análisis de líneas, pero solo consulta el archivo actual; los archivos rotados deben conservarse por separado.

## 3. Eventos observados

La bitácora permitió identificar distintos tipos de eventos:

### 3.1 Conexiones exitosas y fallidas

Se realizaron intentos de conexión como `app_ventas` y como `usuario_inexistente`.

- El intento de `app_ventas` con contraseña incorrecta produjo `FATAL: password authentication failed`.
- El intento de `usuario_inexistente` también falló. La bitácora añadió el detalle `Role "usuario_inexistente" does not exist`.
- La conexión válida de `app_ventas` utilizó autenticación `scram-sha-256`, fue autorizada para la base de datos `comercial` en el ejemplo de la guía y terminó con un registro de desconexión.
- En las pruebas del entorno del estudiante, algunos intentos de `app_ventas` autenticaron correctamente, pero no pudieron conectarse porque la base de datos solicitada (`comercial` o `db_20406894`) no existía.

La dirección `127.0.0.1` identifica el origen local de las conexiones TCP observadas. En los intentos fallidos, `app=[unknown]` aparece porque la conexión no llegó a completar la etapa en la que se identifica el nombre de la aplicación. En la conexión completada se registró `app-ventas-web`.

### 3.2 Cambios de privilegios y estructura

Con `log_statement = 'ddl'` se registraron sentencias como:

- `REVOKE UPDATE ON clientes FROM soporte_ana`
- `GRANT UPDATE ON clientes TO app_ventas`
- `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)`
- `CREATE ROLE` y `DROP ROLE`

`GRANT` y `REVOKE` quedan registrados en esta categoría porque son sentencias de administración de privilegios. También se observó que una sentencia que provoca un error puede aparecer acompañada por `ERROR`, `DETAIL` y `STATEMENT`, gracias a `log_min_error_statement = error`.

La bitácora registró un intento de `soporte_ana` de ejecutar `DELETE FROM clientes WHERE id = 5`, que fue rechazado por falta de permisos. El intento no modificó la tabla, pero quedó registrado y es relevante para detectar actividad no autorizada.

### 3.3 Modificaciones de datos

Con `log_statement = 'ddl'`, el `UPDATE` ejecutado por `app_ventas` en la Actividad 7 no apareció como sentencia, aunque sí se registraron la conexión y la desconexión. Esto demuestra que el nivel `ddl` no es suficiente para auditar modificaciones de datos.

Al cambiar a `log_statement = 'mod'`, se registró la sentencia:

```sql
UPDATE clientes SET telefono = '6679990000' WHERE id = 3;
```

La línea permitió identificar usuario, fecha, aplicación, dirección del cliente y sentencia. Sin embargo, la bitácora de sentencias no conservó el valor anterior del teléfono.

### 3.4 Sesiones activas

La vista `pg_stat_activity` permitió observar una sesión de `soporte_ana` que ejecutaba `SELECT pg_sleep(90)`, con su PID, usuario, aplicación, dirección del cliente, hora de inicio, estado y consulta. El PID permite relacionar la sesión activa con las líneas correspondientes de la bitácora.

Una vez terminada la sesión, `pg_stat_activity` deja de mostrarla como sesión activa, pero la bitácora conserva los eventos que se registraron durante su existencia.

### 3.5 Cambios de configuración

Después de recargar la configuración se registraron mensajes como `parameter "log_statement" changed to "ddl"` y otros cambios equivalentes. Estos mensajes aparecen asociados al proceso principal del servidor, porque es PostgreSQL quien aplica la nueva configuración.

Las sentencias `ALTER SYSTEM` ejecutadas antes de activar el registro de sentencias no quedaron registradas como sentencias. Por ello, conviene habilitar la auditoría antes de realizar operaciones administrativas que se quieran investigar.

## 4. Auditoría del dato

Para cumplir el requerimiento de conservar el valor anterior y el nuevo de cada cambio en `clientes`, se creó el esquema `auditoria` y la tabla `auditoria.cambios_clientes`.

La tabla contiene:

| Campo | Propósito |
|---|---|
| `id_evento` | Identificador único del evento. |
| `momento` | Fecha y hora con zona horaria del evento. |
| `usuario_sesion` | Usuario con el que se inició la sesión (`session_user`). |
| `usuario_efectivo` | Usuario efectivo dentro de la ejecución (`current_user`). |
| `aplicacion` | Nombre de aplicación declarado en la conexión. |
| `ip_cliente` | Dirección del cliente, cuando la conexión es TCP/IP. |
| `operacion` | Operación realizada: `INSERT`, `UPDATE` o `DELETE`. |
| `id_cliente` | Identificador del registro afectado. |
| `valores_antes` | Estado anterior del registro en formato `JSONB`. |
| `valores_despues` | Estado nuevo del registro en formato `JSONB`. |

Se creó la función `auditoria.registrar_cambio_cliente()` y el disparador `trg_auditoria_clientes`, que se ejecuta después de cada `INSERT`, `UPDATE` o `DELETE`.

La función utiliza `SECURITY DEFINER`, por lo que se ejecuta con los privilegios de su propietario. Por esa razón, dentro de la función `current_user` aparece como `postgres`. Para identificar al usuario que inició la sesión se conserva `session_user`, que en el cambio auditado fue `app_ventas`.

En la Actividad 12 se registró el siguiente cambio:

| Campo | Valor |
|---|---|
| Usuario de sesión | `app_ventas` |
| Usuario efectivo | `postgres` |
| Aplicación | `app-ventas-web` |
| IP del cliente | `127.0.0.1` |
| Operación | `UPDATE` |
| ID del cliente | `3` |
| RFC anterior | `GAMA780912XYZ` |
| RFC nuevo | `GAMA780912ZZZ` |

La comparación de `valores_antes` y `valores_despues` permitió identificar exactamente el campo modificado y recuperar el valor anterior. Para restaurarlo, la sentencia correspondiente sería:

```sql
UPDATE clientes
SET rfc = 'GAMA780912XYZ'
WHERE id = 3;
```

La tabla de auditoría también conservó los eventos de alta y baja del cliente Pedro Ruiz: un `INSERT` con RFC `RUPE950101AAA` y un `DELETE` cuyo valor anterior era ese mismo RFC. Aunque el registro dejó de existir en `clientes`, la evidencia permaneció en `auditoria.cambios_clientes`.

Los eventos ejecutados mediante conexión local por socket mostraron `ip_cliente` vacío. Esto ocurre porque `inet_client_addr()` devuelve `NULL` cuando no existe una dirección IP de cliente TCP/IP.

## 5. Limitaciones identificadas

La práctica mostró que la bitácora del servidor y la tabla de auditoría resuelven necesidades distintas y complementarias.

- **Lecturas:** el disparador de fila no registra sentencias `SELECT`. Además, `log_statement = 'mod'` registra modificaciones, pero no lecturas. En la prueba, la consulta sensible de `soporte_ana` no produjo una línea identificable en la bitácora.
- **Volumen:** un `UPDATE` masivo puede generar una sola línea de sentencia en la bitácora, pero una fila de auditoría por cada registro modificado. En la prueba, un único `UPDATE` produjo cinco nuevas filas de auditoría.
- **Registro de todas las consultas:** `log_statement = 'all'` permitiría registrar lecturas, pero incrementaría el volumen y podría copiar datos personales, valores sensibles o secretos a los archivos de bitácora.
- **Control administrativo:** un propietario de la tabla puede desactivar el disparador. En la Actividad 14, `postgres` desactivó `trg_auditoria_clientes`, cambió el RFC a `GAMA780912GHI` y volvió a activar el disparador. El conteo de la tabla de auditoría permaneció en tres registros, por lo que ese cambio no quedó en ella.
- **Superusuarios:** ningún mecanismo que dependa exclusivamente del propio servidor ofrece protección completa frente a un administrador con control total. Los registros deben enviarse a un sistema externo y su custodia debe separarse de la administración de la base de datos.

Para registrar lecturas de forma más selectiva se puede utilizar `pgaudit` con auditoría de objeto, o una función específica que registre el acceso. La primera alternativa requiere instalar y cargar la extensión; la segunda requiere adaptar la aplicación.

## 6. Riesgos de la bitácora y conservación de evidencias

### 6.1 Exposición de secretos

Durante la prueba de creación del rol temporal se escribió una contraseña directamente en una sentencia `CREATE ROLE`. Como `log_statement = 'ddl'` estaba activo, la contraseña quedó registrada en texto claro en la bitácora. Eliminar posteriormente el rol no elimina la contraseña de los registros.

Por esta razón, las sentencias que contienen secretos deben evitarse. La práctica compara este comportamiento con `\password`, que calcula el resumen SCRAM en el cliente y evita enviar la contraseña original como parte de una sentencia SQL registrada.

La bitácora y la tabla de auditoría pueden contener RFC, teléfonos y otros datos personales. Deben clasificarse como información sensible, limitarse a personal autorizado y protegerse mediante controles de acceso.

### 6.2 Exportación e integridad

En la Actividad 16 se indicó exportar el archivo vigente de bitácora sustituyendo la contraseña de prueba por `<REDACTED>` antes de guardar el resultado. Después se calcula un resumen SHA-256 y se guarda en un archivo separado.

SHA-256 no impide que alguien modifique el archivo. Permite detectar cambios si se compara el resumen calculado posteriormente con un hash confiable generado anteriormente. Para que el control sea útil, el hash debe conservarse en un repositorio externo, protegido y con acceso restringido.

Conservar la bitácora únicamente en el servidor que la produce implica riesgos de pérdida por fallos, reinstalación o rotación de archivos, y de alteración o eliminación por alguien que comprometa el servidor o tenga privilegios administrativos. Por ello, se recomienda enviar los registros a un sistema externo administrado por otra área.

### 6.3 Retención

Como propuesta para este laboratorio, se plantea conservar la bitácora durante 12 meses: tres meses disponibles para consulta frecuente y nueve meses en un archivo protegido. Este plazo es una propuesta de trabajo, no una regla universal; debe ajustarse a las políticas de la organización, sus obligaciones legales y las necesidades de investigación.

La depuración de la tabla de auditoría no debería depender únicamente del administrador que opera la base de datos. Debe autorizarla el responsable de seguridad, auditoría o cumplimiento, conforme a una política formal de retención y eliminación.

## 7. Cronología y respuesta a Dirección

La reconstrucción de eventos debe distinguir entre lo que se registró directamente y lo que no puede demostrarse. La tabla siguiente resume los eventos relevantes de la bitácora y de la auditoría proporcionadas para el ejercicio.

| Fecha y hora | Usuario | Origen | Evento | Resultado y evidencia |
|---|---|---|---|---|
| 2026-11-08 17:46:07 | Proceso PostgreSQL | Local | Inicio del servidor PostgreSQL 18.6; escucha en `127.0.0.1` y `::1`, puerto 5432. | Exitoso; servidor listo para aceptar conexiones. |
| 2026-11-08 17:48:25 | `postgres` | `[local]` | Autenticación Peer y acceso a la base `postgres`. | Exitoso. |
| 2026-11-08 17:48:42 | `postgres` | `[local]` | Ejecución de `ls` desde `psql`. | Error de sintaxis SQL. |
| 2026-11-08 17:49:04 | `postgres` | `[local]` | Alta de Pedro Ruiz, RFC `RUPE950101AAA`. | Registrado como `INSERT`, `id_evento = 2`. |
| 2026-11-08 17:49:04 | `postgres` | `[local]` | Baja de Pedro Ruiz. | Registrado como `DELETE`, `id_evento = 3`. |
| 2026-11-08 17:52:51 | `app_ventas` | `127.0.0.1` | Intento de conexión a la base `comercial`. | Autenticación exitosa, pero conexión fallida porque la base no existía. |
| 2026-11-08 17:53:29 | `app_ventas` | `127.0.0.1` | Intento de borrar la tabla de auditoría. | Rechazado por falta de permisos sobre el esquema `auditoria`. |
| 2026-11-08 17:53:29 | `app_ventas` | `127.0.0.1` | Intento de desactivar el disparador de auditoría. | Rechazado porque no era propietario de `clientes`. |
| 2026-11-08 18:02:48 | `soporte_ana` | `127.0.0.1` | Conexión autenticada desde la cuenta de soporte. | Conexión registrada; la evidencia disponible no demuestra por sí sola qué consulta ejecutó. |
| 2026-11-08 18:02:55 | `postgres` | `[local]` | `UPDATE clientes SET segmento = 'regular';` | Sentencia registrada; generó cinco filas nuevas en la auditoría. |
| 2026-11-08 18:06:44 | `postgres` | `[local]` | Intento de autenticación Peer con usuario del sistema operativo `bryan`. | Fallido por discrepancia de identidad. |
| 2026-11-08 18:11:41 | `postgres` | `[local]` | Autenticación Peer y acceso a `db_20406894_bryan_zavala`. | Exitoso. |

### Respuestas a Dirección

**1. ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**

- **Actividad 3:** el comando se ejecutó utilizando la conexión de `app_ventas` y devolvió `UPDATE 1`, pero la bitácora no registró ni la sentencia ni la conexión. Por tanto, con la bitácora no se puede demostrar de manera independiente quién realizó el cambio.
- **Actividad 7:** el comando de modificación del RFC se ejecutó mediante `app_ventas`. Sin embargo, como `log_statement` estaba configurado en `ddl`, la sentencia `UPDATE` no quedó registrada. La bitácora solo permite observar la conexión y desconexión de esa cuenta.
- **Actividad 12:** `app_ventas` realizó el cambio. La tabla de auditoría registra `usuario_sesion = app_ventas`, aplicación `app-ventas-web` e IP `127.0.0.1`.
- **Actividad 14:** `postgres` realizó el cambio después de desactivar el disparador de auditoría y antes de volverlo a activar. La bitácora registra las tres sentencias administrativas.

**2. ¿Quién cambió el teléfono?**

La bitácora registra la sentencia `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` ejecutada por `app_ventas`, con la aplicación `app-ventas-web` y el cliente `127.0.0.1`.

**3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**

Sí. La evidencia muestra:

- `app_ventas`, desde `127.0.0.1`, con contraseña incorrecta en la prueba de autenticación.
- `usuario_inexistente`, desde `127.0.0.1`; el rol no existía.
- `postgres`, mediante conexión local `[local]`, cuando el usuario del sistema operativo era `bryan` o `root`; la autenticación Peer falló por no coincidir las identidades.
- También hubo intentos de `app_ventas` con autenticación SCRAM exitosa que no completaron la conexión porque las bases de datos solicitadas no existían. Estos casos son fallos de conexión, pero no fallos de autenticación.

**4. ¿Qué valor tenía el RFC antes de cada cambio?**

| Actividad | RFC anterior | RFC nuevo | Alcance de la evidencia |
|---|---|---|---|
| Actividad 3 | No hay evidencia del valor anterior. | `GAMA780912XXX` | El comando y `UPDATE 1` muestran el valor asignado, pero no se registró el estado previo. |
| Actividad 7 | `GAMA780912XXX` | `GAMA780912XYZ` | La secuencia de comandos del ejercicio muestra los valores asignados; no se conservó una fila de auditoría para ese cambio. |
| Actividad 12 | `GAMA780912XYZ` | `GAMA780912ZZZ` | La tabla de auditoría conserva ambos valores. |
| Actividad 14 | `GAMA780912ZZZ` | `GAMA780912GHI` | La bitácora registra la sentencia, pero el disparador estaba desactivado y no se generó una fila de auditoría. |

Lauditoría de la Actividad 12 permite demostrar quién inició el cambio y cuál era el RFC anterior y posterior. En cambio, en las Actividades 3 y 7 faltó el registro de la sentencia y en la Actividad 14 se desactivó el disparador. La bitácora del servidor ayuda a reconstruir operaciones administrativas y errores, pero por sí sola no conserva necesariamente los valores anteriores de los datos. La combinación de bitácora, auditoría por disparadores, controles de acceso, exportación, hash y custodia externa proporciona una evidencia más completa.

## Conclusión general

La configuración inicial no proporcionaba evidencia suficiente para investigar cambios de datos ni identificar conexiones. La activación del colector, el registro de conexiones y desconexiones, un prefijo con usuario y cliente, y el nivel adecuado de `log_statement` mejoraron la trazabilidad de las operaciones.

La auditoría mediante disparadores permitió conservar los valores anteriores y posteriores de los registros, así como el usuario de sesión, la aplicación, la IP y el momento del cambio. También se comprobó que este mecanismo puede ser desactivado por un administrador con privilegios suficientes, y que las lecturas no quedan registradas por un disparador de fila.

Por tanto, **sí puede demostrarse quién cambió un dato sensible y qué valor tenía antes cuando la auditoría estaba activa y la evidencia se conservó**, como ocurrió en la Actividad 12. No puede garantizarse lo mismo para eventos no registrados o realizados mientras el disparador estaba desactivado. Para fortalecer la confiabilidad se requiere limitar privilegios, separar funciones, proteger los secretos, exportar las bitácoras, verificar su integridad con hashes y conservar copias en un sistema externo.
