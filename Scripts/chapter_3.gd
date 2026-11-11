extends Node2D
## Chapter 3 - Pesulap di Balik Cermin.
##
## Alur:
##   1. Layar hitam + judul CHAPTER 3 / Pesulap di Balik Cermin, lalu kamera turun pelan.
##   2. Alto berjalan ke kanan menuju reruntuhan.
##   3. Alto mendekati Hanpi-hanpi -> dialog mulai otomatis.
##   4. Dialog selesai -> layar fade hitam -> battle melawan Hanpi-hanpi (next_scene).

## Scene berikutnya (battle Hanpi-hanpi). Drag file .tscn-nya ke slot ini di Inspector.
@export_file("*.tscn") var next_scene: String = ""

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

## Dialog sebelum battle. (Draf dari saya, silakan ganti dengan cerita kalian.)
## speaker kosong ("") = teks narasi tanpa nama.
const DIALOGUE := [
	{
		"speaker": "Hanpi-hanpi",
		"text": "Berhenti di situ, Bintang Kecil. Reruntuhan ini bukan tempat untuk orang yang tersesat.",
	},
	{
		"speaker": "Alto",
		"text": "Siapa kau? Aku tidak tersesat. Aku sedang mencari Putri Ellie, dan jalan menuju goa Brok ada di balik sini.",
	},
	{
		"speaker": "Hanpi-hanpi",
		"text": "Hihihi... Putri Ellie? Semua yang mencarinya hanya menemukan bayangan mereka sendiri di dalam cermin ini.",
	},
	{
		"speaker": "Alto",
		"text": "Aku tidak punya waktu untuk permainan cerminmu. Minggirlah!",
	},
	{
		"speaker": "Hanpi-hanpi",
		"text": "Kalau begitu, tunjukkan padaku! Mari kita lihat siapa yang lebih pandai, bintang kecil atau sihir di balik cermin!",
	},
	{
		"speaker": "Alto",
		"text": "Kalau kau tetap menghalangi jalanku, aku terpaksa melawanmu!",
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
	await tween.finished
	if next_scene.is_empty():
		print("[Chapter3] next_scene belum diisi. Isi lewat Inspector (node Chapter3).")
		# Supaya masih bisa dites: layar kembali terang dan Alto bisa digerakkan lagi.
		alto.can_move = true
		create_tween().tween_property(fade, "color:a", 0.0, 1.0)
		return
	get_tree().change_scene_to_file(next_scene)
