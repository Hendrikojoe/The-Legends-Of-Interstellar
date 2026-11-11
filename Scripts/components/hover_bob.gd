extends Node2D
## Gerakan naik-turun pelan (melayang). Pasang di Sprite2D / Node2D mana pun.

@export var amplitude: float = 6.0
@export var period: float = 2.2


func _ready() -> void:
	var base_y := position.y
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", base_y - amplitude, period / 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", base_y, period / 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
