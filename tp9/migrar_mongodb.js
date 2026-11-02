// Ejecutar desde la raiz: mongosh mongodb://127.0.0.1:27017/admin --file tp9/migrar_mongodb.js
// Crea la base foodstore_tp9 y la coleccion pedidos solo si no existen.
// Lee el Extended JSON exportado desde PostgreSQL; no usa credenciales.
const fs = require('node:fs');
const path = require('node:path');

const databaseName = 'foodstore_tp9';
const collectionName = 'pedidos';
const exportPath = path.join(process.cwd(), 'tp9', 'data', 'pedidos_export.ndjson');
const foodstoreDb = db.getSiblingDB(databaseName);

if (foodstoreDb.getCollectionNames().includes(collectionName)) {
  throw new Error(`La coleccion ${databaseName}.${collectionName} ya existe; no se reemplaza.`);
}
if (!fs.existsSync(exportPath)) {
  throw new Error(`No se encuentra el archivo exportado: ${exportPath}`);
}

const lines = fs.readFileSync(exportPath, 'utf8').replace(/^\uFEFF/, '')
  .split(/\r?\n/).filter(line => line.trim() !== '');
const documents = lines.map(line => EJSON.parse(line, { relaxed: false }));
if (documents.length < 5) throw new Error('Se requieren al menos cinco pedidos.');

function cents(decimalValue) {
  const text = decimalValue.toString();
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(text);
  if (!match) throw new Error(`Importe no convertible a centavos exactos: ${text}`);
  return BigInt(match[1]) * 100n + BigInt((match[2] || '').padEnd(2, '0'));
}

const seen = new Set();
let lineCount = 0;
for (const order of documents) {
  const orderId = order.id_pedido.toString();
  if (order._id.toString() !== orderId || seen.has(orderId)) {
    throw new Error(`ID de pedido duplicado o inconsistente: ${orderId}`);
  }
  seen.add(orderId);
  if (order.estado !== 'sin_estado_en_origen' ||
      order.estado_procedencia !== 'pedido_sin_columna_estado') {
    throw new Error(`Estado no trazable para pedido ${orderId}`);
  }
  if (!Array.isArray(order.lineas) || order.lineas.length === 0) {
    throw new Error(`Pedido ${orderId} sin lineas`);
  }
  let sum = 0n;
  for (const line of order.lineas) {
    const quantity = Number(line.cantidad);
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new Error(`Cantidad invalida en pedido ${orderId}`);
    }
    const unit = cents(line.precio_unitario);
    const subtotal = cents(line.subtotal);
    if (subtotal !== BigInt(quantity) * unit) {
      throw new Error(`Subtotal inconsistente en pedido ${orderId}`);
    }
    sum += subtotal;
    lineCount++;
  }
  if (sum !== cents(order.total)) {
    throw new Error(`Total inconsistente en pedido ${orderId}`);
  }
}

foodstoreDb.createCollection(collectionName, {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['id_pedido', 'fecha', 'fecha_pg_exacta', 'estado',
        'estado_procedencia', 'forma_pago', 'cliente', 'lineas', 'total'],
      properties: {
        id_pedido: { bsonType: 'long' },
        fecha: { bsonType: 'date' },
        fecha_pg_exacta: { bsonType: 'string' },
        estado: { enum: ['sin_estado_en_origen'] },
        estado_procedencia: { enum: ['pedido_sin_columna_estado'] },
        forma_pago: { bsonType: 'string' },
        cliente: {
          bsonType: 'object', required: ['id_cliente', 'nombre', 'apellido'],
          properties: {
            id_cliente: { bsonType: 'long' },
            nombre: { bsonType: 'string' },
            apellido: { bsonType: 'string' }
          }
        },
        lineas: {
          bsonType: 'array', minItems: 1,
          items: {
            bsonType: 'object',
            required: ['id_producto', 'cantidad', 'precio_unitario', 'subtotal'],
            properties: {
              id_producto: { bsonType: 'long' },
              cantidad: { bsonType: 'int', minimum: 1 },
              precio_unitario: { bsonType: 'decimal', minimum: Decimal128.fromString('0') },
              subtotal: { bsonType: 'decimal', minimum: Decimal128.fromString('0') }
            }
          }
        },
        total: { bsonType: 'decimal', minimum: Decimal128.fromString('0') }
      }
    }
  },
  validationLevel: 'strict',
  validationAction: 'error'
});

const collection = foodstoreDb.getCollection(collectionName);
const result = collection.insertMany(documents, { ordered: true });
collection.createIndex({ id_pedido: 1 }, { unique: true });
collection.createIndex({ estado: 1 });
collection.createIndex({ 'lineas.id_producto': 1 });
collection.createIndex({ total: 1 });
print(`MIGRACION|base=${databaseName}|coleccion=${collectionName}|documentos=${Object.keys(result.insertedIds).length}|lineas=${lineCount}`);
print(`MONGODB_VERSION|${foodstoreDb.version()}`);
print(`IDS|${[...seen].sort((a, b) => Number(a) - Number(b)).join(',')}`);
