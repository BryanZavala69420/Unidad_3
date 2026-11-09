# Limites: Lecturas y volumenes


**1- Si clientes tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un UPDATE sin WHERE?**
Se generarían aproximadamente un millón de registros nuevos en la tabla de auditoría, uno por cada fila modificada.

Esto provocaría un crecimiento considerable del almacenamiento, mayor consumo de recursos y posibles problemas de rendimiento al consultar o mantener la auditoría.


**2- Propón quién podría autorizar la depuración de auditoria.cambios_clientes.**

La depuración debería ser autorizada por el responsable de seguridad de la información o el área de cumplimiento, con aprobación de la administración correspondiente.

Además, debe existir una política de retención que establezca cuánto tiempo conservar los registros y cuándo pueden eliminarse.

**3- ¿Por qué log_statement = 'all' puede convertir la bitácora en un nuevo depósito de datos sensibles?**

Porque registra todas las consultas SQL ejecutadas, incluyendo aquellas que contienen información personal o sensible, como RFC, teléfonos, correos electrónicos y otros datos de clientes.

Esto provoca que la bitácora almacene información que originalmente solo estaba protegida en las tablas de la base de datos, creando una nueva superficie de exposición.


# Exportar y conservar la bitácora


**1-Un resumen SHA-256, ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?**
No. Un hash SHA-256 no impide que alguien modifique el archivo, pero permite detectar alteraciones al comparar el hash original con uno calculado posteriormente.

Si ambos hashes coinciden, existe evidencia de que el contenido del archivo no ha cambiado desde que se calculó el hash original, siempre que este se haya conservado de forma segura.

**2- ¿Dónde debería guardarse el hash para que sea útil como control de integridad?**
Debe guardarse en un sistema externo y seguro, separado del servidor que genera las bitácoras.

Por ejemplo, en un servidor de evidencias con acceso restringido o en un repositorio protegido contra modificaciones. Así se evita que una persona pueda alterar tanto la bitácora como su hash.


**3- La guía NIST SP 800-92 trata la conservación y protección de bitácoras (REF-U3-03). ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce?**

Existen varios riesgos:
- Si el servidor es comprometido, un atacante podría modificar o eliminar las bitácoras.
- Si ocurre una falla física, podría perderse toda la evidencia.
- Un administrador con privilegios suficientes podría alterar los registros.
- Se dificulta investigar incidentes si el atacante también controla la evidencia.
Por eso, es recomendable enviar las bitácoras a un servidor externo y restringir quién puede consultarlas o modificarlas.


**4- Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio. No existe una cifra única correcta.**

Conservaría las bitácoras durante 12 meses, manteniendo los primeros 3 meses disponibles para consultas frecuentes y los 9 meses restantes en almacenamiento protegido.

Este periodo permitiría investigar incidentes, identificar actividades sospechosas y mantener evidencia para auditorías.

La duración definitiva debería ajustarse a las políticas de seguridad, los requisitos legales y las necesidades de la organización.