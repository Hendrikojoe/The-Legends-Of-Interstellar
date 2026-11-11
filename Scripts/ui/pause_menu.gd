extends CanvasLayer
## Pause menu global (autoload "PauseMenu").
##
## Tekan Esc / P (atau tombol Start di gamepad) kapan saja saat bermain untuk menjeda game.
## Menu ini tidak muncul di Menu Utama. Saat terbuka, seluruh game (fisika, tween, timer
## battle, animasi) berhenti lewat get_tree().paused; hanya menu ini yang tetap berjalan
## (process_mode = Always).

const MENU_SCENE := "res://Scenes/ui/main_menu.tscn"
const PAUSE_ACTION := "pause"

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_pause_action()
	hide()
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(PAUSE_ACTION) or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if visible:
		close()
	elif _can_pause():
		open()


## Pause hanya saat sedang bermain (bukan di Menu Utama / saat belum ada scene).
func _can_pause() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path != MENU_SCENE


func open() -> void:
	if visible:
		return
	get_tree().paused = true
	show()
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false


func _on_restart_pressed() -> void:
	close()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	close()
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _ensure_pause_action() -> void:
	if InputMap.has_action(PAUSE_ACTION):
		return
	InputMap.add_action(PAUSE_ACTION)
	for keycode: Key in [KEY_ESCAPE, KEY_P]:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(PAUSE_ACTION, key_event)
	var pad_event := InputEventJoypadButton.new()
	pad_event.button_index = JOY_BUTTON_START
	InputMap.action_add_event(PAUSE_ACTION, pad_event)
