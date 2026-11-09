--------- CAMBIOS DE PRIVILEGIO Y ESTRUCTURA ---------


--- EN LA SESION DEL ADMINISTRADOR

REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);

---- CREAR UN ROL DESECHABLE

CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
DROP ROLE rol_temporal;


--- CONSULTAR LAS SETENCIAS REGISTEADAS


SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;


------ MODIFICAR DATOS ddl FRENTE A mod

---REPETIR EL INCIDENTE con log_statement = 'ddl';

psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"

SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;

psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"

--- CAMBIAR EL NIVEL

ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();

--- MODIFICAR LA CONSULTA

psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"

--- CONSULTAR LA BITACORA
SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;


---ERRORES Y OPERACIONES

psql "postgresql://soporte_ana:Soporte_Practica_2026@127.0.0.1/db_20406894_bryan_zavala" -c "DELETE FROM clientes WHERE id = 5"

--- DROPEAR EL ROL

DROP ROLE soporte_ana;


---Simular reporte de larga duracion

psql "postgresql://soporte_ana:Soporte_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=reporte-mensual" -c "SELECT pg_sleep(90)"


