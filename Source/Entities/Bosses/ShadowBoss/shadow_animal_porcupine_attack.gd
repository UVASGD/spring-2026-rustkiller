extends Node
class_name ShadowAnimalPorcupineAttack

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func spawn_porcupine_wave_on_map() -> void:
	if boss == null:
		return

	var spawn_positions := _get_animal_porcupine_spawn_positions()
	for spawn_position in spawn_positions:
		var porcupine := boss.SHADOW_PORCUPINE_SCENE.instantiate()
		if porcupine is Node2D:
			(porcupine as Node2D).global_position = spawn_position

		var projectile_hitbox := HitboxComponent.get_child_component(porcupine)
		if projectile_hitbox:
			projectile_hitbox.init(boss.get_animal_porcupine_attack_damage(), "boss")

		porcupine.add_to_group("shadow_projectile")

		var current_scene := boss.get_tree().current_scene
		if current_scene:
			current_scene.add_child(porcupine)
		else:
			boss.add_child(porcupine)

func _get_animal_porcupine_spawn_positions() -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var porcupine_count := boss.get_animal_porcupine_wave_size()
	if porcupine_count <= 0:
		return spawn_positions

	var center_x := boss._light_platform.global_position.x if boss._light_platform != null else boss.global_position.x
	var center_y := boss._light_platform.global_position.y if boss._light_platform != null else boss.global_position.y
	var half_width := 240.0

	if boss._light_platform != null and boss._light_platform.texture != null:
		var platform_scale := boss._light_platform.global_transform.get_scale()
		half_width = boss._light_platform.texture.get_size().x * absf(platform_scale.x) * 0.5

	var usable_half_width := maxf(half_width - 24.0, 24.0)
	var min_spacing := minf(usable_half_width * 0.35, 42.0)
	var max_attempts := porcupine_count * 12
	var attempts := 0
	while spawn_positions.size() < porcupine_count and attempts < max_attempts:
		attempts += 1
		var spawn_x := randf_range(center_x - usable_half_width, center_x + usable_half_width)
		var jitter_y := randf_range(-12.0, 12.0)
		var candidate := Vector2(spawn_x, center_y - boss.animal_porcupine_spawn_height + jitter_y)
		var is_clear := true
		for existing_position in spawn_positions:
			if absf(candidate.x - existing_position.x) < min_spacing:
				is_clear = false
				break
		if is_clear:
			spawn_positions.append(candidate)

	while spawn_positions.size() < porcupine_count:
		var spawn_x := randf_range(center_x - usable_half_width, center_x + usable_half_width)
		var jitter_y := randf_range(-12.0, 12.0)
		spawn_positions.append(Vector2(spawn_x, center_y - boss.animal_porcupine_spawn_height + jitter_y))

	return spawn_positions
