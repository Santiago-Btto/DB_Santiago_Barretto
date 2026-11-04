"""Informe de Unidad 8 basado en la evidencia ejecutada, máximo seis páginas."""

from __future__ import annotations

import re
import shutil
from html import escape
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT / "evidencia"
OUTPUT = ROOT / "docs" / "informe.pdf"
ALIAS = ROOT / "DB_Santiago_Barretto.pdf"


def verified_data() -> tuple[str, str, str]:
    lab = (EVIDENCE / "resultado_laboratorio.txt").read_text(encoding="utf-8-sig")
    mongo = (EVIDENCE / "mongodb_tp9_verificacion.txt").read_text(encoding="utf-8-sig")
    sqlite = (EVIDENCE / "consultas_sqlite.txt").read_text(encoding="utf-8-sig")
    required = ("C1|catalogo_sin_servidor=4", "C2_precio|estado=CONFLICTO",
                "C2_precio_aceptado|estado=SIMULADO_APROBADO",
                "C3_stock_prioridad_rojo|estado=RECHAZADO",
                "C4_baja_logica|estado=RECHAZADO",
                "C5_sin_cambios|estado=SIMULADO_APROBADO",
                "C6|UUID_unico=1|reejecucion_semaforo_cambios=0",
                "C7|filas_item_antes=1|filas_item_despues=1",
                "FINAL|SQLite_integrity_check=ok|foreign_key_check=0|"
                "PostgreSQL_fuente_sin_cambios=true|pedidos_copia=200000")
    if any(item not in lab for item in required):
        raise ValueError("Falta una verificación real de C1-C7")
    for line in lab.splitlines():
        if "|pg_antes=" in line:
            before, after = line.split("|pg_antes=", 1)[1].split("|pg_despues=", 1)
            if before != after or not re.fullmatch(r"200000\|\d+\|[a-f0-9]{32}", before):
                raise ValueError("El semáforo alteró PostgreSQL o falta hash")
    if "mongo_pedidos=20" not in mongo or "producto_100001=8" not in mongo:
        raise ValueError("Falta verificación de MongoDB TP9")
    if "CONFLICTO|1" not in sqlite or "RECHAZADO|2" not in sqlite or "SIMULADO_APROBADO|3" not in sqlite:
        raise ValueError("Faltan conteos finales de SQLite")
    return lab, mongo, sqlite


