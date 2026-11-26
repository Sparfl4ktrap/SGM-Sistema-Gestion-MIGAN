DROP DATABASE IF EXISTS sgm_arif;
CREATE DATABASE sgm_arif CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgm_arif;

CREATE TABLE Proveedor (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  telefono     VARCHAR(15)  NULL,
  correo       VARCHAR(100) NULL,
  direccion    VARCHAR(150) NULL,
  estado       VARCHAR(10)  NOT NULL DEFAULT 'Activo',
  CONSTRAINT uq_proveedor_correo UNIQUE (correo),
  CONSTRAINT chk_proveedor_telefono CHECK (telefono IS NULL OR telefono REGEXP '^[0-9]+$'),
  CONSTRAINT chk_proveedor_correo   CHECK (correo IS NULL OR correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
  CONSTRAINT chk_proveedor_estado   CHECK (estado IN ('Activo','Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Cliente (
  id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,
  correo          VARCHAR(100) NULL,
  telefono        VARCHAR(15)  NULL,
  direccion       VARCHAR(150) NULL,
  contrasena_hash VARCHAR(255) NULL,
  CONSTRAINT uq_cliente_correo UNIQUE (correo),
  CONSTRAINT chk_cliente_correo   CHECK (correo IS NULL OR correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
  CONSTRAINT chk_cliente_telefono CHECK (telefono IS NULL OR telefono REGEXP '^[0-9]+$'),
  CONSTRAINT chk_cliente_contacto CHECK (correo IS NOT NULL OR telefono IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE Usuario (
  id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(100) NOT NULL,
  correo          VARCHAR(100) NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  rol             VARCHAR(30)  NOT NULL,
  departamento    VARCHAR(50)  NULL,
  especialidad    VARCHAR(50)  NULL,
  estado          VARCHAR(10)  NOT NULL DEFAULT 'Activo',
  CONSTRAINT uq_usuario_correo UNIQUE (correo),
  CONSTRAINT chk_usuario_correo CHECK (correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
  CONSTRAINT chk_usuario_rol    CHECK (rol IN ('Administrador','Encargado_Inventario','Tendero','Tecnico')),
  CONSTRAINT chk_usuario_depto  CHECK (departamento IS NULL OR rol IN ('Administrador','Encargado_Inventario')),
  CONSTRAINT chk_usuario_espec  CHECK ((rol = 'Tecnico' AND especialidad IS NOT NULL) OR (rol <> 'Tecnico' AND especialidad IS NULL)),
  CONSTRAINT chk_usuario_estado CHECK (estado IN ('Activo','Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Sesion (
  id_sesion    INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario   INT NULL,
  id_cliente   INT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin    DATETIME NULL,
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  CONSTRAINT fk_sesion_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
  CONSTRAINT chk_sesion_actor  CHECK ((id_usuario IS NULL AND id_cliente IS NOT NULL) OR (id_usuario IS NOT NULL AND id_cliente IS NULL)),
  CONSTRAINT chk_sesion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE Categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(50)  NOT NULL,
  descripcion  VARCHAR(150) NULL,
  CONSTRAINT uq_categoria_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE Producto (
  id_producto     INT AUTO_INCREMENT PRIMARY KEY,
  id_categoria    INT NOT NULL,
  id_proveedor    INT NULL,
  nombre          VARCHAR(100) NOT NULL,
  descripcion     VARCHAR(255) NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  estado          VARCHAR(10)  NOT NULL DEFAULT 'Activo',
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES Categoria (id_categoria),
  CONSTRAINT fk_producto_proveedor FOREIGN KEY (id_proveedor) REFERENCES Proveedor (id_proveedor),
  CONSTRAINT chk_producto_precio CHECK (precio_unitario >= 0),
  CONSTRAINT chk_producto_estado CHECK (estado IN ('Activo','Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Metodo_Pago (
  id_metodo_pago    INT AUTO_INCREMENT PRIMARY KEY,
  nombre            VARCHAR(30) NOT NULL,
  requiere_pasarela BOOLEAN NOT NULL DEFAULT 0,
  estado            VARCHAR(10) NOT NULL DEFAULT 'Activo',
  CONSTRAINT uq_metodo_pago_nombre UNIQUE (nombre),
  CONSTRAINT chk_metodo_pago_estado CHECK (estado IN ('Activo','Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Pasarela_Pago (
  id_pasarela     INT AUTO_INCREMENT PRIMARY KEY,
  nombre_pasarela VARCHAR(80) NOT NULL,
  estado          VARCHAR(10) NOT NULL DEFAULT 'Activo',
  CONSTRAINT uq_pasarela_nombre UNIQUE (nombre_pasarela),
  CONSTRAINT chk_pasarela_estado CHECK (estado IN ('Activo','Inactivo'))
) ENGINE=InnoDB;

CREATE TABLE Compra (
  id_compra          INT AUTO_INCREMENT PRIMARY KEY,
  id_proveedor       INT NOT NULL,
  id_usuario         INT NOT NULL,
  id_metodo_pago     INT NOT NULL,
  fecha_compra       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_confirmacion DATETIME NULL,
  total_compra       DECIMAL(12,2) NOT NULL,
  estado_compra      VARCHAR(20) NOT NULL DEFAULT 'Registrada',
  CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor)   REFERENCES Proveedor (id_proveedor),
  CONSTRAINT fk_compra_usuario   FOREIGN KEY (id_usuario)     REFERENCES Usuario (id_usuario),
  CONSTRAINT fk_compra_metodo    FOREIGN KEY (id_metodo_pago) REFERENCES Metodo_Pago (id_metodo_pago),
  CONSTRAINT chk_compra_total   CHECK (total_compra >= 0),
  CONSTRAINT chk_compra_estado  CHECK (estado_compra IN ('Registrada','Confirmada','Recibida','Anulada')),
  CONSTRAINT chk_compra_fechas  CHECK (fecha_confirmacion IS NULL OR fecha_confirmacion >= fecha_compra)
) ENGINE=InnoDB;

CREATE TABLE Detalle_Compra (
  id_detalle_compra INT AUTO_INCREMENT PRIMARY KEY,
  id_compra         INT NOT NULL,
  id_producto       INT NOT NULL,
  cantidad          INT NOT NULL,
  valor_unitario    DECIMAL(12,2) NOT NULL,
  subtotal          DECIMAL(12,2) NOT NULL,
  stock_actual      INT NOT NULL,
  CONSTRAINT fk_detcompra_compra   FOREIGN KEY (id_compra)   REFERENCES Compra (id_compra),
  CONSTRAINT fk_detcompra_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
  CONSTRAINT uq_detcompra_compra_producto UNIQUE (id_compra, id_producto),
  CONSTRAINT chk_detcompra_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_detcompra_valor    CHECK (valor_unitario >= 0),
  CONSTRAINT chk_detcompra_subtotal CHECK (subtotal = cantidad * valor_unitario),
  CONSTRAINT chk_detcompra_stock    CHECK (stock_actual >= 0)
) ENGINE=InnoDB;

CREATE TABLE Venta (
  id_venta           INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente         INT NOT NULL,
  id_usuario         INT NOT NULL,
  fecha_venta        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_confirmacion DATETIME NULL,
  total_venta        DECIMAL(12,2) NOT NULL,
  estado_venta       VARCHAR(20) NOT NULL DEFAULT 'En proceso',
  CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
  CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  CONSTRAINT chk_venta_total  CHECK (total_venta >= 0),
  CONSTRAINT chk_venta_estado CHECK (estado_venta IN ('En proceso','Confirmada','Finalizada','Anulada')),
  CONSTRAINT chk_venta_fechas CHECK (fecha_confirmacion IS NULL OR fecha_confirmacion >= fecha_venta)
) ENGINE=InnoDB;

CREATE TABLE Detalle_Venta (
  id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_venta         INT NOT NULL,
  id_producto      INT NOT NULL,
  cantidad         INT NOT NULL,
  valor_unitario   DECIMAL(12,2) NOT NULL,
  subtotal         DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_detventa_venta    FOREIGN KEY (id_venta)    REFERENCES Venta (id_venta),
  CONSTRAINT fk_detventa_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
  CONSTRAINT uq_detventa_venta_producto UNIQUE (id_venta, id_producto),
  CONSTRAINT chk_detventa_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_detventa_valor    CHECK (valor_unitario >= 0),
  CONSTRAINT chk_detventa_subtotal CHECK (subtotal = cantidad * valor_unitario)
) ENGINE=InnoDB;

CREATE TABLE Inventario (
  id_inventario       INT AUTO_INCREMENT PRIMARY KEY,
  id_producto         INT NOT NULL,
  cantidad_disponible INT NOT NULL,
  stock_minimo        INT NOT NULL,
  ubicacion           VARCHAR(100) NULL,
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventario_producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
  CONSTRAINT uq_inventario_producto UNIQUE (id_producto),
  CONSTRAINT chk_inventario_cantidad CHECK (cantidad_disponible >= 0),
  CONSTRAINT chk_inventario_minimo   CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE TABLE Movimiento_Inventario (
  id_movimiento     INT AUTO_INCREMENT PRIMARY KEY,
  id_producto       INT NOT NULL,
  id_usuario        INT NOT NULL,
  id_detalle_compra INT NULL,
  id_detalle_venta  INT NULL,
  tipo_movimiento   VARCHAR(10) NOT NULL,
  motivo            VARCHAR(30) NOT NULL,
  cantidad          INT NOT NULL,
  fecha_movimiento  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones     VARCHAR(255) NULL,
  CONSTRAINT fk_mov_producto FOREIGN KEY (id_producto)       REFERENCES Producto (id_producto),
  CONSTRAINT fk_mov_usuario  FOREIGN KEY (id_usuario)        REFERENCES Usuario (id_usuario),
  CONSTRAINT fk_mov_detcomp  FOREIGN KEY (id_detalle_compra) REFERENCES Detalle_Compra (id_detalle_compra),
  CONSTRAINT fk_mov_detvent  FOREIGN KEY (id_detalle_venta)  REFERENCES Detalle_Venta (id_detalle_venta),
  CONSTRAINT uq_mov_detcomp UNIQUE (id_detalle_compra),
  CONSTRAINT uq_mov_detvent UNIQUE (id_detalle_venta),
  CONSTRAINT chk_mov_tipo     CHECK (tipo_movimiento IN ('Entrada','Salida')),
  CONSTRAINT chk_mov_motivo   CHECK (motivo IN ('Compra','Venta','Daño','Vencimiento','Ajuste')),
  CONSTRAINT chk_mov_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_mov_coherencia CHECK (
        (motivo = 'Compra' AND tipo_movimiento = 'Entrada' AND id_detalle_compra IS NOT NULL AND id_detalle_venta IS NULL)
     OR (motivo = 'Venta'  AND tipo_movimiento = 'Salida'  AND id_detalle_venta  IS NOT NULL AND id_detalle_compra IS NULL)
     OR (motivo IN ('Daño','Vencimiento') AND tipo_movimiento = 'Salida' AND id_detalle_compra IS NULL AND id_detalle_venta IS NULL)
     OR (motivo = 'Ajuste' AND id_detalle_compra IS NULL AND id_detalle_venta IS NULL))
) ENGINE=InnoDB;

CREATE TABLE Alerta_Stock (
  id_alerta           INT AUTO_INCREMENT PRIMARY KEY,
  id_producto         INT NOT NULL,
  id_movimiento       INT NULL,
  cantidad_registrada INT NOT NULL,
  fecha_alerta        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado              VARCHAR(15) NOT NULL DEFAULT 'Activa',
  CONSTRAINT fk_alerta_producto   FOREIGN KEY (id_producto)   REFERENCES Producto (id_producto),
  CONSTRAINT fk_alerta_movimiento FOREIGN KEY (id_movimiento) REFERENCES Movimiento_Inventario (id_movimiento),
  CONSTRAINT chk_alerta_cantidad CHECK (cantidad_registrada >= 0),
  CONSTRAINT chk_alerta_estado   CHECK (estado IN ('Activa','Atendida'))
) ENGINE=InnoDB;

CREATE TABLE Historial (
  id_historial       INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario         INT NOT NULL,
  tabla_afectada     VARCHAR(40) NOT NULL,
  id_registro        INT NOT NULL,
  tipo_modificacion  VARCHAR(30) NOT NULL,
  detalle            TEXT NULL,
  fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  CONSTRAINT chk_historial_registro CHECK (id_registro > 0),
  CONSTRAINT chk_historial_tipo CHECK (tipo_modificacion IN ('Creación','Actualización','Eliminación'))
) ENGINE=InnoDB;

CREATE TABLE Reporte (
  id_reporte          INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario          INT NOT NULL,
  tipo                VARCHAR(30) NOT NULL,
  fecha_reporte       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  datos               TEXT NULL,
  formato_exportacion VARCHAR(10) NULL,
  fecha_exportacion   DATETIME NULL,
  CONSTRAINT fk_reporte_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  CONSTRAINT chk_reporte_formato CHECK (formato_exportacion IS NULL OR formato_exportacion IN ('PDF','XLSX','CSV'))
) ENGINE=InnoDB;

CREATE TABLE Aparato (
  id_aparato      INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente      INT NOT NULL,
  tipo            VARCHAR(50)  NOT NULL,
  marca           VARCHAR(50)  NOT NULL,
  modelo          VARCHAR(50)  NULL,
  numero_serie    VARCHAR(50)  NULL,
  falla_reportada VARCHAR(255) NOT NULL,
  estado          VARCHAR(20)  NOT NULL DEFAULT 'Recibido',
  CONSTRAINT fk_aparato_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
  CONSTRAINT uq_aparato_serie UNIQUE (numero_serie),
  CONSTRAINT chk_aparato_estado CHECK (estado IN ('Recibido','En reparación','Reparado','Entregado'))
) ENGINE=InnoDB;

CREATE TABLE Servicio (
  id_servicio    INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente     INT NOT NULL,
  id_aparato     INT NOT NULL,
  id_usuario     INT NOT NULL,
  id_tecnico     INT NULL,
  fecha_ingreso  DATETIME NOT NULL,
  estado         VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
  diagnostico    TEXT NULL,
  valor_servicio DECIMAL(12,2) NULL,
  fecha_entrega  DATETIME NULL,
  CONSTRAINT fk_servicio_cliente FOREIGN KEY (id_cliente) REFERENCES Cliente (id_cliente),
  CONSTRAINT fk_servicio_aparato FOREIGN KEY (id_aparato) REFERENCES Aparato (id_aparato),
  CONSTRAINT fk_servicio_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  CONSTRAINT fk_servicio_tecnico FOREIGN KEY (id_tecnico) REFERENCES Usuario (id_usuario),
  CONSTRAINT chk_servicio_estado CHECK (estado IN ('Pendiente','En diagnóstico','Valorado','En reparación','Finalizado','Entregado','Cancelado')),
  CONSTRAINT chk_servicio_valor  CHECK (valor_servicio IS NULL OR valor_servicio >= 0),
  CONSTRAINT chk_servicio_entrega CHECK (fecha_entrega IS NULL OR (estado = 'Entregado' AND fecha_entrega >= fecha_ingreso))
) ENGINE=InnoDB;

CREATE TABLE Encuesta_Satisfaccion (
  id_encuesta    INT AUTO_INCREMENT PRIMARY KEY,
  id_servicio    INT NOT NULL,
  id_cliente     INT NOT NULL,
  id_usuario     INT NOT NULL,
  calificacion   INT NOT NULL,
  comentarios    VARCHAR(500) NULL,
  fecha_encuesta DATETIME NOT NULL,
  CONSTRAINT fk_encuesta_servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
  CONSTRAINT fk_encuesta_cliente  FOREIGN KEY (id_cliente)  REFERENCES Cliente (id_cliente),
  CONSTRAINT fk_encuesta_usuario  FOREIGN KEY (id_usuario)  REFERENCES Usuario (id_usuario),
  CONSTRAINT uq_encuesta_servicio UNIQUE (id_servicio),
  CONSTRAINT chk_encuesta_calificacion CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE Orden_Pago (
  id_orden_pago INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente    INT NOT NULL,
  id_usuario    INT NOT NULL,
  id_venta      INT NULL,
  id_servicio   INT NULL,
  fecha_orden   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado        VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
  costo_total   DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_orden_cliente  FOREIGN KEY (id_cliente)  REFERENCES Cliente (id_cliente),
  CONSTRAINT fk_orden_usuario  FOREIGN KEY (id_usuario)  REFERENCES Usuario (id_usuario),
  CONSTRAINT fk_orden_venta    FOREIGN KEY (id_venta)    REFERENCES Venta (id_venta),
  CONSTRAINT fk_orden_servicio FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio),
  CONSTRAINT uq_orden_venta    UNIQUE (id_venta),
  CONSTRAINT uq_orden_servicio UNIQUE (id_servicio),
  CONSTRAINT chk_orden_origen CHECK ((id_venta IS NOT NULL AND id_servicio IS NULL) OR (id_venta IS NULL AND id_servicio IS NOT NULL)),
  CONSTRAINT chk_orden_estado CHECK (estado IN ('Pendiente','Abonada','Pagada','Cancelada')),
  CONSTRAINT chk_orden_costo  CHECK (costo_total >= 0)
) ENGINE=InnoDB;

CREATE TABLE Pago (
  id_pago           INT AUTO_INCREMENT PRIMARY KEY,
  id_orden_pago     INT NOT NULL,
  id_metodo_pago    INT NOT NULL,
  id_pasarela       INT NULL,
  id_usuario        INT NULL,
  tipo_pago         VARCHAR(10) NOT NULL,
  monto             DECIMAL(12,2) NOT NULL,
  fecha_pago        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado            VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
  token_transaccion VARCHAR(255) NULL,
  CONSTRAINT fk_pago_orden    FOREIGN KEY (id_orden_pago)  REFERENCES Orden_Pago (id_orden_pago),
  CONSTRAINT fk_pago_metodo   FOREIGN KEY (id_metodo_pago) REFERENCES Metodo_Pago (id_metodo_pago),
  CONSTRAINT fk_pago_pasarela FOREIGN KEY (id_pasarela)    REFERENCES Pasarela_Pago (id_pasarela),
  CONSTRAINT fk_pago_usuario  FOREIGN KEY (id_usuario)     REFERENCES Usuario (id_usuario),
  CONSTRAINT chk_pago_tipo   CHECK (tipo_pago IN ('Abono','Total')),
  CONSTRAINT chk_pago_monto  CHECK (monto > 0),
  CONSTRAINT chk_pago_estado CHECK (estado IN ('Pendiente','Aprobado','Rechazado','Fallido'))
) ENGINE=InnoDB;

CREATE TABLE Recibo (
  id_recibo            INT AUTO_INCREMENT PRIMARY KEY,
  id_pago              INT NOT NULL,
  numero_recibo        VARCHAR(40) NOT NULL,
  fecha_emision        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detalles_adicionales TEXT NULL,
  canal_envio          VARCHAR(15) NULL,
  fecha_envio          DATETIME NULL,
  estado_envio         VARCHAR(15) NOT NULL DEFAULT 'No enviado',
  CONSTRAINT fk_recibo_pago FOREIGN KEY (id_pago) REFERENCES Pago (id_pago),
  CONSTRAINT uq_recibo_pago   UNIQUE (id_pago),
  CONSTRAINT uq_recibo_numero UNIQUE (numero_recibo),
  CONSTRAINT chk_recibo_canal  CHECK (canal_envio IS NULL OR canal_envio IN ('Correo','WhatsApp')),
  CONSTRAINT chk_recibo_estado CHECK (estado_envio IN ('No enviado','Enviado','Fallido'))
) ENGINE=InnoDB;

INSERT INTO Proveedor (id_proveedor, nombre, telefono, correo, direccion, estado) VALUES
  (1, 'Distribuidora Tecnoplaza S.A.S.', '6017452100', 'ventas@tecnoplaza.example.com', 'Cra 30 #12-45, Bogotá', 'Activo'),
  (2, 'Importadora Compuworld Ltda.', '6014438800', 'pedidos@compuworld.example.com', 'Calle 13 #68-20, Bogotá', 'Activo'),
  (3, 'Accesorios y Más S.A.S.', '3112457788', 'contacto@accesoriosymas.example.com', 'Cra 7 #45-10, Bogotá', 'Activo'),
  (4, 'Sonido Digital Colombia S.A.S.', '6042318900', 'comercial@sonidodigital.example.com', 'Cra 43A #7-50, Medellín', 'Activo'),
  (5, 'Suministros e Impresión del Valle', '6023890011', 'mayoreo@suministrosvalles.example.com', 'Av 6N #25-30, Cali', 'Activo'),
  (6, 'Foto y Óptica del Caribe', '6053561234', 'ventas@fotocaribe.example.com', 'Calle 72 #54-12, Barranquilla', 'Activo'),
  (7, 'Periféricos y Partes S.A.S.', '3205561122', 'info@perifericospartes.example.com', 'Calle 100 #15-33, Bogotá', 'Activo'),
  (8, 'Cables y Conectores Ltda.', '6017654321', 'ventas@cablesconectores.example.com', 'Cra 68 #24-18, Bogotá', 'Activo'),
  (9, 'Óptica y Cámaras Pro', '3187789900', 'pedidos@camaraspro.example.com', 'Cra 15 #93-60, Bogotá', 'Activo'),
  (10, 'Importaciones Orión (cerrado)', '6012345678', NULL, 'Calle 19 #4-30, Bogotá', 'Inactivo');

INSERT INTO Cliente (id_cliente, nombre, correo, telefono, direccion, contrasena_hash) VALUES
  (1, 'Juan Pablo Martínez', 'jp.martinez@example.com', '3104567890', 'Cra 15 #82-45, Bogotá', NULL),
  (2, 'María Fernanda López', 'mf.lopez@example.com', '3157894561', 'Calle 100 #19-20, Bogotá', '$2b$10$Qx0w8OKuPYYqKf2WGnYZSbvsYulsXr4TipPtHEAIsLQcpUW2tGfrj'),
  (3, 'Carlos Andrés Ruiz', NULL, '3012345678', 'Av Boyacá #63-10, Bogotá', NULL),
  (4, 'Luisa Fernanda Ortiz', 'luisa.ortiz@example.com', NULL, 'Calle 53 #27-14, Bogotá', NULL),
  (5, 'Pedro Nel Acosta', 'pedro.acosta@example.com', '3209876543', 'Cra 50 #134-20, Bogotá', '$2b$10$FnRcM5k05lsM4DghK0S8djRUorPI/.J7GZ4agqsIvT0BI44kQ4yJR'),
  (6, 'Sandra Milena Vargas', 'sandra.vargas@example.com', '3118765432', 'Calle 127 #7-80, Bogotá', NULL),
  (7, 'Jorge Enrique Peña', NULL, '3226549870', 'Cra 80 #6-45, Bogotá', NULL),
  (8, 'Diana Carolina Mejía', 'diana.mejia@example.com', '3001237894', 'Calle 170 #54-30, Bogotá', '$2b$10$Fjmj6LkforVYFIJIZfWiH09sKswIQYVmtWVTndxla5sTve.KAdv50'),
  (9, 'Andrés Felipe Cruz', 'andres.cruz@example.com', '3135558899', 'Cra 24 #39-15, Bogotá', NULL),
  (10, 'Ángela Patricia Rincón', 'angela.rincon@example.com', '3173332211', 'Calle 26 #92-40, Bogotá', NULL);

INSERT INTO Usuario (id_usuario, nombre, correo, contrasena_hash, rol, departamento, especialidad, estado) VALUES
  (1, 'Laura Gómez', 'laura.gomez@arif-tech.example.com', '$2b$10$u4IDDbwryroyqQvy4geoSoVvxfAzt3xICDarb3f0DxkSXBV1aFJpq', 'Administrador', 'Gerencia', NULL, 'Activo'),
  (2, 'Andrés Rojas', 'andres.rojas@arif-tech.example.com', '$2b$10$bKICyI5Unf9owJv6./xgsvrAdN68Hmd36bpLbHA.0RQHDFmtRA5H9', 'Encargado_Inventario', 'Bodega', NULL, 'Activo'),
  (3, 'Camila Torres', 'camila.torres@arif-tech.example.com', '$2b$10$AR457.IlkPSjOa0ZzRgPTYVeMv66YC0eyOFUeAg4yZwvyt98i2/bY', 'Tendero', NULL, NULL, 'Activo'),
  (4, 'Julián Ríos', 'julian.rios@arif-tech.example.com', '$2b$10$6cmBpHmYYhW6sL9sMu/voUhSU0sTjDUJ2Dae3VEDY9ozr0m8iuh5Z', 'Tendero', NULL, NULL, 'Activo'),
  (5, 'Marcela Pardo', 'marcela.pardo@arif-tech.example.com', '$2b$10$WFCgPoAf.xCNoRYOM3OXlEMAS55nCt3zMADcqQRfpBMFS8Wc.O7cP', 'Tendero', NULL, NULL, 'Activo'),
  (6, 'Sebastián Cárdenas', 'sebastian.cardenas@arif-tech.example.com', '$2b$10$cepfW5YhmMXQUydl5.ks3QUZRWuz1zUpflNdyrF7.E08KFnvE1HEO', 'Tecnico', NULL, 'Computadores y torres', 'Activo'),
  (7, 'Diego Herrera', 'diego.herrera@arif-tech.example.com', '$2b$10$6BgAAPpn6CQEOqUixnQ95X28XeHTnVSDrLYYtpmp3QA0J2saYl0ZZ', 'Tecnico', NULL, 'Impresoras y equipos', 'Activo'),
  (8, 'Natalia Beltrán', 'natalia.beltran@arif-tech.example.com', '$2b$10$yJlRokxsoowT/Rz9xkaytlbWnmGpK5ECO.frWOuRS2soYA7plojcU', 'Tecnico', NULL, 'Mantenimiento y formateo', 'Activo'),
  (9, 'Ricardo Salazar', 'ricardo.salazar@arif-tech.example.com', '$2b$10$VT8mq.7r5L4YYD88Fbv2zTEGAC6GnOknUFSGj7DWEK8G5lfp9WV3m', 'Administrador', 'Contabilidad', NULL, 'Activo'),
  (10, 'Paola Quintero', 'paola.quintero@arif-tech.example.com', '$2b$10$EFqc7zkDx0jrY9QuwAbJtGzauZFBsM2AF2Amt2y7af0x5I7Xtsc8V', 'Tendero', NULL, NULL, 'Inactivo');

INSERT INTO Sesion (id_sesion, id_usuario, id_cliente, fecha_inicio, fecha_fin) VALUES
  (1, 1, NULL, '2026-11-20 08:00:00', '2026-11-20 17:30:00'),
  (2, 2, NULL, '2026-11-20 08:15:00', '2026-11-20 18:00:00'),
  (3, 3, NULL, '2026-11-23 08:30:00', '2026-11-23 18:05:00'),
  (4, 4, NULL, '2026-11-23 08:45:00', '2026-11-23 17:50:00'),
  (5, 5, NULL, '2026-11-23 09:00:00', '2026-11-23 18:10:00'),
  (6, 6, NULL, '2026-11-23 09:10:00', '2026-11-23 17:40:00'),
  (7, 7, NULL, '2026-11-24 08:20:00', NULL),
  (8, NULL, 2, '2026-09-12 19:10:00', '2026-09-12 19:35:00'),
  (9, NULL, 5, '2026-11-13 09:55:00', '2026-11-13 10:12:00'),
  (10, NULL, 8, '2026-11-22 20:00:00', '2026-11-22 20:18:00');

INSERT INTO Categoria (id_categoria, nombre, descripcion) VALUES
  (1, 'Cables', 'Cables USB, HDMI, de red y de datos'),
  (2, 'Audífonos de cable', 'Audífonos alámbricos de diadema e in-ear con conector 3.5mm o USB'),
  (3, 'Tintas', 'Botellas y cartuchos de tinta para impresoras'),
  (4, 'Teclados', 'Teclados alámbricos e inalámbricos para computador'),
  (5, 'Mousepad', 'Almohadillas y superficies para mouse de oficina y gaming'),
  (6, 'Cámaras', 'Cámaras digitales, compactas y de video'),
  (7, 'Accesorios y partes de cámaras', 'Trípodes, baterías, tarjetas de memoria, lentes y repuestos de cámara'),
  (8, 'Cables de video y audio', 'Cables auxiliares, HDMI y adaptadores de conexión'),
  (9, 'Teclados y periféricos', 'Teclados compactos, ergonómicos y complementos de escritorio'),
  (10, 'Repuestos y accesorios de cámara', 'Filtros, tapas, correas y partes de cámaras');

INSERT INTO Producto (id_producto, id_categoria, id_proveedor, nombre, descripcion, precio_unitario, estado) VALUES
  (1, 1, 1, 'Cable USB-C a USB-C 1.5m mallado', 'Cable de carga y transferencia de datos de alta resistencia', 25000, 'Activo'),
  (2, 2, 4, 'Audífonos de cable con micrófono 3.5mm', 'Audífonos alámbricos ligeros con control en el cable', 35000, 'Activo'),
  (3, 3, 5, 'Botella de tinta negra 70ml para impresora', 'Tinta de secado rápido compatible con impresoras de inyección', 45000, 'Activo'),
  (4, 4, 2, 'Teclado alámbrico español USB', 'Teclado estándar de membrana con conexión USB', 40000, 'Activo'),
  (5, 5, 3, 'Mousepad antideslizante borde cosido', 'Superficie de tela suave con base de caucho antideslizante', 18000, 'Activo'),
  (6, 6, 6, 'Cámara digital compacta Full HD', 'Cámara portátil con zoom óptico y grabación en 1080p', 650000, 'Activo'),
  (7, 7, 7, 'Batería y cargador dual para cámara', 'Batería de repuesto compatible más cargador de pared', 95000, 'Activo'),
  (8, 8, 8, 'Cable HDMI 2.0 4K 2 metros', 'Cable de video y audio digital de alta velocidad', 30000, 'Activo'),
  (9, 9, 9, 'Teclado mecánico compacto USB', 'Teclado de respuesta táctil con cable desmontable', 120000, 'Activo'),
  (10, 10, 8, 'Trípode compacto y adaptador para cámara', 'Soporte articulado con rosca universal y adaptador de montura', 55000, 'Activo');

INSERT INTO Metodo_Pago (id_metodo_pago, nombre, requiere_pasarela, estado) VALUES
  (1, 'Efectivo', 0, 'Activo'),
  (2, 'Transferencia bancaria', 0, 'Activo'),
  (3, 'Tarjeta débito', 1, 'Activo'),
  (4, 'Tarjeta crédito', 1, 'Activo'),
  (5, 'PSE', 1, 'Activo'),
  (6, 'Nequi', 1, 'Activo'),
  (7, 'Daviplata', 1, 'Activo'),
  (8, 'Cheque', 0, 'Inactivo'),
  (9, 'Pago contra entrega', 0, 'Activo'),
  (10, 'Código QR Bancolombia', 1, 'Activo');

INSERT INTO Pasarela_Pago (id_pasarela, nombre_pasarela, estado) VALUES
  (1, 'Wompi', 'Activo'),
  (2, 'Mercado Pago', 'Activo'),
  (3, 'PayU Latam', 'Activo'),
  (4, 'ePayco', 'Activo'),
  (5, 'Bold', 'Activo'),
  (6, 'Placetopay', 'Activo'),
  (7, 'Openpay Colombia', 'Activo'),
  (8, 'Stripe', 'Activo'),
  (9, 'Paymentez', 'Activo'),
  (10, 'Kushki', 'Inactivo');

INSERT INTO Compra (id_compra, id_proveedor, id_usuario, id_metodo_pago, fecha_compra, fecha_confirmacion, total_compra, estado_compra) VALUES
  (1, 1, 2, 2, '2026-08-05 09:10:00', '2026-08-05 14:30:00', 300000, 'Recibida'),
  (2, 2, 2, 2, '2026-08-12 10:00:00', '2026-08-12 16:00:00', 250000, 'Recibida'),
  (3, 3, 9, 9, '2026-08-18 11:20:00', '2026-08-18 15:00:00', 1000000, 'Recibida'),
  (4, 4, 2, 2, '2026-09-01 09:45:00', '2026-09-01 17:00:00', 600000, 'Recibida'),
  (5, 5, 1, 2, '2026-09-08 10:30:00', '2026-09-08 16:20:00', 300000, 'Recibida'),
  (6, 6, 2, 2, '2026-10-18 09:00:00', '2026-10-18 15:30:00', 4800000, 'Confirmada'),
  (7, 7, 9, 9, '2026-11-10 11:00:00', '2026-11-10 16:45:00', 975000, 'Confirmada'),
  (8, 8, 2, 1, '2026-11-18 10:15:00', NULL, 216000, 'Registrada'),
  (9, 9, 1, 2, '2026-11-21 14:30:00', NULL, 800000, 'Registrada'),
  (10, 8, 2, 2, '2026-10-25 09:20:00', NULL, 700000, 'Anulada');

INSERT INTO Detalle_Compra (id_detalle_compra, id_compra, id_producto, cantidad, valor_unitario, subtotal, stock_actual) VALUES
  (1, 1, 1, 20, 15000, 300000, 3),
  (2, 2, 4, 10, 25000, 250000, 2),
  (3, 3, 5, 100, 10000, 1000000, 15),
  (4, 4, 2, 30, 20000, 600000, 4),
  (5, 5, 3, 10, 30000, 300000, 1),
  (6, 6, 6, 10, 480000, 4800000, 2),
  (7, 7, 7, 15, 65000, 975000, 5),
  (8, 8, 8, 12, 18000, 216000, 4),
  (9, 9, 9, 10, 80000, 800000, 3),
  (10, 10, 10, 20, 35000, 700000, 18);

INSERT INTO Venta (id_venta, id_cliente, id_usuario, fecha_venta, fecha_confirmacion, total_venta, estado_venta) VALUES
  (1, 1, 3, '2026-09-03 10:15:00', '2026-09-03 10:20:00', 36000, 'Finalizada'),
  (2, 2, 4, '2026-09-10 15:40:00', '2026-09-10 15:45:00', 25000, 'Finalizada'),
  (3, 3, 5, '2026-09-18 11:05:00', '2026-09-18 11:10:00', 35000, 'Finalizada'),
  (4, 4, 3, '2026-11-12 16:20:00', '2026-11-12 16:30:00', 45000, 'Confirmada'),
  (5, 5, 4, '2026-11-20 09:30:00', '2026-11-20 09:40:00', 40000, 'Confirmada'),
  (6, 6, 5, '2026-11-22 12:10:00', NULL, 120000, 'En proceso'),
  (7, 7, 3, '2026-11-23 17:45:00', NULL, 165000, 'En proceso'),
  (8, 8, 4, '2026-11-24 08:50:00', NULL, 95000, 'En proceso'),
  (9, 9, 5, '2026-10-05 14:00:00', NULL, 650000, 'Anulada'),
  (10, 10, 3, '2026-10-14 10:25:00', NULL, 40000, 'Anulada');

INSERT INTO Detalle_Venta (id_detalle_venta, id_venta, id_producto, cantidad, valor_unitario, subtotal) VALUES
  (1, 1, 5, 2, 18000, 36000),
  (2, 2, 1, 1, 25000, 25000),
  (3, 3, 2, 1, 35000, 35000),
  (4, 4, 3, 1, 45000, 45000),
  (5, 5, 4, 1, 40000, 40000),
  (6, 6, 9, 1, 120000, 120000),
  (7, 7, 10, 3, 55000, 165000),
  (8, 8, 7, 1, 95000, 95000),
  (9, 9, 6, 1, 650000, 650000),
  (10, 10, 4, 1, 40000, 40000);

INSERT INTO Movimiento_Inventario (id_movimiento, id_producto, id_usuario, id_detalle_compra, id_detalle_venta, tipo_movimiento, motivo, cantidad, fecha_movimiento, observaciones) VALUES
  (1, 1, 2, 1, NULL, 'Entrada', 'Compra', 20, '2026-08-08 10:00:00', 'Entrada por recepción de cables USB-C de la compra #1'),
  (2, 4, 2, 2, NULL, 'Entrada', 'Compra', 10, '2026-08-15 11:30:00', 'Entrada por recepción de teclados de la compra #2'),
  (3, 5, 9, 3, NULL, 'Entrada', 'Compra', 100, '2026-08-20 09:40:00', 'Entrada por recepción de mousepad de la compra #3'),
  (4, 5, 3, NULL, 1, 'Salida', 'Venta', 2, '2026-09-03 10:20:00', 'Salida por venta #1 de mousepad'),
  (5, 2, 2, 4, NULL, 'Entrada', 'Compra', 30, '2026-09-04 10:15:00', 'Entrada por recepción de audífonos de cable de la compra #4'),
  (6, 1, 4, NULL, 2, 'Salida', 'Venta', 1, '2026-09-10 15:45:00', 'Salida por venta #2 de cable USB-C'),
  (7, 3, 1, 5, NULL, 'Entrada', 'Compra', 10, '2026-09-12 14:00:00', 'Entrada por recepción de tinta para impresora de la compra #5'),
  (8, 2, 5, NULL, 3, 'Salida', 'Venta', 1, '2026-09-18 11:10:00', 'Salida por venta #3 de audífonos de cable'),
  (9, 3, 3, NULL, 4, 'Salida', 'Venta', 1, '2026-11-12 16:30:00', 'Salida por venta #4 de tinta para impresora'),
  (10, 4, 4, NULL, 5, 'Salida', 'Venta', 1, '2026-11-20 09:40:00', 'Salida por venta #5 de teclado USB');

INSERT INTO Inventario (id_inventario, id_producto, cantidad_disponible, stock_minimo, ubicacion, fecha_actualizacion) VALUES
  (1, 1, 22, 5, 'Bodega A - Estante 1', '2026-09-10 15:45:00'),
  (2, 2, 33, 8, 'Mostrador - Vitrina 2', '2026-09-18 11:10:00'),
  (3, 3, 10, 3, 'Bodega B - Piso', '2026-11-12 16:30:00'),
  (4, 4, 11, 4, 'Bodega A - Estante 2', '2026-11-20 09:40:00'),
  (5, 5, 113, 20, 'Mostrador - Vitrina 1', '2026-09-03 10:20:00'),
  (6, 6, 2, 3, 'Bodega A - Estante 3', '2026-07-20 10:00:00'),
  (7, 7, 5, 5, 'Bodega A - Estante 4', '2026-07-20 10:00:00'),
  (8, 8, 4, 4, 'Bodega C - Estante 1', '2026-07-20 10:00:00'),
  (9, 9, 3, 5, 'Mostrador - Vitrina 3', '2026-07-20 10:00:00'),
  (10, 10, 18, 6, 'Bodega C - Estante 2', '2026-07-20 10:00:00');

INSERT INTO Alerta_Stock (id_alerta, id_producto, id_movimiento, cantidad_registrada, fecha_alerta, estado) VALUES
  (1, 1, NULL, 3, '2026-08-01 09:00:00', 'Atendida'),
  (2, 4, NULL, 2, '2026-08-10 09:00:00', 'Atendida'),
  (3, 3, NULL, 1, '2026-09-05 09:00:00', 'Atendida'),
  (4, 5, NULL, 15, '2026-08-10 09:05:00', 'Atendida'),
  (5, 2, NULL, 4, '2026-08-28 09:00:00', 'Atendida'),
  (6, 6, NULL, 2, '2026-10-20 09:00:00', 'Activa'),
  (7, 8, NULL, 4, '2026-11-02 09:00:00', 'Activa'),
  (8, 9, NULL, 3, '2026-11-10 09:00:00', 'Activa'),
  (9, 4, 10, 4, '2026-11-20 09:40:00', 'Activa'),
  (10, 7, NULL, 5, '2026-11-15 09:00:00', 'Activa');

INSERT INTO Aparato (id_aparato, id_cliente, tipo, marca, modelo, numero_serie, falla_reportada, estado) VALUES
  (1, 1, 'Impresora', 'Epson', 'EcoTank L3250', 'IMP-EPS-3250-01', 'No toma papel y arroja atasco', 'Entregado'),
  (2, 3, 'Computador', 'HP', 'ProDesk 400 G7', 'PC-HP-400G7-02', 'No enciende ni da señal de video', 'Entregado'),
  (3, 5, 'Torre', 'Clon Intel Core i5', 'ATX Torre Gamer', 'TOR-ATX-09876', 'Se apaga bajo carga y requiere formateo', 'Entregado'),
  (4, 7, 'Impresora', 'Canon', 'Pixma G3110', 'IMP-CAN-3110-04', 'Cabezal obstruido y rayas al imprimir', 'Reparado'),
  (5, 9, 'Torre', 'Dell', 'OptiPlex 7060', 'TOR-DEL-7060-05', 'Sistema operativo lento y con errores de arranque', 'Reparado'),
  (6, 2, 'Computador', 'Lenovo', 'ThinkPad E14', 'PC-LEN-E14-06', 'Requiere mantenimiento preventivo y limpieza interna', 'Reparado'),
  (7, 4, 'Computador', 'Asus', 'VivoBook 15', 'PC-ASU-VB15-07', 'Revisión general de hardware y formateo', 'Reparado'),
  (8, 6, 'Impresora', 'Brother', 'DCP-T520W', 'IMP-BRO-520W-08', 'Error de tinta y limpieza de rodillos', 'Reparado'),
  (9, 8, 'Torre', 'Clon AMD Ryzen 5', 'MicroATX Oficina', 'TOR-AMD-R5-09', 'Revisión de fuente y formateo limpio', 'Reparado'),
  (10, 10, 'Computador', 'Acer', 'Aspire 5', 'PC-ACE-ASP5-10', 'Mantenimiento general y optimización de sistema', 'Reparado');

INSERT INTO Servicio (id_servicio, id_cliente, id_aparato, id_usuario, id_tecnico, fecha_ingreso, estado, diagnostico, valor_servicio, fecha_entrega) VALUES
  (1, 1, 1, 3, 7, '2026-09-02 09:00:00', 'Entregado', 'Rodillo de arrastre desgastado en impresora; se reemplaza y se calibra.', 120000, '2026-09-09 15:00:00'),
  (2, 3, 2, 4, 6, '2026-09-15 10:00:00', 'Entregado', 'Revisión de equipo y fuente de poder; se realiza mantenimiento y reparación.', 250000, '2026-09-25 10:00:00'),
  (3, 5, 3, 5, 8, '2026-10-01 11:00:00', 'Entregado', 'Mantenimiento a torre y formateo completo con instalación de sistema.', 380000, '2026-10-10 12:00:00'),
  (4, 7, 4, 3, 7, '2026-11-05 09:30:00', 'Finalizado', 'Limpieza profunda de cabezales e impresora revisada y probada.', 150000, NULL),
  (5, 9, 5, 4, 8, '2026-11-10 15:00:00', 'Finalizado', 'Formateo de torre, respaldo y mantenimiento preventivo.', 200000, NULL),
  (6, 2, 6, 5, 6, '2026-10-20 10:30:00', 'Finalizado', 'Mantenimiento a computador, cambio de pasta térmica y limpieza.', 90000, NULL),
  (7, 4, 7, 3, 8, '2026-10-28 14:15:00', 'Finalizado', 'Revisión de equipo y formateo del sistema operativo.', 110000, NULL),
  (8, 6, 8, 4, 7, '2026-11-03 09:50:00', 'Finalizado', 'Reparación de impresora, purga de tinta y limpieza de sensores.', 210000, NULL),
  (9, 8, 9, 5, 8, '2026-11-12 16:00:00', 'Finalizado', 'Revisión de torre y formateo con configuración inicial.', 140000, NULL),
  (10, 10, 10, 3, 6, '2026-11-16 11:40:00', 'Finalizado', 'Mantenimiento a computador y revisión de temperatura.', 70000, NULL);

INSERT INTO Encuesta_Satisfaccion (id_encuesta, id_servicio, id_cliente, id_usuario, calificacion, comentarios, fecha_encuesta) VALUES
  (1, 1, 1, 3, 5, 'Excelente atención y la impresora quedó funcionando perfecto.', '2026-09-10 10:00:00'),
  (2, 2, 3, 4, 4, 'Buen servicio en la revisión del computador, aunque demoró un poco.', '2026-09-26 11:00:00'),
  (3, 3, 5, 5, 5, 'La torre quedó rápida tras el mantenimiento y el formateo.', '2026-10-11 09:30:00'),
  (4, 4, 7, 3, 4, 'Rápido arreglo de la impresora y buen precio.', '2026-11-14 15:20:00'),
  (5, 5, 9, 4, 3, 'Buen formateo de la torre, pero tardaron en avisarme.', '2026-11-17 10:10:00'),
  (6, 6, 2, 5, 5, 'Muy amables, hicieron el mantenimiento del computador el mismo día.', '2026-10-30 12:00:00'),
  (7, 7, 4, 3, 4, 'Quedó bien revisado y formateado, recomendado.', '2026-11-06 16:45:00'),
  (8, 8, 6, 4, 5, NULL, '2026-11-10 09:15:00'),
  (9, 9, 8, 5, 4, 'Buena revisión de la torre y formateo claro.', '2026-11-18 14:00:00'),
  (10, 10, 10, 3, 3, 'Funciona bien el mantenimiento, pero esperaba un precio menor.', '2026-11-21 17:30:00');

INSERT INTO Orden_Pago (id_orden_pago, id_cliente, id_usuario, id_venta, id_servicio, fecha_orden, estado, costo_total) VALUES
  (1, 1, 3, 1, NULL, '2026-09-03 10:20:00', 'Pagada', 36000),
  (2, 2, 4, 2, NULL, '2026-09-10 15:45:00', 'Pagada', 25000),
  (3, 3, 5, 3, NULL, '2026-09-18 11:10:00', 'Pagada', 35000),
  (4, 4, 3, 4, NULL, '2026-11-12 16:30:00', 'Abonada', 45000),
  (5, 5, 4, 5, NULL, '2026-11-20 09:40:00', 'Pendiente', 40000),
  (6, 1, 3, NULL, 1, '2026-09-04 10:00:00', 'Pagada', 120000),
  (7, 3, 4, NULL, 2, '2026-09-17 11:00:00', 'Pagada', 250000),
  (8, 5, 5, NULL, 3, '2026-10-03 10:00:00', 'Pagada', 380000),
  (9, 7, 3, NULL, 4, '2026-11-07 10:30:00', 'Abonada', 150000),
  (10, 9, 4, NULL, 5, '2026-11-12 09:00:00', 'Pendiente', 200000);

INSERT INTO Pago (id_pago, id_orden_pago, id_metodo_pago, id_pasarela, id_usuario, tipo_pago, monto, fecha_pago, estado, token_transaccion) VALUES
  (1, 1, 1, NULL, 3, 'Total', 36000, '2026-09-03 10:30:00', 'Aprobado', NULL),
  (2, 2, 2, NULL, 4, 'Abono', 10000, '2026-09-10 15:50:00', 'Aprobado', NULL),
  (3, 2, 3, 1, NULL, 'Total', 15000, '2026-09-12 19:20:00', 'Aprobado', 'wmp_tx_8f3a91c27d4e'),
  (4, 3, 6, 1, NULL, 'Total', 35000, '2026-09-18 11:30:00', 'Aprobado', 'wmp_tx_52b7e08a19cf'),
  (5, 4, 5, 3, NULL, 'Abono', 25000, '2026-11-13 10:00:00', 'Aprobado', 'payu_tx_c41d7a60b2e8'),
  (6, 6, 1, NULL, 3, 'Total', 120000, '2026-09-09 14:00:00', 'Aprobado', NULL),
  (7, 7, 4, 4, NULL, 'Abono', 100000, '2026-09-17 12:00:00', 'Aprobado', 'epy_tx_a90e3b5d7716'),
  (8, 7, 1, NULL, 4, 'Total', 150000, '2026-09-24 16:00:00', 'Aprobado', NULL),
  (9, 8, 7, 5, NULL, 'Total', 380000, '2026-10-09 18:30:00', 'Aprobado', 'bold_tx_7c2f19e84a03'),
  (10, 9, 1, NULL, 3, 'Abono', 50000, '2026-11-07 11:00:00', 'Aprobado', NULL);

INSERT INTO Recibo (id_recibo, id_pago, numero_recibo, fecha_emision, detalles_adicionales, canal_envio, fecha_envio, estado_envio) VALUES
  (1, 1, 'REC-2026-000001', '2026-09-03 10:30:00', 'Pago de venta', 'Correo', '2026-09-03 10:30:30', 'Enviado'),
  (2, 2, 'REC-2026-000002', '2026-09-10 15:50:00', 'Pago de venta', 'WhatsApp', '2026-09-10 15:50:30', 'Enviado'),
  (3, 3, 'REC-2026-000003', '2026-09-12 19:20:00', 'Pago de venta', 'Correo', '2026-09-12 19:20:30', 'Enviado'),
  (4, 4, 'REC-2026-000004', '2026-09-18 11:30:00', 'Pago de venta', 'WhatsApp', '2026-09-18 11:30:30', 'Enviado'),
  (5, 5, 'REC-2026-000005', '2026-11-13 10:00:00', 'Pago de venta', 'Correo', '2026-11-13 10:00:30', 'Enviado'),
  (6, 6, 'REC-2026-000006', '2026-09-09 14:00:00', 'Pago de servicio técnico', 'Correo', '2026-09-09 14:00:30', 'Enviado'),
  (7, 7, 'REC-2026-000007', '2026-09-17 12:00:00', 'Pago de servicio técnico', 'WhatsApp', '2026-09-17 12:00:30', 'Enviado'),
  (8, 8, 'REC-2026-000008', '2026-09-24 16:00:00', 'Pago de servicio técnico', 'WhatsApp', '2026-09-24 16:00:30', 'Fallido'),
  (9, 9, 'REC-2026-000009', '2026-10-09 18:30:00', 'Pago de servicio técnico', 'Correo', '2026-10-09 18:30:30', 'Enviado'),
  (10, 10, 'REC-2026-000010', '2026-11-07 11:00:00', 'Pago de servicio técnico', NULL, NULL, 'No enviado');

INSERT INTO Historial (id_historial, id_usuario, tabla_afectada, id_registro, tipo_modificacion, detalle, fecha_modificacion) VALUES
  (1, 2, 'Producto', 5, 'Creación', 'Producto creado: Mousepad antideslizante borde cosido', '2026-07-20 10:00:00'),
  (2, 1, 'Producto', 1, 'Actualización', 'precio_unitario: 22000 -> 25000', '2026-08-02 09:30:00'),
  (3, 2, 'Inventario', 1, 'Actualización', 'cantidad_disponible: 3 -> 23 (entrada por compra #1 de cables USB-C)', '2026-08-08 10:00:00'),
  (4, 7, 'Servicio', 1, 'Actualización', 'estado: Pendiente -> En diagnóstico (revisión impresora)', '2026-09-03 09:00:00'),
  (5, 7, 'Aparato', 1, 'Actualización', 'estado: En reparación -> Reparado (impresora Epson)', '2026-09-08 17:00:00'),
  (6, 3, 'Servicio', 1, 'Actualización', 'estado: Finalizado -> Entregado', '2026-09-09 15:00:00'),
  (7, 6, 'Servicio', 2, 'Actualización', 'diagnostico registrado; estado: En diagnóstico -> Valorado', '2026-09-16 16:20:00'),
  (8, 2, 'Inventario', 6, 'Actualización', 'stock_minimo: 2 -> 3', '2026-10-20 08:45:00'),
  (9, 1, 'Producto', 10, 'Actualización', 'descripcion: se agrega ''adaptador de montura''', '2026-10-22 11:10:00'),
  (10, 1, 'Producto', 11, 'Eliminación', 'Producto duplicado eliminado del catálogo', '2026-11-02 12:00:00');

INSERT INTO Reporte (id_reporte, id_usuario, tipo, fecha_reporte, datos, formato_exportacion, fecha_exportacion) VALUES
  (1, 2, 'Existencias', '2026-08-31 18:00:00', 'Resumen de existencias al cierre de agosto', 'PDF', '2026-08-31 18:05:00'),
  (2, 2, 'Entradas', '2026-09-30 18:00:00', 'Entradas de inventario de septiembre', 'XLSX', '2026-09-30 18:10:00'),
  (3, 2, 'Salidas', '2026-09-30 18:02:00', 'Salidas de inventario de septiembre', 'CSV', '2026-09-30 18:12:00'),
  (4, 1, 'Stock mínimo', '2026-10-01 08:30:00', 'Productos en o bajo el stock mínimo', 'PDF', '2026-10-01 08:35:00'),
  (5, 9, 'Existencias', '2026-10-31 18:00:00', 'Resumen de existencias al cierre de octubre', 'XLSX', '2026-10-31 18:07:00'),
  (6, 2, 'Entradas', '2026-10-31 18:03:00', 'Entradas de inventario de octubre', 'PDF', '2026-10-31 18:09:00'),
  (7, 1, 'Salidas', '2026-11-15 17:00:00', 'Salidas de la primera quincena de noviembre', NULL, NULL),
  (8, 2, 'Stock mínimo', '2026-11-20 08:15:00', 'Productos en o bajo el stock mínimo', 'CSV', '2026-11-20 08:20:00'),
  (9, 9, 'Existencias', '2026-11-22 17:30:00', 'Existencias por categoría', NULL, NULL),
  (10, 2, 'Stock mínimo', '2026-11-24 08:10:00', 'Alertas activas de stock mínimo', 'PDF', '2026-11-24 08:14:00');
USE sgm_arif;
SET NAMES utf8mb4;


CREATE OR REPLACE VIEW vw_catalogo_inventario AS
SELECT p.id_producto,
       p.nombre                              AS producto,
       c.nombre                              AS categoria,
       IFNULL(pr.nombre, 'Sin proveedor')    AS proveedor,
       p.precio_unitario,
       p.estado                              AS estado_producto,
       i.cantidad_disponible,
       i.stock_minimo,
       i.ubicacion,
       CASE
            WHEN i.cantidad_disponible = 0                  THEN 'Agotado'
            WHEN i.cantidad_disponible <= i.stock_minimo    THEN 'Stock bajo'
            ELSE 'Disponible'
       END                                   AS estado_stock,
       (SELECT COUNT(*)
          FROM Alerta_Stock a
         WHERE a.id_producto = p.id_producto
           AND a.estado = 'Activa')          AS alertas_activas
FROM Producto p
INNER JOIN Categoria c   ON c.id_categoria = p.id_categoria
LEFT  JOIN Proveedor pr  ON pr.id_proveedor = p.id_proveedor
INNER JOIN Inventario i  ON i.id_producto = p.id_producto;

SELECT * FROM vw_catalogo_inventario ORDER BY categoria, producto;


CREATE OR REPLACE VIEW vw_servicios_tecnicos AS
SELECT s.id_servicio,
       s.fecha_ingreso,
       s.fecha_entrega,
       s.id_cliente,
       cl.nombre                               AS cliente,
       a.tipo                                  AS tipo_equipo,
       a.marca,
       a.modelo,
       a.falla_reportada,
       s.diagnostico,
       s.estado                                AS estado_servicio,
       s.valor_servicio,
       s.id_tecnico,
       IFNULL(tec.nombre, 'Sin asignar')       AS tecnico,
       IFNULL(tec.especialidad, 'N/A')         AS especialidad,
       e.calificacion                          AS calificacion_encuesta
FROM Servicio s
INNER JOIN Cliente cl               ON cl.id_cliente = s.id_cliente
INNER JOIN Aparato a                ON a.id_aparato  = s.id_aparato
LEFT  JOIN Usuario tec              ON tec.id_usuario = s.id_tecnico
LEFT  JOIN Encuesta_Satisfaccion e  ON e.id_servicio = s.id_servicio;

SELECT * FROM vw_servicios_tecnicos ORDER BY fecha_ingreso DESC;



CREATE OR REPLACE VIEW vw_resumen_ordenes_pago AS
SELECT o.id_orden_pago,
       o.fecha_orden,
       cl.nombre                                   AS cliente,
       CASE WHEN o.id_venta IS NOT NULL
            THEN CONCAT('Venta #', o.id_venta)
            ELSE CONCAT('Servicio #', o.id_servicio)
       END                                         AS origen,
       o.estado                                    AS estado_orden,
       o.costo_total,
       IFNULL(pg.total_aprobado, 0)                AS total_abonado_pagado,
       o.costo_total - IFNULL(pg.total_aprobado, 0) AS saldo_pendiente,
       IFNULL(pg.num_pagos, 0)                     AS num_pagos_aprobados,
       CASE
            WHEN o.estado = 'Cancelada'                          THEN 'Cancelada'
            WHEN IFNULL(pg.total_aprobado, 0) >= o.costo_total   THEN 'Pagada'
            WHEN IFNULL(pg.total_aprobado, 0) > 0                THEN 'Abonada'
            ELSE 'Pendiente'
       END                                         AS estado_calculado
FROM Orden_Pago o
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente
LEFT JOIN (
        SELECT id_orden_pago,
               SUM(monto) AS total_aprobado,
               COUNT(*)   AS num_pagos
          FROM Pago
         WHERE estado = 'Aprobado'
         GROUP BY id_orden_pago
     ) pg ON pg.id_orden_pago = o.id_orden_pago;

SELECT * FROM vw_resumen_ordenes_pago ORDER BY id_orden_pago;


CREATE OR REPLACE VIEW vw_actividad_usuarios AS
SELECT u.id_usuario,
       u.nombre AS usuario,
       u.rol,
       u.estado,
       (SELECT COUNT(*)          FROM Sesion s    WHERE s.id_usuario = u.id_usuario) AS total_sesiones,
       (SELECT MAX(s.fecha_inicio) FROM Sesion s  WHERE s.id_usuario = u.id_usuario) AS ultima_sesion,
       (SELECT COUNT(*)          FROM Historial h WHERE h.id_usuario = u.id_usuario) AS total_modificaciones,
       (SELECT COUNT(*)          FROM Reporte r   WHERE r.id_usuario = u.id_usuario) AS total_reportes
FROM Usuario u;

SELECT * FROM vw_actividad_usuarios ORDER BY id_usuario;



SELECT id_orden_pago, estado_orden, estado_calculado
FROM vw_resumen_ordenes_pago
WHERE estado_orden <> estado_calculado;


SELECT a.id_alerta, a.id_producto, a.cantidad_registrada,
       i.cantidad_disponible, i.stock_minimo
FROM Alerta_Stock a
INNER JOIN Inventario i ON i.id_producto = a.id_producto
WHERE a.estado = 'Activa'
  AND i.cantidad_disponible > i.stock_minimo;



USE sgm_arif;
SET NAMES utf8mb4;

SELECT p.id_producto,
       p.nombre AS producto,
       c.nombre AS categoria,
       pr.nombre AS proveedor,
       p.precio_unitario,
       i.cantidad_disponible,
       i.stock_minimo,
       a.estado AS estado_alerta
FROM Producto p
INNER JOIN Categoria c    ON c.id_categoria = p.id_categoria
LEFT JOIN Proveedor pr    ON pr.id_proveedor = p.id_proveedor
INNER JOIN Inventario i   ON i.id_producto = p.id_producto
LEFT JOIN Alerta_Stock a  ON a.id_producto = p.id_producto;


SELECT co.id_compra,
       co.fecha_compra,
       co.estado_compra,
       mp.nombre AS metodo_pago,
       dc.cantidad AS cantidad_comprada,
       dc.subtotal,
       m.tipo_movimiento,
       m.motivo,
       u.nombre AS registrado_por
FROM Compra co
INNER JOIN Metodo_Pago mp          ON mp.id_metodo_pago = co.id_metodo_pago
INNER JOIN Detalle_Compra dc       ON dc.id_compra = co.id_compra
LEFT JOIN Movimiento_Inventario m  ON m.id_detalle_compra = dc.id_detalle_compra
INNER JOIN Usuario u               ON u.id_usuario = co.id_usuario;

SELECT v.id_venta,
       v.fecha_venta,
       v.estado_venta,
       cl.nombre AS cliente,
       dv.cantidad AS unidades_vendidas,
       dv.subtotal,
       o.id_orden_pago,
       o.estado AS estado_orden
FROM Venta v
INNER JOIN Cliente cl        ON cl.id_cliente = v.id_cliente
INNER JOIN Detalle_Venta dv  ON dv.id_venta = v.id_venta
LEFT JOIN Orden_Pago o       ON o.id_venta = v.id_venta;


SELECT s.id_servicio,
       s.fecha_ingreso,
       s.estado AS estado_servicio,
       s.valor_servicio,
       a.tipo AS tipo_equipo,
       a.marca,
       a.modelo,
       a.falla_reportada,
       e.calificacion,
       e.comentarios
FROM Servicio s
INNER JOIN Aparato a               ON a.id_aparato = s.id_aparato
LEFT JOIN Encuesta_Satisfaccion e  ON e.id_servicio = s.id_servicio;

SELECT pg.id_pago,
       pg.fecha_pago,
       pg.tipo_pago,
       pg.monto,
       pg.estado AS estado_pago,
       IFNULL(pas.nombre_pasarela, 'Presencial (sin pasarela)') AS pasarela,
       r.numero_recibo,
       r.canal_envio,
       r.estado_envio
FROM Pago pg
LEFT JOIN Pasarela_Pago pas ON pas.id_pasarela = pg.id_pasarela
LEFT JOIN Recibo r          ON r.id_pago = pg.id_pago;


SELECT u.id_usuario,
       u.nombre AS usuario,
       u.rol,
       s.id_sesion,
       s.fecha_inicio,
       h.tabla_afectada,
       h.tipo_modificacion,
       r.tipo AS tipo_reporte,
       r.formato_exportacion
FROM Usuario u
LEFT JOIN Sesion s    ON s.id_usuario = u.id_usuario
LEFT JOIN Historial h ON h.id_usuario = u.id_usuario
LEFT JOIN Reporte r   ON r.id_usuario = u.id_usuario;


CREATE OR REPLACE VIEW vw_catalogo_inventario AS
SELECT p.id_producto,
       p.nombre AS producto,
       c.nombre AS categoria,
       pr.nombre AS proveedor,
       p.precio_unitario,
       i.cantidad_disponible,
       i.stock_minimo,
       i.ubicacion,
       CASE WHEN i.cantidad_disponible <= i.stock_minimo THEN 'Stock bajo' ELSE 'Disponible' END AS estado_stock
FROM Producto p
INNER JOIN Categoria c   ON c.id_categoria = p.id_categoria
LEFT JOIN Proveedor pr   ON pr.id_proveedor = p.id_proveedor
INNER JOIN Inventario i  ON i.id_producto = p.id_producto;

SELECT * FROM vw_catalogo_inventario ORDER BY categoria, producto;


CREATE OR REPLACE VIEW vw_servicios_tecnicos AS
SELECT s.id_servicio,
       s.fecha_ingreso,
       s.fecha_entrega,
       cl.nombre AS cliente,
       a.tipo AS tipo_equipo,
       a.marca,
       a.modelo,
       a.falla_reportada,
       s.diagnostico,
       s.estado AS estado_servicio,
       s.valor_servicio,
       tec.nombre AS tecnico,
       tec.especialidad,
       e.calificacion AS calificacion_encuesta
FROM Servicio s
INNER JOIN Cliente cl               ON cl.id_cliente = s.id_cliente
INNER JOIN Aparato a                ON a.id_aparato = s.id_aparato
LEFT JOIN Usuario tec               ON tec.id_usuario = s.id_tecnico
LEFT JOIN Encuesta_Satisfaccion e ON e.id_servicio = s.id_servicio;

SELECT * FROM vw_servicios_tecnicos ORDER BY fecha_ingreso DESC;


CREATE OR REPLACE VIEW vw_resumen_ordenes_pago AS
SELECT o.id_orden_pago,
       o.fecha_orden,
       cl.nombre AS cliente,
       CASE WHEN o.id_venta IS NOT NULL THEN CONCAT('Venta #', o.id_venta)
            ELSE CONCAT('Servicio #', o.id_servicio) END AS origen,
       o.estado AS estado_orden,
       o.costo_total,
       IFNULL(SUM(CASE WHEN pg.estado = 'Aprobado' THEN pg.monto END), 0) AS total_abonado_pagado,
       o.costo_total - IFNULL(SUM(CASE WHEN pg.estado = 'Aprobado' THEN pg.monto END), 0) AS saldo_pendiente
FROM Orden_Pago o
INNER JOIN Cliente cl ON cl.id_cliente = o.id_cliente
LEFT JOIN Pago pg     ON pg.id_orden_pago = o.id_orden_pago
GROUP BY o.id_orden_pago, o.fecha_orden, cl.nombre, o.id_venta, o.id_servicio, o.estado, o.costo_total;

SELECT * FROM vw_resumen_ordenes_pago ORDER BY id_orden_pago;                                    

USE sgm_arif;

DELIMITER $$

CREATE TRIGGER trg_movimiento_inventario
AFTER INSERT ON Movimiento_Inventario
FOR EACH ROW
BEGIN
    IF NEW.tipo_movimiento = 'Entrada' THEN

        UPDATE Inventario
        SET cantidad_disponible = cantidad_disponible + NEW.cantidad,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_producto = NEW.id_producto;

    ELSEIF NEW.tipo_movimiento = 'Salida' THEN

        UPDATE Inventario
        SET cantidad_disponible = cantidad_disponible - NEW.cantidad,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_producto = NEW.id_producto
          AND cantidad_disponible >= NEW.cantidad;

        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para realizar la salida';
        END IF;

    END IF;
END$$

CREATE TRIGGER trg_alerta_stock
AFTER UPDATE ON Inventario
FOR EACH ROW
BEGIN
    IF NEW.cantidad_disponible <= NEW.stock_minimo THEN

        IF NOT EXISTS (
            SELECT 1
            FROM Alerta_Stock
            WHERE id_producto = NEW.id_producto
              AND estado = 'Activa'
        ) THEN

            INSERT INTO Alerta_Stock (
                id_producto,
                id_movimiento,
                cantidad_registrada,
                fecha_alerta,
                estado
            )
            VALUES (
                NEW.id_producto,
                NULL,
                NEW.cantidad_disponible,
                CURRENT_TIMESTAMP,
                'Activa'
            );

        END IF;

    END IF;
END$$

CREATE TRIGGER trg_historial_producto_insert
AFTER INSERT ON Producto
FOR EACH ROW
BEGIN
    INSERT INTO Historial (
        id_usuario,
        tabla_afectada,
        id_registro,
        tipo_modificacion,
        detalle
    )
    VALUES (
        1,
        'Producto',
        NEW.id_producto,
        'Creación',
        CONCAT('Producto creado: ', NEW.nombre)
    );
END$$


CREATE TRIGGER trg_historial_producto_update
AFTER UPDATE ON Producto
FOR EACH ROW
BEGIN
    INSERT INTO Historial (
        id_usuario,
        tabla_afectada,
        id_registro,
        tipo_modificacion,
        detalle
    )
    VALUES (
        1,
        'Producto',
        NEW.id_producto,
        'Actualización',
        CONCAT(
            'Producto actualizado: ',
            OLD.nombre,
            ' -> ',
            NEW.nombre,
            '. Precio anterior: ',
            OLD.precio_unitario,
            '. Precio nuevo: ',
            NEW.precio_unitario
        )
    );
END$$


CREATE TRIGGER trg_validar_tecnico
BEFORE INSERT ON Servicio
FOR EACH ROW
BEGIN
    IF NEW.id_tecnico IS NOT NULL THEN

        IF NOT EXISTS (
            SELECT 1
            FROM Usuario
            WHERE id_usuario = NEW.id_tecnico
              AND rol = 'Tecnico'
              AND estado = 'Activo'
        ) THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario asignado debe ser un tecnico activo';

        END IF;

    END IF;
END$$



CREATE TRIGGER trg_validar_tecnico_update
BEFORE UPDATE ON Servicio
FOR EACH ROW
BEGIN
    IF NEW.id_tecnico IS NOT NULL THEN

        IF NOT EXISTS (
            SELECT 1
            FROM Usuario
            WHERE id_usuario = NEW.id_tecnico
              AND rol = 'Tecnico'
              AND estado = 'Activo'
        ) THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario asignado debe ser un tecnico activo';

        END IF;

    END IF;
END$$



CREATE TRIGGER trg_validar_pago
BEFORE INSERT ON Pago
FOR EACH ROW
BEGIN
    DECLARE total_orden DECIMAL(12,2);
    DECLARE total_pagado DECIMAL(12,2);

    SELECT costo_total
    INTO total_orden
    FROM Orden_Pago
    WHERE id_orden_pago = NEW.id_orden_pago;

    SELECT COALESCE(SUM(monto), 0)
    INTO total_pagado
    FROM Pago
    WHERE id_orden_pago = NEW.id_orden_pago
      AND estado = 'Aprobado';

    IF NEW.estado = 'Aprobado'
       AND (total_pagado + NEW.monto) > total_orden THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El pago supera el saldo pendiente de la orden';

    END IF;
END$$


CREATE TRIGGER trg_actualizar_estado_orden
AFTER INSERT ON Pago
FOR EACH ROW
BEGIN
    DECLARE total_orden DECIMAL(12,2);
    DECLARE total_pagado DECIMAL(12,2);

    IF NEW.estado = 'Aprobado' THEN

        SELECT costo_total
        INTO total_orden
        FROM Orden_Pago
        WHERE id_orden_pago = NEW.id_orden_pago;

        SELECT COALESCE(SUM(monto), 0)
        INTO total_pagado
        FROM Pago
        WHERE id_orden_pago = NEW.id_orden_pago
          AND estado = 'Aprobado';

        IF total_pagado >= total_orden THEN

            UPDATE Orden_Pago
            SET estado = 'Pagada'
            WHERE id_orden_pago = NEW.id_orden_pago;

        ELSE

            UPDATE Orden_Pago
            SET estado = 'Abonada'
            WHERE id_orden_pago = NEW.id_orden_pago;

        END IF;

    END IF;
END$$


DELIMITER ;


USE sgm_arif;


UPDATE Producto
SET precio_unitario = 27000
WHERE id_producto = 1;


UPDATE Inventario
SET stock_minimo = 4,
    fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_inventario = 3;


UPDATE Servicio
SET estado = 'Entregado',
    fecha_entrega = '2026-11-25 10:00:00'
WHERE id_servicio = 6;


UPDATE Aparato
SET estado = 'Entregado'
WHERE id_aparato = 6;


UPDATE Alerta_Stock
SET estado = 'Atendida'
WHERE id_alerta = 9;

SELECT id_producto, nombre, precio_unitario FROM Producto WHERE id_producto = 1;
SELECT id_inventario, id_producto, cantidad_disponible, stock_minimo FROM Inventario WHERE id_inventario = 3;
SELECT id_servicio, estado, fecha_entrega FROM Servicio WHERE id_servicio = 6;
SELECT id_aparato, estado FROM Aparato WHERE id_aparato = 6;
SELECT id_alerta, id_producto, estado FROM Alerta_Stock WHERE id_alerta = 9;
-- El UPDATE 1 tambien debio generar una fila nueva en Historial:
SELECT * FROM Historial ORDER BY id_historial DESC LIMIT 1;



DELETE FROM Proveedor
WHERE id_proveedor = 10;


DELETE FROM Metodo_Pago
WHERE id_metodo_pago = 8;


DELETE FROM Pasarela_Pago
WHERE id_pasarela = 10;


DELETE FROM Reporte
WHERE id_reporte = 9;


DELETE FROM Alerta_Stock
WHERE id_alerta = 1;


SELECT * FROM Proveedor     WHERE id_proveedor   = 10;
SELECT * FROM Metodo_Pago   WHERE id_metodo_pago = 8;
SELECT * FROM Pasarela_Pago WHERE id_pasarela    = 10;
SELECT * FROM Reporte       WHERE id_reporte     = 9;
SELECT * FROM Alerta_Stock  WHERE id_alerta      = 1;

USE sgm_arif;

DROP VIEW IF EXISTS vw_proveedores;
DROP VIEW IF EXISTS vw_clientes;
DROP VIEW IF EXISTS vw_usuarios;
DROP VIEW IF EXISTS vw_sesiones;
DROP VIEW IF EXISTS vw_categorias;
DROP VIEW IF EXISTS vw_productos;
DROP VIEW IF EXISTS vw_metodos_pago;
DROP VIEW IF EXISTS vw_pasarelas_pago;
DROP VIEW IF EXISTS vw_compras;
DROP VIEW IF EXISTS vw_detalle_compras;
DROP VIEW IF EXISTS vw_ventas;
DROP VIEW IF EXISTS vw_detalle_ventas;
DROP VIEW IF EXISTS vw_movimientos_inventario;
DROP VIEW IF EXISTS vw_inventario;
DROP VIEW IF EXISTS vw_alertas_stock;
DROP VIEW IF EXISTS vw_aparatos;

CREATE VIEW vw_proveedores AS
SELECT id_proveedor, nombre, telefono, correo, direccion, estado
FROM Proveedor;

CREATE VIEW vw_clientes AS
SELECT id_cliente, nombre, correo, telefono, direccion, contrasena_hash
FROM Cliente;

CREATE VIEW vw_usuarios AS
SELECT id_usuario, nombre, correo, contrasena_hash, rol, departamento, especialidad, estado
FROM Usuario;

CREATE VIEW vw_sesiones AS
SELECT id_sesion, id_usuario, id_cliente, fecha_inicio, fecha_fin
FROM Sesion;

CREATE VIEW vw_categorias AS
SELECT id_categoria, nombre, descripcion
FROM Categoria;

CREATE VIEW vw_productos AS
SELECT id_producto, id_categoria, id_proveedor, nombre, descripcion, precio_unitario, estado
FROM Producto;

CREATE VIEW vw_metodos_pago AS
SELECT id_metodo_pago, nombre, requiere_pasarela, estado
FROM Metodo_Pago;

CREATE VIEW vw_pasarelas_pago AS
SELECT id_pasarela, nombre_pasarela, estado
FROM Pasarela_Pago;

CREATE VIEW vw_compras AS
SELECT id_compra, id_proveedor, id_usuario, id_metodo_pago, fecha_compra, fecha_confirmacion, total_compra, estado_compra
FROM Compra;

CREATE VIEW vw_detalle_compras AS
SELECT id_detalle_compra, id_compra, id_producto, cantidad, valor_unitario, subtotal, stock_actual
FROM Detalle_Compra;

CREATE VIEW vw_ventas AS
SELECT id_venta, id_cliente, id_usuario, fecha_venta, fecha_confirmacion, total_venta, estado_venta
FROM Venta;

CREATE VIEW vw_detalle_ventas AS
SELECT id_detalle_venta, id_venta, id_producto, cantidad, valor_unitario, subtotal
FROM Detalle_Venta;

CREATE VIEW vw_movimientos_inventario AS
SELECT id_movimiento, id_producto, id_usuario, id_detalle_compra, id_detalle_venta, tipo_movimiento, motivo, cantidad, fecha_movimiento, observaciones
FROM Movimiento_Inventario;

CREATE VIEW vw_inventario AS
SELECT id_inventario, id_producto, cantidad_disponible, stock_minimo, ubicacion, fecha_actualizacion
FROM Inventario;

CREATE VIEW vw_alertas_stock AS
SELECT id_alerta, id_producto, id_movimiento, cantidad_registrada, fecha_alerta, estado
FROM Alerta_Stock;

CREATE VIEW vw_aparatos AS
SELECT id_aparato, id_cliente, tipo, marca, modelo, numero_serie, falla_reportada, estado
FROM Aparato;



