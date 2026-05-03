extends Node
class_name ShadowAnimalWolfAttack

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func begin_animal_wolf_circle() -> void:
	if boss == null or not boss.has_target():
		return

	var offset := boss.global_position - boss.player.global_position
	if is_zero_approx(offset.length_squared()):
		offset = Vector2.RIGHT * boss.get_animal_wolf_circle_radius()

	boss._animal_wolf_circle_start_angle = offset.angle()
	set_animal_wolf_circle_progress(0.0)

func set_animal_wolf_circle_progress(progress: float) -> void:
	if boss == null or not boss.has_target():
		if boss:
			boss.stop_motion()
		return

	var orbit_progress := clampf(progress, 0.0, 1.0)
	var orbit_sign := 1.0 if boss.orbit_direction >= 0.0 else -1.0
	var radius := boss.get_animal_wolf_circle_radius()
	var angle := boss._animal_wolf_circle_start_angle + orbit_sign * TAU * orbit_progress
	var offset := Vector2.RIGHT.rotated(angle) * radius
	boss.global_position = boss.player.global_position + offset
	boss.stop_motion()

	var tangent_direction := Vector2(-sin(angle), cos(angle)) * orbit_sign
	boss._face_direction(tangent_direction)
