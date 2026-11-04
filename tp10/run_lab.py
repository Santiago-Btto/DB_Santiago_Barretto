"""Ejecuta y verifica C1-C7 sobre SQLite y una copia PostgreSQL descartable.

No modifica foodstore ni registra ventas. La preparación de C2-C4 modifica
solamente productos de foodstore_tp10_u8 y comprueba que el semáforo no lo haga.
"""

from __future__ import annotations

import argparse
import csv
import io
import sqlite3
import subprocess
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SOURCE_DB = "foodstore"
LAB_DB = "foodstore_tp10_u8"
PG_BIN = Path(r"C:\Program Files\PostgreSQL\18\bin")
PSQL = PG_BIN / "psql.exe"
CREATEDB = PG_BIN / "createdb.exe"
SQLITE_DB = ROOT / "movil" / "foodstore_movil.db"
SNAPSHOT = ROOT / "movil" / "servidor_snapshot.csv"
EVIDENCE = ROOT / "evidencia"
PRODUCT_IDS = (100001, 100002, 100003, 100004)
SOURCE_IDS_SQL = ",".join(map(str, PRODUCT_IDS))
LOG: list[str] = []


def note(message: str) -> None:
    print(message)
    LOG.append(message)


def psql(db: str, *, sql: str | None = None, file: Path | None = None) -> str:
    args = [str(PSQL), "-X", "-w", "-v", "ON_ERROR_STOP=1", "-At", "-F", "|",
            "-h", "localhost", "-p", "5432", "-U", "postgres", "-d", db]
    if (sql is None) == (file is None):
        raise ValueError("Indicar SQL o archivo, exactamente uno")
    args += ["-c", sql] if sql is not None else ["-f", str(file)]
    result = subprocess.run(args, capture_output=True, text=True, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"psql ({db}) falló: {result.stderr.strip()}")
    return result.stdout.strip()


def pg_selected(db: str) -> str:
    return psql(db, sql=(
        "SELECT id_producto,precio_lista,stock,activo FROM producto "
        f"WHERE id_producto IN ({SOURCE_IDS_SQL}) ORDER BY id_producto"
    ))


def pg_counts(db: str) -> str:
    return psql(db, sql="SELECT (SELECT count(*) FROM producto),"
                        "(SELECT count(*) FROM pedido),"
                        "(SELECT count(*) FROM detalle_pedido)")


def pg_business_state(db: str) -> str:
    return psql(db, sql="SELECT (SELECT count(*) FROM pedido),"
                        "(SELECT coalesce(sum(stock),0) FROM producto),"
                        "(SELECT md5(string_agg(id_producto::text || ':' || "
                        "precio_lista::text || ':' || stock::text || ':' || "
                        "activo::text || ':' || coalesce(deleted_at::text,''), "
                        "'|' ORDER BY id_producto)) FROM producto WHERE "
                        f"id_producto IN ({SOURCE_IDS_SQL}))")


def prepare_pg(existing_fresh_lab: bool) -> tuple[str, str]:
    if not PSQL.is_file() or not CREATEDB.is_file():
        raise FileNotFoundError("Faltan psql.exe o createdb.exe")
    source_counts = pg_counts(SOURCE_DB)
    if source_counts != "50000|200000|400000":
        raise RuntimeError(f"La base fuente no es la muestra TP9 prevista: {source_counts}")
    source_products = pg_selected(SOURCE_DB)
    exists = psql("postgres", sql=f"SELECT 1 FROM pg_database WHERE datname='{LAB_DB}'")
    if exists:
        if not existing_fresh_lab:
            raise RuntimeError(f"{LAB_DB} ya existe; no se sobrescribe")
    else:
        if existing_fresh_lab:
            raise RuntimeError("Se pidió una copia existente, pero no existe")
        result = subprocess.run(
            [str(CREATEDB), "-w", "-h", "localhost", "-p", "5432", "-U", "postgres",
             f"--template={SOURCE_DB}", LAB_DB],
            capture_output=True, text=True, encoding="utf-8",
        )
        if result.returncode:
            raise RuntimeError(f"createdb falló: {result.stderr.strip()}")
    if pg_counts(LAB_DB) != source_counts or pg_selected(LAB_DB) != source_products:
        raise RuntimeError("La copia no coincide con la base fuente")
    psql(LAB_DB, file=ROOT / "servidor_snapshot.sql")
    note(f"PG_COPIA|{LAB_DB}|productos=50000|pedidos=200000|detalles=400000")
    note("PG_FUENTE_SIN_CAMBIOS|foodstore|" + source_counts)
    return source_counts, source_products


