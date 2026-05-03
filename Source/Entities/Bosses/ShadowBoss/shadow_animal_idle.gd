extends HFSM

var _idle_duration := 0.0

func on_enter() -> void:
	_idle_duration = _get_idle_duration()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_animal_idle_animation())

func update(_delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

func check_transition(_delta: float) -> TransitionData:
	if works_longer_than(_idle_duration):
		return TransitionData.new(true, "AnimalAttack")
	return TransitionData.new(false, "")

func _get_animal_idle_animation() -> String:
	if character and character.has_method("get_animal_idle_animation"):
		return character.get_animal_idle_animation()
	return "animal_idle"

func _get_idle_duration() -> float:
	if character and character.has_method("consume_animal_idle_duration"):
		return character.consume_animal_idle_duration()
	if character and character.has_method("get_animal_idle_duration"):
		return character.get_animal_idle_duration()
	return 1.0
