extends Node2D
## Chapter 2 - Sang Koki Sayuran (Desa Brocolo).
##
## Alur:
##   1. Layar hitam + judul CHAPTER 2 / Sang Koki Sayuran, lalu kamera turun pelan.
##   2. Alto yang kelaparan menemukan sayuran -> tekan E.
##   3. Pilihan:
##        - Ambil sayuran   -> Carrota muncul, dialog, lanjut ke next_scene (battle Carrota).
##        - Jangan diambil  -> Alto mati kelaparan di perjalanan -> Game Over.

## Scene berikutnya (battle melawan Carrota). Drag file .tscn-nya ke slot ini di Inspector.
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

@export_group("Carrota")
## Posisi X tempat Carrota mulai muncul (default: sekitar pintu rumah wortel di background).
@export var carrota_spawn_x: float = -583.0
## Jarak berhenti Carrota dari Alto (piksel).
@export var carrota_stop_distance: float = 300.0
## Lama Carrota berlari menghampiri Alto (detik).
@export var carrota_run_duration: float = 1.2

# ------------------------------------------------------------------
# TEKS CERITA - edit di sini. speaker kosong ("") = narasi tanpa nama.
# ------------------------------------------------------------------

## Dialog saat Alto berjalan dan merasa sangat lapar di tengah jalan.
const DIALOGUE_HUNGER := [
	{
		"speaker": "Alto",
		"text": "aduh aku sangat lapar ,sekali ",
	},
]

## Sebelum pilihan. (Teks ini draf dari saya, silakan ganti.)
const DIALOGUE_BEFORE_CHOICE := [
	{
		"speaker": "Alto",
		"text": "Perutku... sudah tidak kuat lagi. Sudah berhari-hari aku berjalan tanpa makan.",
	},
	{
		"speaker": "Alto",
		"text": "Itu... sayuran? Tidak ada siapa pun di sekitar sini. Sepertinya tumbuh liar...",
	},
]

const PROMPT_CHOICE := "Apa yang akan Alto lakukan?"
const CHOICES := ["Ambil sayuran", "Jangan diambil"]

## Jalur AMBIL: sebelum Carrota muncul.
const DIALOGUE_TAKE_BEFORE_CARROTA := [
	{
		"speaker": "Alto",
		"text": "Syukurlah... Perutku sudah tidak tertahan lagi. Aku hanya mengambil sedikit saja, semoga pemiliknya tidak keberatan.",
	},
]

## Jalur AMBIL: setelah Carrota muncul.
const DIALOGUE_TAKE_WITH_CARROTA := [
	{
		"speaker": "Carrota",
		"text": "BERHENTI!",
	},
	{
		"speaker": "Alto",
		"text": "W-wah! Siapa kau?!",
	},
	{
		"speaker": "Carrota",
		"text": "Siapa yang memberimu izin mengambil sayuran di kebunku?!",
	},
	{
		"speaker": "Alto",
		"text": "Maaf! Aku tidak sengaja! Aku mengira sayuran ini tumbuh liar, dan... aku sudah berjalan sangat jauh tanpa makan, jadi aku benar-benar lapar...",
	},
	{
		"speaker": "Carrota",
		"text": "Alasan! Kau pikir sayuran ini tumbuh sendiri begitu saja? Aku sudah bekerja keras setiap hari menanam dan merawat semua tanaman ini dengan penuh keringat!",
	},
	{
		"speaker": "Alto",
		"text": "Aku mengerti, tapi kumohon... aku hanya butuh sedikit makanan untuk memulihkan tenagaku agar bisa melanjutkan perjalanan...",
	},
	{
		"speaker": "Carrota",
		"text": "Pencuri tetaplah pencuri! Kau tidak akan kubiarkan lolos begitu saja. Rasakan ini: Raining Soup!",
	},
	{
		"speaker": "Alto",
		"text": "Wah, gawat! Kalau begitu, aku terpaksa membela diri!",
	},
]

## Jalur JANGAN DIAMBIL. (Draf dari saya, silakan ganti.)
const DIALOGUE_REFUSE := [
	{
		"speaker": "Alto",
		"text": "Tidak... ini bukan milikku. Aku tidak boleh mengambil sesuatu tanpa izin pemiliknya.",
	},
]