def export_snapshot(stage: str) -> str:
    command = ("\\copy (SELECT id,nombre,precio_centavos,stock_visto,disponible,"
               "eliminado,fecha_copia FROM v_snapshot_movil ORDER BY id) "
               "TO STDOUT WITH (FORMAT csv, HEADER true)")
    data = psql(LAB_DB, sql=command)
    rows = list(csv.DictReader(io.StringIO(data)))
    if [int(r["id"]) for r in rows] != list(PRODUCT_IDS):
        raise RuntimeError("La instantánea no contiene los cuatro productos esperados")
    (EVIDENCE / "snapshots").mkdir(parents=True, exist_ok=True)
    (EVIDENCE / "snapshots" / f"{stage}.csv").write_text(data + "\n", encoding="utf-8")
    SNAPSHOT.write_text(data + "\n", encoding="utf-8")
    note(f"SNAPSHOT|{stage}|filas={len(rows)}|fecha_copia={rows[0]['fecha_copia']}")
    return data


def import_snapshot(conn: sqlite3.Connection, data: str) -> None:
    rows = list(csv.DictReader(io.StringIO(data)))
    with conn:
        conn.execute("DELETE FROM snapshot_servidor")
        for r in rows:
            values = (int(r["id"]), r["nombre"], int(r["precio_centavos"]),
                      int(r["stock_visto"]), int(r["disponible"]),
                      int(r["eliminado"]), r["fecha_copia"])
            conn.execute("INSERT INTO snapshot_servidor "
                         "(id,nombre,precio_centavos,stock_visto,disponible,eliminado,fecha_copia) "
                         "VALUES (?,?,?,?,?,?,?)", values)
            conn.execute("INSERT INTO producto_cache "
                         "(id,nombre,precio_centavos,stock_visto,disponible,eliminado,fecha_copia) "
                         "VALUES (?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET "
                         "nombre=excluded.nombre,precio_centavos=excluded.precio_centavos,"
                         "stock_visto=excluded.stock_visto,disponible=excluded.disponible,"
                         "eliminado=excluded.eliminado,fecha_copia=excluded.fecha_copia", values)
        conn.execute("UPDATE producto_cache SET disponible=0, eliminado=1 "
                     "WHERE id NOT IN (SELECT id FROM snapshot_servidor)")


def create_sqlite() -> sqlite3.Connection:
    if SQLITE_DB.exists():
        raise RuntimeError(f"{SQLITE_DB} ya existe; no se sobrescribe")
    if sqlite3.sqlite_version_info < (3, 37, 0):
        raise RuntimeError("SQLite 3.37+ es necesario para STRICT")
    conn = sqlite3.connect(SQLITE_DB)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript((ROOT / "movil" / "schema_sqlite.sql").read_text(encoding="utf-8"))
    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
        raise RuntimeError("Las claves foráneas SQLite no están activas")
    note(f"SQLITE_VERSION|{sqlite3.sqlite_version}|foreign_keys=ON|STRICT=5_tablas")
    return conn


