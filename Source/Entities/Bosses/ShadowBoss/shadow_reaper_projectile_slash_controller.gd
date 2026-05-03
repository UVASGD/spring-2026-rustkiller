extends Node
class_name ShadowReaperProjectileSlashController

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func move_to_reaper_projectile_attack_side() -> void:
	if boss == null:
		return
	boss.global_position = _get_reaper_projectile_attack_position()
	boss.stop_motion()
	boss.face_target()

func spawn_reaper_projectile() -> void:
	if boss == null or not boss.has_target():
		return

	var projectile := boss.REAPER_PROJECTILE_SCENE.instantiate()
	if projectile is Node2D:
		var projectile_node := projectile as Node2D
		var projectile_scale := projectile_node.scale
		projectile_scale.x = boss.visuals.scale.x
		projectile_node.scale = projectile_scale

	var projectile_hitbox := HitboxComponent.get_child_component(projectile)
	if projectile_hitbox:
		projectile_hitbox.init(boss.reaper_projectile_damage, "boss")

	var motion_component := ProjectileMotionComponent.get_child_component(projectile)
	var spawn_position := boss.projectile_origin.global_position if boss.projectile_origin != null else boss.global_position
	var direction_to_target := (boss.player.global_position - spawn_position).normalized()
	if direction_to_target == Vector2.ZERO:
		direction_to_target = Vector2.LEFT if boss.visuals.scale.x > 0.0 else Vector2.RIGHT

	if motion_component:
		motion_component.shoot(
			spawn_position,
			direction_to_target,
			boss.reaper_projectile_speed,
			boss.reaper_projectile_lifetime
		)

	projectile.add_to_group("shadow_projectile")

	var current_scene := boss.get_tree().current_scene
	if current_scene:
		current_scene.add_child(projectile)
	else:
		boss.add_child(projectile)

func _get_reaper_projectile_attack_position() -> Vector2:
	var side_sign := _get_reaper_projectile_attack_side_sign()
	var attack_position := boss.global_position

	if boss._light_platform != null and boss._light_platform.texture != null:
		var platform_scale := boss._light_platform.global_transform.get_scale()
		var half_width := boss._light_platform.texture.get_size().x * absf(platform_scale.x) * 0.5
		var horizontal_extent := maxf(half_width - boss.reaper_projectile_attack_side_padding, 0.0)
		attack_position.x = boss._light_platform.global_position.x + side_sign * horizontal_extent
	else:
		attack_position.x += side_sign * 260.0

	if boss.has_target():
		attack_position.y = boss.player.global_position.y

	return attack_position

func _get_reaper_projectile_attack_side_sign() -> float:
	if not boss.has_target():
		return -1.0 if randf() < 0.5 else 1.0

	var arena_center_x := boss._light_platform.global_position.x if boss._light_platform != null else boss.player.global_position.x
	return -1.0 if boss.player.global_position.x >= arena_center_x else 1.0
