extends Control

@export_file("*.tscn") var prolog_scene: String = "res://prolog.tscn"
@export_file("*.tscn") var deck_scene: String = ""
@export_file("*.tscn") var settings_scene: String = ""

@onready var play_button: Button = $Content/Layout/MenusButtons/PlayButton
@onready var deck_button: Button = $Content/Layout/MenusButtons/DeckButton
@onready var settings_button: Button = $Content/Layout/MenusButtons/SettingsButton
@onready var quit_button: Button = $Content/Layout/MenusButtons/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	deck_button.pressed.connect(_on_deck_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	play_button.grab_focus()


func _on_play_pressed() -> void:
	_go_to_scene("res://Scenes/scene/prolog.tscn", "Prolog")


func _on_deck_pressed() -> void:
	_go_to_scene(deck_scene, "Deck")


func _on_settings_pressed() -> void:
	_go_to_scene(settings_scene, "Settings")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _go_to_scene(path: String, button_name: String) -> void:
	if path.is_empty():
		print("[MainMenu] Scene untuk tombol '%s' belum diisi." % button_name)
		return

	get_tree().change_scene_to_file(path)