def test_sqlite_basics(conn: sqlite3.Connection) -> None:
    content = (ROOT / "movil" / "pruebas_sqlite.sql").read_text(encoding="utf-8")
    valid = content.split("-- @expected-error", 1)[0]
    conn.executescript(valid)
    assert conn.execute("SELECT count(*) FROM pedido_borrador").fetchone()[0] == 1
    assert conn.execute("SELECT count(*) FROM item_borrador").fetchone()[0] == 1
    assert conn.execute("SELECT count(*) FROM cola_sync").fetchone()[0] == 1
    assert conn.execute("SELECT count(*) FROM pedido_borrador WHERE id_local LIKE '9999%'").fetchone()[0] == 0
    catalog = conn.execute("SELECT count(*) FROM producto_cache "
                           "WHERE disponible=1 AND eliminado=0").fetchone()[0]
    assert catalog == 4
    note("C1|catalogo_sin_servidor=4|commit_borrador_items_cola=1|rollback=sin_filas")
    before = conn.execute("SELECT count(*) FROM item_borrador").fetchone()[0]
    for label in ("cantidad", "producto"):
        block = content.split(f"-- @expected-error {label}\n", 1)[1].split("-- @expected-error", 1)[0]
        try:
            conn.execute(block)
        except sqlite3.IntegrityError as exc:
            note(f"C7|{label}|ERROR={exc}")
        else:
            raise AssertionError(f"C7 {label} fue aceptado")
    assert conn.execute("SELECT count(*) FROM item_borrador").fetchone()[0] == before
    note("C7|filas_item_antes=1|filas_item_despues=1")


def case_uuid(name: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, "foodstore-u8-" + name))


def add_draft(conn: sqlite3.Connection, name: str, product: int, quantity: int) -> str:
    draft = case_uuid("draft-" + name)
    request = case_uuid("request-" + name)
    price = conn.execute("SELECT precio_centavos FROM producto_cache WHERE id=?",
                         (product,)).fetchone()[0]
    with conn:
        conn.execute("INSERT INTO pedido_borrador VALUES (?,?,?,?)",
                     (draft, "tablet_feria", "EFECTIVO", "2026-11-04T10:00:00Z"))
        conn.execute("INSERT INTO item_borrador VALUES (?,?,?,?)",
                     (draft, product, quantity, price))
        conn.execute("INSERT INTO cola_sync(solicitud_uuid,id_local) VALUES (?,?)",
                     (request, draft))
    return request


def update_product(sql: str, expected_id: int) -> None:
    result = psql(LAB_DB, sql=sql)
    if result.splitlines()[0] != str(expected_id):
        raise RuntimeError(f"UPDATE del producto {expected_id} no afectó una fila: {result}")


