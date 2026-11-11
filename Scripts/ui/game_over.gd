extends CanvasLayer
## Layar Game Over yang bisa dipakai ulang di scene mana pun.
##
##   game_over.show_game_over("ALTO KALAH", "Pesan singkat di bawah judul.")

const MAIN_MENU_PATH := "res://Scenes/ui/main_menu.tscn"

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $Overlay/Center/VBox/TitleLabel
@onready var message_label: Label = $Overlay/Center/VBox/MessageLabel
@onready var retry_button: Button = $Overlay/Center/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Overlay/Center/VBox/Buttons/MainMenuButton


func _ready() -> void:
	hide()
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_game_over(title: String, message: String = "") -> void:
	title_label.text = title
	message_label.text = message
	message_label.visible = not message.is_empty()
	overlay.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
	else:
		print("[GameOver] Scene menu tidak ditemukan: %s" % MAIN_MENU_PATH)
