SELECT c.id_compra, c.fecha_compra, c.total_compra,
       p.nombre AS proveedor, u.nombre AS registrado_por
FROM Compra c
INNER JOIN Proveedor p ON p.id_proveedor = c.id_proveedor
INNER JOIN Usuario u ON u.id_usuario = c.id_usuario;

SELECT c.id_compra, c.fecha_compra, c.estado_compra
FROM Compra c
LEFT JOIN Detalle_Compra d ON d.id_compra = c.id_compra
WHERE d.id_detalle_compra IS NULL;

SELECT c.id_compra, c.fecha_compra, p.nombre AS proveedor
FROM Proveedor p
RIGHT JOIN Compra c ON c.id_proveedor = p.id_proveedor;

SELECT id_compra, fecha_compra, id_producto, cantidad, precio_compra,
       cantidad * precio_compra AS subtotal
FROM Compra
NATURAL JOIN Detalle_Compra;

SELECT p.id_proveedor, p.nombre, c.id_compra, c.total_compra
FROM Proveedor p
LEFT JOIN Compra c ON c.id_proveedor = p.id_proveedor
UNION
SELECT p.id_proveedor, p.nombre, c.id_compra, c.total_compra
FROM Proveedor p
RIGHT JOIN Compra c ON c.id_proveedor = p.id_proveedor;

SELECT d.id_detalle_compra, c.id_compra, c.fecha_compra,
       pr.nombre AS producto, d.cantidad, d.precio_compra,
       d.cantidad * d.precio_compra AS subtotal
FROM Detalle_Compra d
INNER JOIN Compra c ON c.id_compra = d.id_compra
INNER JOIN Producto pr ON pr.id_producto = d.id_producto;

SELECT d.id_detalle_compra, d.id_producto, d.cantidad
FROM Detalle_Compra d
LEFT JOIN Movimiento_Inventario m ON m.id_detalle_compra = d.id_detalle_compra
WHERE m.id_movimiento IS NULL;

SELECT pr.id_producto, pr.nombre
FROM Detalle_Compra d
RIGHT JOIN Producto pr ON pr.id_producto = d.id_producto
WHERE d.id_detalle_compra IS NULL;

SELECT d.id_compra, pv.nombre AS proveedor, p.nombre AS producto, d.cantidad
FROM Detalle_Compra d
JOIN Compra c USING (id_compra)
JOIN Proveedor pv USING (id_proveedor)
JOIN Producto p USING (id_producto);

SELECT d1.id_compra, p1.nombre AS producto_1, p2.nombre AS producto_2
FROM Detalle_Compra d1
INNER JOIN Detalle_Compra d2
        ON d1.id_compra = d2.id_compra AND d1.id_producto < d2.id_producto
INNER JOIN Producto p1 ON p1.id_producto = d1.id_producto
INNER JOIN Producto p2 ON p2.id_producto = d2.id_producto;

SELECT pv.nombre AS proveedor, c.id_compra, c.fecha_compra, c.total_compra
FROM Proveedor pv
INNER JOIN Compra c ON c.id_proveedor = pv.id_proveedor
ORDER BY pv.nombre, c.fecha_compra;

SELECT pv.id_proveedor, pv.nombre, pv.estado
FROM Proveedor pv
LEFT JOIN Compra c ON c.id_proveedor = pv.id_proveedor
WHERE c.id_compra IS NULL;

SELECT pv.id_proveedor, pv.nombre,
       COUNT(c.id_compra) AS num_compras,
       IFNULL(SUM(c.total_compra), 0) AS total_comprado
FROM Compra c
RIGHT JOIN Proveedor pv ON pv.id_proveedor = c.id_proveedor
GROUP BY pv.id_proveedor, pv.nombre;

SELECT pv.nombre AS proveedor, p.nombre AS producto
FROM Proveedor pv
CROSS JOIN Producto p
WHERE pv.estado = 'Activo';

