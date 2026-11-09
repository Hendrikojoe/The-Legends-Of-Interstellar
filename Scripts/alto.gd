extends CharacterBody2D

const InputSetup = preload("res://Scripts/input_setup.gd")

@export_group("Movement")
@export var move_speed: float = 280.0
@export var crouch_speed: float = 110.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_velocity: float = -560.0

@export_group("Collision")
@export var stand_height: float = 96.0
@export var crouch_height: float = 56.0

var can_move: bool = true
var auto_direction: float = 0.0
var is_crouching: bool = false
var facing: int = 1
var has_crystal: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Node2D = $Body
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	InputSetup.ensure_actions()
	add_to_group("player")
	collision.shape = collision.shape.duplicate()
	_apply_height(stand_height)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	var direction := _get_direction()
	_update_crouch()

	if can_move and is_on_floor() and not is_crouching and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var speed := crouch_speed if is_crouching else move_speed
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		_set_facing(1 if direction > 0.0 else -1)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()


func _get_direction() -> float:
	if not can_move:
		return auto_direction
	return Input.get_axis("move_left", "move_right")


func _update_crouch() -> void:
	var wants_crouch := can_move and is_on_floor() and Input.is_action_pressed("crouch")
	if wants_crouch and not is_crouching:
		_set_crouch(true)
	elif not wants_crouch and is_crouching and _can_stand():
		_set_crouch(false)


func _can_stand() -> bool:
	var extra := stand_height - crouch_height
	return not test_move(global_transform, Vector2(0.0, -extra))


func _set_crouch(value: bool) -> void:
	is_crouching = value
	_apply_height(crouch_height if value else stand_height)


func _apply_height(height: float) -> void:
	var capsule := collision.shape as CapsuleShape2D
	capsule.height = height
	collision.position.y = -height / 2.0
	if body_visual.has_method("set_capsule_height"):
		body_visual.set_capsule_height(height)


func _set_facing(new_facing: int) -> void:
	facing = new_facing
	if "facing" in body_visual:
		body_visual.facing = new_facing
