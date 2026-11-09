---QUE EL SERVIOR ADMINISTRE SU PROPIA BITACORA

--- ACTIVAR EL COLECTOR 

ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart 
FROM pg_settings WHERE name = 'logging_collector';



--- COMPROBAR EL RESULTADO
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();



--- CREAR UNAVISTA DE USO EXLUCO DEL ADMINISTRADOR 

CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';


--- ORDENAR Y CITAR LINEAS DEL INFORME Y FILTRAR LA BITACORA SQL

-- últimas 10 líneas
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

-- líneas que contienen un texto, sin distinguir mayúsculas
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

-- líneas que cumplen una expresión regular
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';


----- INCIDENDE SIN BITACORA

---Conectarme y hacer el cambio

psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
UPDATE 1

--- BUSCAR EVIDENCIA

SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';

-------- CONFIGURAR LA BITACORA-------


--- EN LA SESION ADMINISTRADOR ---
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

--- VERIFICAR EL ORIGEN DE LOS VALORES CON UNA CONSULTA NUEVA

SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');


--- REVISAR LAS ULTIMAS LINEAS DE LA BITACORA

SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

---- ACCESOS EXITOSOS Y FALLIDOS --------

psql "postgresql://app_ventas:incorrecta@127.0.0.1/clientes" -c "SELECT 1"
psql "postgresql://usuario_inexistente:x@127.0.0.1/clientes" -c "SELECT 1"
psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"

--- FILTRAR POR BITACORA LA DIRECCION DEL CLIENTE

SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;