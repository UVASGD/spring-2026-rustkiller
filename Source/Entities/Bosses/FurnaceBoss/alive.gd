extends HFSM

@export var rush_series: HFSM

var did_charge := false
var _attack_cycle: Array[String] = ["Charge", "Shoot"]
var _attack_cycle_index: int = 0

func check_transition(_delta) -> TransitionData:
	#if imdeadlmaoo():
		#return TransitionData.new(true, "death")
	#if rush_ended():
		#return TransitionData.new(true, "Idle")	
		#pass
	return TransitionData.new(false, "")
	
func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, get_next_attack())

func get_next_attack() -> String:
	var attack_name := _attack_cycle[_attack_cycle_index]
	_attack_cycle_index = (_attack_cycle_index + 1) % _attack_cycle.size()
	return attack_name
	
