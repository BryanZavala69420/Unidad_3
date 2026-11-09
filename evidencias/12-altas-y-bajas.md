# 12- Altas y bajas 

**1- El cliente Pedro Ruiz ya no existe en clientes. ¿Dónde queda evidencia de que existió y de sus datos?**
La evidencia permanece en la tabla auditoria.cambios_clientes, donde se registran las operaciones realizadas sobre los clientes.

Aunque Pedro Ruiz fue eliminado de la tabla principal, los registros de auditoría conservan información como:
- La operación realizada (INSERT y DELETE).
- El identificador del cliente (id_cliente = 6).
- Los valores anteriores y posteriores almacenados en formato JSON.
- El usuario y la aplicación que realizaron la operación.
En este caso, el RFC RUPE950101AAA demuestra que el registro existió.

**2- Por qué ip_cliente está vacía en los eventos 2 y 3?**
Porque las operaciones se realizaron mediante una conexión local de PostgreSQL utilizando psql a través de un socket Unix, en lugar de una conexión TCP/IP.

Por ello, PostgreSQL no obtuvo una dirección IP del cliente y el campo ip_cliente quedó como NULL.

**4- La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**

Existe un conflicto entre la política de eliminación de datos y la conservación de registros de auditoría.

Por un lado, los datos personales deben eliminarse cuando dejan de ser necesarios. Por otro, los registros de auditoría deben conservar evidencia de las operaciones para garantizar la trazabilidad y detectar posibles incidentes.

Este conflicto debe resolverlo la organización mediante sus responsables de seguridad, protección de datos y cumplimiento legal, estableciendo políticas claras de retención, anonimización y eliminación de registros.



