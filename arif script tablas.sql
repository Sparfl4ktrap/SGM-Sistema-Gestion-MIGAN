SET NAMES utf8mb4;

DROP DATABASE IF EXISTS arif;
CREATE DATABASE arif CHARACTER SET utf8mb4;
USE arif;

-- =====================================================
-- TABLAS
-- =====================================================

CREATE TABLE Proveedor (
    id_proveedor INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NULL,
    correo VARCHAR(100) NULL,
    direccion VARCHAR(150) NULL,
    estado VARCHAR(10) NOT NULL DEFAULT 'Activo',
    PRIMARY KEY (id_proveedor),
    CONSTRAINT chk_proveedor_telefono CHECK (telefono REGEXP '^[0-9]+$'),
    CONSTRAINT chk_proveedor_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT chk_proveedor_estado CHECK (estado IN ('Activo', 'Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Cliente (
    id_cliente INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NULL,
    telefono VARCHAR(15) NULL,
    direccion VARCHAR(150) NULL,
    contrasena_hash VARCHAR(255) NULL,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_cliente_correo (correo),
    CONSTRAINT chk_cliente_telefono CHECK (telefono REGEXP '^[0-9]+$'),
    CONSTRAINT chk_cliente_correo CHECK (correo LIKE '%_@_%._%')
) ENGINE=InnoDB;

CREATE TABLE Usuario (
    id_usuario INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(30) NOT NULL,
    departamento VARCHAR(50) NULL,
    especialidad VARCHAR(50) NULL,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uq_usuario_correo (correo),
    CONSTRAINT chk_usuario_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT chk_usuario_rol CHECK (rol IN ('Administrador', 'Tendero', 'Encargado de inventario', 'Tecnico'))
) ENGINE=InnoDB;

-- La regla "o usuario o cliente (uno solo)" se valida con triggers (ver más abajo)
CREATE TABLE Sesion (
    id_sesion INT NOT NULL AUTO_INCREMENT,
    id_usuario INT NULL,
    id_cliente INT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NULL,
    PRIMARY KEY (id_sesion),
    CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT fk_sesion_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT chk_sesion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE Producto (
    id_producto INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NULL,
    categoria VARCHAR(50) NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    cantidad_disponible INT NOT NULL DEFAULT 0,
    ubicacion VARCHAR(100) NULL,
    fecha_actualizacion DATE NOT NULL,
    PRIMARY KEY (id_producto),
    CONSTRAINT chk_producto_precio CHECK (precio_unitario >= 0),
    CONSTRAINT chk_producto_cantidad CHECK (cantidad_disponible >= 0)
) ENGINE=InnoDB;

CREATE TABLE Compra (
    id_compra INT NOT NULL AUTO_INCREMENT,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_compra DATE NOT NULL,
    total_compra DECIMAL(12,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    estado_compra VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    PRIMARY KEY (id_compra),
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES Proveedor (id_proveedor),
    CONSTRAINT fk_compra_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_compra_total CHECK (total_compra >= 0),
    CONSTRAINT chk_compra_metodo CHECK (metodo_pago IN ('Efectivo', 'Transferencia', 'Tarjeta')),
    CONSTRAINT chk_compra_estado CHECK (estado_compra IN ('Pendiente', 'Recibida', 'Anulada'))
) ENGINE=InnoDB;

CREATE TABLE Detalle_Compra (
    id_detalle_compra INT NOT NULL AUTO_INCREMENT,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_compra DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_detalle_compra),
    UNIQUE KEY uq_detalle_compra_producto (id_compra, id_producto),
    CONSTRAINT fk_detalle_compra_compra FOREIGN KEY (id_compra) REFERENCES Compra (id_compra),
    CONSTRAINT fk_detalle_compra_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
    CONSTRAINT chk_detalle_compra_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_compra_precio CHECK (precio_compra >= 0)
) ENGINE=InnoDB;

CREATE TABLE Venta (
    id_venta INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_venta DATE NOT NULL,
    total_venta DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_venta),
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_venta_total CHECK (total_venta >= 0)
) ENGINE=InnoDB;

CREATE TABLE Detalle_Venta (
    id_detalle_venta INT NOT NULL AUTO_INCREMENT,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    valor_unitario DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_detalle_venta),
    UNIQUE KEY uq_detalle_venta_producto (id_venta, id_producto),
    CONSTRAINT fk_detalle_venta_venta FOREIGN KEY (id_venta) REFERENCES Venta (id_venta),
    CONSTRAINT fk_detalle_venta_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
    CONSTRAINT chk_detalle_venta_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_venta_valor CHECK (valor_unitario >= 0)
) ENGINE=InnoDB;

-- La regla "origen compra o venta, nunca ambos" se valida con triggers
CREATE TABLE Movimiento_Inventario (
    id_movimiento INT NOT NULL AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad INT NOT NULL,
    fecha_movimiento DATE NOT NULL,
    motivo VARCHAR(100) NOT NULL,
    id_detalle_compra INT NULL,
    id_detalle_venta INT NULL,
    observaciones VARCHAR(255) NULL,
    PRIMARY KEY (id_movimiento),
    CONSTRAINT fk_movimiento_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
    CONSTRAINT fk_movimiento_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT fk_movimiento_detalle_compra FOREIGN KEY (id_detalle_compra) REFERENCES Detalle_Compra (id_detalle_compra),
    CONSTRAINT fk_movimiento_detalle_venta FOREIGN KEY (id_detalle_venta) REFERENCES Detalle_Venta (id_detalle_venta),
    CONSTRAINT chk_movimiento_tipo CHECK (tipo_movimiento IN ('Entrada', 'Salida')),
    CONSTRAINT chk_movimiento_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

CREATE TABLE Historial (
    id_historial INT NOT NULL AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    fecha_modificacion DATETIME NOT NULL,
    tipo_modificacion VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_historial),
    CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_historial_tipo CHECK (tipo_modificacion IN ('Creación', 'Actualización', 'Eliminación'))
) ENGINE=InnoDB;

CREATE TABLE Reporte (
    id_reporte INT NOT NULL AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    fecha_reporte DATE NOT NULL,
    datos TEXT NULL,
    PRIMARY KEY (id_reporte),
    CONSTRAINT fk_reporte_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_reporte_tipo CHECK (tipo IN ('Existencias', 'Entradas', 'Salidas'))
) ENGINE=InnoDB;

CREATE TABLE Aparato (
    id_aparato INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Recibido',
    PRIMARY KEY (id_aparato),
    CONSTRAINT fk_aparato_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT chk_aparato_estado CHECK (estado IN ('Recibido', 'En reparación', 'Reparado', 'Entregado'))
) ENGINE=InnoDB;

CREATE TABLE Servicio (
    id_servicio INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    id_aparato INT NOT NULL,
    id_tecnico INT NULL,
    fecha_ingreso DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    diagnostico VARCHAR(255) NULL,
    PRIMARY KEY (id_servicio),
    CONSTRAINT fk_servicio_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT fk_servicio_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT fk_servicio_aparato FOREIGN KEY (id_aparato) REFERENCES Aparato (id_aparato),
    CONSTRAINT fk_servicio_tecnico FOREIGN KEY (id_tecnico) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_servicio_estado CHECK (estado IN ('Pendiente', 'En proceso', 'Finalizado'))
) ENGINE=InnoDB;

CREATE TABLE Encuesta_Satisfaccion (
    id_encuesta INT NOT NULL AUTO_INCREMENT,
    id_servicio INT NOT NULL,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    calificacion INT NOT NULL,
    comentarios VARCHAR(500) NULL,
    PRIMARY KEY (id_encuesta),
    UNIQUE KEY uq_encuesta_servicio (id_servicio),
    CONSTRAINT fk_encuesta_servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
    CONSTRAINT fk_encuesta_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT fk_encuesta_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT chk_encuesta_calificacion CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- La regla "origen venta o servicio (uno solo)" se valida con triggers
CREATE TABLE Orden_Pago (
    id_orden_pago INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    id_venta INT NULL,
    id_servicio INT NULL,
    fecha_ingreso DATETIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    costo_total DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_orden_pago),
    UNIQUE KEY uq_orden_pago_venta (id_venta),
    UNIQUE KEY uq_orden_pago_servicio (id_servicio),
    CONSTRAINT fk_orden_pago_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
    CONSTRAINT fk_orden_pago_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT fk_orden_pago_venta FOREIGN KEY (id_venta) REFERENCES Venta (id_venta),
    CONSTRAINT fk_orden_pago_servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
    CONSTRAINT chk_orden_pago_estado CHECK (estado IN ('Pendiente', 'En proceso', 'Pagada', 'Cancelada')),
    CONSTRAINT chk_orden_pago_costo CHECK (costo_total >= 0)
) ENGINE=InnoDB;

CREATE TABLE Pasarela_Pago (
    id_pasarela INT NOT NULL AUTO_INCREMENT,
    nombre_pasarela VARCHAR(80) NOT NULL,
    PRIMARY KEY (id_pasarela),
    UNIQUE KEY uq_pasarela_nombre (nombre_pasarela)
) ENGINE=InnoDB;

CREATE TABLE Pago (
    id_pago INT NOT NULL AUTO_INCREMENT,
    id_orden_pago INT NOT NULL,
    id_usuario INT NULL,
    id_pasarela INT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATETIME NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    token_transaccion VARCHAR(255) NULL,
    PRIMARY KEY (id_pago),
    CONSTRAINT fk_pago_orden FOREIGN KEY (id_orden_pago) REFERENCES Orden_Pago (id_orden_pago),
    CONSTRAINT fk_pago_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
    CONSTRAINT fk_pago_pasarela FOREIGN KEY (id_pasarela) REFERENCES Pasarela_Pago (id_pasarela),
    CONSTRAINT chk_pago_monto CHECK (monto > 0),
    CONSTRAINT chk_pago_metodo CHECK (metodo_pago IN ('Efectivo', 'Tarjeta', 'Transferencia', 'PSE')),
    CONSTRAINT chk_pago_estado CHECK (estado IN ('Pendiente', 'Aprobado', 'Rechazado', 'Fallido'))
) ENGINE=InnoDB;

CREATE TABLE Recibo (
    id_recibo INT NOT NULL AUTO_INCREMENT,
    id_pago INT NOT NULL,
    numero_recibo VARCHAR(40) NOT NULL,
    fecha_emision DATE NOT NULL,
    detalles_adicionales TEXT NULL,
    PRIMARY KEY (id_recibo),
    UNIQUE KEY uq_recibo_pago (id_pago),
    UNIQUE KEY uq_recibo_numero (numero_recibo),
    CONSTRAINT fk_recibo_pago FOREIGN KEY (id_pago) REFERENCES Pago (id_pago)
) ENGINE=InnoDB;

-- =====================================================
-- TRIGGERS (reglas que antes eran CHECK sobre columnas FK)
-- =====================================================

DELIMITER $$

CREATE TRIGGER trg_sesion_dueno_bi BEFORE INSERT ON Sesion
FOR EACH ROW
BEGIN
    IF (NEW.id_usuario IS NULL) = (NEW.id_cliente IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sesión debe pertenecer a un usuario o a un cliente, no a ambos ni a ninguno';
    END IF;
END$$

CREATE TRIGGER trg_sesion_dueno_bu BEFORE UPDATE ON Sesion
FOR EACH ROW
BEGIN
    IF (NEW.id_usuario IS NULL) = (NEW.id_cliente IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sesión debe pertenecer a un usuario o a un cliente, no a ambos ni a ninguno';
    END IF;
END$$

CREATE TRIGGER trg_movimiento_origen_bi BEFORE INSERT ON Movimiento_Inventario
FOR EACH ROW
BEGIN
    IF NEW.id_detalle_compra IS NOT NULL AND NEW.id_detalle_venta IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento no puede venir de una compra y una venta a la vez';
    END IF;
END$$

CREATE TRIGGER trg_movimiento_origen_bu BEFORE UPDATE ON Movimiento_Inventario
FOR EACH ROW
BEGIN
    IF NEW.id_detalle_compra IS NOT NULL AND NEW.id_detalle_venta IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento no puede venir de una compra y una venta a la vez';
    END IF;
END$$

CREATE TRIGGER trg_orden_pago_origen_bi BEFORE INSERT ON Orden_Pago
FOR EACH ROW
BEGIN
    IF (NEW.id_venta IS NULL) = (NEW.id_servicio IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden de pago debe venir de una venta o de un servicio, no de ambos ni de ninguno';
    END IF;
END$$

CREATE TRIGGER trg_orden_pago_origen_bu BEFORE UPDATE ON Orden_Pago
FOR EACH ROW
BEGIN
    IF (NEW.id_venta IS NULL) = (NEW.id_servicio IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden de pago debe venir de una venta o de un servicio, no de ambos ni de ninguno';
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- DATOS DE PRUEBA (tienda de tecnología)
-- =====================================================

INSERT INTO Proveedor (nombre, telefono, correo, direccion, estado) VALUES
('TecnoMayorista SAS',        '6012345678', 'ventas@tecnomayorista.com',     'Calle 13 # 20-45, Bogotá',        'Activo'),
('Celumundo Distribuciones',  '3104567890', 'pedidos@celumundo.com',         'Carrera 50 # 10-22, Medellín',    'Activo'),
('CompuImport Colombia',      '6019876543', 'comercial@compuimport.com',     'Av. Caracas # 45-12, Bogotá',     'Activo'),
('Accesorios Andinos',        '3157778899', 'contacto@accesoriosandinos.com','Calle 5 # 8-30, Cali',            'Activo'),
('Repuestos Digitales',       '6015551234', 'info@repuestosdigitales.com',   'Carrera 7 # 63-20, Bogotá',       'Activo'),
('Importadora Sur',           '3168889900', NULL,                            'Calle 18 # 25-10, Pasto',         'Inactivo'),
('Gamer Supply SAS',          '3201112233', 'ventas@gamersupply.com',        'Calle 100 # 19-61, Bogotá',       'Activo'),
('Componentes Express',       '6017778899', 'pedidos@componentesexpress.com','Carrera 13 # 54-30, Bogotá',      'Activo'),
('Redes y Cables SAS',        '6014443322', 'ventas@redesycables.com',       'Calle 72 # 10-15, Bogotá',        'Activo'),
('Pantallas del Caribe',      '3004445566', 'ventas@pantallascaribe.com',    'Calle 30 # 20-11, Barranquilla',  'Inactivo');

INSERT INTO Cliente (nombre, correo, telefono, direccion, contrasena_hash) VALUES
('Laura Gómez',          'laura.gomez@correo.com',        '3001112233', 'Calle 80 # 15-20, Bogotá',        'hash_demo'),
('Carlos Ramírez',       'carlos.ramirez@correo.com',     '3012223344', 'Carrera 7 # 32-10, Bogotá',       'hash_demo'),
('Diana Torres',         NULL,                            '3023334455', 'Calle 45 # 22-18, Bogotá',        NULL),
('Andrés Pardo',         'andres.pardo@correo.com',       '3034445566', NULL,                              'hash_demo'),
('Sofía Mejía',          NULL,                            '3045556677', 'Carrera 15 # 90-05, Bogotá',      NULL),
('Julián Rojas',         'julian.rojas@correo.com',       '3056667788', NULL,                              NULL),
('Mariana Quintero',     'mariana.quintero@correo.com',   '3067778899', 'Calle 134 # 55-12, Bogotá',       'hash_demo'),
('Sebastián Cárdenas',   'sebastian.cardenas@correo.com', '3078889900', 'Carrera 68 # 24-30, Bogotá',      NULL),
('Valentina Ospina',     'valentina.ospina@correo.com',   '3089990011', 'Calle 53 # 14-22, Bogotá',        'hash_demo'),
('Daniel Acosta',        NULL,                            '3090001122', 'Av. Boyacá # 80-45, Bogotá',      NULL);

INSERT INTO Usuario (nombre, correo, contrasena_hash, rol, departamento, especialidad) VALUES
('Jorge Herrera',   'jorge.herrera@arif.com',   'hash_demo', 'Administrador',           'Gerencia',  NULL),
('Ricardo Salas',   'ricardo.salas@arif.com',   'hash_demo', 'Administrador',           'Sistemas',  NULL),
('Mario Castro',    'mario.castro@arif.com',    'hash_demo', 'Tendero',                 'Ventas',    NULL),
('Paola Díaz',      'paola.diaz@arif.com',      'hash_demo', 'Tendero',                 'Ventas',    NULL),
('Valeria Ortiz',   'valeria.ortiz@arif.com',   'hash_demo', 'Tendero',                 'Ventas',    NULL),
('Lucía Vargas',    'lucia.vargas@arif.com',    'hash_demo', 'Encargado de inventario', 'Bodega',    NULL),
('Andrés Beltrán',  'andres.beltran@arif.com',  'hash_demo', 'Encargado de inventario', 'Bodega',    NULL),
('Camilo Ruiz',     'camilo.ruiz@arif.com',     'hash_demo', 'Tecnico',                 'Taller',    'Celulares'),
('Natalia Peña',    'natalia.pena@arif.com',    'hash_demo', 'Tecnico',                 'Taller',    'Portátiles'),
('Felipe Mora',     'felipe.mora@arif.com',     'hash_demo', 'Tecnico',                 'Taller',    'Televisores y consolas');

INSERT INTO Sesion (id_usuario, id_cliente, fecha_inicio, fecha_fin) VALUES
(3,    NULL, NOW() - INTERVAL 2 HOUR, NULL),
(4,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '08:00:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '17:00:00')),
(5,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '08:10:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '16:50:00')),
(1,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '09:00:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '12:30:00')),
(2,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '09:15:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '18:00:00')),
(6,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 4 DAY), '07:30:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 4 DAY), '15:00:00')),
(8,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '08:00:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '17:00:00')),
(9,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '08:30:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '17:30:00')),
(NULL, 1,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '19:10:00'), TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '19:40:00')),
(NULL, 2,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '20:00:00'), NULL);

-- Stock = entradas - salidas registradas en Movimiento_Inventario
INSERT INTO Producto (nombre, descripcion, categoria, precio_unitario, cantidad_disponible, ubicacion, fecha_actualizacion) VALUES
('Samsung Galaxy A15 128GB',       'Smartphone 6.5" AMOLED, 4GB RAM, 128GB',        'Celulares',   780000.00, 17, 'Vitrina A1',    DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
('Xiaomi Redmi 13C 128GB',         'Smartphone 6.74" HD+, 4GB RAM, 128GB',          'Celulares',   520000.00, 23, 'Vitrina A2',    DATE_SUB(CURDATE(), INTERVAL 7 DAY)),
('Portátil Lenovo IdeaPad 3 15"',  'Intel Core i5, 8GB RAM, SSD 512GB',             'Portátiles', 2200000.00,  9, 'Estante B1',    DATE_SUB(CURDATE(), INTERVAL 13 DAY)),
('Portátil HP 250 G9',             'Intel Core i3, 8GB RAM, SSD 256GB',             'Portátiles', 1900000.00,  7, 'Estante B1',    DATE_SUB(CURDATE(), INTERVAL 2 DAY)),
('Audífonos Bluetooth JBL Tune 510BT', 'Audífonos on-ear inalámbricos',             'Audio',       150000.00, 28, 'Vitrina C1',    DATE_SUB(CURDATE(), INTERVAL 11 DAY)),
('Cargador rápido 25W USB-C',      'Cargador de pared USB-C carga rápida',          'Accesorios',   45000.00, 57, 'Vitrina C2',    DATE_SUB(CURDATE(), INTERVAL 10 DAY)),
('Cable USB-C a USB-C 1m',         'Cable de carga y datos trenzado',               'Accesorios',   18000.00, 75, 'Vitrina C2',    DATE_SUB(CURDATE(), INTERVAL 6 DAY)),
('Mouse inalámbrico Logitech M170','Mouse óptico inalámbrico 2.4GHz',               'Periféricos',  42000.00, 38, 'Vitrina C3',    DATE_SUB(CURDATE(), INTERVAL 5 DAY)),
('SSD Kingston A400 480GB',        'Unidad de estado sólido SATA 2.5"',             'Componentes', 160000.00, 24, 'Estante D1',    DATE_SUB(CURDATE(), INTERVAL 4 DAY)),
('Memoria RAM DDR4 8GB 3200MHz',   'Módulo RAM para portátil y escritorio',         'Componentes', 120000.00,  0, 'Estante D1',    DATE_SUB(CURDATE(), INTERVAL 2 DAY));

INSERT INTO Compra (id_proveedor, id_usuario, fecha_compra, total_compra, metodo_pago, estado_compra) VALUES
(2, 6, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 13000000.00, 'Transferencia', 'Recibida'),
(2, 6, DATE_SUB(CURDATE(), INTERVAL 28 DAY), 10750000.00, 'Transferencia', 'Recibida'),
(3, 7, DATE_SUB(CURDATE(), INTERVAL 26 DAY), 18500000.00, 'Transferencia', 'Recibida'),
(3, 7, DATE_SUB(CURDATE(), INTERVAL 24 DAY), 12800000.00, 'Tarjeta',       'Recibida'),
(4, 6, DATE_SUB(CURDATE(), INTERVAL 20 DAY),  3150000.00, 'Transferencia', 'Recibida'),
(4, 6, DATE_SUB(CURDATE(), INTERVAL 18 DAY),  1680000.00, 'Efectivo',      'Recibida'),
(9, 7, DATE_SUB(CURDATE(), INTERVAL 15 DAY),   720000.00, 'Efectivo',      'Recibida'),
(4, 6, DATE_SUB(CURDATE(), INTERVAL 12 DAY),  1120000.00, 'Transferencia', 'Recibida'),
(8, 7, DATE_SUB(CURDATE(), INTERVAL 8 DAY),   2875000.00, 'Transferencia', 'Recibida'),
(8, 6, DATE_SUB(CURDATE(), INTERVAL 2 DAY),   2460000.00, 'Tarjeta',       'Pendiente');

INSERT INTO Detalle_Compra (id_compra, id_producto, cantidad, precio_compra) VALUES
(1,  1, 20,  650000.00),
(2,  2, 25,  430000.00),
(3,  3, 10, 1850000.00),
(4,  4,  8, 1600000.00),
(5,  5, 30,  105000.00),
(6,  6, 60,   28000.00),
(7,  7, 80,    9000.00),
(8,  8, 40,   28000.00),
(9,  9, 25,  115000.00),
(10, 10, 30,  82000.00);

INSERT INTO Venta (id_cliente, id_usuario, fecha_venta, total_venta) VALUES
(1,  3, DATE_SUB(CURDATE(), INTERVAL 14 DAY),  780000.00),
(2,  3, DATE_SUB(CURDATE(), INTERVAL 13 DAY), 2200000.00),
(3,  4, DATE_SUB(CURDATE(), INTERVAL 11 DAY),  300000.00),
(4,  4, DATE_SUB(CURDATE(), INTERVAL 10 DAY),  135000.00),
(5,  5, DATE_SUB(CURDATE(), INTERVAL 9 DAY),    72000.00),
(6,  3, DATE_SUB(CURDATE(), INTERVAL 7 DAY),  1040000.00),
(7,  5, DATE_SUB(CURDATE(), INTERVAL 5 DAY),    84000.00),
(8,  4, DATE_SUB(CURDATE(), INTERVAL 4 DAY),   160000.00),
(9,  3, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  1900000.00),
(10, 5, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  1560000.00);

INSERT INTO Detalle_Venta (id_venta, id_producto, cantidad, valor_unitario) VALUES
(1,  1, 1,  780000.00),
(2,  3, 1, 2200000.00),
(3,  5, 2,  150000.00),
(4,  6, 3,   45000.00),
(5,  7, 4,   18000.00),
(6,  2, 2,  520000.00),
(7,  8, 2,   42000.00),
(8,  9, 1,  160000.00),
(9,  4, 1, 1900000.00),
(10, 1, 2,  780000.00);

INSERT INTO Movimiento_Inventario (id_producto, id_usuario, tipo_movimiento, cantidad, fecha_movimiento, motivo, id_detalle_compra, id_detalle_venta, observaciones) VALUES
-- Entradas por compras recibidas
(1, 6, 'Entrada', 20, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 'Compra', 1, NULL, NULL),
(2, 6, 'Entrada', 25, DATE_SUB(CURDATE(), INTERVAL 28 DAY), 'Compra', 2, NULL, NULL),
(3, 7, 'Entrada', 10, DATE_SUB(CURDATE(), INTERVAL 26 DAY), 'Compra', 3, NULL, NULL),
(4, 7, 'Entrada',  8, DATE_SUB(CURDATE(), INTERVAL 24 DAY), 'Compra', 4, NULL, NULL),
(5, 6, 'Entrada', 30, DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'Compra', 5, NULL, NULL),
(6, 6, 'Entrada', 60, DATE_SUB(CURDATE(), INTERVAL 18 DAY), 'Compra', 6, NULL, NULL),
(7, 7, 'Entrada', 80, DATE_SUB(CURDATE(), INTERVAL 15 DAY), 'Compra', 7, NULL, NULL),
(8, 6, 'Entrada', 40, DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'Compra', 8, NULL, NULL),
(9, 7, 'Entrada', 25, DATE_SUB(CURDATE(), INTERVAL 8 DAY),  'Compra', 9, NULL, NULL),
-- Salidas por ventas
(1, 3, 'Salida', 1, DATE_SUB(CURDATE(), INTERVAL 14 DAY), 'Venta', NULL, 1, NULL),
(3, 3, 'Salida', 1, DATE_SUB(CURDATE(), INTERVAL 13 DAY), 'Venta', NULL, 2, NULL),
(5, 4, 'Salida', 2, DATE_SUB(CURDATE(), INTERVAL 11 DAY), 'Venta', NULL, 3, NULL),
(6, 4, 'Salida', 3, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'Venta', NULL, 4, NULL),
(7, 5, 'Salida', 4, DATE_SUB(CURDATE(), INTERVAL 9 DAY),  'Venta', NULL, 5, NULL),
(2, 3, 'Salida', 2, DATE_SUB(CURDATE(), INTERVAL 7 DAY),  'Venta', NULL, 6, NULL),
(8, 5, 'Salida', 2, DATE_SUB(CURDATE(), INTERVAL 5 DAY),  'Venta', NULL, 7, NULL),
(9, 4, 'Salida', 1, DATE_SUB(CURDATE(), INTERVAL 4 DAY),  'Venta', NULL, 8, NULL),
(4, 3, 'Salida', 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'Venta', NULL, 9, NULL),
(1, 5, 'Salida', 2, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'Venta', NULL, 10, NULL),
-- Baja por daño
(7, 7, 'Salida', 1, DATE_SUB(CURDATE(), INTERVAL 6 DAY),  'Daño', NULL, NULL, 'Cable con falla de fábrica');

INSERT INTO Historial (id_usuario, fecha_modificacion, tipo_modificacion) VALUES
(1, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 45 DAY), '10:00:00'), 'Creación'),
(1, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 40 DAY), '09:00:00'), 'Creación'),
(2, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 30 DAY), '15:00:00'), 'Actualización'),
(6, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 28 DAY), '08:30:00'), 'Creación'),
(7, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 20 DAY), '10:15:00'), 'Actualización'),
(6, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 15 DAY), '11:30:00'), 'Eliminación'),
(3, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 10 DAY), '14:00:00'), 'Actualización'),
(4, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 7 DAY),  '16:20:00'), 'Creación'),
(1, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY),  '09:45:00'), 'Actualización'),
(2, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY),  '08:30:00'), 'Eliminación');

