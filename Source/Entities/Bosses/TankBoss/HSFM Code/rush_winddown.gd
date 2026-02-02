extends HFSM

var ended: bool = false 

func check_transition(_delta) -> TransitionData:
	if animation_ended():
		#return TransitionData.new(true, "RushWindup")
		get_parent().ended = true
	return TransitionData.new(false, "")

func on_enter():
	ended = false
	character.velocity = Vector2.ZERO
