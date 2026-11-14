# Aset UI

UI game memakai pack **Tiny RPG – Mana Soul GUI** oleh *tiopalada* (CC0, tanpa AI):
https://tiopalada.itch.io/tiny-rpg-mana-soul-gui — lisensi CC0, atribusi tidak wajib (tetap disarankan dicantumkan di credits).

Pack asli ada di `Assets/tinyRPG_manaSoulGUI_v_1_0/` dan **tidak dimodifikasi**. Semua yang ada di folder ini
dihasilkan dari pack itu oleh `SourceArt/ui_builder/build_ui_from_mana_soul.py`.

## Isi

| File / folder | Fungsi |
|---|---|
| `theme/game_theme.tres` | Theme global (diatur di Project Settings → GUI → Theme → Custom). Semua gaya UI ada di sini. |
| `mana_soul/panel_a.png` | Bingkai navy–emas → panel dialog dan kotak pilihan (`DialoguePanel`). |
| `mana_soul/panel_b.png` | Bingkai ungu → panel HUD battle (`HudPanel`). |
| `mana_soul/panel_c.png` | Bingkai ungu + emas → panel modal default (pause, game over, hasil battle). |
| `mana_soul/button_a_*.png` | Tombol sayap emas (4 state) → menu utama (`WingButton`). |
| `mana_soul/button_b_*.png` | Tombol ungu berornamen (4 state) → tombol default dan opsi pilihan. |
| `mana_soul/header_b.png` | Plat nama pembicara (`NameTag`). |
| `mana_soul/bar_c.png` | Bingkai bar HP (`BarFrame`). Bagian dalamnya transparan, isi bar digambar `ProgressBar`. |
| `arrow_down.png`, `divider.png` | Penanda "lanjut" dialog dan ornamen pembatas. |
| `icon_deck.png`, `icon_discard.png` | Ikon deck/discard di HUD battle (digambar dengan palet pack; pack tidak punya ikon kartu). |
| `cursor_arrow.png`, `cursor_hand.png` | Kursor mouse bulu (dipasang oleh autoload `UiCursor`). |

Semua sprite pack diperbesar **2x** (nearest) supaya terbaca di layar 1152x648. Tinggi tombol = 44 px (di scene dipakai 48 px).

## Variasi gaya di theme

`Label`: `TitleLabel`, `ChapterTitle`, `ChapterSubtitle`, `Heading`, `Hint`, `DialogueText`, `NameTag`, `PromptTag`, `HpText`, `InsetLabel`, `ChipCyan`, `ChipViolet`
`Button`: `WingButton` (menu utama), `ChoiceButton` (opsi pilihan)
`PanelContainer`: `DialoguePanel`, `HudPanel`, `InsetPanel`, `BarFrame`
`ProgressBar`: `HPBarEnemy`

Pakai lewat Inspector → Theme → Theme Type Variation, atau `node.theme_type_variation = &"NamaVariasi"`.

## Mengubah tampilan

- **Ganti warna / margin / ukuran font**: edit konfigurasi di `build_ui_from_mana_soul.py`, lalu jalankan
  `python3 SourceArt/ui_builder/build_ui_from_mana_soul.py` (butuh Pillow + numpy). Hasilnya menimpa isi folder ini.
- **Pakai bingkai lain dari pack**: ubah entri `PANELS` / `BUTTONS` (pack punya panel A–F dan tombol A–C).
- **Ganti pack**: letakkan pack baru, sesuaikan nama file dan margin 9-slice di skrip.
