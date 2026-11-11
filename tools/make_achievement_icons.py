"""Makes the achievement (Memory Moment) icons: assets/achievements/<id>.png, plus locked.png.
A little instant-photo for each one: its category's color, and the memory's first letter.
Run from the project folder:  python3 tools/make_achievement_icons.py"""
import re, os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "achievements")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
S = 128

src = open(os.path.join(ROOT, "scripts", "achievements.gd")).read()
cats = dict(re.findall(r'^\t"(\w+)": "([^"]+)",', src[src.index("const CATEGORY"):src.index("}", src.index("const CATEGORY"))], re.M))
content = open(os.path.join(ROOT, "scripts", "content.gd")).read()
block = content[content.index("const MEMORIES"):content.index("\n}", content.index("const MEMORIES"))]
mems = re.findall(r'^\t"(\w+)": \["([^"]+)"', block, re.M)

COLORS = {  # sky, photo, letter
    "At Home": ("#E9B872", "#B5562F"),
    "Around Town": ("#8FC1C8", "#2E6B69"),
    "Holidays & Seasons": ("#D98FA0", "#8A2F4B"),
    "School": ("#B8C77A", "#56662A"),
}

def card(title_letter, sky, ink, locked=False):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([10, 6, S - 10, S - 4], 8, fill=(0, 0, 0, 70))            # shadow
    d.rounded_rectangle([8, 2, S - 12, S - 8], 8, fill="#F5EEDC")                  # the print
    d.rectangle([18, 12, S - 22, 88], fill="#8A8A8A" if locked else sky)           # the photo
    if not locked:
        d.ellipse([S - 52, 18, S - 30, 40], fill="#FFF3C4")                         # a sun
    f = ImageFont.truetype(FONT, 46)
    w = d.textlength(title_letter, font=f)
    d.text(((S - 4 - w) / 2, 26), title_letter, font=f, fill="#5A5A5A" if locked else ink)
    d.rectangle([22, 96, S - 26, 100], fill="#D8CFBA")                              # writing on it
    d.rectangle([22, 106, S - 50, 110], fill="#D8CFBA")
    return im

os.makedirs(OUT, exist_ok=True)
for mid, title in mems:
    cat = cats.get(mid, "Around Town")
    sky, ink = COLORS[cat]
    letter = title.replace("The ", "", 1)[0].upper()
    card(letter, sky, ink).save(os.path.join(OUT, mid + ".png"))
card("?", "", "", locked=True).save(os.path.join(OUT, "locked.png"))
print("icons:", len(mems) + 1)
