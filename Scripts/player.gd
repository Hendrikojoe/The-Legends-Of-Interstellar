
extends CharacterBody2D

@export var speed: float = 200.0

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta):

	# Mengambil input gerakan horizontal dan vertikal
	var direction_x = Input.get_axis("move_left", "move_right")
	var direction_y = Input.get_axis("move_up", "move_down")

	# Mengatur gerakan melayang
	velocity.x = direction_x * speed
	velocity.y = direction_y * speed

	# Mengatur arah sprite
	if direction_x < 0:
		sprite.flip_h = true
	elif direction_x > 0:
		sprite.flip_h = false

	move_and_slide()
