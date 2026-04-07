extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _animation_time := 0.0

func _ready():
	animated_sprite.animation = &"default"
	animated_sprite.frame = 0

func _physics_process(delta):
	if animated_sprite.sprite_frames == null:
		return

	var animation_name: StringName = &"default"
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return

	var animation_speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if animation_speed <= 0.0:
		return

	_animation_time += delta * animation_speed
	animated_sprite.frame = int(floor(_animation_time)) % frame_count