SELECT DISTINCT pv.nombre AS proveedor, p.nombre AS producto
FROM Proveedor pv
INNER JOIN Compra c ON c.id_proveedor = pv.id_proveedor
INNER JOIN Detalle_Compra d ON d.id_compra = c.id_compra
INNER JOIN Producto p ON p.id_producto = d.id_producto
ORDER BY pv.nombre;

SELECT cl.nombre AS cliente, v.id_venta, v.fecha_venta, v.total_venta
FROM Cliente cl
INNER JOIN Venta v ON v.id_cliente = cl.id_cliente;

SELECT cl.id_cliente, cl.nombre, cl.telefono
FROM Cliente cl
LEFT JOIN Venta v ON v.id_cliente = cl.id_cliente
WHERE v.id_venta IS NULL;

SELECT cl.nombre AS cliente, a.tipo, a.marca, s.id_servicio, s.estado
FROM Cliente cl
LEFT JOIN Aparato a ON a.id_cliente = cl.id_cliente
LEFT JOIN Servicio s ON s.id_aparato = a.id_aparato;

SELECT cl.nombre AS cliente, cat.categoria
FROM Cliente cl
CROSS JOIN (SELECT DISTINCT categoria
            FROM Producto
            WHERE categoria IS NOT NULL) cat;

SELECT cl.id_cliente, cl.nombre, s.id_sesion, s.fecha_inicio
FROM Cliente cl
LEFT JOIN Sesion s ON s.id_cliente = cl.id_cliente
UNION
SELECT cl.id_cliente, cl.nombre, s.id_sesion, s.fecha_inicio
FROM Cliente cl
RIGHT JOIN Sesion s ON s.id_cliente = cl.id_cliente;

SELECT u.nombre AS tendero,
       COUNT(v.id_venta) AS num_ventas,
       SUM(v.total_venta) AS total_vendido
FROM Usuario u
INNER JOIN Venta v ON v.id_usuario = u.id_usuario
WHERE u.rol = 'Tendero'
GROUP BY u.id_usuario, u.nombre;

SELECT u.id_usuario, u.nombre, u.rol
FROM Usuario u
LEFT JOIN Movimiento_Inventario m ON m.id_usuario = u.id_usuario
WHERE m.id_movimiento IS NULL;

SELECT s.id_servicio, t.nombre AS tendero, tec.nombre AS tecnico
FROM Servicio s
INNER JOIN Usuario t ON t.id_usuario = s.id_usuario
LEFT JOIN Usuario tec ON tec.id_usuario = s.id_tecnico;

SELECT s.id_sesion, u.nombre AS usuario, c.nombre AS cliente, s.fecha_inicio
FROM Usuario u
RIGHT JOIN Sesion s ON s.id_usuario = u.id_usuario
LEFT JOIN Cliente c ON c.id_cliente = s.id_cliente;

SELECT u.nombre AS tecnico, u.especialidad, a.id_aparato, a.tipo, a.marca
FROM Usuario u
CROSS JOIN Aparato a
WHERE u.rol = 'Tecnico' AND a.estado = 'Recibido';

SELECT s.id_sesion, u.nombre, u.rol, s.fecha_inicio, s.fecha_fin
FROM Sesion s
INNER JOIN Usuario u ON u.id_usuario = s.id_usuario;

SELECT s.id_sesion,
       COALESCE(u.nombre, c.nombre) AS quien_inicio,
       CASE WHEN u.id_usuario IS NOT NULL THEN 'Personal' ELSE 'Cliente' END AS tipo,
       s.fecha_inicio, s.fecha_fin
FROM Sesion s
LEFT JOIN Usuario u ON u.id_usuario = s.id_usuario
LEFT JOIN Cliente c ON c.id_cliente = s.id_cliente;