const NARRATION_STARVE := [
	{
		"speaker": "",
		"text": "Alto memilih melanjutkan perjalanan tanpa menyentuh sayuran itu.",
	},
	{
		"speaker": "",
		"text": "Perutnya makin perih di setiap langkah. Jalan menuju monster ketiga masih sangat jauh, dan tidak ada lagi desa di sepanjang jalan.",
	},
	{
		"speaker": "",
		"text": "Hari demi hari berlalu. Langkah Alto makin pelan, pandangannya makin kabur...",
	},
	{
		"speaker": "",
		"text": "Di tengah perjalanan, tenaganya benar-benar habis. Alto tak pernah sampai ke tujuannya.",
	},
]

const GAME_OVER_TITLE := "ALTO MATI KELAPARAN"
const GAME_OVER_MESSAGE := "Alto tumbang di tengah jalan sebelum sempat menyelamatkan Putri Ellie."

var _intro_playing: bool = false
var _intro_tween: Tween
var _hunger_triggered: bool = false

@onready var alto = $Alto
@onready var vegetables = $Vegetables
@onready var carrota: Node2D = $Carrota
@onready var dialogue_box = $DialogueBox
@onready var choice_box = $ChoiceBox
@onready var game_over = $GameOver
@onready var fade: ColorRect = $IntroLayer/Fade
@onready var title_box: Control = $IntroLayer/TitleBox
@onready var hunger_trigger: Area2D = $HungerTrigger


func _ready() -> void:
	alto.camera.limit_right = camera_limit_right
	vegetables.interacted.connect(_on_vegetables_interacted)
	if hunger_trigger:
		hunger_trigger.body_entered.connect(_on_hunger_trigger_body_entered)
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
	vegetables.enabled = false

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
	vegetables.enabled = true


# -------------------------------------------------------- Trigger Lapar

func _on_hunger_trigger_body_entered(body: Node2D) -> void:
	if _hunger_triggered or _intro_playing:
		return
	if not body.is_in_group("player"):
		return
	_hunger_triggered = true
	if is_instance_valid(hunger_trigger):
		hunger_trigger.set_deferred("monitoring", false)
	alto.can_move = false
	alto.velocity.x = 0.0
	await _say(DIALOGUE_HUNGER)
	alto.can_move = true


# ------------------------------------------------------ Sayuran & pilihan

func _on_vegetables_interacted() -> void:
	alto.can_move = false
	vegetables.enabled = false
	await _say(DIALOGUE_BEFORE_CHOICE)

	var choice: int = await choice_box.ask(CHOICES, PROMPT_CHOICE)
	if choice == 0:
		await _take_vegetables()
	else:
		await _leave_vegetables()


## Jalur 1: sayuran diambil -> Carrota memergoki -> (battle nanti).
func _take_vegetables() -> void:
	vegetables.hide()
	await _say(DIALOGUE_TAKE_BEFORE_CARROTA)
	await _carrota_enter()
	await _say(DIALOGUE_TAKE_WITH_CARROTA)
	_end_chapter()


## Jalur 2: sayuran tidak diambil -> Alto mati kelaparan -> Game Over.
func _leave_vegetables() -> void:
	await _say(DIALOGUE_REFUSE)
	await _fade_to(1.0, 1.5)
	await _say(NARRATION_STARVE)
	game_over.show_game_over(GAME_OVER_TITLE, GAME_OVER_MESSAGE)


func _carrota_enter() -> void:
	var target_x: float = maxf(alto.global_position.x - carrota_stop_distance, carrota_spawn_x)
	carrota.position = Vector2(carrota_spawn_x, 0.0)
	carrota.modulate.a = 0.0
	carrota.show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(carrota, "modulate:a", 1.0, 0.3)
	tween.tween_property(carrota, "position:x", target_x, carrota_run_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


# --------------------------------------------------------------- Helper

func _say(lines: Array) -> void:
	dialogue_box.start(lines)
	await dialogue_box.dialogue_finished


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, duration)
	await tween.finished


# --------------------------------------------------------------- Ending

func _end_chapter() -> void:
	# Belum ada battle Carrota: layar memudar hitam lalu pindah ke next_scene.
	await _fade_to(1.0, 2.0)
	if next_scene.is_empty():
		print("[Chapter2] next_scene belum diisi. Isi lewat Inspector (node Chapter2).")
		# Supaya masih bisa dites: layar kembali terang dan Alto bisa digerakkan lagi.
		alto.can_move = true
		_fade_to(0.0, 1.0)
		return
	get_tree().change_scene_to_file(next_scene)
