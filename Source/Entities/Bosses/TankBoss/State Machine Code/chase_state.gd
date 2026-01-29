extends State

@export var chase_speed := 75.0

func physics_process_state(_delta: float):
	if not target:
		return
	var direction = target.global_position - entity.global_position
	
	entity.velocity = direction.normalized() * chase_speed
	entity.move_and_slide()

var idle_timer : Timer

func enter():
	entity.velocity = Vector2.ZERO
	idle_timer = Timer.new()
	idle_timer.wait_time = randf_range(0, 0.5)
	idle_timer.timeout.connect(on_timeout)
	idle_timer.autostart = true
	add_child(idle_timer)

func on_timeout():
	transitioned.emit(self, "tweak")
	
func exit():
	idle_timer.stop()
	idle_timer.timeout.disconnect(on_timeout)
	idle_timer.queue_free()
	idle_timer = null