SELECT u.id_usuario, u.nombre, u.rol
FROM Sesion s
RIGHT JOIN Usuario u ON u.id_usuario = s.id_usuario
WHERE s.id_sesion IS NULL;

SELECT s1.id_usuario, s1.id_sesion AS sesion_1, s2.id_sesion AS sesion_2
FROM Sesion s1
INNER JOIN Sesion s2
        ON s1.id_usuario = s2.id_usuario
       AND s1.id_sesion < s2.id_sesion
       AND s1.fecha_inicio < IFNULL(s2.fecha_fin, NOW())
       AND s2.fecha_inicio < IFNULL(s1.fecha_fin, NOW());

SELECT DISTINCT u.nombre AS tendero, v.id_venta, v.fecha_venta
FROM Sesion s
INNER JOIN Usuario u ON u.id_usuario = s.id_usuario
INNER JOIN Venta v ON v.id_usuario = s.id_usuario
                  AND v.fecha_venta = DATE(s.fecha_inicio);

SELECT v.id_venta, v.fecha_venta, v.total_venta,
       cl.nombre AS cliente, u.nombre AS tendero
FROM Venta v
INNER JOIN Cliente cl ON cl.id_cliente = v.id_cliente
INNER JOIN Usuario u ON u.id_usuario = v.id_usuario;

SELECT v.id_venta, v.fecha_venta, v.total_venta
FROM Venta v
LEFT JOIN Orden_Pago o ON o.id_venta = v.id_venta
WHERE o.id_orden_pago IS NULL;

SELECT v.id_venta, v.fecha_venta
FROM Detalle_Venta d
RIGHT JOIN Venta v ON v.id_venta = d.id_venta
WHERE d.id_detalle_venta IS NULL;

SELECT id_venta, fecha_venta, id_producto, cantidad, valor_unitario,
       cantidad * valor_unitario AS subtotal
FROM Venta
NATURAL JOIN Detalle_Venta;

SELECT v.id_venta, v.total_venta, o.estado AS estado_orden,
       p.monto, p.metodo_pago, r.numero_recibo
FROM Venta v
INNER JOIN Orden_Pago o ON o.id_venta = v.id_venta
LEFT JOIN Pago p ON p.id_orden_pago = o.id_orden_pago
LEFT JOIN Recibo r ON r.id_pago = p.id_pago;

SELECT d.id_detalle_venta, v.id_venta, v.fecha_venta,
       p.nombre AS producto, d.cantidad, d.valor_unitario,
       d.cantidad * d.valor_unitario AS subtotal
FROM Detalle_Venta d
INNER JOIN Venta v ON v.id_venta = d.id_venta
INNER JOIN Producto p ON p.id_producto = d.id_producto;

SELECT d.id_detalle_venta, d.id_producto, d.cantidad
FROM Detalle_Venta d
LEFT JOIN Movimiento_Inventario m ON m.id_detalle_venta = d.id_detalle_venta
WHERE m.id_movimiento IS NULL;

SELECT p.id_producto, p.nombre
FROM Detalle_Venta d
RIGHT JOIN Producto p ON p.id_producto = d.id_producto
WHERE d.id_detalle_venta IS NULL;

SELECT cl.nombre AS cliente, p.nombre AS producto, d.cantidad, d.valor_unitario
FROM Detalle_Venta d
JOIN Venta v USING (id_venta)
JOIN Cliente cl USING (id_cliente)
JOIN Producto p USING (id_producto);

SELECT d1.id_venta, p1.nombre AS producto_1, p2.nombre AS producto_2
FROM Detalle_Venta d1
INNER JOIN Detalle_Venta d2
        ON d1.id_venta = d2.id_venta AND d1.id_producto < d2.id_producto
INNER JOIN Producto p1 ON p1.id_producto = d1.id_producto
INNER JOIN Producto p2 ON p2.id_producto = d2.id_producto;

