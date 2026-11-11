extends RefCounted
## Data battle: kartu Alto, musuh, dan skill musuh.
##
## Semua angka (damage, HP, bobot peluang) dan teks ada di file ini,
## jadi untuk menyeimbangkan battle cukup edit di sini tanpa menyentuh logika.
##
## Cara menambah musuh baru:
##   1. Tambah entri di ENEMIES (frame animasi ada di Assets/battle/enemies/<id>/).
##   2. Buat scene battle baru yang mewarisi battle.tscn, lalu isi `enemy_id`-nya.

const CARD_DIR := "res://Assets/battle/cards/"
const ENEMY_DIR := "res://Assets/battle/enemies/"
const PROP_DIR := "res://Assets/battle/props/"

# ------------------------------------------------------------------ KARTU ALTO
# damage / block / heal boleh digabung dalam satu kartu.
# "text" = teks deskripsi yang ditulis oleh kode di area kosong kartu
# (karena gambar kartu Alto belum punya teks deskripsi).
const ALTO_CARDS := {
	"charged_attack": {
		"name": "Charged Attack",
		"art": CARD_DIR + "alto_charged_attack.png",
		"damage": 12,
		"block": 0,
		"heal": 0,
		"text": "Serangan bertenaga.\n12 Damage",
	},
	"metal_claw": {
		"name": "Metal Claw",
		"art": CARD_DIR + "alto_metal_claw.png",
		"damage": 8,
		"block": 4,
		"heal": 0,
		"text": "Cakar logam.\n8 Damage, +4 Block",
	},
	"crowned": {
		"name": "Crowned",
		"art": CARD_DIR + "alto_crowned.png",
		"damage": 0,
		"block": 10,
		"heal": 4,
		"text": "Mahkota pelindung.\n+10 Block, +4 HP",
	},
}

## Isi deck Alto: id kartu -> jumlah salinan.
const ALTO_DECK := {
	"charged_attack": 4,
	"metal_claw": 4,
	"crowned": 4,
}

