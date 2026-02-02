extends HFSM

@export var rush_series: HFSM

func check_transition(_delta) -> TransitionData:
	#if imdeadlmaoo():
		#return TransitionData.new(true, "death")
	if rush_ended():
		return TransitionData.new(true, "Idle")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "RushSeries")

func rush_ended() -> bool:
	return rush_series.ended
