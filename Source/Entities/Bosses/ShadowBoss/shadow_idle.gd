extends HFSM

func check_transition(_delta: float) -> TransitionData:
	return TransitionData.new(false, "")
