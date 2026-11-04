PRAGMA foreign_keys = ON;

CREATE TABLE producto_cache (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL CHECK (trim(nombre) <> ''),
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL CHECK (trim(fecha_copia) <> ''),
    CHECK (eliminado = 0 OR disponible = 0)
) STRICT;

CREATE TABLE pedido_borrador (
    id_local TEXT PRIMARY KEY CHECK (length(id_local) = 36 AND
        substr(id_local, 9, 1) = '-' AND substr(id_local, 14, 1) = '-' AND
        substr(id_local, 19, 1) = '-' AND substr(id_local, 24, 1) = '-'),
    usuario TEXT NOT NULL CHECK (trim(usuario) <> ''),
    forma_pago TEXT NOT NULL CHECK (forma_pago IN
        ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    fecha TEXT NOT NULL CHECK (trim(fecha) <> '')
) STRICT;

CREATE TABLE item_borrador (
    id_local TEXT NOT NULL,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache(id) ON DELETE RESTRICT
) STRICT;

CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY CHECK (length(solicitud_uuid) = 36 AND
        substr(solicitud_uuid, 9, 1) = '-' AND substr(solicitud_uuid, 14, 1) = '-' AND
        substr(solicitud_uuid, 19, 1) = '-' AND substr(solicitud_uuid, 24, 1) = '-'),
    id_local TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN
        ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo TEXT,
    resuelto_en TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE RESTRICT
) STRICT;

-- Tabla de importación: conserva incluso productos dados de baja para resolver
-- solicitudes pendientes; la caché no depende de esta tabla por FK.
CREATE TABLE snapshot_servidor (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL,
    CHECK (eliminado = 0 OR disponible = 0)
) STRICT;

CREATE INDEX idx_cola_sync_pendiente ON cola_sync(estado);
CREATE INDEX idx_item_borrador_producto ON item_borrador(producto_id);
