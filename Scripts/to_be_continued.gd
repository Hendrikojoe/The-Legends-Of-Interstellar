extends Node2D
## Penutup (sementara): Alto melanjutkan perjalanan, kamera naik ke langit, muncul "TO BE CONTINUED...".
## Kebalikan dari intro Prolog (yang kameranya turun dari atas ke bawah).

## Scene tujuan setelah penutup selesai (default: menu utama).
@export_file("*.tscn") var menu_scene: String = "res://Scenes/menu/main_menu.tscn"

@export_group("Kamera")
## Posisi kamera relatif ke Alto di awal (negatif = kamera lebih tinggi dari kaki).
@export var camera_start_offset: Vector2 = Vector2(0.0, -210.0)
## Seberapa tinggi kamera naik (piksel). Jangan melebihi tinggi background.
@export var camera_rise_height: float = 600.0
## Lama kamera naik (detik).
@export var camera_rise_duration: float = 8.0
## Batas kanan kamera supaya tidak menampilkan area kosong di luar background.
@export var camera_limit_right: int = 1152

var _leaving: bool = false

@onready var alto = $Alto
@onready var fade: ColorRect = $FadeLayer/Fade
@onready var title: Label = $TextLayer/TitleLabel


func _ready() -> void:
	alto.camera.limit_right = camera_limit_right
	alto.camera.offset = camera_start_offset
	# Alto berjalan sendiri ke kanan, keluar dari layar.
	alto.can_move = false
	alto.auto_direction = 1.0

	fade.color.a = 1.0
	title.modulate.a = 0.0

	var end_offset := camera_start_offset + Vector2(0.0, -camera_rise_height)
	var tween := create_tween()
	# 1) Layar terang, kamera mulai naik pelan dari tanah ke atas.
	tween.tween_property(fade, "color:a", 0.0, 1.5)
	tween.parallel().tween_property(alto.camera, "offset", end_offset, camera_rise_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 2) Tulisan muncul saat kamera sudah cukup tinggi.
	tween.parallel().tween_property(title, "modulate:a", 1.0, 1.5) \
		.set_delay(maxf(camera_rise_duration * 0.4, 0.0))
	# 3) Layar memudar hitam, tulisan tetap, lalu kembali ke menu.
	tween.tween_property(fade, "color:a", 1.0, 2.0)
	tween.tween_interval(3.0)
	tween.tween_callback(_go_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	# Tekan E / Enter / Space untuk langsung kembali ke menu.
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_go_to_menu()


func _go_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	if menu_scene.is_empty():
		print("[ToBeContinued] menu_scene belum diisi.")
		return
	get_tree().change_scene_to_file(menu_scene)
