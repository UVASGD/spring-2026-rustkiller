extends HFSM

func on_enter() -> void:
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation("player_appear")

func update(_delta: float) -> void:
	if character == null:
		return

	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

func check_transition(_delta: float) -> TransitionData:
	if _animation_finished("player_appear"):
		_clear_animation_finished("player_appear")
		return TransitionData.new(true, "Walk")
	return TransitionData.new(false, "")

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return false

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)