INSERT INTO Reporte (id_usuario, tipo, fecha_reporte, datos) VALUES
(6, 'Existencias', DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'Existencias iniciales por producto tras recepción de compras'),
(7, 'Entradas',    DATE_SUB(CURDATE(), INTERVAL 15 DAY), 'Entradas de portátiles y accesorios del periodo'),
(1, 'Salidas',     DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'Salidas por ventas de la semana anterior'),
(6, 'Existencias', DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'Resumen de existencias por categoría'),
(2, 'Entradas',    DATE_SUB(CURDATE(), INTERVAL 8 DAY),  'Entradas de componentes (SSD y memorias)'),
(1, 'Salidas',     DATE_SUB(CURDATE(), INTERVAL 6 DAY),  'Salidas por ventas y bajas por daño'),
(7, 'Existencias', DATE_SUB(CURDATE(), INTERVAL 5 DAY),  'Productos con stock bajo: portátiles y RAM'),
(6, 'Entradas',    DATE_SUB(CURDATE(), INTERVAL 3 DAY),  'Compras recibidas en los últimos 30 días'),
(2, 'Salidas',     DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'Ventas de celulares y portátiles'),
(1, 'Existencias', DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'Corte de existencias del día');

INSERT INTO Aparato (id_cliente, tipo, marca, modelo, estado) VALUES
(1,  'Celular',  'Samsung',  'Galaxy A54',          'Entregado'),
(2,  'Portátil', 'Lenovo',   'IdeaPad 3 15"',       'Entregado'),
(3,  'Celular',  'Xiaomi',   'Redmi Note 12',       'Reparado'),
(4,  'Portátil', 'HP',       'Pavilion 15',         'En reparación'),
(5,  'Televisor','LG',       '43 pulgadas 43UQ7500','Entregado'),
(6,  'Consola',  'Sony',     'PlayStation 4 Slim',  'Reparado'),
(7,  'Tablet',   'Samsung',  'Galaxy Tab A8',       'Recibido'),
(8,  'Celular',  'Apple',    'iPhone 11',           'Entregado'),
(9,  'Portátil', 'Asus',     'VivoBook 14',         'En reparación'),
(10, 'Celular',  'Motorola', 'Moto G23',            'Recibido');

