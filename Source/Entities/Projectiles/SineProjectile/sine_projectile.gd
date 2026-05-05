extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _animation_time := 0.0
var timer_node: Timer = Timer.new()

func _ready():
	animated_sprite.animation = &"default"
	animated_sprite.frame = 0
	if timer_node.get_parent() == null:
		add_child(timer_node)
	timer_node.one_shot = true
	timer_node.autostart = false
	timer_node.wait_time = 10.0
	if not timer_node.timeout.is_connected(on_timer_timeout):
		timer_node.timeout.connect(on_timer_timeout)
	timer_node.start()

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

func on_timer_timeout():
	queue_free()
