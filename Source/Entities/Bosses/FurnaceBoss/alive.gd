extends HFSM

@export var rush_series: HFSM

var did_charge := false
var _attack_cycle: Array[String] = ["Charge", "Shoot", "Combo"]
@export var use_predetermined_order: bool = false
var _attack_cycle_index: int = 0
var _last_attack: String = ""

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
	if use_predetermined_order:
		var ordered_attack := _attack_cycle[_attack_cycle_index]
		_attack_cycle_index = (_attack_cycle_index + 1) % _attack_cycle.size()
		_last_attack = ordered_attack
		return ordered_attack

	var available_attacks := _attack_cycle.filter(func(attack: String) -> bool: return attack != _last_attack)
	if available_attacks.is_empty():
		available_attacks = _attack_cycle

	var attack_name: String = available_attacks[randi() % available_attacks.size()]
	_last_attack = attack_name
	return attack_name
	
