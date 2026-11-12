extends Control

@export_file("*.tscn") var play_scene: String = ""
@export_file("*.tscn") var deck_scene: String = ""
@export_file("*.tscn") var settings_scene: String = ""

@onready var background: Node = $Background
@onready var play_button: Button = $Content/Layout/MenusButtons/PlayButton

@onready var settings_button: Button = $Content/Layout/MenusButtons/SettingsButton
@onready var quit_button: Button = $Content/Layout/MenusButtons/QuitButton


func _ready() -> void:
	# Video latar di-loop lewat properti `loop`; sambungan ini cadangan untuk versi Godot yang tidak mengulang otomatis.
	if background is VideoStreamPlayer:
		background.finished.connect(background.play)
	play_button.pressed.connect(_on_play_pressed)
	
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	_connect_pause_menu()


func _connect_pause_menu() -> void:
	if has_node("/root/PauseMenu"):
		var pause_menu = get_node("/root/PauseMenu")
		if pause_menu.has_signal("closed") and not pause_menu.closed.is_connected(_on_pause_menu_closed):
			pause_menu.closed.connect(_on_pause_menu_closed)


func _on_pause_menu_closed() -> void:
	if is_inside_tree() and is_visible_in_tree() and is_instance_valid(settings_button):
		settings_button.grab_focus()


func _on_play_pressed() -> void:
	_go_to_scene(play_scene, "Play")


func _on_deck_pressed() -> void:
	_go_to_scene(deck_scene, "Deck")


func _on_settings_pressed() -> void:
	if settings_scene.is_empty() or settings_scene.ends_with("pause_menu.tscn"):
		_show_pause_menu()
	else:
		_go_to_scene(settings_scene, "Settings")


func _show_pause_menu() -> void:
	if has_node("/root/PauseMenu"):
		var pause_menu = get_node("/root/PauseMenu")
		_connect_pause_menu()
		pause_menu.open()
	else:
		var pause_scene = load("res://Scenes/ui/pause_menu.tscn")
		if pause_scene:
			var pause_instance = pause_scene.instantiate()
			pause_instance.name = "PauseMenu"
			get_tree().root.add_child(pause_instance)
			_connect_pause_menu()
			if pause_instance.has_method("open"):
				pause_instance.open()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _go_to_scene(path: String, button_name: String) -> void:
	if path.is_empty():
		print("[MainMenu] Scene untuk tombol '%s' belum diisi." % button_name)
		return
	get_tree().change_scene_to_file(path)
