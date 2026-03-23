extends HFSM

var timer := 0.0

func on_enter():
	#animator.play("idle")
	#timer = animator.get_animation("idle_1").length
	pass
func update(delta):
	timer -= delta

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		var alive_state := get_parent() as HFSM
		if alive_state and alive_state.has_method("get_next_attack"):
			return TransitionData.new(true, alive_state.get_next_attack())
		return TransitionData.new(true, "Charge")
		

	return TransitionData.new(false, "")
