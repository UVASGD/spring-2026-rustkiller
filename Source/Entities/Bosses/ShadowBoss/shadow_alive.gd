extends HFSM

func check_transition(_delta: float) -> TransitionData:
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	if character and character.has_method("should_start_in_player_phase") and character.should_start_in_player_phase():
		return TransitionData.new(true, "PlayerPhase")
	return TransitionData.new(true, "AnimalPhase")