def build() -> None:
    lab, _, _ = verified_data()
    fonts = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(fonts / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(fonts / "arialbd.ttf")))
    navy = colors.HexColor("#173044")
    teal = colors.HexColor("#087A82")
    ink = colors.HexColor("#2A3B43")
    muted = colors.HexColor("#59717A")
    title = ParagraphStyle("title", fontName="Arial-Bold", fontSize=18, leading=21,
                           alignment=TA_CENTER, textColor=navy, spaceAfter=5)
    subtitle = ParagraphStyle("subtitle", fontName="Arial", fontSize=9, leading=12,
                              alignment=TA_CENTER, textColor=muted, spaceAfter=12)
    h1 = ParagraphStyle("h1", fontName="Arial-Bold", fontSize=12.3, leading=15,
                        textColor=teal, spaceBefore=9, spaceAfter=5)
    h2 = ParagraphStyle("h2", fontName="Arial-Bold", fontSize=10, leading=12.5,
                        textColor=navy, spaceBefore=7, spaceAfter=4)
    body = ParagraphStyle("body", fontName="Arial", fontSize=8.7, leading=12,
                          textColor=ink, spaceAfter=6)
    small = ParagraphStyle("small", parent=body, fontSize=7.6, leading=10.2)
    cell = ParagraphStyle("cell", parent=body, fontSize=7.65, leading=10.2, spaceAfter=0)
    cell_head = ParagraphStyle("cellhead", parent=cell, fontName="Arial-Bold")

    def p(value: str, style: ParagraphStyle = body) -> Paragraph:
        return Paragraph(value.replace("`", ""), style)

    def table(headers: list[str], rows: list[list[str]], widths: list[float]) -> Table:
        result = Table([[p(x, cell_head) for x in headers]] +
                       [[p(x, cell) for x in row] for row in rows],
                       colWidths=widths, repeatRows=1, hAlign="LEFT")
        result.setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#C5D5DA")),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DDECEF")),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1),
             [colors.white, colors.HexColor("#F5F8F8")]),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ("RIGHTPADDING", (0, 0), (-1, -1), 6),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]))
        return result

    doc = SimpleDocTemplate(str(OUTPUT), pagesize=A4,
                            leftMargin=17 * mm, rightMargin=17 * mm,
                            topMargin=15 * mm, bottomMargin=16 * mm,
                            title="Food Store - TP8 Unidad 8", author="Santiago Barretto")
    story = [
        p("Food Store en la feria", title),
        p("TP8 de la cátedra · Unidad 8 · Santiago Barretto · DB_Santiago_Barretto · 04/11/2026", subtitle),
        p("Alcance y regla de autoridad", h1),
        p("Se trabajó con <b>foodstore_tp10_u8</b>, copia de PostgreSQL Food Store usada en TP9, "
          "y con SQLite 3.49.1. Los cuatro productos son sintéticos; el 100001 también aparece "
          "en los pedidos MongoDB de Unidad 7. El móvil consulta y arma borradores; "
          "<b>PostgreSQL decide precio, stock y ventas</b>. SIMULADO_APROBADO no es una venta."),
        p("1.a · Qué datos viajan", h1),
        table(["A la tablet", "No a la tablet"], [[
            "ID, nombre, precio en centavos enteros, stock visto, disponible, eliminado y fecha de copia.",
            "Clientes, cuentas, contraseñas, correos, teléfonos, costos internos e historial completo de pedidos."
        ]], [88 * mm, 88 * mm]),
        p("1.b · Esquema local", h1),
        table(["Tabla STRICT", "Reglas principales"], [
            ["producto_cache", "Centavos y stock no negativos; disponible/eliminado 0 o 1; lápida conservada."],
            ["pedido_borrador", "UUID local; usuario sintético, forma de pago permitida y fecha."],
            ["item_borrador", "FK a borrador y caché; cantidad &gt; 0; precio visto en centavos."],
            ["cola_sync", "UUID único; estados PENDIENTE, CONFLICTO, RECHAZADO o SIMULADO_APROBADO."],
            ["snapshot_servidor", "Instantánea importada del CSV; contiene también productos dados de baja."],
        ], [43 * mm, 133 * mm]),
        p("1.c · Transacciones, catálogo y errores", h1),
        p("<b>C1:</b> un BEGIN/COMMIT guardó borrador, ítem y solicitud; otro BEGIN/ROLLBACK "
          "no dejó fila. El catálogo devolvió cuatro productos sin conexión al servidor. "
          "<b>C7:</b> cantidad cero produjo error CHECK y producto inexistente error FK; "
          "el conteo de ítems siguió en uno. `PRAGMA foreign_keys` estuvo activo y las "
          "cinco tablas se crearon como STRICT.", body),
        PageBreak(),
        p("2. Sincronización y semáforo", h1),
        p("2.a · Instantánea PostgreSQL → CSV → SQLite", h2),
        p("La vista <b>v_snapshot_movil</b> en la copia exportó los productos 100001-100004. "
          "El CSV se importó en `snapshot_servidor` y actualizó `producto_cache` en una "
          "transacción. Las cuatro versiones de la instantánea están en "
          "`evidencia/snapshots/`; la última conserva la lápida 100003. Fecha de copia "
          + escape(re.search(r"SNAPSHOT\|c4_baja_logica\|filas=4\|fecha_copia=([^\n]+)", lab).group(1))
          + "."),
        p("2.b · Regla ejecutada", h2),
        p("El SQL procesa solamente solicitudes PENDIENTE. <b>Rojo → RECHAZADO</b> si el ítem "
          "falta, está no disponible, eliminado o excede stock; si no hay rojo, "
          "<b>amarillo → CONFLICTO</b> por precio distinto; si tampoco hay amarillo, "
          "<b>verde → SIMULADO_APROBADO</b>. La decisión y el motivo se escriben sólo en `cola_sync`."),
        p("2.c · Casos ejecutados", h2),
        table(["Caso y comando/preparación", "Resultado real y explicación"], [
            ["C2: UPDATE de precio en copia (100001: 53700 → 54700 centavos), nueva instantánea; luego UPDATE del precio visto e INSERT con otro UUID.",
             "CONFLICTO; tras aceptar, SIMULADO_APROBADO. El UUID anterior conserva el conflicto."],
            ["C3: UPDATE stock=2 y precio+100 centavos para 100002; borrador de 5 unidades.",
             "RECHAZADO por stock insuficiente. Rojo prevaleció aunque también cambió el precio."],
            ["C4: UPDATE activo=false, deleted_at=clock_timestamp() para 100003; nueva instantánea y recarga.",
             "RECHAZADO. El producto no aparece como disponible, pero su fila queda con eliminado=1."],
            ["C5: INSERT de borrador de 100004 sin cambios en la instantánea.",
             "SIMULADO_APROBADO; sólo una resolución local."],
            ["C6: INSERT de solicitud con UUID de C5 y segunda corrida del semáforo.",
             "Error UNIQUE; una fila por UUID y cero cambios al repetir la simulación."],
        ], [88 * mm, 88 * mm]),
        p("Control PostgreSQL: antes y después de <b>cada</b> semáforo coincidieron los 200.000 "
          "pedidos, la suma de stock y el hash de precio/stock/actividad/lápida de los cuatro "
          "productos. Los cambios entre C2-C4 fueron preparación explícita en la copia; la "
          "base original `foodstore` quedó sin cambios.", small),
        PageBreak(),
        p("3. Integración de tres motores", h1),
        p("3.a · Mapa de datos y autoridad", h2),
        table(["Motor", "Qué guarda", "Quién manda"], [
            ["PostgreSQL", "Productos, precios, stock, clientes, pedidos y detalles.",
             "Fuente de verdad; el TP usa una copia de prueba."],
            ["MongoDB U7", "20 pedidos y 40 líneas embebidas; ocho pedidos contienen 100001.",
             "Copia documental de lectura. No autoriza ventas."],
            ["SQLite U8", "Caché, instantánea, borradores, ítems y cola.",
             "Autoridad sólo sobre borradores locales; el semáforo es simulado."],
        ], [31 * mm, 78 * mm, 67 * mm]),
        p("3.b · Mantenimiento y restauración", h2),
        table(["Pregunta", "Plan"], [
            ["¿Qué se respalda?", "PostgreSQL: pg_dump custom diario, SHA-256 y restauración semanal de prueba como en U6. "
             "Borradores/cola de tablets: copia cifrada al cierre. MongoDB derivado: respaldo propio si se usa, "
             "o reconstrucción contrastada desde PostgreSQL."],
            ["¿Servidor restaurado desde copia vieja?", "Detener envíos automáticos; conservar UUID locales, "
             "descargar una instantánea nueva y revalidar todo en el servidor. Ningún "
             "SIMULADO_APROBADO antiguo se convierte en venta."],
            ["¿Cuándo se revisan conflictos?", "Responsable de operaciones: al recuperar conexión, "
             "cada 30 minutos durante feria activa y al cierre diario. Requiere aceptación humana o cancelación."],
        ], [56 * mm, 120 * mm]),
        p("La idempotencia real iría en el servidor: tabla de solicitud_uuid única y "
          "transacción que revalide precio/stock, cree el pedido y descuente stock sólo una vez. "
          "No se implementó esa venta en la tablet.", body),
        PageBreak(),
        p("3.c · Code review con OpenCode Plan", h1),
        p("OpenCode inventarió scripts SQL, JS, PowerShell y Python de varias unidades. Se "
          "contrastaron cuatro observaciones con archivos y con el laboratorio; la respuesta "
          "original y la decisión detallada están en `evidencia/` y `docs/revision_opencode.md`."),
        table(["Unidad y hallazgo", "Decisión y prueba"], [
            ["U8: conteo de pedidos + suma de stock no detectaban un cambio de precio o baja.",
             "CORREGIDO: hash de los cuatro productos antes/después de cada semáforo; "
             "coincide en C1-C5."],
            ["U7: un fallo parcial de insertMany puede dejar colección y bloquear el reintento.",
             "ACEPTADO como riesgo; el guardia impide sobrescritura. Se documentó inspección "
             "y recuperación manual; la colección válida tiene 20 documentos."],
            ["U6: la última línea de SELECT EXISTS podría ser un aviso; se sugirió riesgo de interpolación.",
             "DESCARTADO para este ensayo: nombres constantes, salidas reales de una línea `t`. "
             "No se altera un TP previo sin fallo reproducido."],
            ["U8: el runner no reejecuta sobre SQLite existente.",
             "ACEPTADO como protección: exige copia fresca y no pisa borradores/evidencia."],
        ], [86 * mm, 90 * mm]),
        p("Una sospecha adicional de IA fue descartada: `SIMULADO_APROBADO` no se trata como "
          "venta; `semaforo.sql` únicamente modifica la cola SQLite. El conteo de pedidos "
          "y el estado del servidor se verifican antes y después de cada corrida.", small),
        PageBreak(),
        p("4. Spec, bitácora y defensa", h1),
        p("4.a · Spec previa en formato Kiro", h2),
        table(["EARS", "Comportamiento y caso"], [
            ["REQ-01", "WHEN se crea un borrador, guardar todo en transacción; invalidaciones sin filas parciales. C1/C7."],
            ["REQ-02", "WHEN cambia precio sin rojo, marcar CONFLICTO; con precio aceptado y UUID nuevo, aprobación simulada. C2."],
            ["REQ-03", "WHEN falta producto, hay baja o stock insuficiente, marcar RECHAZADO sin tocar el servidor. C3/C4."],
            ["REQ-04", "WHEN todo coincide, marcar SIMULADO_APROBADO una vez; UUID repetido falla. C5/C6."],
        ], [30 * mm, 146 * mm]),
        p("`docs/kiro/requirements.md`, `design.md` y `tasks.md` se escribieron antes de los "
          "scripts. El formato es compatible con la actividad; no se afirma haber usado la "
          "aplicación Kiro. OpenCode Plan propuso el esquema y el semáforo a partir de la spec."),
        p("4.b · Bitácora de IA y DUIA", h2),
        p("Tres entradas reales en `docs/bitacora_ia.md`: (1) se aceptó la prioridad del "
          "semáforo y se corrigieron los campos usuario/forma_pago omitidos por la IA; "
          "(2) se corrigió la verificación de PostgreSQL con hash; (3) se documentó el "
          "riesgo de importación parcial MongoDB y se descartó el supuesto fallo concreto "
          "del script U6. `docs/DUIA.md` declara Codex y OpenCode, decisiones y pruebas."),
        p("4.c · Defensa", h2),
        p("`docs/ensayo_defensa.md` prepara diez minutos: mapa, C2 en vivo y hallazgo "
          "corregido. La presentación en clase corresponde al estudiante y no se declara "
          "como realizada por este informe."),
        p("Cierre", h2),
        p("SQLite permite consultar una copia local y guardar borradores con integridad. "
          "La prueba demostró conflicto, rechazo, lápida e idempotencia local sin crear "
          "ventas. PostgreSQL debe conservar la decisión final; MongoDB U7 sigue como "
          "lectura documental. El informe se acompaña de scripts, CSV, DB SQLite y "
          "evidencia en la rama `codex/tp10-unidad8-sqlite`."),
        p("Fuentes técnicas: <link href='https://www.sqlite.org/stricttables.html' color='#087A82'>"
          "SQLite STRICT</link>, <link href='https://www.sqlite.org/pragma.html#pragma_foreign_keys' "
          "color='#087A82'>SQLite foreign_keys</link> y "
          "<link href='https://www.postgresql.org/docs/18/sql-createview.html' "
          "color='#087A82'>PostgreSQL CREATE VIEW</link>. Salidas ejecutadas: `evidencia/resultado_laboratorio.txt`.", small),
    ]

    def footer(canvas, _doc):
        canvas.saveState()
        canvas.setFont("Arial", 7.4)
        canvas.setFillColor(muted)
        canvas.drawString(17 * mm, 10 * mm, "DB_Santiago_Barretto | TP8 Unidad 8 | tp10")
        canvas.drawRightString(A4[0] - 17 * mm, 10 * mm,
                               f"Página {canvas.getPageNumber()}")
        canvas.restoreState()

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    shutil.copyfile(OUTPUT, ALIAS)
    print(f"Informe generado: {OUTPUT} y {ALIAS}")


if __name__ == "__main__":
    build()