INSERT INTO Servicio (id_cliente, id_usuario, id_aparato, id_tecnico, fecha_ingreso, estado, diagnostico) VALUES
(1,  3, 1,  8,    DATE_SUB(CURDATE(), INTERVAL 25 DAY), 'Finalizado', 'Cambio de pantalla AMOLED'),
(2,  4, 2,  9,    DATE_SUB(CURDATE(), INTERVAL 22 DAY), 'Finalizado', 'Cambio de disco HDD por SSD y limpieza interna'),
(3,  3, 3,  8,    DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'Finalizado', 'Cambio de puerto de carga'),
(4,  5, 4,  9,    DATE_SUB(CURDATE(), INTERVAL 6 DAY),  'En proceso', 'Reemplazo de teclado y mantenimiento térmico'),
(5,  4, 5,  10,   DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'Finalizado', 'Cambio de tira LED de retroiluminación'),
(6,  3, 6,  10,   DATE_SUB(CURDATE(), INTERVAL 5 DAY),  'Finalizado', 'Cambio de lector de discos y limpieza'),
(7,  5, 7,  NULL, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'Pendiente',  NULL),
(8,  4, 8,  8,    DATE_SUB(CURDATE(), INTERVAL 9 DAY),  'Finalizado', 'Cambio de batería'),
(9,  5, 9,  9,    DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'En proceso', 'Equipo no enciende, revisión de placa base'),
(10, 3, 10, NULL, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'Pendiente',  NULL);

