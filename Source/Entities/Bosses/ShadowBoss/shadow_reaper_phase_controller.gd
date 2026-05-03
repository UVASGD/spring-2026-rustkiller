extends Node
class_name ShadowReaperPhaseController

@onready var boss: ShadowBoss = get_parent() as ShadowBoss

func enter_phase() -> void:
	if boss == null:
		return
	if not boss._reaper_phase_active:
		boss._refill_health_for_phase(boss.reaper_phase_health)
	boss._reaper_phase_active = true
	boss._player_phase_active = false
	boss._player_phase_appear_ready = false
	boss._reaper_phase_switch_ready = false
	boss._player_phase_switch_ready = false
	boss._reaper_phase_complete = false
	boss._machine_pending_phase = ""
	boss._animal_attack_index = 0
	boss.reset_reaper_slash_movement()
	boss._reaper_attack_bag.clear()
	boss._last_reaper_attack_state = ""
	boss._restore_after_machine_intermission()
	boss.enable_phase_hitboxes()
	boss.stop_motion()
	if boss.sfx_manager:
		boss.sfx_manager.play_reaper_arrival_audio()

func choose_reaper_attack_state() -> String:
	if boss == null:
		return "ReaperSlash"
	if boss._reaper_attack_bag.is_empty():
		_refill_reaper_attack_bag()

	if boss._reaper_attack_bag.is_empty():
		return "ReaperSlash"

	var next_state: String = boss._reaper_attack_bag.pop_back()
	boss._last_reaper_attack_state = next_state
	return next_state

func get_reaper_appear_animation() -> String:
	return String(boss.reaper_appear_animation)

func get_reaper_disintegrate_animation() -> String:
	return String(boss.reaper_disintegrate_animation)

func get_reaper_idle_animation() -> String:
	return String(boss.reaper_idle_animation)

func get_reaper_slash_animation() -> String:
	return String(boss.reaper_slash_animation)

func get_reaper_triple_animation() -> String:
	return String(boss.reaper_triple_animation)

func get_reaper_projectile_slash_animation() -> String:
	return String(boss.reaper_projectile_slash_animation)

func get_reaper_idle_duration() -> float:
	return maxf(boss.reaper_idle_duration, 0.0)

func get_reaper_post_melee_idle_duration() -> float:
	return maxf(boss.reaper_post_melee_idle_duration, 0.0)

func get_reaper_post_melee_walk_speed() -> float:
	return maxf(boss.reaper_post_melee_walk_speed, 0.0)

func get_reaper_slash_damage() -> float:
	return maxf(boss.reaper_slash_damage, 0.0)

func get_reaper_triple_damage() -> float:
	return maxf(boss.reaper_triple_damage, 0.0)

func get_reaper_melee_charge_count() -> int:
	return maxi(boss.reaper_melee_charge_count, 1)

func get_reaper_projectile_volley_count() -> int:
	return maxi(boss.reaper_projectile_volley_count, 1)

func reaper_move_toward_target(delta: float) -> void:
	_reaper_move_toward_target_with_speed(delta, boss.reaper_move_speed)

func reaper_move_toward_target_post_melee(delta: float) -> void:
	_reaper_move_toward_target_with_speed(delta, boss.reaper_post_melee_walk_speed)

func reaper_orbit_target(delta: float) -> void:
	_reaper_orbit_target_with_speed(delta, boss.reaper_move_speed)

func reaper_orbit_target_post_melee(delta: float) -> void:
	_reaper_orbit_target_with_speed(delta, boss.reaper_post_melee_walk_speed)

func mark_reaper_phase_complete() -> void:
	boss._reaper_phase_complete = true

func is_reaper_phase_complete() -> bool:
	return boss != null and boss._reaper_phase_complete

func _reaper_move_toward_target_with_speed(delta: float, movement_speed: float) -> void:
	if boss == null:
		return
	if not boss.has_target():
		boss.stop_motion()
		return

	var direction := boss.global_position.direction_to(boss.player.global_position)
	var desired_velocity := direction * movement_speed
	boss.velocity = boss.velocity.move_toward(desired_velocity, boss.acceleration * delta * 100.0)
	boss._face_direction(direction)

func _reaper_orbit_target_with_speed(delta: float, movement_speed: float) -> void:
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
	var desired_velocity := desired_direction * movement_speed

	boss.velocity = boss.velocity.move_toward(desired_velocity, boss.acceleration * delta * 100.0)
	boss._face_direction(desired_direction)

func _refill_reaper_attack_bag() -> void:
	boss._reaper_attack_bag = _get_configured_reaper_attack_states()
	boss._reaper_attack_bag.shuffle()

	if boss._reaper_attack_bag.size() > 1 and boss._last_reaper_attack_state != "" and boss._reaper_attack_bag.back() == boss._last_reaper_attack_state:
		var swap_index := randi_range(0, boss._reaper_attack_bag.size() - 2)
		var swapped_attack_state := boss._reaper_attack_bag[swap_index]
		boss._reaper_attack_bag[swap_index] = boss._reaper_attack_bag.back()
		boss._reaper_attack_bag[boss._reaper_attack_bag.size() - 1] = swapped_attack_state

func _get_configured_reaper_attack_states() -> Array[String]:
	var default_attack_states: Array[String] = ["ReaperSlash", "ReaperProjectileSlash", "ReaperTriple"]
	var allowed_attack_states := {
		"ReaperSlash": true,
		"ReaperProjectileSlash": true,
		"ReaperTriple": true,
	}
	var configured_attack_states: Array[String] = []

	for attack_state in boss.reaper_phase_attack_states:
		if allowed_attack_states.has(attack_state):
			configured_attack_states.append(attack_state)

	if configured_attack_states.is_empty():
		return default_attack_states.duplicate()

	return configured_attack_states
