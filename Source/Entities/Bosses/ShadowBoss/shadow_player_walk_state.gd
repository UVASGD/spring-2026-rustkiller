extends Node
class_name ShadowPlayerWalkState

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func move_toward_target(delta: float) -> void:
	if boss == null:
		return
	if not boss.has_target():
		boss.velocity = boss.velocity.move_toward(Vector2.ZERO, boss.acceleration * delta * 100.0)
		return

	var direction := boss.global_position.direction_to(boss.player.global_position)
	var desired_velocity := direction * boss.move_speed
	boss.velocity = boss.velocity.move_toward(desired_velocity, boss.acceleration * delta * 100.0)
	boss._face_direction(direction)

func orbit_target(delta: float) -> void:
	if boss == null:
		return
	if not boss.has_target():
		boss.velocity = boss.velocity.move_toward(Vector2.ZERO, boss.acceleration * delta * 100.0)
		return

	var to_player := boss.player.global_position - boss.global_position
	var distance := to_player.length()
	if is_zero_approx(distance):
		boss.velocity = boss.velocity.move_toward(Vector2.ZERO, boss.acceleration * delta * 100.0)
		return

	var radial_direction := to_player / distance
	var tangent_direction := Vector2(-radial_direction.y, radial_direction.x) * signf(boss.orbit_direction)
	var radius_error := distance - boss.orbit_radius
	var correction_strength := clampf(radius_error / maxf(boss.orbit_radius, 1.0), -0.65, 0.65)
	var desired_direction := (tangent_direction + radial_direction * correction_strength).normalized()
	var desired_velocity := desired_direction * boss.move_speed

	boss.velocity = boss.velocity.move_toward(desired_velocity, boss.acceleration * delta * 100.0)
	boss._face_direction(desired_direction)
