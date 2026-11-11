"""Contrasta la variante generada con OpenCode con el laboratorio SQLite original."""

from __future__ import annotations

import sqlite3
import subprocess
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VARIANT = ROOT / "tpi2" / "opencode_variantes"
ADOPTED = ROOT / "tp10" / "movil"
BASELINE_REV = "b6cd291"


def uid(number: int) -> str:
    return str(uuid.UUID(int=number))


def reject(conn: sqlite3.Connection, sql: str, params: tuple) -> None:
    try:
        conn.execute(sql, params)
    except sqlite3.IntegrityError:
        return
    raise AssertionError(f"Se aceptó una fila inválida: {sql}")


def baseline_sql(name: str) -> str:
    return subprocess.run(
        ["git", "show", f"{BASELINE_REV}:tp10/movil/{name}"],
        cwd=ROOT, capture_output=True, check=True, encoding="utf-8",
    ).stdout


def scenario(schema: str, semaforo: str) -> list[tuple[str, str, str]]:
    conn = sqlite3.connect(":memory:")
    conn.executescript(schema)
    assert conn.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    for product_id in range(1, 6):
        conn.execute(
            "INSERT INTO producto_cache VALUES(?,?,?,?,?,?,?)",
            (product_id, f"Producto {product_id}", 100, 10, 1, 0, "2026-11-11"),
        )
    for product_id, price, stock, available, deleted in (
        (1, 120, 10, 1, 0), (2, 120, 2, 1, 0),
        (3, 100, 10, 0, 1), (4, 100, 10, 1, 0),
    ):
        conn.execute(
            "INSERT INTO snapshot_servidor VALUES(?,?,?,?,?,?,?)",
            (product_id, f"Producto {product_id}", price, stock, available, deleted, "2026-11-11"),
        )
    cases = [
        (1, 1, 1, "PENDIENTE"), (2, 2, 5, "PENDIENTE"),
        (3, 3, 1, "PENDIENTE"), (4, 4, 1, "PENDIENTE"),
        (5, 5, 1, "PENDIENTE"), (6, None, None, "PENDIENTE"),
        (7, 4, 1, "CONFLICTO"),
    ]
    for number, product_id, quantity, status in cases:
        conn.execute(
            "INSERT INTO pedido_borrador VALUES(?,?,?,?)",
            (uid(number), "cajero", "EFECTIVO", "2026-11-11"),
        )
        if product_id is not None:
            conn.execute(
                "INSERT INTO item_borrador VALUES(?,?,?,?)",
                (uid(number), product_id, quantity, 100),
            )
        conn.execute(
            "INSERT INTO cola_sync(solicitud_uuid,id_local,estado,motivo) VALUES(?,?,?,?)",
            (uid(number + 100), uid(number), status, "histórico" if number == 7 else None),
        )
    conn.commit()
    conn.executescript(semaforo)
    # La última parte del UUID contiene el número en hexadecimal.
    observed = {
        int(row[0][-12:], 16) - 100: (row[1], row[2])
        for row in conn.execute("SELECT solicitud_uuid,estado,motivo FROM cola_sync")
    }
    expected = {
        1: "CONFLICTO", 2: "RECHAZADO", 3: "RECHAZADO",
        4: "SIMULADO_APROBADO", 5: "RECHAZADO", 6: "RECHAZADO",
        7: "CONFLICTO",
    }
    assert {key: value[0] for key, value in observed.items()} == expected
    assert observed[2][1].endswith("stock insuficiente")
    assert observed[7][1] == "histórico"
    before = list(conn.execute("SELECT solicitud_uuid,estado,motivo,resuelto_en FROM cola_sync ORDER BY 1"))
    conn.executescript(semaforo)
    assert before == list(conn.execute("SELECT solicitud_uuid,estado,motivo,resuelto_en FROM cola_sync ORDER BY 1"))
    conn.execute("UPDATE producto_cache SET precio_centavos=120 WHERE id=1")
    conn.execute("INSERT INTO pedido_borrador VALUES(?,?,?,?)", (uid(9), "cajero", "EFECTIVO", "2026-11-11"))
    conn.execute("INSERT INTO item_borrador VALUES(?,?,?,?)", (uid(9), 1, 1, 120))
    conn.execute("INSERT INTO cola_sync(solicitud_uuid,id_local) VALUES(?,?)", (uid(109), uid(9)))
    conn.commit()
    conn.executescript(semaforo)
    resolved = conn.execute("SELECT estado,motivo FROM cola_sync WHERE solicitud_uuid=?", (uid(109),)).fetchone()
    assert resolved == ("SIMULADO_APROBADO", "coincide con instantanea del servidor")
    reject(conn, "INSERT INTO cola_sync(solicitud_uuid,id_local) VALUES(?,?)", (uid(101), uid(1)))
    reject(conn, "INSERT INTO item_borrador VALUES(?,?,?,?)", (uid(4), 4, 0, 100))
    reject(conn, "INSERT INTO item_borrador VALUES(?,?,?,?)", (uid(4), 999999, 1, 100))
    conn.rollback()
    conn.execute("BEGIN")
    conn.execute("INSERT INTO pedido_borrador VALUES(?,?,?,?)", (uid(8), "cajero", "EFECTIVO", "2026-11-11"))
    conn.rollback()
    assert conn.execute("SELECT count(*) FROM pedido_borrador WHERE id_local=?", (uid(8),)).fetchone()[0] == 0
    assert conn.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    assert conn.execute("PRAGMA foreign_key_check").fetchall() == []
    result = [(str(key), value[0], value[1] or "") for key, value in sorted(observed.items())]
    result.append(("9", resolved[0], resolved[1]))
    conn.close()
    return result


def main() -> None:
    schema = (VARIANT / "schema_sqlite.sql").read_text(encoding="utf-8")
    semaforo = (VARIANT / "semaforo.sql").read_text(encoding="utf-8")
    assert (ADOPTED / "schema_sqlite.sql").read_text(encoding="utf-8") == schema
    assert (ADOPTED / "semaforo.sql").read_text(encoding="utf-8") == semaforo
    original = scenario(baseline_sql("schema_sqlite.sql"), baseline_sql("semaforo.sql"))
    variant = scenario(schema, semaforo)
    assert original == variant, (original, variant)
    print("SQLITE|baseline_vs_opencode=iguales|adoptado=identico|solicitudes=8|errores_integridad=3|segunda_corrida_sin_cambios=true")
    for key, status, reason in variant:
        print(f"S{key}|{status}|{reason}")


if __name__ == "__main__":
    main()
