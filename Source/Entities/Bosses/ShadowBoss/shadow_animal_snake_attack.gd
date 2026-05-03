extends Node
class_name ShadowAnimalSnakeAttack

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func animal_move_toward_target(delta: float) -> void:
	if boss == null:
		return
	if not boss.has_target():
		boss.stop_motion()
		return

	var direction := boss.global_position.direction_to(boss.player.global_position)
	var desired_velocity := direction * boss.animal_move_speed
	boss.velocity = boss.velocity.move_toward(desired_velocity, boss.acceleration * delta * 100.0)
	boss._face_direction(direction)

func is_near_animal_attack_target() -> bool:
	return boss != null and boss.has_target() and boss.distance_to_target() <= boss.animal_attack_stop_distance
