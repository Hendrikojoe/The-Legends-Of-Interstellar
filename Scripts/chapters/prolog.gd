extends Node2D

@export_file("*.tscn") var next_scene: String = ""

@export_group("Intro")
@export var camera_pan_duration: float = 5.0
@export var camera_start_height: float = 1500.0
@export var camera_final_offset: Vector2 = Vector2(0.0, -120.0)

const DIALOGUE := [
	{
		"speaker": "Alto",
		"text": "Yang Mulia! Saya mendengar kabar tentang Putri Ellie. Izinkan saya pergi untuk mencarinya!",
	},
	{
		"speaker": "Raja Interstellar",
		"text": "Alto... Anak muda, kau harus tahu bahwa yang dihadapi bukanlah musuh biasa. Brok tinggal di sebuah goa tersembunyi di balik pegunungan yang jarang dijamah. Perjalanan ini sangat berbahaya. Berhati-hatilah.",
	},
	{
		"speaker": "Alto",
		"text": "Jangan khawatir, Yang Mulia. Apa pun rintangannya, saya berjanji... saya akan membawa Putri Ellie pulang dengan selamat!",
	},
	{
		"speaker": "Raja Interstellar",
		"text": "Baiklah jika itu keputusanmu. Ambillah kristal ini; ia akan membantumu memancarkan cahaya di tempat-tempat paling gelap dan mengeluarkan serangan bercahaya saat kau membutuhkannya.",
	},
	{
		"speaker": "Alto",
		"text": "Terima kasih, Yang Mulia. Saya akan menjaga kepercayaan ini.",
	},
]

var _intro_playing: bool = false
var _intro_tween: Tween

@onready var alto = $Alto
@onready var king = $King
@onready var dialogue_box = $DialogueBox
@onready var fade: ColorRect = $IntroLayer/Fade
@onready var title: Label = $IntroLayer/PrologTitle


func _ready() -> void:
	king.interacted.connect(_on_king_interacted)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	if _intro_playing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_intro_tween.kill()
		_on_intro_finished()


func _play_intro() -> void:
	_intro_playing = true
	alto.can_move = false
	king.enabled = false

	fade.color.a = 1.0
	title.modulate.a = 0.0
	alto.camera.offset = camera_final_offset + Vector2(0.0, -camera_start_height)

	_intro_tween = create_tween()
	_intro_tween.tween_property(title, "modulate:a", 1.0, 1.0)
	_intro_tween.tween_interval(1.0)
	_intro_tween.tween_property(fade, "color:a", 0.0, 1.5)
	_intro_tween.parallel().tween_property(alto.camera, "offset", camera_final_offset, camera_pan_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_intro_tween.parallel().tween_property(title, "modulate:a", 0.0, 1.5) \
		.set_delay(maxf(camera_pan_duration - 1.5, 0.0))
	_intro_tween.tween_callback(_on_intro_finished)


func _on_intro_finished() -> void:
	_intro_playing = false
	fade.color.a = 0.0
	title.modulate.a = 0.0
	alto.camera.offset = camera_final_offset
	alto.can_move = true
	king.enabled = true


func _on_king_interacted() -> void:
	alto.can_move = false
	king.enabled = false
	dialogue_box.start(DIALOGUE)


func _on_dialogue_finished() -> void:
	alto.has_crystal = true
	_end_prolog()


func _end_prolog() -> void:
	alto.auto_direction = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 2.0)
	tween.tween_callback(_change_to_next_scene)


func _change_to_next_scene() -> void:
	if next_scene.is_empty():
		print("[Prolog] next_scene belum diisi. Isi lewat Inspector (node Prolog).")
		alto.auto_direction = 0.0
		alto.can_move = true
		create_tween().tween_property(fade, "color:a", 0.0, 1.0)
		return
	get_tree().change_scene_to_file(next_scene)
