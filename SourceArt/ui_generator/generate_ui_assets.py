"""Generator aset UI "Cosmic Gilded" untuk The Legends of Interstellar.

Jalankan dari root proyek:
    python3 SourceArt/ui_generator/generate_ui_assets.py

Menulis PNG ke Assets/ui/ (pixel-art, di-upscale 3x supaya selaras dengan font Baskic8 24px)
dan Theme Godot ke Assets/ui/theme/game_theme.tres.
Ingin pakai pack dari itch.io? Lihat Assets/ui/README.md.
"""
from PIL import Image
import os

S = 3  # 1 "piksel logis" = 3 piksel layar
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "Assets", "ui")
os.makedirs(os.path.join(OUT, "theme"), exist_ok=True)


def hx(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


INK = hx("05061a")
NAVY9 = hx("07081c")
NAVY8 = hx("0e1030")
GOLD3 = hx("ffe9a8")
GOLD4 = hx("ffd166")
GOLD5 = hx("e0a63a")
GOLD6 = hx("a8741f")
GOLD7 = hx("6e4a14")
CLEAR = (0, 0, 0, 0)


def save(im, name):
    im = im.resize((im.width * S, im.height * S), Image.NEAREST)
    im.save(os.path.join(OUT, name))
    return im.size


def frame(w, h, rings, fill, corner_clear=True):
    """rings: warna per jarak-dari-tepi (d=0,1,2,...). Setelah rings habis = fill."""
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if corner_clear and x in (0, w - 1) and y in (0, h - 1):
                continue
            d = min(x, y, w - 1 - x, h - 1 - y)
            px[x, y] = rings[d] if d < len(rings) else fill
    return im


# ------------------------------------------------------------------ panel utama
def make_panel():
    w = h = 16
    im = frame(w, h, [INK, GOLD4, GOLD7, hx("262a66")], NAVY8)
    px = im.load()
    for cx, sx in ((0, 1), (w - 1, -1)):
        for cy, sy in ((0, 1), (h - 1, -1)):
            px[cx + 2 * sx, cy + 2 * sy] = GOLD3
            px[cx + 3 * sx, cy + 2 * sy] = GOLD4
            px[cx + 2 * sx, cy + 3 * sy] = GOLD4
    save(im, "panel.png")


def make_inset():
    im = frame(12, 12, [INK, hx("2a2e70")], NAVY9)
    save(im, "panel_inset.png")


# ------------------------------------------------------------------ tombol
def make_button(name, border, fill, hi, shade):
    w = h = 16
    im = frame(w, h, [INK, border], fill)
    px = im.load()
    for x in range(2, w - 2):
        px[x, 2] = hi
        px[x, h - 3] = shade
    save(im, name)


def make_buttons():
    make_button("button_normal.png", GOLD6, hx("1d2150"), hx("3b3f93"), hx("12143a"))
    make_button("button_hover.png", GOLD4, hx("2a3080"), hx("6a70d8"), hx("1a1e56"))
    make_button("button_pressed.png", GOLD3, hx("10122f"), hx("0a0b22"), hx("3b3f93"))
    make_button("button_disabled.png", hx("3a3d5e"), hx("14162c"), hx("14162c"), hx("14162c"))
    # cincin fokus (hanya garis tepi)
    im = Image.new("RGBA", (16, 16), CLEAR)
    px = im.load()
    for y in range(16):
        for x in range(16):
            if x in (0, 15) and y in (0, 15):
                continue
            if min(x, y, 15 - x, 15 - y) == 0:
                px[x, y] = GOLD3
    save(im, "button_focus.png")


# ------------------------------------------------------------------ bar HP
def make_bars():
    save(frame(8, 8, [INK, GOLD6], NAVY9), "bar_frame.png")

    def fill(name, rows):
        im = Image.new("RGBA", (4, 6), CLEAR)
        px = im.load()
        for y, c in enumerate(rows):
            for x in range(4):
                px[x, y] = hx(c)
        save(im, name)

    fill("bar_fill_player.png", ["b6ffc4", "6fe88a", "3fc463", "3fc463", "2a9448", "1b6a31"])
    fill("bar_fill_enemy.png", ["ffb3b9", "ff7a85", "e8404f", "e8404f", "b02a3a", "741a28"])


# ------------------------------------------------------------------ chip & nameplate
def make_chips():
    for name, border, fill in [
        ("navy", "2a2e70", "10122f"),
        ("cyan", "6fd6ff", "0e2a4a"),
        ("violet", "a98bff", "231550"),
        ("gold", "ffd166", "3a2a0e"),
    ]:
        save(frame(8, 8, [INK, hx(border)], hx(fill)), f"chip_{name}.png")


def make_nameplate():
    w, h = 16, 12
    im = frame(w, h, [INK, GOLD3], GOLD4)
    px = im.load()
    for x in range(2, w - 2):
        px[x, h - 3] = GOLD5
    # ornamen ujung
    for y in (h // 2 - 1, h // 2):
        px[1, y] = GOLD6
        px[w - 2, y] = GOLD6
    save(im, "nameplate.png")


# ------------------------------------------------------------------ ikon & ornamen
def ascii_icon(name, rows, pal):
    h, w = len(rows), len(rows[0])
    assert all(len(r) == w for r in rows), (name, [len(r) for r in rows])
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c != ".":
                px[x, y] = pal[c]
    save(im, name)


def make_icons():
    ascii_icon("icon_heart.png", [
        ".ooo.ooo.",
        "ohhrorrro",
        "ohrrrrrdo",
        "orrrrrrdo",
        ".orrrrdo.",
        "..orrdo..",
        "...odo...",
        "....o....",
    ], {"o": INK, "h": hx("ffd0d4"), "r": hx("ff4d63"), "d": hx("b81d3a")})
    ascii_icon("icon_shield.png", [
        "oooooooo",
        "occbbbdo",
        "ocbbbbdo",
        "ocbbbbdo",
        "ocbbbbdo",
        ".obbbdo.",
        ".obbbdo.",
        "..obdo..",
        "...oo...",
    ], {"o": INK, "c": hx("d6f4ff"), "b": hx("6fd6ff"), "d": hx("2b8fc4")})

    def card_icon(name, cross):
        w, h = 9, 10
        im = Image.new("RGBA", (w, h), CLEAR)
        px = im.load()

        def rect(x0, y0, x1, y1, border, fill):
            for y in range(y0, y1 + 1):
                for x in range(x0, x1 + 1):
                    edge = x in (x0, x1) or y in (y0, y1)
                    px[x, y] = border if edge else fill

        rect(3, 0, 8, 7, INK, hx("5b60c8"))     # kartu belakang
        rect(0, 2, 6, 9, INK, hx("1d2150"))     # kartu depan
        for x in range(1, 6):
            px[x, 3] = hx("3b3f93")
        if cross:
            for i in range(3):
                px[2 + i, 5 + i - 1 + 1 - 1] = hx("ff7a85")
                px[4 - i, 5 + i - 1 + 1 - 1] = hx("ff7a85")
        else:
            for dx, dy in ((3, 5), (2, 6), (4, 6), (3, 7), (3, 6)):
                px[dx, dy] = GOLD4
        save(im, name)

    card_icon("icon_deck.png", False)
    card_icon("icon_discard.png", True)


def make_ornaments():
    star = Image.new("RGBA", (7, 7), CLEAR)
    p = star.load()
    for i in range(7):
        p[3, i] = GOLD4
        p[i, 3] = GOLD4
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        p[3 + dx, 3 + dy] = GOLD3
    p[3, 3] = hx("fffbea")
    for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        p[3 + dx * 1, 3 + dy * 1] = hx("fff0b8")
    save(star, "star.png")

    sm = Image.new("RGBA", (5, 5), CLEAR)
    p = sm.load()
    for i in range(5):
        p[2, i] = GOLD4
        p[i, 2] = GOLD4
    p[2, 2] = hx("fffbea")
    save(sm, "star_small.png")

    ad = Image.new("RGBA", (7, 4), CLEAR)
    p = ad.load()
    for y, (x0, x1) in enumerate([(0, 6), (1, 5), (2, 4), (3, 3)]):
        for x in range(x0, x1 + 1):
            p[x, y] = GOLD4
    save(ad, "arrow_down.png")

    ar = Image.new("RGBA", (4, 7), CLEAR)
    p = ar.load()
    for x, (y0, y1) in enumerate([(0, 6), (1, 5), (2, 4), (3, 3)]):
        for y in range(y0, y1 + 1):
            p[x, y] = GOLD4
    save(ar, "arrow_right.png")

    dv = Image.new("RGBA", (41, 5), CLEAR)
    p = dv.load()
    for x in list(range(2, 17)) + list(range(24, 39)):
        p[x, 2] = GOLD6
    for x in (0, 1, 39, 40):
        p[x, 2] = GOLD7
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        p[20 + dx, 2 + dy] = GOLD4
    p[20, 2] = GOLD3
    for x in (18, 22):
        p[x, 2] = GOLD5
    save(dv, "divider.png")


# ------------------------------------------------------------------ Theme .tres
class ThemeWriter:
    def __init__(self):
        self.ext, self.subs, self.items = [], [], []
        self._ids = {}

    def ext_res(self, key, rtype, path):
        self.ext.append(f'[ext_resource type="{rtype}" path="{path}" id="{key}"]')
        return f'ExtResource("{key}")'

    def tex_style(self, sid, tex, m, content=(0, 0, 0, 0), expand=0, modulate=None,
                  margins=None, stretch=None):
        ml, mt, mr, mb = margins if margins else (m, m, m, m)
        lines = [f'[sub_resource type="StyleBoxTexture" id="{sid}"]']
        for k, v in zip(("left", "top", "right", "bottom"), content):
            if v:
                lines.append(f"content_margin_{k} = {float(v)}")
        lines.append(f"texture = {tex}")
        for k, v in zip(("left", "top", "right", "bottom"), (ml, mt, mr, mb)):
            lines.append(f"texture_margin_{k} = {float(v)}")
        if expand:
            for k in ("left", "top", "right", "bottom"):
                lines.append(f"expand_margin_{k} = {float(expand)}")
        if stretch:
            lines.append(f"axis_stretch_horizontal = {stretch[0]}")
            lines.append(f"axis_stretch_vertical = {stretch[1]}")
        if modulate:
            lines.append(f"modulate_color = Color({modulate[0]}, {modulate[1]}, {modulate[2]}, {modulate[3]})")
        self.subs.append("\n".join(lines))
        return f'SubResource("{sid}")'

    def flat(self, sid, color, content=(0, 0, 0, 0)):
        lines = [f'[sub_resource type="StyleBoxFlat" id="{sid}"]']
        for k, v in zip(("left", "top", "right", "bottom"), content):
            if v:
                lines.append(f"content_margin_{k} = {float(v)}")
        lines.append(f"bg_color = Color({color[0]}, {color[1]}, {color[2]}, {color[3]})")
        self.subs.append("\n".join(lines))
        return f'SubResource("{sid}")'

    def line(self, sid, color, thickness):
        self.subs.append(
            f'[sub_resource type="StyleBoxLine" id="{sid}"]\n'
            f"color = Color({color[0]}, {color[1]}, {color[2]}, {color[3]})\nthickness = {thickness}"
        )
        return f'SubResource("{sid}")'

    def add(self, key, value):
        self.items.append(f"{key} = {value}")

    def write(self, path):
        txt = "[gd_resource type=\"Theme\" format=3]\n\n" + "\n".join(self.ext) + "\n\n"
        txt += "\n\n".join(self.subs) + "\n\n[resource]\n" + "\n".join(self.items) + "\n"
        with open(path, "w", newline="\n") as f:
            f.write(txt)


def col(s, a=1.0):
    c = hx(s)
    return f"Color({c[0]/255:.3f}, {c[1]/255:.3f}, {c[2]/255:.3f}, {a})"


def make_theme():
    t = ThemeWriter()
    A = "res://Assets/ui/"
    f_body = t.ext_res("font_body", "FontFile", "res://Assets/fonts/pixel_overload/Baskic8.otf")
    f_title = t.ext_res("font_title", "FontFile", "res://Assets/fonts/pixel_overload/Essentle4.otf")
    T = lambda k, n: t.ext_res(k, "Texture2D", A + n)

    # --- panel
    tex_panel, tex_inset = T("t_panel", "panel.png"), T("t_inset", "panel_inset.png")
    sb_panel = t.tex_style("sb_panel", tex_panel, 18, content=(30, 24, 30, 24))
    sb_dialog = t.tex_style("sb_dialog", tex_panel, 18, content=(36, 26, 36, 22), modulate=(1, 1, 1, 0.95))
    sb_hud = t.tex_style("sb_hud", tex_panel, 18, content=(24, 18, 24, 18), modulate=(1, 1, 1, 0.9))
    sb_inset = t.tex_style("sb_inset", tex_inset, 12, content=(18, 10, 18, 10), modulate=(1, 1, 1, 0.9))
    sb_barframe = t.tex_style("sb_barframe", T("t_barframe", "bar_frame.png"), 6, content=(6, 6, 6, 6))

    # --- tombol
    mk = lambda sid, n: t.tex_style(sid, T("t_" + sid, n), 15, content=(36, 12, 36, 12))
    sb_bn, sb_bh = mk("sb_bn", "button_normal.png"), mk("sb_bh", "button_hover.png")
    sb_bp, sb_bd = mk("sb_bp", "button_pressed.png"), mk("sb_bd", "button_disabled.png")
    sb_bf = t.tex_style("sb_bf", T("t_bf", "button_focus.png"), 15, expand=3)

    # --- chip, nameplate
    chips = {n: t.tex_style(f"sb_chip_{n}", T(f"t_chip_{n}", f"chip_{n}.png"), 9, content=(12, 6, 12, 6))
             for n in ("navy", "cyan", "violet", "gold")}
    sb_name = t.tex_style("sb_name", T("t_name", "nameplate.png"), 12, content=(24, 6, 24, 8))
    sb_fill_p = t.tex_style("sb_fill_p", T("t_fill_p", "bar_fill_player.png"), 0, margins=(0, 6, 0, 6))
    sb_fill_e = t.tex_style("sb_fill_e", T("t_fill_e", "bar_fill_enemy.png"), 0, margins=(0, 6, 0, 6))
    sb_barbg = t.flat("sb_barbg", (0.027, 0.031, 0.11, 1))
    sb_sep = t.line("sb_sep", hx("6e4a14"), 3)

    ink = col("05061a")
    # --- default
    t.add("default_font", f_body)
    t.add("default_font_size", 24)

    # Label
    t.add("Label/colors/font_color", col("e8ebff"))
    t.add("Label/colors/font_shadow_color", "Color(0, 0, 0, 0.6)")
    t.add("Label/constants/shadow_offset_x", 2)
    t.add("Label/constants/shadow_offset_y", 2)

    def label_var(name, **kw):
        t.add(f"{name}/base_type", '&"Label"')
        for k, v in kw.items():
            t.add(f"{name}/{k.replace('__', '/')}", v)

    label_var("TitleLabel", fonts__font=f_title, font_sizes__font_size=64,
              colors__font_color=col("ffd166"), colors__font_outline_color=ink,
              constants__outline_size=12, constants__shadow_offset_x=4, constants__shadow_offset_y=4)
    label_var("ChapterTitle", fonts__font=f_title, font_sizes__font_size=64,
              colors__font_color=col("ffd166"), colors__font_outline_color=ink,
              constants__outline_size=12, constants__shadow_offset_x=4, constants__shadow_offset_y=4)
    label_var("ChapterSubtitle", font_sizes__font_size=32, colors__font_color=col("d8c9ff"),
              colors__font_outline_color=ink, constants__outline_size=8)
    label_var("Heading", fonts__font=f_title, font_sizes__font_size=32, colors__font_color=col("ffd166"))
    label_var("Hint", font_sizes__font_size=16, colors__font_color=col("8f94c9"))
    label_var("NameTag", styles__normal=sb_name, colors__font_color=col("1a1030"),
              colors__font_shadow_color="Color(1, 1, 1, 0.25)", constants__shadow_offset_x=0,
              constants__shadow_offset_y=2)
    label_var("PromptTag", styles__normal=chips["gold"], font_sizes__font_size=24,
              colors__font_color=col("fff6d6"))
    label_var("InsetLabel", styles__normal=sb_inset, font_sizes__font_size=16, colors__font_color=col("c9cdf5"))
    label_var("HpText", font_sizes__font_size=16, colors__font_color=col("ffffff"),
              colors__font_outline_color=ink, constants__outline_size=6)
    for n, c in (("Navy", "e8ebff"), ("Cyan", "bfeaff"), ("Violet", "dccfff"), ("Gold", "ffe9a8")):
        label_var(f"Chip{n}", styles__normal=chips[n.lower()], font_sizes__font_size=16, colors__font_color=col(c))

    # Panel
    t.add("PanelContainer/styles/panel", sb_panel)
    for name, sb in (("DialoguePanel", sb_dialog), ("HudPanel", sb_hud), ("InsetPanel", sb_inset),
                     ("BarFrame", sb_barframe)):
        t.add(f"{name}/base_type", '&"PanelContainer"')
        t.add(f"{name}/styles/panel", sb)

    # Button
    t.add("Button/colors/font_color", col("e8ebff"))
    t.add("Button/colors/font_hover_color", col("ffd166"))
    t.add("Button/colors/font_focus_color", col("ffd166"))
    t.add("Button/colors/font_pressed_color", col("ffe9a8"))
    t.add("Button/colors/font_disabled_color", col("6b6e96"))
    t.add("Button/colors/font_hover_pressed_color", col("ffe9a8"))
    t.add("Button/colors/font_shadow_color", "Color(0, 0, 0, 0.6)")
    t.add("Button/constants/shadow_offset_x", 2)
    t.add("Button/constants/shadow_offset_y", 2)
    t.add("Button/font_sizes/font_size", 24)
    for k, v in (("normal", sb_bn), ("hover", sb_bh), ("pressed", sb_bp), ("disabled", sb_bd),
                 ("hover_pressed", sb_bp), ("focus", sb_bf)):
        t.add(f"Button/styles/{k}", v)
    t.add("MenuButton/base_type", '&"Button"')
    t.add("MenuButton/font_sizes/font_size", 32)

    # Separator, ProgressBar, RichText
    t.add("HSeparator/constants/separation", 14)
    t.add("HSeparator/styles/separator", sb_sep)
    t.add("ProgressBar/styles/background", sb_barbg)
    t.add("ProgressBar/styles/fill", sb_fill_p)
    t.add("HPBarEnemy/base_type", '&"ProgressBar"')
    t.add("HPBarEnemy/styles/fill", sb_fill_e)
    t.add("RichTextLabel/colors/default_color", col("d8dcff"))
    t.add("RichTextLabel/font_sizes/normal_font_size", 24)
    t.add("RichTextLabel/font_sizes/bold_font_size", 24)

    t.write(os.path.join(OUT, "theme", "game_theme.tres"))


if __name__ == "__main__":
    make_panel(); make_inset(); make_buttons(); make_bars(); make_chips()
    make_nameplate(); make_icons(); make_ornaments(); make_theme()
    print("OK ->", OUT)
