# The Legends of Interstellar

Game 2D platformer + battle kartu bergiliran, dibuat dengan **Godot 4.x**.
Alto, berbekal kristal dari Raja Interstellar, berangkat mencari Putri Ellie dan menghadapi Brok.

## Cara main

| Tombol            | Fungsi                              |
|-------------------|-------------------------------------|
| A / D (atau panah) | Jalan kiri / kanan                  |
| W / Spasi          | Lompat                              |
| E                  | Bicara / periksa / lanjut dialog    |
| Esc atau P         | Pause menu                          |
| Mouse              | Pilih kartu & tombol saat battle    |

## Alur cerita (urutan scene)

```
Menu Utama -> Prolog -> Chapter 1 -> Battle Slimy -> Chapter 2 -> Battle Carrota
		  -> Chapter 3 -> Battle Hanpi-hanpi -> To Be Continued -> Menu Utama
```
Setiap scene menyimpan tujuan berikutnya di properti Inspector `next_scene` / `next_scene_on_win`.

## Struktur folder

```
Assets/                 Semua aset yang dipakai game (diimpor Godot)
  backgrounds/          Latar tiap lokasi (castle_interstellar, forest_bridge, carrot_village, mirror_ruins, ...)
  battle/               Aset khusus battle
	cards/              Gambar kartu (alto_*, slimy_*, carrota_*, hanpi_*)
	enemies/<musuh>/    Frame animasi musuh: idle_1.png, throw_1.png, ... (dibaca otomatis oleh enemy_view.gd)
	props/              Benda yang dilempar/efek (carrot, chili_sauce, slimy_glob, ...)
  characters/           Sprite karakter di dunia/cerita
	alto/form_1..3/     Alto: neutral, happy, mad, sad, shocked
	king/               Raja Interstellar: king_front, king_back, king_side_left, king_side_right
	slimy/ carrota/ hanpi/
  fonts/pixel_overload/ Font (Baskic8 = font utama game)
Scenes/
  chapters/             prolog, chapter_1..3, to_be_continued
  characters/           alto, king, slimy, carrota, hanpi
  battle/               battle (Slimy) + battle_carrota + battle_hanpi + enemy_view
  ui/                   main_menu, pause_menu, dialogue_box, choice_box, game_over
  props/                vegetables
  _archive/             Scene lama/percobaan yang tidak dipakai game (aman dihapus)
Scripts/                Struktur sama dengan Scenes
  core/                 game_state (autoload), input_setup
  characters/           alto, slimy
  components/           interactable (objek yang bisa diajak bicara/diperiksa), hover_bob
  chapters/             skrip tiap chapter
  ui/                   skrip menu & kotak dialog
  battle/               battle_data (data kartu & musuh), battle_manager, enemy_view
SourceArt/              File mentah (.clip, .aseprite) & ekspor animasi (.webp). Di-.gdignore:
						tidak diimpor Godot dan tidak ikut export. Hapus .gdignore jika ingin memakainya.
```

## Konvensi

- Nama folder & file: `snake_case`, tanpa spasi (mis. `king_side_left.png`).
- Satu scene punya satu skrip dengan nama yang sama (mis. `chapter_3.tscn` -> `chapter_3.gd`).
- Teks cerita (dialog) ada di konstanta `DIALOGUE` di skrip chapter masing-masing.
- Angka battle (HP, damage, peluang skill) hanya di `Scripts/battle/battle_data.gd`.
- **Pindah/rename file lewat panel FileSystem Godot**, bukan lewat Explorer, supaya referensi ikut terupdate.

## Menambah musuh baru

1. Tambahkan frame animasi di `Assets/battle/enemies/<id>/` dan gambar kartu di `Assets/battle/cards/`.
2. Tambah entri musuh (HP, skill, background) di `ENEMIES` pada `Scripts/battle/battle_data.gd`.
3. Buat scene baru di `Scenes/battle/` yang mewarisi `battle.tscn`, lalu isi `enemy_id` dan `next_scene_on_win`.
