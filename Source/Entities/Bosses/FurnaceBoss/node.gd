extends HFSM

var timer := 0.0

func on_enter():
	animator.play("idle")
	timer = animator.get_animation("idle").length

func update(delta):
	timer -= delta

func check_transition(_delta) -> TransitionData:
	if timer <= 0:
		return TransitionData.new(true, "Charge")

	return TransitionData.new(false, "")
