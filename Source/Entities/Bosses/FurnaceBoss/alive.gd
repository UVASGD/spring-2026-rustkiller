extends HFSM

@export var rush_series: HFSM

var did_charge := false
var attack_cycle_phase_1: Array[String] = ["Charge", "Shoot", "Combo"]
var attack_cycle_phase_2: Array[String] = ["Charge2", "Shoot2", "Combo2"]
@export var use_predetermined_order: bool = false
var attack_cycle_index: int = 0
var last_attack: String = ""
var using_phase_2_cycle := false

func check_transition(_delta) -> TransitionData:
	if character and character.has_method("should_enter_phase_2") and character.should_enter_phase_2():
		return TransitionData.new(true, "Awaken2")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, get_next_attack())

func get_next_attack() -> String:
	var attack_cycle := get_attack_cycle()

	if use_predetermined_order:
		var ordered_attack := attack_cycle[attack_cycle_index % attack_cycle.size()]
		attack_cycle_index = (attack_cycle_index + 1) % attack_cycle.size()
		last_attack = ordered_attack
		return ordered_attack

	var available_attacks := attack_cycle.filter(func(attack: String) -> bool: return attack != last_attack)
	if available_attacks.is_empty():
		available_attacks = attack_cycle

	var attack_name: String = available_attacks[randi() % available_attacks.size()]
	last_attack = attack_name
	return attack_name

func get_attack_cycle() -> Array[String]:
	var is_phase_2_active: bool = character != null and character.has_method("is_phase_2") and character.is_phase_2()
	if is_phase_2_active != using_phase_2_cycle:
		using_phase_2_cycle = is_phase_2_active
		attack_cycle_index = 0
		last_attack = ""

	if using_phase_2_cycle:
		return attack_cycle_phase_2
	return attack_cycle_phase_1
