extends HFSM

func check_transition(_delta) -> TransitionData:
	return TransitionData.new(true, "Alive")
