extends Node2D
## Chapter 1 - Sebuah Perjalanan Dimulai.
##
## Alur:
##   1. Layar hitam + judul CHAPTER 1 / Sebuah Perjalanan Dimulai, lalu kamera turun pelan.
##   2. Pemain menggerakkan Alto ke kanan.
##   3. Alto mendekati Slimy -> dialog mulai otomatis.
##   4. Dialog selesai -> layar fade hitam -> pindah ke next_scene (nanti: scene battle).

## Scene berikutnya (mis. scene battle). Drag file .tscn-nya ke slot ini di Inspector.
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
@export var camera_limit_right: int = 1253

## Edit dialog di sini. speaker kosong ("") = teks narasi tanpa nama.
const DIALOGUE := [
	{
		"speaker": "Alto",
		"text": "Tunggu... Siapa kau?",
	},
	{
		"speaker": "Slimy",
		"text": "Namaku Slimy! Dan kau tidak boleh melewati tempat ini!",
	},
	{
		"speaker": "Alto",
		"text": "Maaf, aku tidak bermaksud mencari masalah. Tapi aku sedang terburu-buru mencari jalan menuju goa Brok untuk menyelamatkan Putri Ellie.",
	},
	{
		"speaker": "Slimy",
		"text": "Aku tidak peduli ke mana tujuanmu! Siapa pun dilarang lewat sini, dan kau tidak akan bisa melangkah lebih jauh!",
	},
	{
		"speaker": "Alto",
		"text": "Aku harus segera pergi ke sana. Kalau kau tetap memaksa menghalangi jalanku... terpaksa aku harus melewatimu dengan cara lain.",
	},
	{
		"speaker": "Slimy",
		"text": "Berani sekali! Kalau begitu, hadapi aku dulu!",
	},
]

var _intro_playing: bool = false
var _intro_tween: Tween

@onready var alto = $Alto
@onready var slimy = $Slimy
@onready var dialogue_box = $DialogueBox
@onready var fade: ColorRect = $IntroLayer/Fade
@onready var title_box: Control = $IntroLayer/TitleBox


func _ready() -> void:
	alto.camera.limit_right = camera_limit_right
	slimy.interacted.connect(_on_slimy_interacted)
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
	slimy.enabled = false

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
	slimy.enabled = true


# ------------------------------------------------------------- Dialogue

func _on_slimy_interacted() -> void:
	alto.can_move = false
	slimy.enabled = false
	dialogue_box.start(DIALOGUE)


func _on_dialogue_finished() -> void:
	_end_chapter()


# --------------------------------------------------------------- Ending

func _end_chapter() -> void:
	# Belum ada mekanik battle: layar memudar hitam lalu pindah ke next_scene.
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 2.0)
	tween.tween_callback(_change_to_next_scene)


func _change_to_next_scene() -> void:
	if next_scene.is_empty():
		print("[Chapter1] next_scene belum diisi. Isi lewat Inspector (node Chapter1).")
		# Supaya masih bisa dites: layar kembali terang dan Alto bisa digerakkan lagi.
		alto.can_move = true
		create_tween().tween_property(fade, "color:a", 0.0, 1.0)
		return
	get_tree().change_scene_to_file(next_scene)
