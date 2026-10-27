"""Genera el informe de una página a partir de la evidencia real del TP8."""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path
from shutil import copyfile

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parent
EVIDENCE = max((ROOT / "evidencia").iterdir(), key=lambda p: p.name)
MANIFEST = json.loads((EVIDENCE / "backup_manifest.json").read_text(encoding="utf-8-sig"))
RESTORE_LOG = (EVIDENCE / "restore_run.log").read_text(encoding="utf-8-sig")
OUTPUT = ROOT / "informe_u6.pdf"
DELIVERY_COPY = ROOT / "DB_Santiago_Barretto.pdf"


def observed_seconds(label: str) -> float:
    match = re.search(rf"{re.escape(label)}[^\n]*?: (\d+(?:\.\d+)?) segundos", RESTORE_LOG)
    if not match:
        raise RuntimeError(f"Falta la medición {label} en restore_run.log")
    return float(match.group(1))


def validation_file(name: str) -> dict[str, int]:
    values: dict[str, int] = {}
    for line in (EVIDENCE / name).read_text(encoding="utf-8-sig").splitlines():
        key, count = line.split("|", 1)
        values[key] = int(count)
    return values


def register_fonts() -> None:
    font_dir = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(font_dir / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(font_dir / "arialbd.ttf")))


def paragraph(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def build() -> None:
    if "SIMULACRO EXITOSO" not in RESTORE_LOG:
        raise RuntimeError("La evidencia no acredita una restauración exitosa")
    source = validation_file("validation_source.txt")
    restored = validation_file("validation_restored.txt")
    expected = {key: int(value) for key, value in MANIFEST["validation"].items()}
    if source != expected or restored != expected:
        raise RuntimeError("Los conteos no coinciden entre manifiesto, origen y restauración")
    if expected["productos_invalidos"] or expected["detalles_invalidos"]:
        raise RuntimeError("La evidencia contiene datos inválidos")

    rpo = observed_seconds("RPO observado")
    rto = observed_seconds("RTO observado")
    started = datetime.fromisoformat(MANIFEST["backup_started_at"])
    finished = datetime.fromisoformat(MANIFEST["backup_completed_at"])
    register_fonts()

    navy = colors.HexColor("#123047")
    teal = colors.HexColor("#137C82")
    pale = colors.HexColor("#EAF3F3")
    light = colors.HexColor("#F2F5F6")
    ink = colors.HexColor("#25343B")

    title = ParagraphStyle("title", fontName="Arial-Bold", fontSize=17.5, leading=21,
                           textColor=navy, alignment=TA_CENTER, spaceAfter=3)
    subtitle = ParagraphStyle("subtitle", fontName="Arial", fontSize=9, leading=12,
                              textColor=colors.HexColor("#4C636B"), alignment=TA_CENTER)
    section = ParagraphStyle("section", fontName="Arial-Bold", fontSize=10.3, leading=13,
                             textColor=teal, spaceBefore=9, spaceAfter=4)
    body = ParagraphStyle("body", fontName="Arial", fontSize=8.3, leading=11.1,
                          textColor=ink, spaceAfter=4)
    small = ParagraphStyle("small", parent=body, fontSize=7.5, leading=10)
    cell = ParagraphStyle("cell", parent=body, fontSize=7.8, leading=10, spaceAfter=0)
    cell_bold = ParagraphStyle("cell_bold", parent=cell, fontName="Arial-Bold")

    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=17 * mm, rightMargin=17 * mm,
        topMargin=15 * mm, bottomMargin=15 * mm, title="Informe TP8 Unidad 6 - Food Store",
        author="Santiago Barretto",
    )
    story = [
        paragraph("TP8 · Unidad 6 — Mantenimiento y recuperación", title),
        paragraph("Food Store | Santiago Barretto | 27/10/2026 | PostgreSQL 18.4", subtitle),
        Spacer(1, 5 * mm),
    ]

    summary = Table([
        [paragraph("Base principal", cell_bold), paragraph("foodstore (copia de food_store_tp5_base)", cell),
         paragraph("Destino", cell_bold), paragraph("foodstore_restore_test", cell)],
        [paragraph("Respaldo", cell_bold),
         paragraph(f"{started:%d/%m/%Y %H:%M:%S} a {finished:%H:%M:%S} (-03:00)", cell),
         paragraph("Formato", cell_bold), paragraph("custom / pg_dump -Fc", cell)],
        [paragraph("Tamaño", cell_bold), paragraph(f"{MANIFEST['bytes']:,} bytes".replace(",", "."), cell),
         paragraph("Integridad", cell_bold), paragraph("SHA-256 y pg_restore --list: OK", cell)],
    ], colWidths=[27 * mm, 72 * mm, 23 * mm, 54 * mm])
    summary.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), light),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [light, colors.white]),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#D1DFE1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(summary)

    story.append(paragraph("Recuperación contra reloj", section))
    recovery = Table([
        [paragraph("Métrica", cell_bold), paragraph("Meta del laboratorio", cell_bold),
         paragraph("Resultado observado", cell_bold)],
        [paragraph("RPO", cell_bold), paragraph("≤ 24 h", cell),
         paragraph(f"{rpo:.3f} s ({rpo / 60:.2f} min)", cell)],
        [paragraph("RTO", cell_bold), paragraph("≤ 600 s (10 min)", cell),
         paragraph(f"{rto:.3f} s", cell)],
    ], colWidths=[31 * mm, 58 * mm, 87 * mm])
    recovery.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), pale),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#D1DFE1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(recovery)
    story.append(paragraph(
        "El RPO es la edad conservadora del respaldo al iniciar el simulacro; indica exposición "
        "potencial, no pérdida real demostrada. El RTO se midió desde justo antes de crear la base "
        "de prueba hasta terminar las validaciones.", body))

    story.append(paragraph("Validación de la restauración", section))
    rows = [[paragraph("Tabla / control", cell_bold), paragraph("Antes del respaldo", cell_bold),
             paragraph("Restaurado", cell_bold)]]
    for key in ("categoria", "cliente", "producto", "pedido", "detalle_pedido"):
        count = f"{expected[key]:,}".replace(",", ".")
        rows.append([paragraph(key, cell), paragraph(count, cell), paragraph(count, cell)])
    rows.append([paragraph("Productos / detalles inválidos", cell_bold),
                 paragraph("0 / 0", cell), paragraph("0 / 0", cell)])
    validation = Table(rows, colWidths=[74 * mm, 51 * mm, 51 * mm])
    validation.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), pale),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, light]),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#D1DFE1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(validation)

    story.append(paragraph("Monitoreo, problema y mejora", section))
    story.append(paragraph(
        "Salud: base de 150 MB, actividad de conexiones, estado de tablas y consultas activas "
        "registrados. Las cinco tablas carecían de estadísticas ANALYZE en la copia; se ejecutó "
        "ANALYZE condicional. En la segunda pasada no hizo falta repetirlo. No se usó VACUUM FULL.", body))
    story.append(paragraph(
        "Problema real: la guía usa producto.precio, pero el esquema tiene producto.precio_lista; "
        "la consulta inicial falló y se corrigió. También se corrigió la codificación de los logs "
        "en PowerShell 5.1 y se repitió la restauración. Mejora: respaldos diarios en un segundo "
        "almacenamiento, con retención, hash y restauración semanal programada.", body))

    story.append(paragraph("Asistencia y trazabilidad", section))
    story.append(paragraph(
        "OpenCode propuso un borrador bajo SPEC_U6.md. Se corrigieron nombres de tablas, comparación "
        "contra el manifiesto previo al dump, cálculo de RPO y controles lógicos; se aceptó sólo "
        "tras probar pg_dump, pg_restore y psql. Evidencia: tp8/evidencia/20261027_091130/ "
        "(manifiesto, logs y siete validaciones). El dump no se publica y ningún script contiene "
        "contraseñas.", small))

    def footer(canvas, _doc):
        canvas.saveState()
        canvas.setFont("Arial", 7.2)
        canvas.setFillColor(colors.HexColor("#667A82"))
        canvas.drawString(17 * mm, 10 * mm, "DB_Santiago_Barretto | TP8 - Unidad 6")
        canvas.drawRightString(A4[0] - 17 * mm, 10 * mm, "1 / 1")
        canvas.restoreState()

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    copyfile(OUTPUT, DELIVERY_COPY)
    print(f"Generados: {OUTPUT} y {DELIVERY_COPY}")


if __name__ == "__main__":
    build()
