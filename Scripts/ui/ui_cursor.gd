extends Node
## Mengganti kursor mouse dengan bulu dari pack Mana Soul GUI (autoload "UiCursor").
##
## Gambar ada di Assets/ui/ (cursor_arrow.png & cursor_hand.png). Hotspot = ujung bulu
## di pojok kiri atas gambar.

const ARROW := preload("res://Assets/ui/cursor_arrow.png")
const HAND := preload("res://Assets/ui/cursor_hand.png")
const HOTSPOT := Vector2(1.0, 1.0)


func _ready() -> void:
	Input.set_custom_mouse_cursor(ARROW, Input.CURSOR_ARROW, HOTSPOT)
	Input.set_custom_mouse_cursor(HAND, Input.CURSOR_POINTING_HAND, HOTSPOT)
