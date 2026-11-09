@tool
extends Node2D

@export var radius: float = 20.0:
	set(value):
		radius = value
		queue_redraw()

@export var height: float = 96.0:
	set(value):
		height = value
		queue_redraw()

@export var color: Color = Color(0.4, 0.8, 1.0, 1.0):
	set(value):
		color = value
		queue_redraw()

@export var facing: int = 1:
	set(value):
		facing = value
		queue_redraw()


func set_capsule_height(new_height: float) -> void:
	height = new_height


func _draw() -> void:
	var r: float = minf(radius, height / 2.0)
	var bottom_center := Vector2(0.0, -r)
	var top_center := Vector2(0.0, -(height - r))
	draw_circle(bottom_center, r, color)
	draw_circle(top_center, r, color)
	draw_rect(Rect2(-r, -(height - r), r * 2.0, height - r * 2.0), color)
	draw_circle(top_center + Vector2(r * 0.45 * facing, -r * 0.1), r * 0.22, Color.WHITE)
