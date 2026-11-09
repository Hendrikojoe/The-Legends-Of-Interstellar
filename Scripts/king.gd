extends Node2D

signal interacted

@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_prompt()

var _player_in_range: bool = false

@onready var zone: Area2D = $InteractZone
@onready var prompt: Label = $Prompt


func _ready() -> void:
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if enabled and _player_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_refresh_prompt()


func _refresh_prompt() -> void:
	if not is_node_ready():
		return
	prompt.visible = enabled and _player_in_range
