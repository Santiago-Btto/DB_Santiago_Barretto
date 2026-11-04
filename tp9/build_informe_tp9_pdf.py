"""Construye el PDF de Unidad 7 únicamente desde resultados ya verificados."""

from __future__ import annotations

import json
import re
from html import escape
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle,
)


ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT / "evidencia" / "20261102_133900"
OUTPUT = ROOT / "DB_Santiago_Barretto.pdf"


def read(name: str) -> str:
    return (EVIDENCE / name).read_text(encoding="utf-8-sig")


def parse_comparisons() -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    active: str | None = None
    for line in read("comparacion_motores.txt").splitlines():
        if line.startswith("IDs|"):
            if active is None:
                raise ValueError("IDs sin consulta en la comparación")
            result[active]["ids"] = line.removeprefix("IDs|")
            continue
        pieces = line.split("|")
        if len(pieces) != 4:
            raise ValueError(f"Comparación inesperada: {line}")
        active = pieces[0]
        result[active] = {part.split("=", 1)[0]: part.split("=", 1)[1]
                          for part in pieces[1:]}
    for key in ("B_ESTADO", "C_PRODUCTO", "D_TOTAL", "E_FORMA_PAGO"):
        row = result[key]
        if row["PostgreSQL"] != row["MongoDB"] or row["IDs_coinciden"] != "True" or not row.get("ids"):
            raise ValueError(f"No se verificó equivalencia para {key}")
    return result


def register_fonts() -> None:
    fonts = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(fonts / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(fonts / "arialbd.ttf")))
    pdfmetrics.registerFont(TTFont("Consolas", str(fonts / "consola.ttf")))


def make_table(rows: list[list[Paragraph]], widths: list[float], header: bool = True) -> Table:
    table = Table(rows, colWidths=widths, repeatRows=1 if header else 0)
    style = [
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#CCD9DF")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    if header:
        style += [
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DCECED")),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1),
             [colors.white, colors.HexColor("#F4F7F8")]),
        ]
    else:
        style.append(("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F4F7F8")))
    table.setStyle(TableStyle(style))
    return table