def run_semaphore(conn: sqlite3.Connection, request: str, expected: str, case: str) -> None:
    pg_before = pg_business_state(LAB_DB)
    conn.executescript((ROOT / "movil" / "semaforo.sql").read_text(encoding="utf-8"))
    pg_after = pg_business_state(LAB_DB)
    if pg_before != pg_after:
        raise AssertionError(f"{case}: el semáforo cambió pedidos o stock PostgreSQL")
    row = conn.execute("SELECT estado,motivo FROM cola_sync WHERE solicitud_uuid=?",
                       (request,)).fetchone()
    if row is None or row[0] != expected:
        raise AssertionError(f"{case}: esperado {expected}, obtenido {row}")
    note(f"{case}|estado={row[0]}|motivo={row[1]}|pg_antes={pg_before}|pg_despues={pg_after}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--existing-fresh-lab", action="store_true",
                        help="Usar copia ya creada sólo si sigue intacta")
    args = parser.parse_args()
    if SQLITE_DB.exists():
        raise RuntimeError("Ya existe la base SQLite; el runner nunca la reemplaza")
    EVIDENCE.mkdir(exist_ok=True)
    source_counts, source_products = prepare_pg(args.existing_fresh_lab)
    conn = create_sqlite()
    try:
        import_snapshot(conn, export_snapshot("c1_inicial"))
        test_sqlite_basics(conn)
        run_semaphore(conn, "a1111111-1111-4111-8111-111111111111",
                      "SIMULADO_APROBADO", "C1")

        c2 = add_draft(conn, "c2", 100001, 2)
        update_product("UPDATE producto SET precio_lista=precio_lista+10 "
                       "WHERE id_producto=100001 RETURNING id_producto", 100001)
        import_snapshot(conn, export_snapshot("c2_precio_cambiado"))
        run_semaphore(conn, c2, "CONFLICTO", "C2_precio")
        draft_c2 = case_uuid("draft-c2")
        with conn:
            conn.execute("UPDATE item_borrador SET precio_centavos_visto="
                         "(SELECT precio_centavos FROM snapshot_servidor WHERE id=100001) "
                         "WHERE id_local=?", (draft_c2,))
            c2_new = case_uuid("request-c2-aceptado")
            conn.execute("INSERT INTO cola_sync(solicitud_uuid,id_local) VALUES (?,?)",
                         (c2_new, draft_c2))
        run_semaphore(conn, c2_new, "SIMULADO_APROBADO", "C2_precio_aceptado")

        c3 = add_draft(conn, "c3", 100002, 5)
        update_product("UPDATE producto SET stock=2, precio_lista=precio_lista+1 "
                       "WHERE id_producto=100002 RETURNING id_producto", 100002)
        import_snapshot(conn, export_snapshot("c3_stock_y_precio"))
        run_semaphore(conn, c3, "RECHAZADO", "C3_stock_prioridad_rojo")

        c4 = add_draft(conn, "c4", 100003, 1)
        update_product("UPDATE producto SET activo=false, deleted_at=clock_timestamp() "
                       "WHERE id_producto=100003 RETURNING id_producto", 100003)
        import_snapshot(conn, export_snapshot("c4_baja_logica"))
        run_semaphore(conn, c4, "RECHAZADO", "C4_baja_logica")
        cache = conn.execute("SELECT disponible,eliminado FROM producto_cache WHERE id=100003").fetchone()
        assert cache == (0, 1)
        assert conn.execute("SELECT count(*) FROM producto_cache WHERE id=100003").fetchone()[0] == 1
        assert conn.execute("SELECT count(*) FROM producto_cache WHERE id=100003 "
                            "AND disponible=1 AND eliminado=0").fetchone()[0] == 0
        note("C4|catalogo_100003=ausente|lapida_conservada=1")

        c5 = add_draft(conn, "c5", 100004, 1)
        run_semaphore(conn, c5, "SIMULADO_APROBADO", "C5_sin_cambios")
        previous = conn.execute("SELECT estado,motivo,resuelto_en FROM cola_sync "
                                "WHERE solicitud_uuid=?", (c5,)).fetchone()
        try:
            conn.execute("INSERT INTO cola_sync(solicitud_uuid,id_local) VALUES (?,?)",
                         (c5, case_uuid("draft-c5")))
        except sqlite3.IntegrityError as exc:
            note(f"C6|UUID_repetido|ERROR={exc}")
        else:
            raise AssertionError("C6 aceptó el mismo UUID dos veces")
        changes_before = conn.total_changes
        conn.executescript((ROOT / "movil" / "semaforo.sql").read_text(encoding="utf-8"))
        assert conn.total_changes == changes_before
        assert previous == conn.execute("SELECT estado,motivo,resuelto_en FROM cola_sync "
                                        "WHERE solicitud_uuid=?", (c5,)).fetchone()
        assert conn.execute("SELECT count(*) FROM cola_sync WHERE solicitud_uuid=?", (c5,)).fetchone()[0] == 1
        note("C6|UUID_unico=1|reejecucion_semaforo_cambios=0")

        assert conn.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
        assert conn.execute("PRAGMA foreign_key_check").fetchall() == []
        assert pg_counts(SOURCE_DB) == source_counts
        assert pg_selected(SOURCE_DB) == source_products
        assert pg_counts(LAB_DB) == source_counts
        note("FINAL|SQLite_integrity_check=ok|foreign_key_check=0|"
             "PostgreSQL_fuente_sin_cambios=true|pedidos_copia=200000")
        (EVIDENCE / "resultado_laboratorio.txt").write_text(
            "\n".join(LOG) + "\n", encoding="utf-8")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
