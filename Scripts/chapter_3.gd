extends Node2D
## Chapter 3 - Pesulap di Balik Cermin (Reruntuhan Cermin).
##
## Alur:
##   1. Layar hitam + judul CHAPTER 3 / Pesulap di Balik Cermin, lalu kamera turun pelan
##      (sama seperti intro Prolog / Chapter 1 / Chapter 2).
##   2. Alto berjalan ke kanan, mendekati Hanpi-hanpi -> dialog mulai otomatis.
##   3. Dialog selesai -> layar fade hitam -> battle Hanpi-hanpi.
##   4. Menang -> Chapter 3 Ending ("To Be Continued?").

## Scene berikutnya (battle Hanpi-hanpi).
@export_file("*.tscn") var next_scene: String = "res://Scenes/battle/battle_hanpi.tscn"

@export_group("Intro")
## Lama kamera turun dari atas ke Alto (detik).
@export var camera_pan_duration: float = 5.0
## Seberapa tinggi kamera mulai di atas posisi akhirnya (piksel).
@export var camera_start_height: float = 600.0
## Posisi akhir kamera relatif ke Alto (negatif = kamera lebih tinggi dari kaki).
@export var camera_final_offset: Vector2 = Vector2(0.0, -210.0)

@export_group("Camera")
## Batas kanan kamera (koordinat dunia) supaya tidak menampilkan area kosong di luar background.
@export var camera_limit_right: int = 1152

# ------------------------------------------------------------------
# TEKS CERITA - edit di sini. speaker kosong ("") = narasi tanpa nama.
# (Teks ini draf dari saya, silakan ganti sesuai cerita kamu.)
# ------------------------------------------------------------------
const DIALOGUE := [
	{
		"speaker": "Alto",
		"text": "Tempat apa ini...? Cahaya ungu ada di mana-mana, dan reruntuhan ini terasa aneh.",
	},
	{
		"speaker": "Hanpi-hanpi",
		"text": "Hihihi... Satu penonton lagi masuk ke dalam pertunjukanku!",
	},
	{
		"speaker": "Alto",
		"text": "Cermin yang bisa bicara?! Siapa kau sebenarnya?",
	},
	{
		"speaker": "Hanpi-hanpi",
		"text": "Aku Hanpi-hanpi, pesulap yang tinggal di balik cermin! Tidak ada yang boleh melewati reruntuhan ini sebelum menyaksikan triknya.",
	},
	{
		"speaker": "Alto",
		"text": "Aku tidak punya waktu untuk pertunjukan. Aku harus menyelamatkan Putri Ellie dari Brok!",
	},
	{
		"speaker": "Hanpi-hanpi",
		"text": "Kalau begitu, kalahkan aku dulu! Tapi hati-hati... serangan yang kau lepaskan bisa saja kembali padamu. Hihihi!",
	},
	{
		"speaker": "Alto",
		"text": "Aku tidak akan terpedaya oleh sulapmu. Majulah!",
	},
]

var _intro_playing: bool = false
var _intro_tween: Tween

@onready var alto = $Alto
@onready var hanpi = $Hanpi
@onready var dialogue_box = $DialogueBox
@onready var fade: ColorRect = $IntroLayer/Fade
@onready var title_box: Control = $IntroLayer/TitleBox


func _ready() -> void:
	alto.camera.limit_right = camera_limit_right
	hanpi.interacted.connect(_on_hanpi_interacted)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	# Tekan E saat intro untuk melewati (berguna saat testing).
	if _intro_playing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_intro_tween.kill()
		_on_intro_finished()


# ---------------------------------------------------------------- Intro

func _play_intro() -> void:
	_intro_playing = true
	alto.can_move = false
	hanpi.enabled = false

	fade.color.a = 1.0
	title_box.modulate.a = 0.0
	alto.camera.offset = camera_final_offset + Vector2(0.0, -camera_start_height)

	_intro_tween = create_tween()
	# 1) Judul chapter muncul di atas layar hitam.
	_intro_tween.tween_property(title_box, "modulate:a", 1.0, 1.0)
	_intro_tween.tween_interval(1.5)
	# 2) Layar terang pelan-pelan sambil kamera turun dari atas.
	_intro_tween.tween_property(fade, "color:a", 0.0, 1.5)
	_intro_tween.parallel().tween_property(alto.camera, "offset", camera_final_offset, camera_pan_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 3) Judul menghilang menjelang kamera sampai.
	_intro_tween.parallel().tween_property(title_box, "modulate:a", 0.0, 1.5) \
		.set_delay(maxf(camera_pan_duration - 1.5, 0.0))
	_intro_tween.tween_callback(_on_intro_finished)


func _on_intro_finished() -> void:
	_intro_playing = false
	fade.color.a = 0.0
	title_box.modulate.a = 0.0
	alto.camera.offset = camera_final_offset
	alto.can_move = true
	hanpi.enabled = true


# ------------------------------------------------------------- Dialogue

func _on_hanpi_interacted() -> void:
	alto.can_move = false
	hanpi.enabled = false
	dialogue_box.start(DIALOGUE)


func _on_dialogue_finished() -> void:
	_end_chapter()


# --------------------------------------------------------------- Ending

func _end_chapter() -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 2.0)
	tween.tween_callback(_change_to_next_scene)


func _change_to_next_scene() -> void:
	if next_scene.is_empty():
		print("[Chapter3] next_scene belum diisi. Isi lewat Inspector (node Chapter3).")
		alto.can_move = true
		create_tween().tween_property(fade, "color:a", 0.0, 1.0)
		return
	get_tree().change_scene_to_file(next_scene)
