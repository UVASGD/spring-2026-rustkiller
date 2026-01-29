extends State

var idle_timer : Timer

func enter():
	entity.velocity = Vector2.ZERO
	
	idle_timer = Timer.new()
	idle_timer.wait_time = 0.1
	idle_timer.timeout.connect(_on_timeout)
	idle_timer.autostart = true
	add_child(idle_timer)
	

func _on_timeout():
	transitioned.emit(self, "chase")

# When leaving this state (for any reason), stop timer,
# disconnect signals, and free timer
# Technically, just queue_free() would be required, but
# I like showcasing all of the options
func exit():
	idle_timer.stop()
	idle_timer.timeout.disconnect(_on_timeout)
	idle_timer.queue_free()
	idle_timer = null