-- Solo hay encuesta para los servicios finalizados (1, 2, 3, 5, 6, 8)
INSERT INTO Encuesta_Satisfaccion (id_servicio, id_cliente, id_usuario, calificacion, comentarios) VALUES
(1, 1, 3, 5, 'Excelente servicio, el celular quedó como nuevo'),
(2, 2, 4, 4, 'Buen trabajo, se demoró un poco'),
(3, 3, 3, 5, 'Rápido y a buen precio'),
(5, 5, 4, 3, 'Funciona bien pero tardó más de lo prometido'),
(6, 6, 3, 4, 'Buena atención'),
(8, 8, 4, 5, 'Muy recomendado');

INSERT INTO Orden_Pago (id_cliente, id_usuario, id_venta, id_servicio, fecha_ingreso, estado, costo_total) VALUES
(1,  3, 1,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 14 DAY), '10:00:00'),  'Pagada',     780000.00),
(2,  3, 2,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 13 DAY), '11:00:00'),  'Pagada',    2200000.00),
(9,  3, 9,    NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY),  '15:00:00'),  'En proceso',1900000.00),
(10, 5, 10,   NULL, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY),  '16:00:00'),  'Pagada',    1560000.00),
(1,  3, NULL, 1,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 23 DAY), '09:00:00'),  'Pagada',     180000.00),
(2,  4, NULL, 2,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 20 DAY), '10:00:00'),  'Pagada',     220000.00),
(3,  3, NULL, 3,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 10 DAY), '14:00:00'),  'Pagada',      90000.00),
(5,  4, NULL, 5,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 18 DAY), '09:30:00'),  'Pagada',     150000.00),
(6,  3, NULL, 6,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY),  '11:00:00'),  'Pendiente',  120000.00),
(8,  4, NULL, 8,    TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY),  '12:00:00'),  'Pagada',     130000.00);

