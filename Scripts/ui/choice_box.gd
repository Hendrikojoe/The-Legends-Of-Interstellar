extends CanvasLayer
## Kotak pilihan (2-4 opsi). Pemakaian:
##
##   var pilihan: int = await choice_box.ask(["Ambil", "Jangan"], "Apa yang akan Alto lakukan?")
##
## Hasilnya index opsi yang dipilih (0, 1, ...).
## Kontrol: panah atas/bawah untuk pindah, Enter/Space/E untuk memilih, atau klik mouse.

signal chosen(index: int)

var is_active: bool = false

@onready var panel: PanelContainer = $Panel
@onready var prompt_label: Label = $Panel/Margin/VBox/PromptLabel
@onready var options_box: VBoxContainer = $Panel/Margin/VBox/Options


func _ready() -> void:
	panel.hide()


func ask(options: Array, prompt: String = "") -> int:
	for child in options_box.get_children():
		options_box.remove_child(child)
		child.queue_free()

	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()

	for i in options.size():
		var button := Button.new()
		button.text = str(options[i])
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_on_option_pressed.bind(i))
		options_box.add_child(button)

	is_active = true
	panel.show()
	(options_box.get_child(0) as Button).grab_focus.call_deferred()

	var index: int = await chosen
	is_active = false
	panel.hide()
	return index


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("interact"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button:
			get_viewport().set_input_as_handled()
			(focused as Button).pressed.emit()


func _on_option_pressed(index: int) -> void:
	if is_active:
		chosen.emit(index)