SELECT p.nombre, m.tipo_movimiento, m.cantidad, m.fecha_movimiento, m.motivo
FROM Producto p
INNER JOIN Movimiento_Inventario m ON m.id_producto = p.id_producto;

SELECT p.id_producto, p.nombre, p.cantidad_disponible
FROM Producto p
LEFT JOIN Movimiento_Inventario m ON m.id_producto = p.id_producto
WHERE m.id_movimiento IS NULL;

SELECT p.id_producto, p.nombre,
       IFNULL(SUM(d.cantidad), 0) AS unidades_vendidas
FROM Detalle_Venta d
RIGHT JOIN Producto p ON p.id_producto = d.id_producto
GROUP BY p.id_producto, p.nombre
ORDER BY unidades_vendidas DESC;

SELECT p.nombre, t.comprado, t.vendido
FROM Producto p
INNER JOIN (
    SELECT c.id_producto, c.comprado, v.vendido
    FROM (SELECT id_producto, SUM(cantidad) AS comprado
          FROM Detalle_Compra GROUP BY id_producto) c
    LEFT JOIN (SELECT id_producto, SUM(cantidad) AS vendido
               FROM Detalle_Venta GROUP BY id_producto) v
           ON v.id_producto = c.id_producto
    UNION
    SELECT v.id_producto, c.comprado, v.vendido
    FROM (SELECT id_producto, SUM(cantidad) AS comprado
          FROM Detalle_Compra GROUP BY id_producto) c
    RIGHT JOIN (SELECT id_producto, SUM(cantidad) AS vendido
                FROM Detalle_Venta GROUP BY id_producto) v
            ON v.id_producto = c.id_producto
) t ON t.id_producto = p.id_producto;

SELECT p.nombre, p.precio_unitario, d.descuento,
       p.precio_unitario * (1 - d.descuento / 100) AS precio_con_descuento
FROM Producto p
CROSS JOIN (SELECT 5 AS descuento
            UNION SELECT 10
            UNION SELECT 20) d;

SELECT m.id_movimiento, m.fecha_movimiento, m.tipo_movimiento, m.cantidad,
       p.nombre AS producto, u.nombre AS registrado_por
FROM Movimiento_Inventario m
INNER JOIN Producto p ON p.id_producto = m.id_producto
INNER JOIN Usuario u ON u.id_usuario = m.id_usuario;

SELECT m.id_movimiento, m.tipo_movimiento, m.motivo, m.cantidad,
       dc.id_compra, dv.id_venta
FROM Movimiento_Inventario m
LEFT JOIN Detalle_Compra dc ON dc.id_detalle_compra = m.id_detalle_compra
LEFT JOIN Detalle_Venta dv ON dv.id_detalle_venta = m.id_detalle_venta;

SELECT p.nombre,
       IFNULL(SUM(CASE WHEN m.tipo_movimiento = 'Entrada' THEN m.cantidad END), 0) AS entradas,
       IFNULL(SUM(CASE WHEN m.tipo_movimiento = 'Salida' THEN m.cantidad END), 0) AS salidas
FROM Movimiento_Inventario m
RIGHT JOIN Producto p ON p.id_producto = m.id_producto
GROUP BY p.id_producto, p.nombre;

SELECT m.id_movimiento, m.fecha_movimiento, m.cantidad,
       c.id_compra, pv.nombre AS proveedor
FROM Movimiento_Inventario m
INNER JOIN Detalle_Compra dc ON dc.id_detalle_compra = m.id_detalle_compra
INNER JOIN Compra c ON c.id_compra = dc.id_compra
INNER JOIN Proveedor pv ON pv.id_proveedor = c.id_proveedor
WHERE m.tipo_movimiento = 'Entrada';

SELECT p.nombre AS producto, e.fecha_movimiento,
       e.cantidad AS cantidad_entrada, s.cantidad AS cantidad_salida
