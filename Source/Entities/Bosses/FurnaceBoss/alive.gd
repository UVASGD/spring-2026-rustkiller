extends HFSM

@export var rush_series: HFSM

var did_charge := false

func check_transition(_delta) -> TransitionData:
	#if imdeadlmaoo():
		#return TransitionData.new(true, "death")
	#if rush_ended():
		#return TransitionData.new(true, "Idle")	
		#pass
	return TransitionData.new(false, "")
	
func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Charge")
	
