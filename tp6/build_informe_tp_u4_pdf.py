from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "Informe_TP_U4_FNBC_Desnormalizacion.pdf"


def register_fonts() -> None:
    pdfmetrics.registerFont(TTFont("Arial", r"C:\Windows\Fonts\arial.ttf"))
    pdfmetrics.registerFont(TTFont("Arial-Bold", r"C:\Windows\Fonts\arialbd.ttf"))
    pdfmetrics.registerFont(TTFont("Consolas", r"C:\Windows\Fonts\consola.ttf"))


def build_styles():
    styles = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "Title", parent=styles["Title"], fontName="Arial-Bold", fontSize=21,
            leading=26, alignment=TA_CENTER, textColor=colors.HexColor("#123047"), spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "Subtitle", parent=styles["Normal"], fontName="Arial", fontSize=11,
            leading=16, alignment=TA_CENTER, textColor=colors.HexColor("#445A67"), spaceAfter=18,
        ),
        "h1": ParagraphStyle(
            "H1", parent=styles["Heading1"], fontName="Arial-Bold", fontSize=15,
            leading=19, textColor=colors.HexColor("#123047"), spaceBefore=12, spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "H2", parent=styles["Heading2"], fontName="Arial-Bold", fontSize=11.5,
            leading=15, textColor=colors.HexColor("#15616D"), spaceBefore=9, spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "Body", parent=styles["BodyText"], fontName="Arial", fontSize=9.4,
            leading=13.2, textColor=colors.HexColor("#222222"), spaceAfter=7,
        ),
        "small": ParagraphStyle(
            "Small", parent=styles["BodyText"], fontName="Arial", fontSize=8.3,
            leading=11.2, textColor=colors.HexColor("#263B45"), spaceAfter=5,
        ),
        "table_header": ParagraphStyle(
            "TableHeader", parent=styles["BodyText"], fontName="Arial-Bold", fontSize=8.3,
            leading=11.2, textColor=colors.white, spaceAfter=0,
        ),
        "code": ParagraphStyle(
            "Code", parent=styles["Code"], fontName="Consolas", fontSize=7.4,
            leading=10.1, textColor=colors.HexColor("#102A3A"),
        ),
    }


def p(text, style):
    return Paragraph(text, style)


def section_title(text, styles):
    return p(text, styles["h1"])


