## Respuestas — Actividad 19: Auditoría de objeto con `pgaudit`

**1. ¿Por qué no apareció `SELECT nombre, ciudad ...`? ¿Por qué sí apareció `SELECT * ...`?**

La primera consulta no apareció porque únicamente solicita las columnas `nombre` y `ciudad`, sobre las cuales el rol `auditor_datos` no tiene privilegios de auditoría.

En cambio, `SELECT *` sí apareció porque incluye todas las columnas de la tabla, entre ellas `rfc` y `telefono`, que son las columnas sensibles configuradas para la auditoría.

**2. ¿Por qué no apareció `UPDATE ... ciudad ...`?**

Porque el rol `auditor_datos` únicamente tiene privilegios de auditoría `UPDATE` sobre las columnas `rfc` y `telefono`. La columna `ciudad` no está incluida en esos privilegios, por lo que su modificación no genera un registro de auditoría de objeto.

**3. ¿Qué diferencia de volumen esperarías frente a `log_statement = 'all'`?**

Se esperaría un volumen menor de registros con `pgaudit` en modo de objeto, porque permite filtrar las operaciones sobre columnas específicas. En cambio, `log_statement = 'all'` registra todas las sentencias SQL ejecutadas, incluyendo consultas y operaciones que no involucran información sensible.

Esto permite reducir el espacio de almacenamiento utilizado y facilita la revisión de los registros.

**4. El README oficial advierte que `pgaudit` no puede auditar de forma confiable a los superusuarios (REF-U3-09). ¿Qué implica para la separación de funciones?**

Implica que los superusuarios no deben ser los únicos responsables de administrar la base de datos y controlar las evidencias de auditoría, ya que tienen privilegios suficientes para modificar configuraciones y mecanismos de registro.

Se recomienda separar las funciones:
- **Administrador de base de datos:** administra el servidor y sus usuarios.
- **Responsable de auditoría:** revisa y protege los registros.
- **Cuenta de aplicación:** realiza únicamente las operaciones necesarias para el funcionamiento de la aplicación.

Además, los registros deben enviarse a un sistema externo con acceso restringido para reducir el riesgo de manipulación o eliminación.