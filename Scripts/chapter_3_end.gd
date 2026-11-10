extends Node2D
## Penutup Chapter 3: Alto melanjutkan perjalanan + tulisan "To Be Continued?".
##
## Ini kebalikan dari intro Prolog/Chapter:
##   Intro  : kamera TURUN dari atas ke Alto, judul memudar keluar.
##   Ending : kamera NAIK dari bawah ke atas meninggalkan Alto, tulisan muncul naik dari bawah.
##
## Alur:
##   1. Layar terang pelan-pelan, Alto berjalan otomatis ke kanan.
##   2. Kamera naik pelan, tulisan "To Be Continued?" muncul sambil bergerak naik.
##   3. Layar memudar hitam. Tekan E untuk kembali ke Menu Utama.

@export_file("*.tscn") var menu_scene: String = "res://Scenes/menu/main_menu.tscn"

@export_group("Ending")
## Batas kanan kamera (koordinat dunia) supaya tidak menampilkan area kosong di luar background.
@export var camera_limit_right: int = 1152
## Posisi awal kamera relatif ke Alto (sama dengan posisi akhir intro Chapter 2/3).
@export var camera_start_offset: Vector2 = Vector2(0.0, -210.0)
## Seberapa tinggi kamera naik (piksel). Jangan terlalu besar supaya tidak keluar dari background.
@export var camera_rise_height: float = 600.0
## Lama kamera naik (detik).
@export var camera_rise_duration: float = 6.0
## Jeda sebelum kamera mulai naik (detik).
@export var camera_rise_delay: float = 1.0
## Kapan tulisan mulai muncul (detik sejak scene mulai).
@export var text_delay: float = 2.5
## Jarak tulisan bergerak naik dari bawah ke posisi akhirnya (piksel).
@export var text_rise_distance: float = 160.0
## Lama tulisan tampil penuh sebelum layar memudar hitam (detik).
@export var text_hold: float = 2.5

var _can_exit: bool = false
var _sequence: Tween

@onready var alto = $Alto
@onready var fade: ColorRect = $EndLayer/Fade
@onready var tbc_label: Label = $EndLayer/ToBeContinued
@onready var hint_label: Label = $EndLayer/Hint


func _ready() -> void:
	alto.camera.limit_right = camera_limit_right
	alto.can_move = false
	alto.auto_direction = 1.0  # Alto berjalan sendiri ke kanan.

	fade.color.a = 1.0
	tbc_label.modulate.a = 0.0
	tbc_label.position.y = text_rise_distance
	hint_label.modulate.a = 0.0
	alto.camera.offset = camera_start_offset

	_sequence = create_tween()
	# 1) Layar terang pelan-pelan.
	_sequence.tween_property(fade, "color:a", 0.0, 1.5)
	# 2) Kamera naik dari bawah ke atas.
	_sequence.parallel().tween_property(alto.camera, "offset", \
		camera_start_offset + Vector2(0.0, -camera_rise_height), camera_rise_duration) \
		.set_delay(camera_rise_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 3) Tulisan muncul sambil naik dari bawah.
	_sequence.parallel().tween_property(tbc_label, "modulate:a", 1.0, 1.5).set_delay(text_delay)
	_sequence.parallel().tween_property(tbc_label, "position:y", 0.0, 3.0) \
		.set_delay(text_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 4) Tahan sebentar, lalu layar memudar hitam.
	_sequence.tween_interval(text_hold)
	_sequence.tween_property(fade, "color:a", 1.0, 2.0)
	_sequence.tween_callback(_on_sequence_finished)


func _on_sequence_finished() -> void:
	alto.auto_direction = 0.0
	_can_exit = true
	create_tween().tween_property(hint_label, "modulate:a", 1.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _can_exit and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_go_to_menu()


func _go_to_menu() -> void:
	_can_exit = false
	if ResourceLoader.exists(menu_scene):
		get_tree().change_scene_to_file(menu_scene)
	else:
		print("[Chapter3End] Scene menu tidak ditemukan: %s" % menu_scene)