FROM Movimiento_Inventario e
INNER JOIN Movimiento_Inventario s
        ON s.id_producto = e.id_producto
       AND s.fecha_movimiento = e.fecha_movimiento
INNER JOIN Producto p ON p.id_producto = e.id_producto
WHERE e.tipo_movimiento = 'Entrada' AND s.tipo_movimiento = 'Salida';

SELECT h.id_historial, h.fecha_modificacion, h.tipo_modificacion,
       u.nombre AS usuario, u.rol
FROM Historial h
INNER JOIN Usuario u ON u.id_usuario = h.id_usuario;

SELECT u.id_usuario, u.nombre, COUNT(h.id_historial) AS num_modificaciones
FROM Historial h
RIGHT JOIN Usuario u ON u.id_usuario = h.id_usuario
GROUP BY u.id_usuario, u.nombre;

SELECT h.id_historial, h.tipo_modificacion, h.fecha_modificacion, u.nombre AS usuario
FROM Historial h
LEFT JOIN Usuario u ON u.id_usuario = h.id_usuario
WHERE h.fecha_modificacion >= DATE_SUB(NOW(), INTERVAL 30 DAY);

SELECT h1.id_usuario,
       h1.id_historial AS modificacion_1, h1.fecha_modificacion AS fecha_1,
       h2.id_historial AS modificacion_2, h2.fecha_modificacion AS fecha_2
FROM Historial h1
INNER JOIN Historial h2
        ON h1.id_usuario = h2.id_usuario
       AND DATE(h1.fecha_modificacion) = DATE(h2.fecha_modificacion)
       AND h1.fecha_modificacion < h2.fecha_modificacion;

SELECT u.nombre AS usuario, t.tipo, COUNT(h.id_historial) AS cantidad
FROM Usuario u
CROSS JOIN (SELECT 'Creación' AS tipo
            UNION SELECT 'Actualización'
            UNION SELECT 'Eliminación') t
LEFT JOIN Historial h ON h.id_usuario = u.id_usuario
                     AND h.tipo_modificacion = t.tipo
GROUP BY u.id_usuario, u.nombre, t.tipo;

SELECT r.id_reporte, r.tipo, r.fecha_reporte, u.nombre AS generado_por
FROM Reporte r
INNER JOIN Usuario u ON u.id_usuario = r.id_usuario;

SELECT u.id_usuario, u.nombre, u.rol
FROM Reporte r
RIGHT JOIN Usuario u ON u.id_usuario = r.id_usuario
WHERE r.id_reporte IS NULL
  AND u.rol IN ('Administrador', 'Encargado de inventario');

SELECT r.tipo, COUNT(r.id_reporte) AS num_reportes,
       MAX(r.fecha_reporte) AS ultimo_reporte,
       COUNT(DISTINCT u.id_usuario) AS usuarios_distintos
FROM Reporte r
LEFT JOIN Usuario u ON u.id_usuario = r.id_usuario
GROUP BY r.tipo;

SELECT u.nombre AS usuario, t.tipo,
       CASE WHEN COUNT(r.id_reporte) = 0 THEN 'Falta' ELSE 'Generado' END AS estado
FROM Usuario u
CROSS JOIN (SELECT 'Existencias' AS tipo
            UNION SELECT 'Entradas'
            UNION SELECT 'Salidas') t
LEFT JOIN Reporte r ON r.id_usuario = u.id_usuario AND r.tipo = t.tipo
WHERE u.rol IN ('Administrador', 'Encargado de inventario')
GROUP BY u.id_usuario, u.nombre, t.tipo;

SELECT u.id_usuario, u.nombre, r.id_reporte, r.tipo
FROM Usuario u
LEFT JOIN Reporte r ON r.id_usuario = u.id_usuario
UNION
SELECT u.id_usuario, u.nombre, r.id_reporte, r.tipo
FROM Usuario u
RIGHT JOIN Reporte r ON r.id_usuario = u.id_usuario;

