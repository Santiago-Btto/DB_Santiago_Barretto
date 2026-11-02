// TP9 / Unidad 7. Ejecutar despues de migrar_mongodb.js.
const foodstoreDb = db.getSiblingDB('foodstore_tp9');
const orders = foodstoreDb.getCollection('pedidos');
if (!foodstoreDb.getCollectionNames().includes('pedidos')) {
  throw new Error('La coleccion pedidos no existe. Ejecutar migrar_mongodb.js.');
}

// A. Todos los pedidos, identificador y estado.
const all = orders.find({}, { id_pedido: 1, estado: 1, _id: 0 })
  .sort({ id_pedido: 1 }).toArray();
print(`A_TODOS|${all.length}|${all.map(p => `${p.id_pedido}:${p.estado}`).join(',')}`);

function queryIds(filter) {
  return orders.find(filter, { id_pedido: 1, _id: 0 })
    .sort({ id_pedido: 1 }).toArray().map(p => p.id_pedido.toString());
}

// B. Estado que efectivamente existe en los datos: no registrado en origen.
const byState = queryIds({ estado: 'sin_estado_en_origen' });
print(`B_ESTADO|${byState.length}|${byState.join(',')}`);

// C. Un producto presente en ocho pedidos de la muestra.
const byProduct = queryIds({ 'lineas.id_producto': NumberLong('100001') });
print(`C_PRODUCTO|${byProduct.length}|${byProduct.join(',')}`);

// D. Umbral elegido tras inspeccionar los importes de la muestra.
const byTotal = queryIds({ total: { $gt: Decimal128.fromString('10000.00') } });
print(`D_TOTAL|${byTotal.length}|${byTotal.join(',')}`);

// E. Consulta adicional sobre un atributo realmente presente en PostgreSQL.
const byPayment = queryIds({ forma_pago: 'TARJETA' });
print(`E_FORMA_PAGO|${byPayment.length}|${byPayment.join(',')}`);
