# Intentar manipular la auditoría


**1-¿Qué evidencia permite detectar que hubo un cambio sin auditar?**
a evidencia se encuentra en la bitácora del servidor (dba.bitacora), donde quedaron registradas las instrucciones ejecutadas por el administrador:
- Desactivación del disparador trg_auditoria_clientes.
- Modificación del RFC del cliente con ID 3.
- Reactivación del disparador.

Además, el conteo de registros de auditoria.cambios_clientes permanece en 3, lo que demuestra que la modificación no generó un registro de auditoría.

**2- ¿Qué control administrativo (no técnico) reduciría este riesgo?**
Establecer una política de separación de responsabilidades, donde las modificaciones administrativas requieran autorización previa y sean revisadas por otra persona.

También se deben realizar revisiones periódicas de las bitácoras y documentar cualquier cambio realizado en los mecanismos de auditoría.



**3-Relaciona esta actividad con el principio de separación de funciones de la Unidad II.**
Esta actividad demuestra que una sola persona no debería tener el control absoluto de la base de datos y de sus mecanismos de auditoría.

El administrador puede desactivar los disparadores y modificar información sin generar registros en la tabla de auditoría. Por ello, es necesario separar las funciones entre quien administra la base de datos y quien supervisa o resguarda las evidencias.