SELECT a.id_aparato, a.tipo, a.marca, a.modelo, a.estado, cl.nombre AS dueno
FROM Aparato a
INNER JOIN Cliente cl ON cl.id_cliente = a.id_cliente;

SELECT a.id_aparato, a.tipo, a.marca
FROM Aparato a
LEFT JOIN Servicio s ON s.id_aparato = a.id_aparato
WHERE s.id_servicio IS NULL;

SELECT a.id_aparato, a.tipo, a.marca, COUNT(s.id_servicio) AS num_servicios
FROM Servicio s
RIGHT JOIN Aparato a ON a.id_aparato = s.id_aparato
GROUP BY a.id_aparato, a.tipo, a.marca;

SELECT cl.nombre AS cliente, a.tipo, a.marca, s.estado,
       tec.nombre AS tecnico, s.diagnostico
FROM Aparato a
INNER JOIN Cliente cl ON cl.id_cliente = a.id_cliente
INNER JOIN Servicio s ON s.id_aparato = a.id_aparato
LEFT JOIN Usuario tec ON tec.id_usuario = s.id_tecnico;

SELECT cl.nombre AS cliente, a1.marca,
       a1.id_aparato AS aparato_1, a2.id_aparato AS aparato_2
FROM Aparato a1
INNER JOIN Aparato a2
        ON a1.id_cliente = a2.id_cliente
       AND a1.marca = a2.marca
       AND a1.id_aparato < a2.id_aparato
INNER JOIN Cliente cl ON cl.id_cliente = a1.id_cliente;

SELECT s.id_servicio, s.fecha_ingreso, s.estado,
       cl.nombre AS cliente, a.tipo, a.marca
FROM Servicio s
INNER JOIN Cliente cl ON cl.id_cliente = s.id_cliente
INNER JOIN Aparato a ON a.id_aparato = s.id_aparato;

SELECT s.id_servicio, s.fecha_ingreso, s.estado,
       IFNULL(tec.nombre, 'Sin asignar') AS tecnico
FROM Servicio s
LEFT JOIN Usuario tec ON tec.id_usuario = s.id_tecnico;

SELECT s.id_servicio, s.fecha_ingreso, s.id_cliente
FROM Servicio s
LEFT JOIN Encuesta_Satisfaccion e ON e.id_servicio = s.id_servicio
WHERE s.estado = 'Finalizado' AND e.id_encuesta IS NULL;

SELECT s.id_servicio, s.estado, s.fecha_ingreso
FROM Orden_Pago o
RIGHT JOIN Servicio s ON s.id_servicio = o.id_servicio
WHERE o.id_orden_pago IS NULL;

SELECT s.id_servicio, s.estado, e.id_encuesta, e.calificacion
FROM Servicio s
LEFT JOIN Encuesta_Satisfaccion e ON e.id_servicio = s.id_servicio
UNION
SELECT s.id_servicio, s.estado, e.id_encuesta, e.calificacion
FROM Servicio s
RIGHT JOIN Encuesta_Satisfaccion e ON e.id_servicio = s.id_servicio;

SELECT e.id_encuesta, e.calificacion, e.comentarios,
       s.id_servicio, cl.nombre AS cliente
FROM Encuesta_Satisfaccion e
INNER JOIN Servicio s ON s.id_servicio = e.id_servicio
INNER JOIN Cliente cl ON cl.id_cliente = e.id_cliente;

SELECT u.nombre AS tendero,
       COUNT(e.id_encuesta) AS num_encuestas,
       ROUND(AVG(e.calificacion), 2) AS promedio
FROM Encuesta_Satisfaccion e
INNER JOIN Usuario u ON u.id_usuario = e.id_usuario
GROUP BY u.id_usuario, u.nombre;

SELECT u.id_usuario, u.nombre
FROM Encuesta_Satisfaccion e
RIGHT JOIN Usuario u ON u.id_usuario = e.id_usuario
WHERE u.rol = 'Tendero' AND e.id_encuesta IS NULL;

