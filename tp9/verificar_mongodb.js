// Verifica integridad de documentos migrados y una insercion invalida rechazada.
const fs = require('node:fs');
const path = require('node:path');
const foodstoreDb = db.getSiblingDB('foodstore_tp9');
const orders = foodstoreDb.getCollection('pedidos');
const documents = orders.find().toArray();
const exportPath = path.join(process.cwd(), 'tp9', 'data', 'pedidos_export.ndjson');
const source = fs.readFileSync(exportPath, 'utf8').replace(/^\uFEFF/, '')
  .split(/\r?\n/).filter(Boolean).map(line => EJSON.parse(line, { relaxed: false }));
const sourceById = new Map(source.map(order => [order.id_pedido.toString(), order]));
if (documents.length !== 20) throw new Error(`Se esperaban 20 pedidos; hay ${documents.length}`);
let lines = 0;
for (const order of documents) {
  const original = sourceById.get(order.id_pedido.toString());
  if (!original) throw new Error(`ID ajeno a la exportacion: ${order.id_pedido}`);
  if (order._id.toString() !== order.id_pedido.toString() || !order.lineas.length) {
    throw new Error(`ID o lineas invalidas en ${order.id_pedido}`);
  }
  if (order.fecha.getTime() !== original.fecha.getTime() ||
      order.fecha_pg_exacta !== original.fecha_pg_exacta ||
      order.estado !== original.estado ||
      order.estado_procedencia !== original.estado_procedencia ||
      order.forma_pago !== original.forma_pago ||
      order.cliente.id_cliente.toString() !== original.cliente.id_cliente.toString() ||
      order.cliente.nombre !== original.cliente.nombre ||
      order.cliente.apellido !== original.cliente.apellido ||
      order.total.toString() !== original.total.toString() ||
      order.lineas.length !== original.lineas.length) {
    throw new Error(`Cabecera diferente al origen para pedido ${order.id_pedido}`);
  }
  for (let i = 0; i < order.lineas.length; i++) {
    const line = order.lineas[i];
    const before = original.lineas[i];
    if (line.id_producto.toString() !== before.id_producto.toString() ||
        line.nombre_producto_actual !== before.nombre_producto_actual ||
        Number(line.cantidad) !== Number(before.cantidad) ||
        line.precio_unitario.toString() !== before.precio_unitario.toString() ||
        line.subtotal.toString() !== before.subtotal.toString()) {
      throw new Error(`Linea diferente al origen para pedido ${order.id_pedido}`);
    }
  }
  lines += order.lineas.length;
}
if (lines !== 40) throw new Error(`Se esperaban 40 lineas; hay ${lines}`);

let rejected = false;
try {
  orders.insertOne({
    _id: NumberLong('999999'), id_pedido: NumberLong('999999'),
    fecha: new Date(), fecha_pg_exacta: 'prueba',
    estado: 'sin_estado_en_origen',
    estado_procedencia: 'pedido_sin_columna_estado',
    forma_pago: 'PRUEBA',
    cliente: { id_cliente: NumberLong('1'), nombre: 'Prueba', apellido: 'Prueba' },
    lineas: [{ id_producto: NumberLong('1'), cantidad: NumberInt(0),
      precio_unitario: Decimal128.fromString('1.00'),
      subtotal: Decimal128.fromString('0.00') }],
    total: Decimal128.fromString('0.00')
  });
} catch (error) {
  if (error.code === 121) rejected = true; else throw error;
}
if (!rejected || orders.countDocuments({ _id: NumberLong('999999') }) !== 0) {
  throw new Error('La regla de cantidad positiva no rechazo el documento de prueba.');
}
print(`INTEGRIDAD|documentos=${documents.length}|lineas=${lines}|campos_origen_iguales=true|cantidad_cero_rechazada=${rejected}|coleccion_sin_prueba=true`);
