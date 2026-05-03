extends Node
class_name ShadowPlayerRangeAttackController

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func can_start_range() -> bool:
	return boss != null and boss.has_target() and boss._range_cooldown_remaining <= 0.0

func should_use_range_attack() -> bool:
	return can_start_range() and randf() <= boss.range_attack_chance

func begin_range_cooldown() -> void:
	if boss == null:
		return
	boss._range_cooldown_remaining = boss.range_cooldown

func spawn_shadow_skulls_near_player() -> void:
	if boss == null or not boss.has_target():
		return

	var spawn_positions := _get_shadow_skull_spawn_positions()
	for spawn_position in spawn_positions:
		var projectile_scene := boss.SHADOW_SKULL_SCENE if randf() < boss.skull_spawn_chance else boss.SHADOW_BAT_SCENE
		var projectile := projectile_scene.instantiate()
		projectile.global_position = spawn_position
		if projectile_scene == boss.SHADOW_SKULL_SCENE:
			var projectile_hitbox := HitboxComponent.get_child_component(projectile)
			if projectile_hitbox:
				projectile_hitbox.init(boss.skull_attack_damage, "boss")
		projectile.add_to_group("shadow_projectile")
		boss.get_tree().current_scene.add_child(projectile)

func _get_shadow_skull_spawn_positions() -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var skull_count := maxi(boss.skulls_per_range_loop, 0)
	if skull_count <= 0:
		return spawn_positions

	var radius := maxf(boss.skull_spawn_radius, 1.0)
	var min_distance := maxf(boss.skull_spawn_min_distance, 1.0)
	var player_position := boss.player.global_position
	var max_attempts := skull_count * 24
	var attempts := 0

	while spawn_positions.size() < skull_count and attempts < max_attempts:
		attempts += 1
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, radius)
		var candidate_position := player_position + offset
		if _is_shadow_skull_spawn_position_clear(candidate_position, spawn_positions, min_distance):
			spawn_positions.append(candidate_position)

	if spawn_positions.size() >= skull_count:
		return spawn_positions

	var ring_radius := min_distance
	while spawn_positions.size() < skull_count:
		var angle := TAU * float(spawn_positions.size()) / float(skull_count)
		var candidate_position := player_position + Vector2.RIGHT.rotated(angle) * ring_radius
		if _is_shadow_skull_spawn_position_clear(candidate_position, spawn_positions, min_distance):
			spawn_positions.append(candidate_position)
		ring_radius += min_distance

	return spawn_positions

func _is_shadow_skull_spawn_position_clear(candidate_position: Vector2, spawn_positions: Array[Vector2], min_distance: float) -> bool:
	for spawn_position in spawn_positions:
		if candidate_position.distance_to(spawn_position) < min_distance:
			return false
	for projectile in boss.get_tree().get_nodes_in_group("shadow_projectile"):
		if not is_instance_valid(projectile) or not (projectile is Node2D):
			continue
		if candidate_position.distance_to(projectile.global_position) < min_distance:
			return false
	return true
