"""วาดตัวเลือกไอคอนระบบงานเงินเดือน 4 แบบ ลงภาพเดียวให้ผู้ใช้เลือก (ไม่ได้ใช้ในแอป)"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
KANIT = str(ROOT / 'assets' / 'fonts' / 'Kanit-Bold.ttf')
SARABUN = str(ROOT / 'assets' / 'fonts' / 'Sarabun-Bold.ttf')
S = 512

TEAL_DARK, TEAL_LIGHT = (15, 118, 110), (20, 184, 166)
AMBER, AMBER_DARK = (245, 158, 11), (180, 83, 9)
NAVY = (15, 23, 42)
MINT = (204, 251, 241)
GREY = (203, 213, 225)
GREEN = (22, 163, 74)
GREEN_LIGHT = (220, 252, 231)
WHITE = (255, 255, 255)


def base():
    g = Image.new('RGB', (S, S))
    px = g.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * (S - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TEAL_DARK, TEAL_LIGHT))
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(0.24 * S), fill=255)
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    img.paste(g, (0, 0), mask)
    return img


def f(path, size):
    return ImageFont.truetype(path, int(size))


def banknote(d, x0, y0, x1, y1, label=True):
    """ธนบัตรสีเขียว มีวงกลมกลางและเลข 1000"""
    r = (y1 - y0) * 0.14
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=GREEN_LIGHT, outline=GREEN, width=int(S * 0.018))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rr = (y1 - y0) * 0.26
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=GREEN, width=int(S * 0.016))
    if label:
        d.text((cx, cy), 'บาท', font=f(SARABUN, rr * 0.9), fill=GREEN, anchor='mm')


# 1) ซองเงินเดือน: ซองสีขาวมีธนบัตรโผล่
def opt_envelope():
    img = base()
    d = ImageDraw.Draw(img)
    banknote(d, S * 0.24, S * 0.18, S * 0.76, S * 0.52, label=False)
    # ตัวซอง
    d.rounded_rectangle([S * 0.17, S * 0.38, S * 0.83, S * 0.80], radius=S * 0.05, fill=WHITE)
    d.polygon([(S * 0.17, S * 0.40), (S * 0.50, S * 0.62), (S * 0.83, S * 0.40)], fill=(241, 245, 249))
    d.line([(S * 0.17, S * 0.40), (S * 0.50, S * 0.62), (S * 0.83, S * 0.40)], fill=GREY, width=int(S * 0.012))
    d.text((S * 0.50, S * 0.71), 'เงินเดือน', font=f(KANIT, S * 0.085), fill=TEAL_DARK, anchor='mm')
    return img


# 2) ธนบัตร + บุคลากร
def opt_note_person():
    img = base()
    d = ImageDraw.Draw(img)
    banknote(d, S * 0.14, S * 0.30, S * 0.76, S * 0.66)
    # ป้ายคน มุมขวาล่าง
    cx, cy, r = S * 0.70, S * 0.70, S * 0.17
    d.ellipse([cx - r - 10, cy - r - 10, cx + r + 10, cy + r + 10], fill=WHITE)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=AMBER)
    d.ellipse([cx - r * 0.32, cy - r * 0.62, cx + r * 0.32, cy + r * 0.02], fill=WHITE)
    d.pieslice([cx - r * 0.62, cy + r * 0.12, cx + r * 0.62, cy + r * 1.2], 180, 360, fill=WHITE)
    return img


# 3) ปฏิทิน + เงิน (จ่ายรายเดือน)
def opt_calendar():
    img = base()
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = S * 0.20, S * 0.22, S * 0.74, S * 0.78
    d.rounded_rectangle([x0, y0, x1, y1], radius=S * 0.05, fill=WHITE)
    d.rounded_rectangle([x0, y0, x1, y0 + S * 0.13], radius=S * 0.05, fill=AMBER)
    d.rectangle([x0, y0 + S * 0.08, x1, y0 + S * 0.13], fill=AMBER)
    for hx in (0.33, 0.61):
        d.rounded_rectangle([S * hx - 8, S * 0.16, S * hx + 8, S * 0.28], radius=8, fill=NAVY)
    d.text(((x0 + x1) / 2, y0 + S * 0.30), '25', font=f(KANIT, S * 0.20), fill=TEAL_DARK, anchor='mm')
    # เหรียญเงิน มุมขวาล่าง
    cx, cy, r = S * 0.72, S * 0.72, S * 0.16
    d.ellipse([cx - r - 10, cy - r - 10, cx + r + 10, cy + r + 10], fill=WHITE)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
    d.text((cx, cy + 2), 'บาท', font=f(SARABUN, r * 0.62), fill=WHITE, anchor='mm')
    return img


# 4) สลิปเงินเดือน + ป้าย "บาท" (แบบปัจจุบัน แต่เลิกใช้สัญลักษณ์ ฿ ที่คล้าย Bitcoin)
def opt_slip_baht():
    img = base()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([S * 0.25, S * 0.16, S * 0.71, S * 0.80], radius=S * 0.06, fill=WHITE)
    d.text((S * 0.48, S * 0.27), 'สลิป', font=f(KANIT, S * 0.08), fill=TEAL_DARK, anchor='mm')
    for i, w in enumerate((0.20, 0.16, 0.22)):
        y = S * (0.38 + i * 0.085)
        d.rounded_rectangle([S * 0.31, y, S * (0.31 + w), y + S * 0.035], radius=8, fill=GREY)
        d.rounded_rectangle([S * 0.57, y, S * 0.65, y + S * 0.035], radius=8, fill=MINT)
    x0, y0, x1, y1 = S * 0.46, S * 0.64, S * 0.90, S * 0.86
    d.rounded_rectangle([x0 - 8, y0 - 8, x1 + 8, y1 + 8], radius=S * 0.06, fill=WHITE)
    d.rounded_rectangle([x0, y0, x1, y1], radius=S * 0.05, fill=AMBER)
    d.text(((x0 + x1) / 2, (y0 + y1) / 2 + 2), 'บาท', font=f(KANIT, S * 0.10), fill=NAVY, anchor='mm')
    return img


if __name__ == '__main__':
    opts = [('1 ซองเงินเดือน', opt_envelope()), ('2 ธนบัตร + บุคลากร', opt_note_person()),
            ('3 ปฏิทิน + เงิน (จ่ายรายเดือน)', opt_calendar()), ('4 สลิป + บาท', opt_slip_baht())]
    tile, pad, cap = 300, 40, 70
    sheet = Image.new('RGB', (len(opts) * (tile + pad) + pad, tile + pad * 2 + cap), (241, 245, 249))
    d = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(opts):
        x = pad + i * (tile + pad)
        sheet.paste(im.resize((tile, tile), Image.LANCZOS), (x, pad), im.resize((tile, tile), Image.LANCZOS))
        small = im.resize((48, 48), Image.LANCZOS)
        sheet.paste(small, (x, pad + tile + 14), small)
        d.text((x + 60, pad + tile + 38), name, font=f(SARABUN, 26), fill=NAVY, anchor='lm')
    out = ROOT / 'build' / 'icon_options.png'
    out.parent.mkdir(exist_ok=True)
    sheet.save(out)
    print(out)
