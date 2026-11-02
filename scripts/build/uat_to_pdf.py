"""Builds a UAT PDF from the UAT markdown (headings, paragraphs, bullets, tables).
    python scripts/build/uat_to_pdf.py docs/AutoDrive_UAT_GoLive.md docs/AutoDrive_UAT_GoLive.pdf
"""
import re
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import CondPageBreak, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

SRC, OUT = sys.argv[1], sys.argv[2]
base = getSampleStyleSheet()
body = ParagraphStyle('body', parent=base['Normal'], fontName='Helvetica', fontSize=9.5, leading=13, spaceAfter=4)
cell = ParagraphStyle('cell', parent=body, fontSize=8.5, leading=11, spaceAfter=0)
head = ParagraphStyle('head', parent=cell, fontName='Helvetica-Bold')
h1 = ParagraphStyle('h1', parent=base['Title'], fontSize=20, leading=24, spaceAfter=10)
h2 = ParagraphStyle('h2', parent=base['Heading1'], fontSize=14, leading=18, spaceBefore=6, spaceAfter=6, textColor=colors.HexColor('#1F3864'))
h4 = ParagraphStyle('h4', parent=base['Heading3'], fontSize=11, leading=14, spaceBefore=8, spaceAfter=3)
WIDTH = A4[0] - 3 * cm


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
    if line.startswith('# '):
        story.append(Paragraph(inline(line[2:]), h1))
    elif line.startswith('## '):
        title = line[3:]
        # each role's tests start on a new page
        if re.match(r'\d+\. .+ – ', title) or title.endswith('Sign-off'):
            story.append(PageBreak())
        story.append(Paragraph(inline(title), h2))
    elif line.startswith('#### ') or line.startswith('### '):
        story += [CondPageBreak(4 * cm), Paragraph(inline(line.lstrip('#').strip()), h4)]
    elif line.startswith('- '):
        story.append(Paragraph(inline(line[2:]), body, bulletText='•'))
    elif line.strip():
        story.append(Paragraph(inline(line), body))
    i += 1


def footer(canvas, doc):
    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(colors.grey)
    canvas.drawString(1.5 * cm, 1 * cm, 'AutoDrive Motors – User Acceptance Testing')
    canvas.drawRightString(A4[0] - 1.5 * cm, 1 * cm, f'Page {doc.page}')


SimpleDocTemplate(OUT, pagesize=A4, leftMargin=1.5 * cm, rightMargin=1.5 * cm, topMargin=1.5 * cm, bottomMargin=1.8 * cm,
                  title='AutoDrive Motors – User Acceptance Testing').build(story, onFirstPage=footer, onLaterPages=footer)
print('ok')
