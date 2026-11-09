---------- INCIDENTE AUDITADO ---------

---CAMBIAR LA AUDITORIA
psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
psql "postgresql://app_ventas:Ventas_Practica_2026@127.0.0.1/db_20406894_bryan_zavala" -c "SELECT * FROM auditoria.cambios_clientes"

--- PRESENTACION VERTICAL DE PSQL

\x
SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;
\x


---CAMPOS CAMBIADOS

