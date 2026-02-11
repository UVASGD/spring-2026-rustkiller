extends HFSM

func check_transition(_delta) -> TransitionData:
	return TransitionData.new(false, "")

func on_enter():
	character.velocity = direction_to_player() * 167
func update(_delta : float):
	
	character.move_and_slide()
