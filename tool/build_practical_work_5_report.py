"""Build the editable Word report from its UTF-8 Markdown source."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from xml.etree.ElementTree import Element, SubElement, register_namespace, tostring

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "SOYLE_practical_work_05_report.md"
OUTPUT = ROOT / "docs" / "SOYLE_practical_work_05_report_corrected.docx"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
register_namespace("w", W)
register_namespace("r", R)


def w(name):
    return f"{{{W}}}{name}"


def sub(parent, name, attrs=None):
    return SubElement(parent, w(name), attrs or {})


def clean_markdown(value):
    return value.replace("**", "").replace("`", "").strip()


document = Element(w("document"))
body = sub(document, "body")


def add_paragraph(text, style="Normal", align=None, bold=False, size=None):
    p = sub(body, "p")
    ppr = sub(p, "pPr")
    sub(ppr, "pStyle", {w("val"): style})
    if align:
        sub(ppr, "jc", {w("val"): align})
    run = sub(p, "r")
    rpr = sub(run, "rPr")
    if bold:
        sub(rpr, "b")
    if size:
        sub(rpr, "sz", {w("val"): str(size)})
    fonts = sub(rpr, "rFonts")
    fonts.set(w("ascii"), "Times New Roman")
    fonts.set(w("hAnsi"), "Times New Roman")
    t = sub(run, "t")
    t.text = text


def add_page_break():
    p = sub(body, "p")
    run = sub(p, "r")
    sub(run, "br", {w("type"): "page"})


def add_table(rows, placeholder=False):
    table = sub(body, "tbl")
    props = sub(table, "tblPr")
    sub(props, "tblW", {w("w"): "9072", w("type"): "dxa"})
    borders = sub(props, "tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        sub(
            borders,
            side,
            {w("val"): "single", w("sz"): "6", w("color"): "AAB4C3"},
        )
    widths = [9072 // len(rows[0])] * len(rows[0])
    widths[-1] += 9072 - sum(widths)
    grid = sub(table, "tblGrid")
    for width in widths:
        sub(grid, "gridCol", {w("w"): str(width)})
    for row_index, row in enumerate(rows):
        tr = sub(table, "tr")
        if placeholder:
            trpr = sub(tr, "trPr")
            sub(trpr, "trHeight", {w("val"): "3100", w("hRule"): "atLeast"})
        for column_index, value in enumerate(row):
            cell = sub(tr, "tc")
            tcpr = sub(cell, "tcPr")
            sub(tcpr, "tcW", {w("w"): str(widths[column_index]), w("type"): "dxa"})
            if placeholder:
                sub(tcpr, "shd", {w("fill"): "F4F7FB", w("val"): "clear"})
                sub(tcpr, "vAlign", {w("val"): "center"})
            elif row_index == 0:
                sub(tcpr, "shd", {w("fill"): "E7EEF7", w("val"): "clear"})
            p = sub(cell, "p")
            ppr = sub(p, "pPr")
            sub(ppr, "jc", {w("val"): "center" if placeholder else "left"})
            run = sub(p, "r")
            rpr = sub(run, "rPr")
            fonts = sub(rpr, "rFonts")
            fonts.set(w("ascii"), "Times New Roman")
            fonts.set(w("hAnsi"), "Times New Roman")
            if row_index == 0 and not placeholder:
                sub(rpr, "b")
            if placeholder:
                sub(rpr, "sz", {w("val"): "24"})
                sub(rpr, "color", {w("val"): "596579"})
            sub(run, "t").text = value


lines = SOURCE.read_text(encoding="utf-8").splitlines()
cover = True
index = 0
while index < len(lines):
    raw = lines[index].strip()
    if raw == "---" and cover:
        add_page_break()
        cover = False
        index += 1
        continue
    if not raw or raw == "<br><br>":
        index += 1
        continue
    if raw.startswith("|"):
        table_lines = []
        while index < len(lines) and lines[index].strip().startswith("|"):
            table_lines.append(lines[index].strip())
            index += 1
        rows = []
        for row in table_lines:
            cells = [cell.strip() for cell in row.strip("|").split("|")]
            if all(set(cell) <= {"-", ":", " "} for cell in cells):
                continue
            rows.append([clean_markdown(cell) for cell in cells])
        if rows:
            add_table(rows)
        continue
    if raw.startswith("> ") and "[СУРЕТ" in raw:
        placeholder = clean_markdown(raw[2:])
        add_table([[placeholder]], placeholder=True)
        index += 1
        continue
    if raw.startswith("```"):
        index += 1
        while index < len(lines) and not lines[index].strip().startswith("```"):
            add_paragraph(lines[index].strip(), size=22)
            index += 1
        index += 1
        continue
    if cover:
        alignment = "right" if raw.startswith(("**Орындаған", "**Қабылдаған")) else "center"
        text = clean_markdown(raw.lstrip("# "))
        add_paragraph(text, align=alignment, bold=raw.startswith("#"), size=34 if "ПРАКТИКАЛЫҚ" in text else 28)
    elif raw.startswith("## "):
        add_paragraph(raw[3:], "Heading1")
    elif raw.startswith("### "):
        add_paragraph(raw[4:], "Heading2")
    elif raw.startswith("# "):
        add_paragraph(raw[2:], "Heading1")
    elif raw.startswith("- "):
        add_paragraph("• " + clean_markdown(raw[2:]))
    else:
        add_paragraph(clean_markdown(raw))
    index += 1

sect = sub(body, "sectPr")
footer = sub(sect, "footerReference", {w("type"): "default"})
footer.set(f"{{{R}}}id", "rId2")
sub(sect, "pgSz", {w("w"): "11906", w("h"): "16838"})
sub(
    sect,
    "pgMar",
    {
        w("top"): "1134",
        w("right"): "1134",
        w("bottom"): "1134",
        w("left"): "1417",
        w("header"): "567",
        w("footer"): "567",
        w("gutter"): "0",
    },
)

styles = Element(w("styles"))


def add_style(style_id, name, size, bold=False, color="000000"):
    style = sub(styles, "style", {w("type"): "paragraph", w("styleId"): style_id})
    sub(style, "name", {w("val"): name})
    ppr = sub(style, "pPr")
    sub(ppr, "spacing", {w("after"): "180", w("line"): "360", w("lineRule"): "auto"})
    rpr = sub(style, "rPr")
    sub(rpr, "rFonts", {w("ascii"): "Times New Roman", w("hAnsi"): "Times New Roman"})
    sub(rpr, "sz", {w("val"): str(size)})
    sub(rpr, "color", {w("val"): color})
    if bold:
        sub(rpr, "b")


add_style("Normal", "Normal", 28)
add_style("Heading1", "heading 1", 32, True, "1F3A5F")
add_style("Heading2", "heading 2", 28, True, "315A7D")

footer_xml = (
    f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    f'<w:ftr xmlns:w="{W}"><w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
    '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
    '<w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>'
    '<w:r><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>'
).encode("utf-8")
document_rels = (
    f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>'
    '</Relationships>'
).encode("utf-8")
root_rels = b'<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
content_types = b'<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>'
output_rels = (
    f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>'
    '</Relationships>'
).encode("utf-8")

with ZipFile(OUTPUT, "w", ZIP_DEFLATED) as archive:
    archive.writestr("[Content_Types].xml", content_types)
    archive.writestr("_rels/.rels", root_rels)
    archive.writestr("word/document.xml", tostring(document, encoding="utf-8", xml_declaration=True))
    archive.writestr("word/styles.xml", tostring(styles, encoding="utf-8", xml_declaration=True))
    archive.writestr("word/_rels/document.xml.rels", output_rels)
    archive.writestr("word/footer1.xml", footer_xml)

with ZipFile(OUTPUT) as archive:
    if archive.testzip() is not None:
        raise RuntimeError("Generated DOCX archive is invalid")
print(f"Created {OUTPUT} ({OUTPUT.stat().st_size} bytes)")
