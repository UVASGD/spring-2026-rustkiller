extends HFSM

func check_transition(_delta: float) -> TransitionData:
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Alive")

