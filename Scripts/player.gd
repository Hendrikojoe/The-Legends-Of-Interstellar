
extends CharacterBody2D

@export var speed: float = 200.0

@export var gravity: float = 980.0

@onready var sprite = $AnimatedSprite2D


func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


	var direction = Input.get_axis(
		"move_left",
        "move_right"
	)

	velocity.x = direction * speed


	if direction < 0:
		sprite.flip_h = true

	elif direction > 0:
		sprite.flip_h = false


	move_and_slide()
