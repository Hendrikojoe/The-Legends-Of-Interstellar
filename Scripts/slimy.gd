extends Node2D
## Slimy - monster penghalang jalan di Hutan Malky.
##
## auto_trigger = true  -> dialog mulai otomatis saat Alto mendekat (Slimy menghadang).
## auto_trigger = false -> muncul prompt [E] Bicara seperti Raja di Prolog.

signal interacted

## Set false untuk mematikan interaksi (mis. saat dialog berjalan / sudah selesai).
@export var enabled: bool = true:
	set(value):
		enabled = value
		_refresh_prompt()
		_check_auto_trigger()
## true = dialog mulai sendiri begitu Alto masuk ke InteractZone.
@export var auto_trigger: bool = true

var _player_in_range: bool = false

@onready var zone: Area2D = $InteractZone
@onready var prompt: Label = $Prompt


func _ready() -> void:
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if auto_trigger:
		return
	if enabled and _player_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_refresh_prompt()
		_check_auto_trigger()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_refresh_prompt()


func _check_auto_trigger() -> void:
	if not is_node_ready():
		return
	if auto_trigger and enabled and _player_in_range:
		# Ditunda supaya aman dipanggil dari dalam callback physics.
		interacted.emit.call_deferred()


func _refresh_prompt() -> void:
	if not is_node_ready():
		return
	prompt.visible = enabled and _player_in_range and not auto_trigger