def code_box(lines, styles):
    body = "<br/>".join(line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;") for line in lines)
    table = Table([[p(body, styles["code"])]], colWidths=[6.85 * inch])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#EDF4F5")),
        ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#B9D4D8")),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return table


def styled_table(rows, widths, styles, header=True):
    data = []
    for index, row in enumerate(rows):
        row_style = styles["table_header"] if header and index == 0 else styles["small"]
        data.append([p(str(cell), row_style) for cell in row])
    table = Table(data, colWidths=widths, repeatRows=1 if header else 0)
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#C7D8DD")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]
    if header:
        commands.extend([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#123047")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ])
    for index in range(1 if header else 0, len(rows)):
        if index % 2 == 0:
            commands.append(("BACKGROUND", (0, index), (-1, index), colors.HexColor("#F4F8F9")))
    table.setStyle(TableStyle(commands))
    return table


def footer(canvas, document):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#B9D4D8"))
    canvas.line(0.72 * inch, 0.55 * inch, 7.78 * inch, 0.55 * inch)
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#4D6570"))
    canvas.drawString(0.72 * inch, 0.35 * inch, "Food Store - Base de Datos II - TP Unidad 4")
    canvas.drawRightString(7.78 * inch, 0.35 * inch, f"Pagina {document.page}")
    canvas.restoreState()


def build_document():
    register_fonts()
    styles = build_styles()
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=letter, leftMargin=0.72 * inch, rightMargin=0.72 * inch,
        topMargin=0.68 * inch, bottomMargin=0.75 * inch,
        title="Informe TP Unidad 4 - FNBC y Desnormalizacion",
        author="Santiago Barretto",
    )
    story = []

    story.extend([
        Spacer(1, 0.45 * inch),
        p("Trabajo Practico - Unidad 4", styles["title"]),
        p("Forma Normal de Boyce-Codd y desnormalizacion controlada en Food Store", styles["subtitle"]),
        Spacer(1, 0.14 * inch),
        styled_table([
            ["Estudiante", "Santiago Barretto"],
            ["Motor", "PostgreSQL 18.4"],
            ["Base de laboratorio", "food_store_tp_u4_fnbc"],
            ["Fecha de ejecucion", "03/10/2026"],
            ["Repositorio", "DB_Santiago_Barretto"],
        ], [1.75 * inch, 5.10 * inch], styles, header=False),
        Spacer(1, 0.28 * inch),
        p("<b>Alcance.</b> La resolucion se ejecuto sobre una copia aislada y poblada de Food Store. No se modificaron <i>practica_bd2</i> ni las bases utilizadas en TP3, TP4, TP5 o TPI.", styles["body"]),
        section_title("Entregables", styles),
        p("1. <b>tp_fnbc_control_lote.sql</b>: esquema, instancia, descomposicion, vista de compatibilidad y verificacion de la Parte 1.", styles["body"]),
        p("2. <b>tp_desnormalizacion_top_categorias.sql</b>: estructura desnormalizada, sincronizacion, planes y auditoria de la Parte 2.", styles["body"]),
        p("3. Este informe, complementado por la evidencia directa del motor en <b>tp6/evidencia/20261003_153429/</b>.", styles["body"]),
        Spacer(1, 0.12 * inch),
        styled_table([
            ["Control de ejecucion", "Resultado real"],
            ["Productos / pedidos / detalles", "50.000 / 200.000 / 400.000"],
            ["Pedidos y detalles del dia medido", "311 / 622"],
            ["Equivalencia de la descomposicion", "0 diferencias en ambos sentidos"],
            ["Auditoria de la estructura redundante", "0 diferencias"],
        ], [3.55 * inch, 3.30 * inch], styles),
        PageBreak(),
    ])

    story.extend([
        section_title("1. Parte 1 - Analisis de FNBC", styles),
        p("La relacion inicial es <b>R(LoteID, DepositoID, ResponsableControlID)</b>. A partir de las dos reglas de negocio se obtienen las dependencias funcionales siguientes:", styles["body"]),
        code_box([
            "{LoteID, DepositoID} -> ResponsableControlID",
            "ResponsableControlID -> DepositoID",
        ], styles),
        Spacer(1, 0.10 * inch),
        p("Las clausuras muestran que existen dos claves candidatas. Todos los atributos son primos, porque cada uno integra al menos una de esas claves.", styles["body"]),
        styled_table([
            ["Conjunto", "Clausura", "Resultado"],
            ["{LoteID, DepositoID}", "{LoteID, DepositoID, ResponsableControlID}", "Clave candidata"],
            ["{LoteID, ResponsableControlID}", "{LoteID, ResponsableControlID, DepositoID}", "Clave candidata"],
            ["{ResponsableControlID}", "{ResponsableControlID, DepositoID}", "No es clave"],
            ["{LoteID}", "{LoteID}", "No es clave"],
            ["{DepositoID}", "{DepositoID}", "No es clave"],
        ], [1.85 * inch, 3.15 * inch, 1.85 * inch], styles),
        section_title("Violacion y anomalias", styles),
        p("La dependencia <b>ResponsableControlID -> DepositoID</b> viola FNBC. Su determinante no es superclave: su clausura no contiene LoteID. Con la instancia dada, esta redundancia habilita tres anomalias:", styles["body"]),
        p("<b>Insercion:</b> no puede registrarse al responsable 803 en el deposito 30 sin asignarlo a un lote. <b>Borrado:</b> borrar (503, 31, 802) elimina tambien el unico dato de pertenencia de 802. <b>Actualizacion:</b> mover a 801 exige cambiar las filas de 501 y 502; si solo se modifica una, se contradice la regla.", styles["body"]),
        section_title("Descomposicion sin perdida", styles),
        code_box([
            "responsable_deposito(ResponsableControlID PK, DepositoID FK)",
            "control_lote_responsable(LoteID, ResponsableControlID,",
            "                          PK(LoteID, ResponsableControlID))",
        ], styles),
        p("El atributo comun, ResponsableControlID, es clave de <i>responsable_deposito</i>; por el criterio formal de descomposicion, la reunion natural es sin perdida. La vista <b>vw_control_lote_almacen_compatibilidad</b> la reconstruye. Los controles SQL <i>original menos vista</i> y <i>vista menos original</i> devolvieron 0 diferencias.", styles["body"]),
        PageBreak(),
    ])

    story.extend([
        section_title("2. Parte 2 - Medicion del reporte normalizado", styles),
        p("La guia pide el top 5 diario de categorias. Para evitar una medicion vacia, las fechas de la copia de laboratorio se desplazaron de forma exclusiva a 03/10/2026. La consulta de origen recorre <i>detalle_pedido</i>, <i>producto</i>, <i>categoria</i> y <i>pedido</i>.", styles["body"]),
        p("<b>Captura textual de EXPLAIN ANALYZE - antes</b>", styles["h2"]),
        code_box([
            "Parallel Seq Scan on public.detalle_pedido dp",
            "  Filter: (NOT dp.eliminado)",
            "  actual rows=133333.33 loops=3",
            "",
            "Parallel Seq Scan on public.pedido ped",
            "  Filter: ((NOT ped.eliminado) AND ((ped.fecha)::date = CURRENT_DATE))",
            "  Rows Removed by Filter: 199689",
            "",
            "Execution Time: 49.870 ms",
        ], styles),
        Spacer(1, 0.1 * inch),
        p("El costo se concentra en los recorridos paralelos y sus uniones: se examina la tabla completa de 400.000 detalles para obtener 622 detalles del dia. Por esa evidencia, se justifica precalcular el agregado solicitado por un panel de lectura frecuente.", styles["body"]),
        section_title("Patron elegido y consistencia", styles),
        p("Se implemento una <b>vista materializada diaria por categoria</b>. Sus triggers <i>AFTER ... FOR EACH STATEMENT</i> se instalan sobre detalle_pedido, pedido, producto y categoria. Todos llaman a REFRESH MATERIALIZED VIEW dentro de la misma transaccion que cambia la fuente. Por eso, un COMMIT publica fuente y resumen coherentes, mientras que un ROLLBACK revierte ambos. Las tablas normalizadas permanecen como fuente de verdad: eliminar y recrear la vista no pierde informacion.", styles["body"]),
        styled_table([
            ["Evidencia que motiva", "Mecanismo anti-desincronizacion", "Reversibilidad"],
            ["49,870 ms y recorridos paralelos sobre 400.000 detalles", "Triggers en las 4 tablas fuente y refresh transaccional", "La vista se reconstruye por completo desde tablas normalizadas"],
        ], [2.25 * inch, 2.45 * inch, 2.15 * inch], styles),
        PageBreak(),
    ])

    story.extend([
        section_title("3. Resultado de la estructura desnormalizada", styles),
        p("La consulta final lee directamente <b>mv_tp_u4_top_categorias_dia</b>, filtrando por fecha y ordenando por monto. No vuelve a recorrer ni unir las cuatro tablas operativas.", styles["body"]),
        p("<b>Captura textual de EXPLAIN ANALYZE - despues</b>", styles["h2"]),
        code_box([
            "Bitmap Index Scan on ix_mv_tp_u4_top_categorias_fecha_monto",
            "  Index Cond: (mv_tp_u4_top_categorias_dia.fecha = CURRENT_DATE)",
            "",
            "Bitmap Heap Scan on public.mv_tp_u4_top_categorias_dia",
            "  actual rows=2 loops=1",
            "",
            "Execution Time: 0.344 ms",
        ], styles),
        Spacer(1, 0.10 * inch),
        styled_table([
            ["Antes: modelo normalizado", "Despues: vista materializada"],
            ["<b>Tiempo de ejecucion:</b> 49,870 ms", "<b>Tiempo de ejecucion:</b> 0,344 ms"],
            ["<b>Nodo dominante:</b> Parallel Seq Scan / Parallel Hash Join", "<b>Nodo dominante:</b> Bitmap Heap Scan apoyado por Bitmap Index Scan"],
            ["<b>Acceso:</b> 4 tablas y agregacion en tiempo real", "<b>Acceso:</b> una vista materializada indexada"],
        ], [3.42 * inch, 3.43 * inch], styles),
        Spacer(1, 0.12 * inch),
        p("La mejora medida es aproximadamente <b>99,31 %</b>. La vista materializada no pretende reemplazar el modelo normalizado: solo evita recalcular el mismo agregado para una lectura de alta frecuencia.", styles["body"]),
        section_title("Auditoria y prueba reversible", styles),
        p("La auditoria compara la agregacion fuente con la vista mediante FULL OUTER JOIN y devuelve cualquier fila faltante, extra o con monto distinto. Sobre la base migrada devolvio cero filas. Ademas, se inserto un pedido y detalle de prueba dentro de una transaccion: el trigger refresco la vista, la auditoria interna devolvio 0 diferencias y ROLLBACK dejo la copia sin esa modificacion.", styles["body"]),
        code_box([
            "auditoria sobre base migrada: (0 rows)",
            "auditoria_durante_prueba | diferencias",
            "--------------------------+-------------",
            "auditoria_durante_prueba | 0",
            "ROLLBACK",
        ], styles),
        section_title("Conclusiones y ubicacion de la evidencia", styles),
        p("La Parte 1 demuestra con dependencias, claves, DDL y equivalencia que la descomposicion elimina la violacion de FNBC sin perder informacion. La Parte 2 fundamenta la redundancia con una medicion reproducible, asegura su sincronizacion, mide el plan resultante y verifica que no existan diferencias. La salida original de PostgreSQL se conserva en <b>tp6/evidencia/20261003_153429/</b>.", styles["body"]),
    ])

    doc.build(story, onFirstPage=footer, onLaterPages=footer)


if __name__ == "__main__":
    build_document()
    print(OUTPUT)
