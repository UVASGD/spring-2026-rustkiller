extends HFSM

func check_transition(_delta) -> TransitionData:
	return TransitionData.new(false, "")

func on_enter():
	$Charge_Sound.play()
	character.velocity = direction_to_player() * 167
func update(_delta : float):
	character.move_and_slide()

func choose_internal_move() -> TransitionData:
	return TransitionData.new(true, "Idle")
	
