"""Membangun aset UI game dari pack "Tiny RPG - Mana Soul GUI" (tiopalada, CC0).

Menjalankan skrip ini (python3, butuh Pillow + numpy):
  1. memotong sprite pack dan memperbesarnya 2x (nearest) ke Assets/ui/mana_soul/
  2. membuat ornamen, panah, ikon deck/discard, dan kursor di Assets/ui/
  3. menulis Assets/ui/theme/game_theme.tres (Theme global game)

Kalau pack diganti, ubah konfigurasi MARGIN/palet di bawah lalu jalankan ulang:
    python3 SourceArt/ui_builder/build_ui_from_mana_soul.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "Assets" / "tinyRPG_manaSoulGUI_v_1_0"
OUT = ROOT / "Assets" / "ui"
OUT_PACK = OUT / "mana_soul"
OUT_THEME = OUT / "theme"
for d in (OUT, OUT_PACK, OUT_THEME):
    d.mkdir(parents=True, exist_ok=True)

S = 2  # skala piksel UI (semua sprite pack dibesarkan 2x)


def sheet(name: str) -> Image.Image:
    return Image.open(PACK / f"20250{name}.png").convert("RGBA")


def bbox_crop(im: Image.Image) -> Image.Image:
    a = np.array(im)
    ys, xs = np.nonzero(a[..., 3] > 0)
    return im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def up(im: Image.Image, k: int = S) -> Image.Image:
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


# ------------------------------------------------------------------ sprite
# Panel 9-slice: margin (kiri, atas, kanan, bawah) dalam piksel ASLI pack (1x).
PANELS = {
    "panel_a": ("420manaSoul9SlicesA-Sheet", (20, 18, 20, 18)),  # navy + emas  -> dialog/pilihan
    "panel_b": ("420manaSoul9SlicesB-Sheet", (14, 14, 14, 14)),  # ungu         -> panel HUD
    "panel_c": ("420manaSoul9SlicesC-Sheet", (14, 14, 14, 14)),  # ungu + emas  -> modal (pause, game over)
}
# Tombol 3-slice: margin cap kiri/kanan (1x). Sheet = 4 state x 96 px.
BUTTONS = {
    "button_a": ("421manaSoulButtonA-Sheet", 22),  # sayap emas, biru     -> menu utama
    "button_b": ("421manaSoulButtonB-Sheet", 20),  # ungu + ornamen emas  -> tombol default
}
STATES = ["normal", "hover", "pressed", "disabled"]

meta = {}
for name, (fn, m) in PANELS.items():
    img = up(bbox_crop(sheet(fn)))
    img.save(OUT_PACK / f"{name}.png")
    meta[name] = dict(size=img.size, margin=tuple(v * S for v in m))

for name, (fn, cap) in BUTTONS.items():
    sh = sheet(fn)
    for i, st in enumerate(STATES):
        cell = sh.crop((i * 96, 0, i * 96 + 96, sh.height))
        up(cell).save(OUT_PACK / f"{name}_{st}.png")
    meta[name] = dict(size=(96 * S, sh.height * S), cap=cap * S)

up(bbox_crop(sheet("420manaSoulHeaderB-Sheet"))).save(OUT_PACK / "header_b.png")
meta["header_b"] = dict(size=(96 * S, 22 * S), cap=30 * S)
up(sheet("421barC-Sheet")).save(OUT_PACK / "bar_c.png")
meta["bar_c"] = dict(size=(95 * S, 15 * S), margin=(6 * S, 3 * S, 6 * S, 4 * S))

# panah bawah (penanda "lanjut" dialog): state pertama
up(sheet("425downArrow-Sheet").crop((0, 0, 14, 21))).save(OUT / "arrow_down.png")

# ornamen pembatas: potongan "ukiran - mahkota - ukiran" dari cursorTarget
div = bbox_crop(sheet("421cursorTarget-Sheet").crop((190, 0, 251, 12)))
up(div).save(OUT / "divider.png")

# kursor mouse (bulu): state 0 = biasa, state 1 = hover. Ukuran asli 1x supaya tajam.
mouse = sheet("422mouseBig-Sheet")
cells = [(0, 22), (23, 45), (46, 67), (71, 92)]
bbox_crop(mouse.crop((cells[0][0], 0, cells[0][1], 23))).save(OUT / "cursor_arrow.png")
bbox_crop(mouse.crop((cells[1][0], 0, cells[1][1], 23))).save(OUT / "cursor_hand.png")


# ------------------------------------------------------------------ ikon deck / discard
def draw_icon(path: Path, deck: bool) -> None:
    """Ikon tumpukan kartu pixel-art (1x) dengan palet pack, lalu diperbesar 2x."""
    navy = (17, 19, 67, 255); gold = (249, 212, 47, 255); orange = (242, 118, 70, 255)
    mid = (66, 31, 89, 255); lav = (150, 140, 200, 255)
    body, edge = (mid, gold) if deck else ((50, 48, 90, 255), lav)
    im = Image.new("RGBA", (13, 15), (0, 0, 0, 0))
    px = im.load()

    def card(ox: int, oy: int, fill, border) -> None:
        for y in range(11):
            for x in range(8):
                on_edge = x in (0, 7) or y in (0, 10)
                px[ox + x, oy + y] = border if on_edge else fill
        for (x, y) in ((0, 0), (7, 0), (0, 10), (7, 10)):
            px[ox + x, oy + y] = navy

    for k in (2, 1, 0):  # tumpuk dari belakang ke depan
        card(k * 2, 4 - k * 2, body, navy if k else edge)
    for y in range(4, 8):  # hiasan kecil di kartu depan
        px[3 + (y % 2), y + 2] = orange if deck else lav
    if not deck:  # tanda panah turun kecil
        for i in range(3):
            px[8 + i, 12 + i // 2] = lav
    up(im).save(path)


draw_icon(OUT / "icon_deck.png", True)
draw_icon(OUT / "icon_discard.png", False)

# ------------------------------------------------------------------ theme .tres
FONT_BODY = "res://Assets/fonts/pixel_overload/Baskic8.otf"
FONT_TITLE = "res://Assets/fonts/pixel_overload/Essentle4.otf"

CREAM = (255, 238, 204); WHITE = (255, 255, 255); GOLD = (249, 212, 47)
NAVY = (17, 19, 67); SHADOW = (76, 70, 130); LAV = (190, 176, 224); GREY = (150, 140, 190)

ext, sub, lines = [], [], []
_ids = {}


def col(c, a=1.0):
    return "Color(%.4f, %.4f, %.4f, %.3f)" % (c[0] / 255, c[1] / 255, c[2] / 255, a)


def ext_res(kind: str, path: str) -> str:
    key = (kind, path)
    if key not in _ids:
        _ids[key] = "%d_%s" % (len(_ids) + 1, Path(path).stem.lower().replace("-", "_")[:18])
        ext.append(f'[ext_resource type="{kind}" path="{path}" id="{_ids[key]}"]')
    return _ids[key]


def tex_sb(sid, png, tm, cm, axis=2):
    t = ext_res("Texture2D", f"res://Assets/ui/mana_soul/{png}")
    sub.append(
        f'[sub_resource type="StyleBoxTexture" id="{sid}"]\n'
        f"content_margin_left = {cm[0]}\ncontent_margin_top = {cm[1]}\ncontent_margin_right = {cm[2]}\ncontent_margin_bottom = {cm[3]}\n"
        f'texture = ExtResource("{t}")\n'
        f"texture_margin_left = {tm[0]}\ntexture_margin_top = {tm[1]}\ntexture_margin_right = {tm[2]}\ntexture_margin_bottom = {tm[3]}\n"
        f"axis_stretch_horizontal = {axis}\naxis_stretch_vertical = {axis}\n"
    )
    return sid


def flat_sb(sid, bg, bg_a=1.0, border=None, bw=(0, 0, 0, 0), cm=(8, 4, 8, 4)):
    s = f'[sub_resource type="StyleBoxFlat" id="{sid}"]\n'
    s += f"content_margin_left = {cm[0]}\ncontent_margin_top = {cm[1]}\ncontent_margin_right = {cm[2]}\ncontent_margin_bottom = {cm[3]}\n"
    s += f"bg_color = {col(bg, bg_a)}\n"
    if border is not None:
        s += f"border_width_left = {bw[0]}\nborder_width_top = {bw[1]}\nborder_width_right = {bw[2]}\nborder_width_bottom = {bw[3]}\n"
        s += f"border_color = {col(border[0], border[1])}\n"
    s += "anti_aliasing = false\n"
    sub.append(s)
    return sid


def prop(path, value):
    lines.append(f"{path} = {value}")


# --- gaya tekstur
pa, pb, pc = meta["panel_a"]["margin"], meta["panel_b"]["margin"], meta["panel_c"]["margin"]
tex_sb("SB_panel_dialog", "panel_a.png", pa, (56, 36, 56, 30))
tex_sb("SB_panel_hud", "panel_b.png", pb, (24, 16, 24, 16))
tex_sb("SB_panel_modal", "panel_c.png", pc, (36, 26, 36, 26))
tm = meta["bar_c"]["margin"]
tex_sb("SB_bar_frame", "bar_c.png", tm, (tm[0], tm[1], tm[2], tm[3]))
hc = meta["header_b"]["cap"]
tex_sb("SB_nametag", "header_b.png", (hc, 8, hc, 8), (hc + 6, 10, hc + 6, 10))

btn_sb = {}
for key, (cm_x, cm_y) in {"button_b": (36, 10), "button_a": (52, 10)}.items():
    cap = meta[key]["cap"]
    for st in STATES:
        btn_sb[(key, st)] = tex_sb(f"SB_{key}_{st}", f"{key}_{st}.png", (cap, 16, cap, 16), (cm_x, cm_y, cm_x, cm_y))

# --- gaya flat
flat_sb("SB_inset", (8, 8, 40), 0.72, (SHADOW, 1.0), (2, 2, 2, 2), (14, 10, 14, 10))
flat_sb("SB_inset_label", (8, 8, 40), 0.70, (SHADOW, 1.0), (2, 2, 2, 2), (12, 8, 12, 8))
flat_sb("SB_prompt", NAVY, 0.88, (GOLD, 1.0), (2, 2, 2, 2), (10, 4, 10, 4))
flat_sb("SB_chip_cyan", (20, 44, 84), 0.96, ((96, 200, 235), 1.0), (2, 2, 2, 2), (10, 4, 10, 4))
flat_sb("SB_chip_violet", (50, 24, 92), 0.96, ((176, 120, 235), 1.0), (2, 2, 2, 2), (10, 4, 10, 4))
flat_sb("SB_bar_bg", (8, 8, 34), 1.0, None)
flat_sb("SB_fill_player", (92, 204, 84), 1.0, ((176, 240, 140), 1.0), (0, 4, 0, 0), (0, 0, 0, 0))
flat_sb("SB_fill_enemy", (226, 66, 108), 1.0, ((255, 160, 180), 1.0), (0, 4, 0, 0), (0, 0, 0, 0))
sub.append('[sub_resource type="StyleBoxLine" id="SB_hsep"]\ncolor = %s\nthickness = 2\n' % col(GOLD, 0.5))

# --- default
prop("default_font", f'ExtResource("{ext_res("FontFile", FONT_BODY)}")')
prop("default_font_size", 16)

# Label
prop("Label/colors/font_color", col(CREAM))
prop("Label/colors/font_shadow_color", col(NAVY, 0.75))
prop("Label/constants/shadow_offset_x", 0)
prop("Label/constants/shadow_offset_y", 2)


def button_set(type_name, key, base=None):
    if base:
        prop(f"{type_name}/base_type", f'&"{base}"')
    for st in STATES:
        prop(f"{type_name}/styles/{st}", f'SubResource("{btn_sb[(key, st)]}")')
    prop(f"{type_name}/styles/focus", f'SubResource("{btn_sb[(key, "hover")]}")')
    prop(f"{type_name}/styles/hover_pressed", f'SubResource("{btn_sb[(key, "pressed")]}")')
    prop(f"{type_name}/colors/font_color", col(CREAM))
    prop(f"{type_name}/colors/font_hover_color", col(WHITE))
    prop(f"{type_name}/colors/font_focus_color", col(WHITE))
    prop(f"{type_name}/colors/font_pressed_color", col(GOLD))
    prop(f"{type_name}/colors/font_hover_pressed_color", col(GOLD))
    prop(f"{type_name}/colors/font_disabled_color", col(GREY))
    prop(f"{type_name}/colors/font_outline_color", col(NAVY))
    prop(f"{type_name}/constants/outline_size", 4)
    prop(f"{type_name}/font_sizes/font_size", 24)


button_set("Button", "button_b")
button_set("WingButton", "button_a", "Button")     # menu utama
button_set("ChoiceButton", "button_b", "Button")   # opsi pilihan (hover biru terang = jelas terpilih)

# Panel
prop("PanelContainer/styles/panel", 'SubResource("SB_panel_modal")')
prop("Panel/styles/panel", 'SubResource("SB_panel_modal")')
for name, sb in (("DialoguePanel", "SB_panel_dialog"), ("HudPanel", "SB_panel_hud"),
                 ("InsetPanel", "SB_inset"), ("BarFrame", "SB_bar_frame")):
    prop(f"{name}/base_type", '&"PanelContainer"')
    prop(f"{name}/styles/panel", f'SubResource("{sb}")')

# Bar HP
prop("ProgressBar/styles/background", 'SubResource("SB_bar_bg")')
prop("ProgressBar/styles/fill", 'SubResource("SB_fill_player")')
prop("HPBarEnemy/base_type", '&"ProgressBar"')
prop("HPBarEnemy/styles/background", 'SubResource("SB_bar_bg")')
prop("HPBarEnemy/styles/fill", 'SubResource("SB_fill_enemy")')

# Variasi Label
title_font = f'ExtResource("{ext_res("FontFile", FONT_TITLE)}")'


def label_var(name, size, color, font=None, outline=0, outline_col=NAVY, style=None, shadow=True):
    prop(f"{name}/base_type", '&"Label"')
    if font:
        prop(f"{name}/fonts/font", font)
    prop(f"{name}/font_sizes/font_size", size)
    prop(f"{name}/colors/font_color", col(color))
    if outline:
        prop(f"{name}/colors/font_outline_color", col(outline_col))
        prop(f"{name}/constants/outline_size", outline)
    if style:
        prop(f"{name}/styles/normal", f'SubResource("{style}")')
    if not shadow:
        prop(f"{name}/colors/font_shadow_color", col(NAVY, 0.0))


label_var("TitleLabel", 48, GOLD, title_font, 8)
label_var("ChapterTitle", 72, GOLD, title_font, 10)
label_var("ChapterSubtitle", 32, CREAM, None, 6)
label_var("Heading", 24, GOLD, title_font, 4)
label_var("Hint", 16, LAV)
label_var("DialogueText", 24, CREAM)
label_var("NameTag", 24, CREAM, None, 4, NAVY, "SB_nametag", shadow=False)
label_var("PromptTag", 16, CREAM, None, 0, NAVY, "SB_prompt", shadow=False)
label_var("HpText", 16, WHITE, None, 4)
label_var("InsetLabel", 16, (230, 225, 255), None, 0, NAVY, "SB_inset_label", shadow=False)
label_var("ChipCyan", 16, (200, 240, 255), None, 0, NAVY, "SB_chip_cyan", shadow=False)
label_var("ChipViolet", 16, (232, 208, 255), None, 0, NAVY, "SB_chip_violet", shadow=False)

# Lain-lain
prop("HSeparator/styles/separator", 'SubResource("SB_hsep")')
prop("HSeparator/constants/separation", 14)
prop("RichTextLabel/colors/default_color", col(CREAM))
prop("RichTextLabel/font_sizes/normal_font_size", 16)
prop("RichTextLabel/font_sizes/bold_font_size", 16)

steps = len(ext) + len(sub) + 1
tres = (f'[gd_resource type="Theme" load_steps={steps} format=3]\n\n' + "\n".join(ext) + "\n\n"
        + "\n".join(sub) + "\n[resource]\n" + "\n".join(lines) + "\n")
(OUT_THEME / "game_theme.tres").write_text(tres, encoding="utf-8")

print("Selesai.", len(list(OUT_PACK.glob('*.png'))), "PNG di mana_soul/ +", len(lines), "properti theme")
