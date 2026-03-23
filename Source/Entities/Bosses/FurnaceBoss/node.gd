extends HFSM

var timer := 0.0

func on_enter():
	if animator.has_animation("RESET"):
		animator.play("RESET")
		animator.advance(0.0)
	animator.play(animation)
	timer = animator.get_animation(animation).length

func update(delta):
	timer -= delta

func check_transition(_delta) -> TransitionData:
	if timer <= 0.0:
		var alive_state := get_parent() as HFSM
		if alive_state and alive_state.has_method("get_next_attack"):
			return TransitionData.new(true, alive_state.get_next_attack())
		return TransitionData.new(true, "Charge")
		

	return TransitionData.new(false, "")
