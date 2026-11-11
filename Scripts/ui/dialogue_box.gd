extends CanvasLayer

signal dialogue_finished

@export var chars_per_second: float = 45.0

var is_active: bool = false

var _lines: Array = []
var _index: int = 0
var _typing: bool = false
var _tween: Tween

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/Margin/VBox/NameLabel
@onready var text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var hint_label: Label = $Panel/Margin/VBox/HintLabel


func _ready() -> void:
	panel.hide()


func start(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	is_active = true
	panel.show()
	_show_line()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
		else:
			_next_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	name_label.text = speaker
	name_label.visible = not speaker.is_empty()
	text_label.text = text
	text_label.visible_ratio = 0.0
	hint_label.hide()

	_typing = true
	if _tween:
		_tween.kill()
	var duration: float = maxf(text.length() / chars_per_second, 0.05)
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typing_done)


func _finish_typing() -> void:
	if _tween:
		_tween.kill()
	text_label.visible_ratio = 1.0
	_on_typing_done()


func _on_typing_done() -> void:
	_typing = false
	hint_label.show()


func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	is_active = false
	panel.hide()
	dialogue_finished.emit()
