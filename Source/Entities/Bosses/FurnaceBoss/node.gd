extends HFSM

var timer := 0.0

func on_enter():
	if animator.has_animation("RESET"):
		animator.play("RESET")
		animator.advance(0.0)

	var active_animation := get_active_animation_name()
	animation = active_animation
	animator.play(active_animation)
	timer = 0.1

func update(delta):
	timer -= delta

func check_transition(_delta) -> TransitionData:
	if timer <= 0.0:
		var alive_state := get_parent() as HFSM
		if alive_state and alive_state.has_method("get_next_attack"):
			return TransitionData.new(true, alive_state.get_next_attack())
		return TransitionData.new(true, "Charge")

	return TransitionData.new(false, "")

func get_active_animation_name() -> String:
	if animation == "idle_1" and character and character.has_method("is_phase_2") and character.is_phase_2():
		return "idle_2"
	return animation