# ---------------------------------------------------------------------- MUSUH
# Kunci skill:
#   weight          bobot peluang dipilih
#   damage/block/heal   efek langsung
#   inflict         status untuk Alto   {"slow": giliran, "burn": giliran, "dizzy": giliran}
#   gain            status untuk musuh  {"reflect": giliran, "strength": tambahan damage}
#   no_repeat       true = tidak dipakai dua kali berturut-turut
#   hp_below        hanya dipakai kalau HP musuh di bawah pecahan ini (0.6 = 60%)
#   max_strength    berhenti dipakai kalau strength sudah segini
#   animation       nama animasi di "animations" (kosong = tidak ada)
#   release_ms      kapan efek/damage terjadi sejak animasi mulai
#   fx              efek visual (projectile / beam / bubble / grow / glow / none)
#   label           teks kecil di bawah kartu intent
#   summary         teks penjelasan di panel musuh
const ENEMIES := {
	# ------------------------------------------------------------------ SLIMY
	"slimy": {
		"name": "Slimy",
		"max_hp": 40,
		"background": "res://Assets/background/2.png",
		"display_height": 130.0,
		"idle_bob": 0.0,
		"frame_size": Vector2(517, 445),
		"feet": Vector2(259.0, 434.5),
		"ref_height": 410.0,
		"muzzle": Vector2(-40, -80),
		"animations": {
			"idle": {"ms": [500, 500], "loop": true},
			"slomy": {"ms": [250, 250, 125, 125, 125], "loop": false},
		},
		"skills": {
			"slomy": {
				"name": "Slomy",
				"art": CARD_DIR + "slimy_slomy.png",
				"weight": 55,
				"damage": 7,
				"inflict": {"slow": 2},
				"animation": "slomy",
				"release_ms": 500,
				"fx": {
					"type": "projectile",
					"textures": [PROP_DIR + "slimy_glob.png"],
					"scale": 0.55,
					"duration": 0.35,
					"arc": 50.0,
				},
				"label": "7 DMG + SLOW",
				"summary": "Slomy: 7 damage, Alto jadi lambat (serangan -30%) selama 2 giliran.",
			},
			"boincy": {
				"name": "Boincy",
				"art": CARD_DIR + "slimy_boincy.png",
				"weight": 25,
				"gain": {"reflect": 1},
				"no_repeat": true,
				"animation": "",
				"release_ms": 200,
				"fx": {"type": "bubble", "texture": PROP_DIR + "slimy_bubble.png"},
				"label": "REFLECT",
				"summary": "Boincy: gelembung memantulkan serangan Alto di giliran berikutnya.",
			},
			"biggy": {
				"name": "Biggy",
				"art": CARD_DIR + "slimy_biggy.png",
				"weight": 20,
				"gain": {"strength": 4},
				"max_strength": 8,
				"no_repeat": true,
				"animation": "",
				"release_ms": 100,
				"fx": {"type": "grow"},
				"label": "POWER +4",
				"summary": "Biggy: tubuh membesar, semua serangannya +4 damage (maksimal +8).",
			},
		},
	},
	# ---------------------------------------------------------------- CARROTA
	"carrota": {
		"name": "Carrota",
		"max_hp": 48,
		"background": "res://Assets/background/3.png",
		"display_height": 200.0,
		"idle_bob": 3.0,
		"frame_size": Vector2(416, 547),
		"feet": Vector2(196.2, 542.0),
		"ref_height": 494.0,
		"muzzle": Vector2(-70, -120),
		"animations": {
			"idle": {"ms": [1000], "loop": true},
			"throw": {"ms": [250, 250, 125, 125, 125], "loop": false},
			"heal": {"ms": [375, 375, 250], "loop": false},
		},
		"skills": {
			"raining_soup": {
				"name": "Raining Soup",
				"art": CARD_DIR + "carrota_raining_soup.png",
				"weight": 45,
				"damage": 8,
				"animation": "throw",
				"release_ms": 625,
				"fx": {
					"type": "projectile",
					"textures": [PROP_DIR + "carrot_1.png", PROP_DIR + "carrot_2.png"],
					"scale": 0.8,
					"duration": 0.4,
					"arc": 70.0,
					"spin": -6.28,
				},
				"label": "8 DMG",
				"summary": "Raining Soup: melempar bahan sup ke arah Alto, 8 damage.",
			},
			"chili_sauce": {
				"name": "Chili Sauce",
				"art": CARD_DIR + "carrota_chili_sauce.png",
				"weight": 35,
				"damage": 5,
				"inflict": {"burn": 3},
				"animation": "throw",
				"release_ms": 625,
				"fx": {
					"type": "projectile",
					"textures": [PROP_DIR + "chili_sauce.png"],
					"scale": 0.7,
					"duration": 0.4,
					"arc": 40.0,
				},
				"label": "5 DMG + BURN",
				"summary": "Chili Sauce: 5 damage + Alto terbakar 3 giliran (3 damage per giliran).",
			},
			"healty_soup": {
				"name": "Healty Soup",
				"art": CARD_DIR + "carrota_healty_soup.png",
				"weight": 20,
				"heal": 8,
				"hp_below": 0.6,
				"no_repeat": true,
				"animation": "heal",
				"release_ms": 750,
				"fx": {"type": "glow", "color": Color(0.6, 1.0, 0.7, 1.0)},
				"label": "HEAL +8",
				"summary": "Healty Soup: Carrota memakan sup dan memulihkan 8 HP.",
			},
		},
	},
	# ------------------------------------------------------------------ HANPI
	"hanpi": {
		"name": "Hanpi-hanpi",
		"max_hp": 60,
		"background": "res://Assets/background/4.png",
		"display_height": 190.0,
		"idle_bob": 6.0,
		"frame_size": Vector2(540, 543),
		"feet": Vector2(282.0, 510.0),
		"ref_height": 450.0,
		"muzzle": Vector2(-60, -100),
		"animations": {
			"idle": {"ms": [1000], "loop": true},
			"dizzy_dizza": {"ms": [125, 125, 125, 125, 375], "loop": false},
			"soreyes": {"ms": [125, 125, 125], "loop": false},
			"stubidi": {"ms": [250, 125, 125, 125], "loop": false},
		},
		"skills": {
			"stubidi": {
				"name": "Stubidi",
				"art": CARD_DIR + "hanpi_stubidi.png",
				"weight": 40,
				"damage": 12,
				"animation": "stubidi",
				"release_ms": 400,
				"fx": {"type": "beam", "color": Color(0.45, 0.85, 1.0, 1.0), "width": 30.0},
				"label": "12 DMG",
				"summary": "Stubidi: sinar biru dari cermin, 12 damage.",
			},
			"dizzy_dizza": {
				"name": "Dizzy-Dizza",
				"art": CARD_DIR + "hanpi_dizzy_dizza.png",
				"weight": 35,
				"damage": 6,
				"inflict": {"dizzy": 1},
				"animation": "dizzy_dizza",
				"release_ms": 300,
				"fx": {"type": "beam", "color": Color(1.0, 0.95, 0.7, 1.0), "width": 26.0},
				"label": "6 DMG + DIZZY",
				"summary": "Dizzy-Dizza: 6 damage + Alto pusing (kartu berikutnya terpilih acak).",
			},
			"soreyes": {
				"name": "Soreyes",
				"art": CARD_DIR + "hanpi_soreyes.png",
				"weight": 25,
				"block": 10,
				"no_repeat": true,
				"animation": "soreyes",
				"release_ms": 300,
				"fx": {"type": "none"},
				"label": "+10 BLOCK",
				"summary": "Soreyes: Hanpi menggandakan bayangan, mendapat 10 Block.",
			},
		},
	},
}
