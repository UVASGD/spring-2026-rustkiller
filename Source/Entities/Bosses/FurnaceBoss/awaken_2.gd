extends HFSM

func on_enter():
	if character.has_method("begin_phase_2"):
		character.begin_phase_2()

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Alive")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")

func on_exit():
	if character.has_method("complete_phase_2_transition"):
		character.complete_phase_2_transition()