def build() -> None:
    comparisons = parse_comparisons()
    model = read("postgresql_modelo.txt")
    integrity = read("mongodb_integridad.txt")
    mongo = read("mongodb_coleccion.txt")
    pg_queries = read("postgresql_consultas.txt")
    mongo_queries = read("mongodb_consultas.txt")
    if "columna_estado|f" not in model or "clientes_sinteticos|t" not in model:
        raise ValueError("No se confirmó el esquema real y la procedencia sintética")
    if "documentos=20|lineas=40|campos_origen_iguales=true|cantidad_cero_rechazada=true" not in integrity:
        raise ValueError("No se confirmó la integridad de la migración")
    if "COLECCION|foodstore_tp9.pedidos|documentos=20" not in mongo:
        raise ValueError("No se confirmó la colección MongoDB")
    if "A_TODOS|20|" not in mongo_queries:
        raise ValueError("No se confirmó la consulta de todos los pedidos")
    if len(re.findall(r"^\d+\|sin_estado_en_origen$", pg_queries, re.M)) != 20:
        raise ValueError("La consulta A de PostgreSQL no devolvió 20 pedidos")

    first = json.loads((ROOT / "data" / "pedidos_export.ndjson").read_text(
        encoding="utf-8-sig").splitlines()[0])
    if first["id_pedido"]["$numberLong"] != "400001":
        raise ValueError("Cambió el documento ilustrativo")
    lines = first["lineas"]
    conclusion = (ROOT / "IA_CONTRASTE.md").read_text(encoding="utf-8")
    conclusion = conclusion.split("## Conclusión (menos de 200 palabras)", 1)[1].strip()
    if len(conclusion.split()) > 200:
        raise ValueError("La conclusión supera 200 palabras")

    register_fonts()
    navy = colors.HexColor("#173044")
    teal = colors.HexColor("#0B7780")
    ink = colors.HexColor("#283941")
    title = ParagraphStyle("Title", fontName="Arial-Bold", fontSize=19, leading=23,
                           textColor=navy, alignment=TA_CENTER, spaceAfter=5)
    subtitle = ParagraphStyle("Subtitle", fontName="Arial", fontSize=9.5, leading=13,
                              textColor=colors.HexColor("#587078"), alignment=TA_CENTER)
    h1 = ParagraphStyle("H1", fontName="Arial-Bold", fontSize=12.5, leading=16,
                        textColor=teal, spaceBefore=12, spaceAfter=5)
    h2 = ParagraphStyle("H2", fontName="Arial-Bold", fontSize=10, leading=13,
                        textColor=navy, spaceBefore=8, spaceAfter=4)
    body = ParagraphStyle("Body", fontName="Arial", fontSize=8.8, leading=12.1,
                          textColor=ink, spaceAfter=6)
    small = ParagraphStyle("Small", parent=body, fontSize=7.7, leading=10.3)
    cell = ParagraphStyle("Cell", parent=body, fontSize=7.8, leading=10.2,
                          spaceAfter=0)
    cell_bold = ParagraphStyle("CellBold", parent=cell, fontName="Arial-Bold")

    def p(text: str, style: ParagraphStyle = body) -> Paragraph:
        return Paragraph(text, style)

    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=17 * mm, rightMargin=17 * mm,
        topMargin=15 * mm, bottomMargin=16 * mm,
        title="TP9 Unidad 7 - NoSQL y Food Store", author="Santiago Barretto",
    )
    story = [
        p("TP9 - Unidad 7: Food Store en MongoDB", title),
        p("Santiago Barretto | DB_Santiago_Barretto | Unidad 7 | laboratorio: 02/11/2026", subtitle),
        Spacer(1, 5 * mm),
        p("1. Modelo documental y migración", h1),
        p("Desde PostgreSQL 18.4 se exportaron <b>20 pedidos existentes y 40 líneas</b> de la "
          "carga sintética Food Store. MongoDB 9.0.4 contiene una colección "
          "<b>foodstore_tp9.pedidos</b> con 20 documentos. Se conservaron los IDs originales, "
          "la forma de pago, las cantidades y el precio histórico de cada línea. El total "
          "se calculó con esos precios, no con el precio de lista actual."),
    ]

    mapping = [
        [p("PostgreSQL", cell_bold), p("Documento MongoDB", cell_bold)],
        [p("pedido (PK id_pedido, fecha, forma_pago)", cell),
         p("_id/id_pedido Long; fecha Date + fecha_pg_exacta; forma_pago", cell)],
        [p("cliente (FK id_cliente)", cell),
         p("cliente embebido: id_cliente, nombre y apellido sintéticos", cell)],
        [p("detalle_pedido (FK pedido/producto)", cell),
         p("lineas[]: id_producto, cantidad, precio_unitario y subtotal", cell)],
        [p("SUM(cantidad * precio_unitario)", cell),
         p("total Decimal128; precios y subtotales también Decimal128", cell)],
    ]
    story.append(make_table(mapping, [74 * mm, 102 * mm]))
    story.append(p("El origen <b>no tiene columna estado</b>. Se usó la marca explícita "
                   "<b>sin_estado_en_origen</b> en los documentos; no representa un estado "
                   "comercial. Se omitieron email y teléfono. El texto fecha_pg_exacta "
                   "preserva los microsegundos que BSON Date no retiene.", body))

    story.append(p("Documento real de ejemplo: pedido 400001", h2))
    detail_rows = [
        [p("Producto", cell_bold), p("Cantidad", cell_bold),
         p("Precio histórico", cell_bold), p("Subtotal", cell_bold)],
    ]
    for line in lines:
        detail_rows.append([
            p(escape(line["id_producto"]["$numberLong"]), cell),
            p(escape(line["cantidad"]["$numberInt"]), cell),
            p(escape(line["precio_unitario"]["$numberDecimal"]), cell),
            p(escape(line["subtotal"]["$numberDecimal"]), cell),
        ])
    story.append(make_table(detail_rows, [42 * mm, 37 * mm, 48 * mm, 49 * mm]))
    story.append(p(
        f"Cliente ID {first['cliente']['id_cliente']['$numberLong']}; "
        f"forma de pago {escape(first['forma_pago'])}; "
        f"total {first['total']['$numberDecimal']}. La colección tiene índices por ID, "
        "estado, producto embebido y total.", small))
    story.append(p("Reglas preservadas", h2))
    story.append(p("(1) Cada pedido tiene al menos una línea, cantidad positiva y precio no "
                   "negativo; subtotal y total coinciden con la aritmética exacta en centavos. "
                   "(2) Los IDs de pedido son únicos y las referencias de cliente/producto "
                   "proceden de FK válidas en PostgreSQL. La verificación posterior comparó "
                   "todos los campos y MongoDB rechazó una inserción con cantidad cero.", body))
    story.append(PageBreak())

    story.append(p("2. Consultas y verificación entre motores", h1))
    story.append(p("Las consultas se ejecutaron sobre la misma muestra de 20 pedidos. "
                   "MongoDB mostró todos los IDs y su marca de estado (consulta A). "
                   "Para el producto se eligió el ID 100001, presente en ocho pedidos. "
                   "El umbral 10.000,00 separa seis pedidos; los totales van de "
                   "3.418,00 a 26.099,00."))
    result_rows = [[p("Consulta", cell_bold), p("PostgreSQL", cell_bold),
                    p("MongoDB", cell_bold), p("IDs", cell_bold)]]
    labels = [
        ("B_ESTADO", "Estado ausente"),
        ("C_PRODUCTO", "Producto 100001"),
        ("D_TOTAL", "Total > 10.000"),
        ("E_FORMA_PAGO", "Pago TARJETA (extra)"),
    ]
    for key, label in labels:
        row = comparisons[key]
        result_rows.append([
            p(label, cell), p(row["PostgreSQL"], cell), p(row["MongoDB"], cell),
            p("Coinciden", cell),
        ])
    story.append(make_table(result_rows, [69 * mm, 33 * mm, 33 * mm, 41 * mm]))
    story.append(p("<b>IDs por estado (B):</b> " + escape(comparisons["B_ESTADO"]["ids"].replace(",", ", ")), small))
    story.append(p("<b>IDs por producto (C):</b> " + escape(comparisons["C_PRODUCTO"]["ids"].replace(",", ", ")), small))
    story.append(p("El filtro de estado devuelve los 20 por ausencia del dato en el origen. "
                   "Como contraste selectivo con un atributo real se añadió forma_pago = TARJETA: "
                   "7 IDs idénticos en ambos motores.", body))

    story.append(p("3. Dos afirmaciones de IA contrastadas", h1))
    story.append(p("<b>Lectura del pedido completo.</b> OpenCode indicó que embebiendo líneas se "
                   "evita el JOIN. La "
                   "<link href='https://www.mongodb.com/docs/manual/data-modeling/embedding/' color='#0B7780'>"
                   "documentación oficial de MongoDB</link> permite recuperar datos relacionados "
                   "en una operación, y la consulta real devuelve cabecera y líneas. Esto no "
                   "demuestra que sea más rápido: no se midió latencia.", body))
    story.append(p("<b>Coherencia y atomicidad.</b> La afirmación de que MongoDB deja toda la "
                   "coherencia a la aplicación era demasiado amplia. Sus "
                   "<link href='https://www.mongodb.com/docs/manual/core/write-operations-atomicity/' color='#0B7780'>"
                   "escrituras son atómicas por documento y admite transacciones multidocumento</link> "
                   "en despliegues compatibles. Este laboratorio embebe cabecera y líneas y "
                   "valida cantidades; la igualdad de totales se comprobó en el script. "
                   "PostgreSQL conserva las "
                   "<link href='https://www.postgresql.org/docs/18/ddl-constraints.html' color='#0B7780'>"
                   "claves foráneas observadas</link> entre tablas.", body))

    story.append(p("4. Conclusión", h1))
    story.append(p(escape(conclusion).replace("`", ""), body))
    story.append(p("Evidencia íntegra y scripts: tp9/evidencia/20261102_133900/, "
                   "consultas_mongodb.js y consultas_postgresql.sql. No se incluyeron "
                   "datos personales reales ni mediciones de rendimiento inventadas.", small))

    story.append(PageBreak())
    story.append(p("5. Evidencias de ejecución", h1))
    story.append(p("Estas salidas se obtuvieron del laboratorio de PostgreSQL y MongoDB el "
                   "02/11/2026. Se incluyen aquí para que el informe sea verificable por sí "
                   "mismo; los archivos íntegros y los scripts están en el repositorio.", body))
    evidence_rows = [
        [p("Comprobación", cell_bold), p("Resultado observado", cell_bold)],
        [p("Migración con mongosh", cell),
         p("MIGRACION | base=foodstore_tp9 | coleccion=pedidos | documentos=20 | lineas=40", cell)],
        [p("Colección e índices", cell),
         p("foodstore_tp9.pedidos: 20 documentos; _id_, id_pedido_1, estado_1, "
           "lineas.id_producto_1, total_1", cell)],
        [p("Integridad posterior", cell),
         p("20 documentos y 40 líneas iguales a la exportación; inserción de cantidad cero "
           "rechazada; colección de prueba sin residuos", cell)],
    ]
    story.append(make_table(evidence_rows, [57 * mm, 119 * mm]))

    story.append(p("Cuatro consultas MongoDB ejecutadas", h2))
    query_rows = [[p("Consulta", cell_bold), p("Salida de mongosh", cell_bold)]]
    query_rows += [
        [p("A. Todos los pedidos", cell),
         p("20 documentos; IDs 400001 a 400013 y 405882, 450001, 455882, "
           "500001, 505882, 550001, 555882; todos con estado "
           "sin_estado_en_origen", cell)],
        [p("B. Estado seleccionado", cell),
         p("20 pedidos con estado sin_estado_en_origen; IDs completos en la página 2", cell)],
        [p("C. Producto 100001", cell),
         p("8 pedidos: " + escape(comparisons["C_PRODUCTO"]["ids"].replace(",", ", ")), cell)],
        [p("D. Total &gt; 10.000,00", cell),
         p("6 pedidos: " + escape(comparisons["D_TOTAL"]["ids"].replace(",", ", ")), cell)],
    ]
    story.append(make_table(query_rows, [57 * mm, 119 * mm]))
    story.append(p("En PostgreSQL, las consultas B y C devolvieron exactamente los mismos "
                   "IDs que MongoDB (20 y 8 respectivamente), según la tabla de la página 2. "
                   "El estado es una marca de ausencia, porque la tabla original no tiene "
                   "esa columna; no se presentó como estado comercial real.", body))
    story.append(p("<b>Repositorio y código:</b> "
                   "<link href='https://github.com/Santiago-Btto/DB_Santiago_Barretto/tree/main/tp9' "
                   "color='#0B7780'>github.com/Santiago-Btto/DB_Santiago_Barretto/tree/main/tp9</link>. "
                   "Allí se encuentran los scripts "
                   "<b>consultas_mongodb.js</b> y <b>consultas_postgresql.sql</b>, "
                   "la exportación y las salidas completas en evidencia/20261102_133900/.", small))

    def footer(canvas, _doc):
        canvas.saveState()
        canvas.setFont("Arial", 7.5)
        canvas.setFillColor(colors.HexColor("#62757D"))
        canvas.drawString(17 * mm, 10 * mm, "DB_Santiago_Barretto | TP9 - Unidad 7")
        canvas.drawRightString(A4[0] - 17 * mm, 10 * mm,
                               f"Página {canvas.getPageNumber()}")
        canvas.restoreState()

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Informe generado: {OUTPUT}")


if __name__ == "__main__":
    build()