SELECT e.id_encuesta, e.calificacion, a.tipo, a.marca, s.estado
FROM Encuesta_Satisfaccion e
JOIN Servicio s USING (id_servicio)
JOIN Aparato a USING (id_aparato);

SELECT e.id_encuesta, e.calificacion, e.comentarios, t.promedio
FROM Encuesta_Satisfaccion e
CROSS JOIN (SELECT AVG(calificacion) AS promedio
            FROM Encuesta_Satisfaccion) t
WHERE e.calificacion < t.promedio;

SELECT o.id_orden_pago, o.fecha_ingreso, o.estado, o.costo_total,
       cl.nombre AS cliente, u.nombre AS tendero
FROM Orden_Pago o
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente
INNER JOIN Usuario u ON u.id_usuario = o.id_usuario;

SELECT o.id_orden_pago, o.costo_total,
       CASE WHEN v.id_venta IS NOT NULL THEN 'Venta' ELSE 'Servicio' END AS origen,
       COALESCE(v.id_venta, s.id_servicio) AS id_origen
FROM Orden_Pago o
LEFT JOIN Venta v ON v.id_venta = o.id_venta
LEFT JOIN Servicio s ON s.id_servicio = o.id_servicio;

SELECT o.id_orden_pago, o.fecha_ingreso, o.costo_total
FROM Orden_Pago o
LEFT JOIN Pago p ON p.id_orden_pago = o.id_orden_pago
WHERE p.id_pago IS NULL;

SELECT o.id_orden_pago, o.costo_total,
       IFNULL(SUM(CASE WHEN p.estado = 'Aprobado' THEN p.monto END), 0) AS pagado,
       o.costo_total
         - IFNULL(SUM(CASE WHEN p.estado = 'Aprobado' THEN p.monto END), 0) AS saldo_pendiente
FROM Pago p
RIGHT JOIN Orden_Pago o ON o.id_orden_pago = p.id_orden_pago
GROUP BY o.id_orden_pago, o.costo_total;

SELECT o.id_orden_pago, cl.nombre AS cliente, p.monto, p.estado,
       IFNULL(g.nombre_pasarela, 'Presencial') AS pasarela,
       r.numero_recibo
FROM Orden_Pago o
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente
LEFT JOIN Pago p ON p.id_orden_pago = o.id_orden_pago
LEFT JOIN Pasarela_Pago g ON g.id_pasarela = p.id_pasarela
LEFT JOIN Recibo r ON r.id_pago = p.id_pago;

SELECT g.nombre_pasarela, p.id_pago, p.monto, p.estado, p.fecha_pago
FROM Pasarela_Pago g
INNER JOIN Pago p ON p.id_pasarela = g.id_pasarela;

SELECT g.id_pasarela, g.nombre_pasarela
FROM Pasarela_Pago g
LEFT JOIN Pago p ON p.id_pasarela = g.id_pasarela
WHERE p.id_pago IS NULL;

SELECT g.nombre_pasarela,
       COUNT(p.id_pago) AS num_pagos,
       IFNULL(SUM(p.monto), 0) AS total_procesado
FROM Pago p
RIGHT JOIN Pasarela_Pago g ON g.id_pasarela = p.id_pasarela
GROUP BY g.id_pasarela, g.nombre_pasarela;

SELECT g.id_pasarela, g.nombre_pasarela, p.id_pago, p.monto
FROM Pasarela_Pago g
LEFT JOIN Pago p ON p.id_pasarela = g.id_pasarela
UNION
SELECT g.id_pasarela, g.nombre_pasarela, p.id_pago, p.monto
FROM Pasarela_Pago g
RIGHT JOIN Pago p ON p.id_pasarela = g.id_pasarela;

