extends State

@export var tweak_speed := 500.0
@export var dash_duration := 0.3
@export var dash_cooldown := 0.5

var dash_timer: Timer
var cooldown_timer: Timer
var target_position: Vector2
var is_dashing: bool = false

func enter():
	entity.velocity = Vector2.ZERO
	
	dash_timer = Timer.new()
	dash_timer.wait_time = dash_duration
	dash_timer.timeout.connect(on_dash_complete)
	dash_timer.one_shot = true
	add_child(dash_timer)
	
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = dash_cooldown
	cooldown_timer.timeout.connect(on_cooldown_complete)
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	
	_start_dash()

func physics_process_state(_delta: float):
	if is_dashing:
		var direction = target_position - entity.global_position
		entity.velocity = direction.normalized() * tweak_speed
		entity.move_and_slide()
		
		if entity.global_position.distance_to(target_position) < 10.0:
			on_dash_complete()

func _start_dash():
	var behind_offset = (target.global_position - entity.global_position).normalized() * -80.0
	var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
	target_position = target.global_position + behind_offset + random_offset
	
	is_dashing = true
	dash_timer.start()

func on_dash_complete():
	is_dashing = false
	entity.velocity = Vector2.ZERO
	dash_timer.stop()
	
	if randf() < 0.6:
		cooldown_timer.start()
	else:
		transitioned.emit(self, "chase")

func on_cooldown_complete():
	if randf() < 0.7:
		_start_dash()
	else:
		transitioned.emit(self, "chase")

func exit():
	is_dashing = false
	
	if dash_timer:
		dash_timer.stop()
		dash_timer.timeout.disconnect(on_dash_complete)
		dash_timer.queue_free()
		dash_timer = null
	
	if cooldown_timer:
		cooldown_timer.stop()
		cooldown_timer.timeout.disconnect(on_cooldown_complete)
		cooldown_timer.queue_free()
		cooldown_timer = null
