extends Node2D
## Chapter 1 End - Monolog Alto setelah mengalahkan Slimy sebelum menuju Chapter 2.

@export_file("*.tscn") var next_scene: String = "res://Scenes/chapters/chapter_2.tscn"

const DIALOGUE := [
	{
		"speaker": "Alto",
		"text": "Fiuh... pertarungan tadi lumayan juga.",
	},
	{
		"speaker": "Alto",
		"text": "Lebih baik aku langsung melanjutkan perjalanan.",
	},
	{
		"speaker": "Alto",
		"text": "*Grrr...* Ah, perutku berbunyi... Kok tiba-tiba aku lapar sekali ya? Semoga di jalan nanti ada makanan...",
	},
]

var _leaving: bool = false

@onready var alto: CharacterBody2D = $Alto
@onready var dialogue_box = $DialogueBox
@onready var fade: ColorRect = $FadeLayer/Fade


func _ready() -> void:
	alto.can_move = false
	alto.camera.enabled = false
	fade.color.a = 1.0

	# Fade in dari hitam
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 1.0)
	await tween.finished

	# Mulai dialog
	dialogue_box.start(DIALOGUE)
	await dialogue_box.dialogue_finished

	# Selesai dialog -> Alto melangkah lalu fade out ke Chapter 2
	_end_scene()


func _end_scene() -> void:
	if _leaving:
		return
	_leaving = true
	alto.auto_direction = 1.0

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)
	await tween.finished

	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)

