"""สร้างไอคอนโปรแกรมงานเงินเดือน: ปฏิทิน (วันที่ 25 วันเงินเดือนออก) + เหรียญบาท
ผู้ใช้เลือกแบบนี้จากตัวเลือก 4 แบบ (tool/icon_options.py) เมื่อ 2 ต.ค. 2569

ใช้ภาพเดียวกันทุกที่:
  web/favicon.png, web/icons/Icon-*.png   ไอคอนแท็บเบราว์เซอร์และตอนติดตั้งเป็นแอป
  assets/images/app_logo.png              โลโก้ในแถบหัวและเมนูข้าง (AppLogo)

รันซ้ำได้: python tool/make_icons.py  (ต้องมี Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
KANIT = str(ROOT / 'assets' / 'fonts' / 'Kanit-Bold.ttf')
SARABUN = str(ROOT / 'assets' / 'fonts' / 'Sarabun-Bold.ttf')
S = 1024  # วาดใหญ่แล้วย่อ ขอบจะเนียน

TEAL_DARK = (15, 118, 110)
TEAL_LIGHT = (20, 184, 166)
AMBER = (245, 158, 11)
NAVY = (15, 23, 42)
GREEN = (22, 163, 74)
WHITE = (255, 255, 255)


def gradient(size):
    """พื้นไล่สีแนวทแยงจากซ้ายบนไปขวาล่าง"""
    g = Image.new('RGB', (size, size))
    px = g.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TEAL_DARK, TEAL_LIGHT))
    return g


def draw_content(img, scale=1.0):
    """วาดปฏิทิน + เหรียญบาท ลงบน img ขนาด S ย่อ/ขยายรอบจุดกลางตาม scale"""
    d = ImageDraw.Draw(img)
    c = S / 2

    def p(v):  # พิกัดสัดส่วน (0-1) เป็นพิกเซล ย่อรอบจุดกลาง
        return c + (v * S - c) * scale

    def box(x0, y0, x1, y1):
        return [p(x0), p(y0), p(x1), p(y1)]

    k = S * scale  # ใช้กับรัศมี/ขนาดฟอนต์

    # ตัวปฏิทิน + แถบหัวสีอำพัน
    x0, y0, x1, y1 = 0.20, 0.22, 0.74, 0.78
    d.rounded_rectangle(box(x0, y0, x1, y1), radius=0.05 * k, fill=WHITE)
    d.rounded_rectangle(box(x0, y0, x1, y0 + 0.13), radius=0.05 * k, fill=AMBER)
    d.rectangle(box(x0, y0 + 0.08, x1, y0 + 0.13), fill=AMBER)
    # ห่วงปฏิทิน
    for hx in (0.33, 0.61):
        d.rounded_rectangle(box(hx - 0.016, 0.16, hx + 0.016, 0.28), radius=0.016 * k, fill=NAVY)
    # วันที่ 25
    d.text((p((x0 + x1) / 2), p(y0 + 0.30)), '25', font=ImageFont.truetype(KANIT, round(0.20 * k)),
           fill=TEAL_DARK, anchor='mm')
    # เหรียญบาท มุมขวาล่าง ขอบขาว
    cx, cy, r, ring = 0.72, 0.72, 0.16, 0.02
    d.ellipse(box(cx - r - ring, cy - r - ring, cx + r + ring, cy + r + ring), fill=WHITE)
    d.ellipse(box(cx - r, cy - r, cx + r, cy + r), fill=GREEN)
    d.text((p(cx), p(cy) + 0.004 * k), 'บาท', font=ImageFont.truetype(SARABUN, round(r * 0.62 * k)),
           fill=WHITE, anchor='mm')


def rounded_icon():
    """ไอคอนมุมมน พื้นหลังโปร่งใส"""
    bg = gradient(S)
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=round(0.24 * S), fill=255)
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    img.paste(bg, (0, 0), mask)
    draw_content(img)
    return img


def maskable_icon():
    """ไอคอน maskable: พื้นเต็มกรอบ เนื้อหาอยู่ในวงกลมปลอดภัย 80% ตรงกลาง"""
    img = gradient(S).convert('RGBA')
    draw_content(img, scale=0.78)
    return img


def save(img, size, rel):
    out = ROOT / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(out, optimize=True)
    print(f'{rel}: {size}x{size}')


if __name__ == '__main__':
    r = rounded_icon()
    m = maskable_icon()
    save(r, 32, 'web/favicon.png')
    save(r, 192, 'web/icons/Icon-192.png')
    save(r, 512, 'web/icons/Icon-512.png')
    save(m, 192, 'web/icons/Icon-maskable-192.png')
    save(m, 512, 'web/icons/Icon-maskable-512.png')
    # โลโก้ในแอป แสดงที่ 34-42 จุด เผื่อจอความละเอียดสูง 3 เท่า
    save(r, 160, 'assets/images/app_logo.png')