SELECT g.nombre_pasarela, m.metodo, COUNT(p.id_pago) AS num_pagos
FROM Pasarela_Pago g
CROSS JOIN (SELECT 'Tarjeta' AS metodo
            UNION SELECT 'Transferencia'
            UNION SELECT 'PSE') m
LEFT JOIN Pago p ON p.id_pasarela = g.id_pasarela
                AND p.metodo_pago = m.metodo
GROUP BY g.id_pasarela, g.nombre_pasarela, m.metodo;

SELECT p.id_pago, p.fecha_pago, p.monto, p.metodo_pago, p.estado,
       o.id_orden_pago, cl.nombre AS cliente
FROM Pago p
INNER JOIN Orden_Pago o ON o.id_orden_pago = p.id_orden_pago
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente;

SELECT p.id_pago, p.monto,
       IFNULL(u.nombre, '(en línea)') AS tendero,
       IFNULL(g.nombre_pasarela, 'Presencial') AS pasarela
FROM Pago p
LEFT JOIN Usuario u ON u.id_usuario = p.id_usuario
LEFT JOIN Pasarela_Pago g ON g.id_pasarela = p.id_pasarela;

SELECT u.nombre AS tendero, COUNT(p.id_pago) AS num_pagos, SUM(p.monto) AS total_recaudado
FROM Pago p
INNER JOIN Usuario u ON u.id_usuario = p.id_usuario
WHERE p.estado = 'Aprobado'
GROUP BY u.id_usuario, u.nombre;

SELECT u.id_usuario, u.nombre
FROM Pago p
RIGHT JOIN Usuario u ON u.id_usuario = p.id_usuario
WHERE u.rol = 'Tendero' AND p.id_pago IS NULL;

SELECT p1.id_orden_pago,
       p1.id_pago AS pago_anterior, p1.monto AS monto_anterior,
       p2.id_pago AS pago_siguiente, p2.monto AS monto_siguiente
FROM Pago p1
INNER JOIN Pago p2
        ON p1.id_orden_pago = p2.id_orden_pago
       AND p1.fecha_pago < p2.fecha_pago;

SELECT r.numero_recibo, r.fecha_emision, p.monto, p.metodo_pago,
       cl.nombre AS cliente
FROM Recibo r
INNER JOIN Pago p ON p.id_pago = r.id_pago
INNER JOIN Orden_Pago o ON o.id_orden_pago = p.id_orden_pago
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente;

SELECT r.numero_recibo, p.monto,
       CASE WHEN v.id_venta IS NOT NULL THEN 'Venta' ELSE 'Servicio' END AS origen,
       COALESCE(v.id_venta, s.id_servicio) AS id_origen
FROM Recibo r
INNER JOIN Pago p ON p.id_pago = r.id_pago
INNER JOIN Orden_Pago o ON o.id_orden_pago = p.id_orden_pago
LEFT JOIN Venta v ON v.id_venta = o.id_venta
LEFT JOIN Servicio s ON s.id_servicio = o.id_servicio;

SELECT p.id_pago, p.monto, p.fecha_pago
FROM Recibo r
RIGHT JOIN Pago p ON p.id_pago = r.id_pago
WHERE p.estado = 'Aprobado' AND r.id_recibo IS NULL;

SELECT numero_recibo, fecha_emision, monto, metodo_pago, estado
FROM Recibo
NATURAL JOIN Pago;

SELECT cl.nombre AS cliente,
       DATE_FORMAT(r.fecha_emision, '%Y-%m') AS mes,
       COUNT(r.id_recibo) AS num_recibos,
       SUM(p.monto) AS total_pagado
FROM Recibo r
INNER JOIN Pago p ON p.id_pago = r.id_pago
INNER JOIN Orden_Pago o ON o.id_orden_pago = p.id_orden_pago
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente
GROUP BY cl.id_cliente, cl.nombre, DATE_FORMAT(r.fecha_emision, '%Y-%m');