"""Builds a PDF from a project markdown document (headings, paragraphs, bullets, tables, code blocks).
    python scripts/build/uat_to_pdf.py docs/AutoDrive_UAT_GoLive.md docs/AutoDrive_UAT_GoLive.pdf
Add "doc" as a third argument for documents other than the UAT (no page break per role), or "wide" for a landscape page.
"""
import re
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import CondPageBreak, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

SRC, OUT = sys.argv[1], sys.argv[2]
UAT = len(sys.argv) < 4 or sys.argv[3] not in ('doc', 'wide')
PAGE = landscape(A4) if len(sys.argv) > 3 and sys.argv[3] == 'wide' else A4
base = getSampleStyleSheet()
body = ParagraphStyle('body', parent=base['Normal'], fontName='Helvetica', fontSize=9.5, leading=13, spaceAfter=4)
cell = ParagraphStyle('cell', parent=body, fontSize=8.5, leading=11, spaceAfter=0)
head = ParagraphStyle('head', parent=cell, fontName='Helvetica-Bold')
h1 = ParagraphStyle('h1', parent=base['Title'], fontSize=20, leading=24, spaceAfter=10)
h2 = ParagraphStyle('h2', parent=base['Heading1'], fontSize=14, leading=18, spaceBefore=6, spaceAfter=6, textColor=colors.HexColor('#1F3864'))
code = ParagraphStyle('code', parent=body, fontName='Courier', fontSize=8, leading=10, leftIndent=8)
h3 = ParagraphStyle('h3', parent=base['Heading2'], fontSize=12, leading=15, spaceBefore=8, spaceAfter=4)
h4 = ParagraphStyle('h4', parent=base['Heading3'], fontSize=11, leading=14, spaceBefore=8, spaceAfter=3)
WIDTH = PAGE[0] - 3 * cm


def inline(text):
    text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1', text)
    return text


def table(rows):
    cells = [[c.strip() for c in r.strip().strip('|').split('|')] for r in rows if not re.match(r'^\|[\s|:-]+\|$', r.strip())]
    n = len(cells[0])
    widths = {5: [0.06, 0.37, 0.33, 0.14, 0.10], 3: [0.12, 0.62, 0.26], 2: [0.4, 0.6], 4: [0.28, 0.28, 0.24, 0.20]}.get(n, [1 / n] * n)
    data = [[Paragraph(inline(c), head if i == 0 else cell) for c in row + [''] * (n - len(row))] for i, row in enumerate(cells)]
    t = Table(data, colWidths=[w * WIDTH for w in widths], repeatRows=1)
    t.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#A6A6A6')),
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#D9E2F3')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 4), ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]))
    return t


story = []
lines = open(SRC, encoding='utf8').read().split('\n')
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith('|'):
        block = []
        while i < len(lines) and lines[i].startswith('|'):
            block.append(lines[i]); i += 1
        story += [table(block), Spacer(1, 6)]
        continue
    if line.startswith('```'):
        i += 1
        while i < len(lines) and not lines[i].startswith('```'):
            story.append(Paragraph(inline(lines[i]) or '&nbsp;', code)); i += 1
        i += 1
        continue
    if line.strip() in ('---', '***'):
        story.append(Spacer(1, 8)); i += 1
        continue
    if line.startswith('# '):
        story.append(Paragraph(inline(line[2:]), h1))
    elif line.startswith('## '):
        title = line[3:]
        # each role's tests start on a new page
        if UAT and (re.match(r'\d+\. .+ – ', title) or title.endswith('Sign-off')):
            story.append(PageBreak())
        story.append(Paragraph(inline(title), h2))
    elif line.startswith('### '):
        story += [CondPageBreak(4 * cm), Paragraph(inline(line[4:]), h3)]
    elif line.startswith('#### '):
        story += [CondPageBreak(4 * cm), Paragraph(inline(line.lstrip('#').strip()), h4)]
    elif re.match(r'^\s*[-*] ', line):
        story.append(Paragraph(inline(re.sub(r'^\s*[-*] ', '', line)), body, bulletText='•'))
    elif re.match(r'^\s*\d+\. ', line):
        num = re.match(r'^\s*(\d+)\. ', line).group(1)
        story.append(Paragraph(inline(re.sub(r'^\s*\d+\. ', '', line)), body, bulletText=num + '.'))
    elif line.strip():
        story.append(Paragraph(inline(line), body))
    i += 1


def footer(canvas, doc):
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(colors.grey)
    canvas.drawString(1.5 * cm, 1 * cm, TITLE)
    canvas.drawRightString(PAGE[0] - 1.5 * cm, 1 * cm, f'Page {doc.page}')


TITLE = next((l[2:].strip() for l in lines if l.startswith('# ')), 'AutoDrive Motors')
SimpleDocTemplate(OUT, pagesize=PAGE, leftMargin=1.5 * cm, rightMargin=1.5 * cm, topMargin=1.5 * cm, bottomMargin=1.8 * cm,
                  title=TITLE).build(story, onFirstPage=footer, onLaterPages=footer)
print('ok')
