# Aset UI "Cosmic Gilded"

Semua tampilan UI (menu, dialog, pilihan, pause, game over, HUD battle, prompt `[E]`, judul chapter)
diatur lewat **satu Theme**: `Assets/ui/theme/game_theme.tres`. Theme ini dipasang global di
Project Settings -> GUI -> Theme -> Custom, jadi setiap `Button`, `Label`, `PanelContainer`, dst.
otomatis memakainya. Style khusus dipanggil lewat *Theme Type Variation* di Inspector:

| Variation        | Dipakai untuk                                  |
|------------------|------------------------------------------------|
| `TitleLabel`     | logo / judul besar (font Essentle4, emas)      |
| `ChapterTitle` / `ChapterSubtitle` | kartu judul chapter, Prolog, Tamat   |
| `Heading`        | judul kecil (nama karakter di HUD, prompt pilihan) |
| `Hint`           | teks petunjuk kecil                            |
| `NameTag`        | pita emas nama pembicara di dialog             |
| `PromptTag`      | label `[E] Bicara` di atas objek               |
| `ChipCyan/Violet/Navy/Gold` | lencana Block, status, dll.         |
| `InsetLabel`     | teks niat musuh                                |
| `HudPanel` / `DialoguePanel` / `InsetPanel` / `BarFrame` | variasi panel |
| `MenuButton`     | tombol menu utama (font lebih besar)           |
| `HPBarEnemy`     | bar HP musuh (merah). Bar default = hijau      |

## Isi folder

PNG di sini digambar 3x (1 "piksel logis" = 3 px) supaya selaras dengan font Baskic8 24 px.
9-slice dan margin-nya ada di `game_theme.tres`:

| File                     | Margin 9-slice | Catatan                     |
|--------------------------|---------------|-----------------------------|
| `panel.png`              | 18 px         | panel utama, sudut bintang  |
| `panel_inset.png`        | 12 px         | kotak log, teks niat musuh  |
| `button_normal/hover/pressed/disabled.png` | 15 px | state tombol     |
| `button_focus.png`       | 15 px, expand 3 | cincin fokus keyboard     |
| `bar_frame.png`          | 6 px          | bingkai bar HP              |
| `bar_fill_player/enemy.png` | atas/bawah 6 px | isi bar HP            |
| `chip_*.png`             | 9 px          | lencana kecil               |
| `nameplate.png`          | 12 px         | pita nama dialog            |
| `icon_*.png`, `star*.png`, `arrow_*.png`, `divider.png` | - | ikon & ornamen |

Aset di atas dibuat oleh `SourceArt/ui_generator/generate_ui_assets.py` (lisensi: milik proyek ini).
Ubah warna/bentuk di skrip itu lalu jalankan ulang:
`python3 SourceArt/ui_generator/generate_ui_assets.py` (butuh Pillow).

## Memakai pack dari itch.io

Pack di bawah dipilih dari deskripsi & lisensi di halamannya (belum diuji di game ini).
Selalu cek lisensi di halaman pack sebelum dipakai/dirilis.

| Pack | Lisensi | Kenapa cocok |
|------|---------|--------------|
| [Tiny RPG - Mana Soul GUI](https://tiopalada.itch.io/tiny-rpg-mana-soul-gui) (tiopalada) | CC0, bayar sesukanya (bisa $0), tercantum untuk Godot | frame 9-slice, bar HP/mana, tombol 4 state, header menu, kursor; bernuansa magis |
| [Pixel UI Fantasy Free](https://heyheythere.itch.io/pixel-ui-fantasy-free) (heyheythere) | CC BY 4.0 (wajib kredit); halamannya menyebut dibuat dengan bantuan AI | sudah berupa Theme Godot 4 + PNG 9-slice; tema parchment (coklat) senada dengan badan kartu |
| [Fantasy UI Borders](https://kenney-assets.itch.io/fantasy-ui-borders) (Kenney) | biasanya CC0 - konfirmasi di halaman | 130+ sprite bingkai 9-slice, gaya bersih (bukan pixel-art) |

Cara menukar (urutan paling singkat):

1. Di itch.io klik **Download Now** pada pack (biasanya halaman "bayar sesukanya" dulu), ekstrak ke
   `Assets/ui/vendor/<nama_pack>/`.
2. Pack pixel biasanya berukuran 1x. Besarkan 3x tanpa smoothing agar tebalnya sama dengan UI sekarang:
   `magick in.png -filter point -resize 300% out.png`
3. Timpa PNG di `Assets/ui/` dengan file pack yang setara (nama file tetap), atau di Godot buka
   `game_theme.tres` dan ganti *Texture* tiap StyleBoxTexture.
4. Sesuaikan **Texture Margins** tiap StyleBoxTexture dengan lebar sudut pack (tabel di atas = nilai sekarang).
5. Kalau pack punya warna beda, ubah warna font di theme (`Label/colors/font_color`, `Button/colors/*`).

Kalau pack-nya diunggah ke saya, pemetaan dan margin-nya bisa saya kerjakan langsung.

## Kredit

Pack CC BY wajib dikreditkan. Contoh baris kredit:
`Pixel UI Fantasy Free by heyheythere - https://heyheythere.itch.io/pixel-ui-fantasy-free - CC BY 4.0`
