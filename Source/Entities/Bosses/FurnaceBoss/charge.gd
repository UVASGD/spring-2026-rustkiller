extends HFSM

@export var charge_time := 2
var timer := 0.0

func on_enter():
	$Charge_Sound.play()
	character.velocity = direction_to_player() * 167
	timer = charge_time

func update(delta : float):
	character.move_and_slide()
	timer -= delta

func check_transition(_delta) -> TransitionData:
	if timer <= 0:
		return TransitionData.new(true, "Pause")
	return TransitionData.new(false, "")

func choose_internal_move() -> TransitionData:
	return TransitionData.new(false, "")
