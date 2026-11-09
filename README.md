## Anexo A — Particularidades del despliegue

### A.1 Plataforma y versión

El servidor PostgreSQL fue desplegado en un entorno Linux Fedora mediante paquetes del sistema.

- **Sistema operativo:** Fedora Linux.
- **Motor de base de datos:** PostgreSQL.
- **Versión instalada:** PostgreSQL 18.6.
- **Puerto de conexión:** 5432.
- **Base de datos utilizada:** `db_20406894_bryan_zavala`.

La versión del servidor se verificó mediante:

```sql
SELECT version(); 
```

## Contenido del proyecto

| Carpeta o archivo | Contenido |
|---|---|
| `sql/` | Seis scripts SQL con los comandos ejecutados durante las actividades de auditoría y configuración de PostgreSQL. |
| `evidencias/01.md` a `evidencias/15.md` | Evidencias de las actividades 1 a 15. Cada archivo contiene los comandos ejecutados, sus resultados y una interpretación. |
| `evidencias/exportacion-bitacora.md` | Evidencia de la actividad 16, correspondiente a la exportación y conservación de la bitácora. |
| `evidencias/bitacora-lab01.log` | Archivo de bitácora exportado desde PostgreSQL, con la contraseña sustituida por `<REDACTED>`. |
| `evidencias/bitacora-lab01.sha256` | Archivo que contiene el hash SHA-256 de la bitácora exportada para comprobar su integridad. |
| `informe.md` | Informe final con los resultados, hallazgos, análisis y conclusiones de la práctica. |

La práctica se realizó directamente en Fedora Linux, utilizando PostgreSQL 18.6 y una base de datos local. La administración del servidor se efectuó mediante `sudo -u postgres psql`, y el servicio se gestionó con `systemctl`.

La Parte C, correspondiente a la implementación de `pgaudit`, es opcional y no se realizó.

## Resultado resumido

Durante la práctica se configuró y examinó el sistema de auditoría de PostgreSQL para registrar conexiones, desconexiones, instrucciones SQL y modificaciones realizadas sobre la tabla de clientes.

Los principales resultados fueron:

1. **Registro de actividad:** se habilitaron los registros de conexiones, desconexiones y sentencias SQL para obtener evidencia de las operaciones realizadas.

2. **Auditoría de modificaciones:** se utilizó un trigger para registrar operaciones `INSERT`, `UPDATE` y `DELETE` sobre la tabla `clientes`.

3. **Control de permisos:** se comprobó que la cuenta `app_ventas` no podía eliminar los registros de auditoría ni deshabilitar el trigger de auditoría.

4. **Identificación de usuarios:** se analizaron las bitácoras para relacionar las operaciones con los usuarios, las bases de datos, las aplicaciones y las direcciones de origen disponibles.

5. **Limitaciones de auditoría:** se comprobó que el trigger no registra consultas `SELECT` y que deshabilitarlo permite realizar modificaciones que no quedan registradas en la tabla de auditoría.

6. **Conservación de evidencia:** se exportó la bitácora a un archivo `.log`, se sustituyó la contraseña por `<REDACTED>` y se generó un hash SHA-256 para verificar su integridad.

7. **Análisis de eventos:** se reconstruyó una línea de tiempo con conexiones, errores de autenticación, operaciones sobre clientes y modificaciones relacionadas con la auditoría.

En conclusión, la práctica permitió comprobar que la auditoría de PostgreSQL requiere combinar registros del servidor, controles de permisos y mecanismos de auditoría a nivel de tablas. También se identificó la importancia de proteger las bitácoras y conservar copias externas para evitar su pérdida o manipulación.
