"""Genera el PDF entregable a partir del informe Markdown integrado."""

from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    HRFlowable,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "informe_tecnico.md"
OUTPUT = HERE / "DB_Santiago_Barretto_TPI2.pdf"
pdfmetrics.registerFont(TTFont("Arial", r"C:\Windows\Fonts\arial.ttf"))
pdfmetrics.registerFont(TTFont("Arial-Bold", r"C:\Windows\Fonts\arialbd.ttf"))


def inline(value: str) -> str:
    value = html.escape(value.strip())
    value = value.replace("**", "")
    value = value.replace("`", "")
    return value.replace("  ", " ")


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#d0d9e5"))
    canvas.line(18 * mm, 17 * mm, 192 * mm, 17 * mm)
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#5b6778"))
    canvas.drawString(18 * mm, 12 * mm, "Food Store  |  TPI segunda entrega  |  Santiago Barretto")
    canvas.drawRightString(192 * mm, 12 * mm, f"{doc.page}")
    canvas.restoreState()


styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    name="TitleCustom", fontName="Arial-Bold", fontSize=17, leading=21,
    textColor=colors.HexColor("#17365d"), spaceAfter=9,
))
styles.add(ParagraphStyle(
    name="H2Custom", fontName="Arial-Bold", fontSize=11.2, leading=14,
    textColor=colors.HexColor("#17365d"), spaceBefore=11, spaceAfter=5,
))
styles.add(ParagraphStyle(
    name="BodyCustom", fontName="Arial", fontSize=9, leading=13,
    spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="CellCustom", fontName="Arial", fontSize=8.4, leading=11,
))
styles.add(ParagraphStyle(
    name="CellHeadCustom", parent=styles["CellCustom"], fontName="Arial-Bold",
    textColor=colors.white,
))


def parse_table(lines: list[str]):
    rows = []
    for line in lines:
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-{2,}:?", cell) for cell in cells):
            continue
        rows.append(cells)
    table_data = []
    for index, row in enumerate(rows):
        style = styles["CellHeadCustom"] if index == 0 else styles["CellCustom"]
        table_data.append([Paragraph(inline(cell), style) for cell in row])
    table = Table(table_data, colWidths=[27 * mm, 151 * mm], hAlign="LEFT", repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#17365d")),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#c9d3df")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f6f8fb")]),
    ]))
    return table


def build():
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    story = []
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue
        if line.startswith("# "):
            story.append(Paragraph(inline(line[2:]), styles["TitleCustom"]))
            story.append(HRFlowable(width="100%", thickness=1.2, color=colors.HexColor("#2e74ad")))
            story.append(Spacer(1, 5 * mm))
            index += 1
            continue
        if line.startswith("## "):
            if line[3:].startswith("Cómo se probó"):
                story.append(PageBreak())
            story.append(Paragraph(inline(line[3:]), styles["H2Custom"]))
            index += 1
            continue
        if line.startswith("|"):
            block = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                block.append(lines[index])
                index += 1
            story.append(parse_table(block))
            story.append(Spacer(1, 3 * mm))
            continue
        paragraph = []
        while index < len(lines) and lines[index].strip() and not lines[index].startswith(("#", "|")):
            paragraph.append(lines[index].strip())
            index += 1
        story.append(Paragraph(inline(" ".join(paragraph)), styles["BodyCustom"]))
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
        topMargin=17 * mm, bottomMargin=22 * mm,
        title="TPI Food Store - Segunda entrega", author="Santiago Barretto",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