INSERT INTO Pasarela_Pago (nombre_pasarela) VALUES
('Wompi'),
('PayU'),
('Mercado Pago'),
('ePayco'),
('Nequi'),
('Daviplata'),
('Bold'),
('Addi'),
('Stripe'),
('PayPal');

INSERT INTO Pago (id_orden_pago, id_usuario, id_pasarela, monto, fecha_pago, metodo_pago, estado, token_transaccion) VALUES
(1,  3,    NULL, 780000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 14 DAY), '10:05:00'), 'Efectivo',      'Aprobado', NULL),
(2,  NULL, 1,    1000000.00, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 13 DAY), '11:10:00'), 'Tarjeta',       'Aprobado', 'tok_wompi_0001'),
(2,  NULL, 1,    1200000.00, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 12 DAY), '09:30:00'), 'PSE',           'Aprobado', 'tok_wompi_0002'),
(3,  NULL, 2,    900000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY),  '15:20:00'), 'PSE',           'Aprobado', 'tok_payu_0001'),
(4,  5,    NULL, 1560000.00, TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY),  '16:10:00'), 'Transferencia', 'Aprobado', NULL),
(5,  3,    NULL, 180000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 23 DAY), '09:15:00'), 'Efectivo',      'Aprobado', NULL),
(6,  NULL, 3,    220000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 20 DAY), '10:20:00'), 'Tarjeta',       'Aprobado', 'tok_mp_0001'),
(7,  3,    NULL, 90000.00,   TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 10 DAY), '14:10:00'), 'Efectivo',      'Aprobado', NULL),
(8,  4,    NULL, 150000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 18 DAY), '09:45:00'), 'Transferencia', 'Aprobado', NULL),
(10, 4,    NULL, 130000.00,  TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 8 DAY),  '12:10:00'), 'Efectivo',      'Aprobado', NULL);

INSERT INTO Recibo (id_pago, numero_recibo, fecha_emision, detalles_adicionales) VALUES
(1,  'R-0001', DATE_SUB(CURDATE(), INTERVAL 14 DAY), 'Venta Samsung Galaxy A15'),
(2,  'R-0002', DATE_SUB(CURDATE(), INTERVAL 13 DAY), 'Abono 1 de 2'),
(3,  'R-0003', DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'Abono 2 de 2 - saldo cancelado'),
(4,  'R-0004', DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'Abono 1 de 2 - saldo pendiente $1.000.000'),
(5,  'R-0005', DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'Pago total de contado'),
(6,  'R-0006', DATE_SUB(CURDATE(), INTERVAL 23 DAY), 'Servicio técnico: cambio de pantalla'),
(7,  'R-0007', DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'Servicio técnico: SSD e instalación'),
(8,  'R-0008', DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'Servicio técnico: puerto de carga'),
(9,  'R-0009', DATE_SUB(CURDATE(), INTERVAL 18 DAY), 'Servicio técnico: retroiluminación TV'),
(10, 'R-0010', DATE_SUB(CURDATE(), INTERVAL 8 DAY),  'Servicio técnico: cambio de batería');
