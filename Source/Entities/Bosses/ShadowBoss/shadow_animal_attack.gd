extends HFSM

const ATTACK_PLAYBACK_SPEED := 1.5
const DAMAGE_TICK_INTERVAL := 0.1

enum AttackMode {
	SNAKE,
	WOLF,
	PORCUPINE,
}

enum SnakePhase {
	TRANSFORM,
	SLITHER,
	OUROBOROS,
}

enum WolfPhase {
	INTRO,
	APPROACH,
	ATTACK,
}

var _attack_mode := AttackMode.SNAKE
var _snake_phase := SnakePhase.TRANSFORM
var _wolf_phase := WolfPhase.INTRO
var _attack_hitbox: HitboxComponent
var _attack_shape: CollisionShape2D
var _damage_tick_timer := 0.0
var _was_parried := false
var _snake_finished := false
var _porcupine_finished := false
var _porcupine_waves_spawned := 0
var _approach_animations: Array[String] = []
var _attack_animations: Array[String] = []
var _phase_elapsed := 0.0
var _phase_duration := 0.0
var _current_pair_index := 0
var _attack_anchor_position := Vector2.ZERO

func on_enter() -> void:
	_attack_mode = _choose_attack_mode()
	_assign_attack_hitbox()
	_configure_attack_hitbox()
	_reset_visual_animation_speed()
	_damage_tick_timer = 0.0
	_was_parried = false
	_snake_finished = false
	_porcupine_finished = false
	_porcupine_waves_spawned = 0
	_phase_elapsed = 0.0
	_phase_duration = 0.0
	_current_pair_index = 0
	_attack_anchor_position = Vector2.ZERO
	_approach_animations = []
	_attack_animations = []

	if character and character.has_method("stop_motion"):
		character.stop_motion()

	match _attack_mode:
		AttackMode.SNAKE:
			_start_snake_transform_phase()
		AttackMode.PORCUPINE:
			_start_porcupine_phase()
		AttackMode.WOLF:
			_approach_animations = _get_wolf_approach_animations()
			_attack_animations = _get_wolf_attack_animations()
			_start_wolf_intro_phase()

func on_exit() -> void:
	_set_attack_hitbox_active(false)
	_reset_visual_animation_speed()
	_damage_tick_timer = 0.0
	_was_parried = false

func update(delta: float) -> void:
	if character == null:
		return

	_update_damage_ticks(delta)

	match _attack_mode:
		AttackMode.SNAKE:
			_update_snake_attack(delta)
		AttackMode.PORCUPINE:
			_update_porcupine_attack(delta)
		AttackMode.WOLF:
			_update_wolf_attack(delta)

func check_transition(_delta: float) -> TransitionData:
	if _was_parried:
		return TransitionData.new(true, "AnimalIdle")
	if _attack_mode == AttackMode.SNAKE and _snake_finished:
		return TransitionData.new(true, "AnimalIdle")
	if _attack_mode == AttackMode.PORCUPINE and _porcupine_finished:
		return TransitionData.new(true, "AnimalIdle")
	if _attack_mode == AttackMode.WOLF and _wolf_is_finished():
		return TransitionData.new(true, "AnimalIdle")
	return TransitionData.new(false, "")

func parry_charge_attack() -> bool:
	if _attack_mode == AttackMode.SNAKE and _snake_phase != SnakePhase.OUROBOROS:
		return false
	if _attack_mode == AttackMode.PORCUPINE:
		return false
	if _attack_mode == AttackMode.WOLF and _wolf_phase != WolfPhase.ATTACK:
		return false

	_was_parried = true
	_set_attack_hitbox_active(false)
	_reset_visual_animation_speed()
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	return true

func _choose_attack_mode() -> int:
	if character and character.has_method("choose_animal_attack_type"):
		var attack_type := String(character.choose_animal_attack_type())
		if attack_type == "porcupine":
			return AttackMode.PORCUPINE
		if attack_type == "wolf":
			return AttackMode.WOLF
	return AttackMode.SNAKE

func _assign_attack_hitbox() -> void:
	if character == null:
		_attack_hitbox = null
		_attack_shape = null
		return

	var hitbox_name := ""
	match _attack_mode:
		AttackMode.SNAKE:
			hitbox_name = "ouroboros_hitbox"
		AttackMode.WOLF:
			hitbox_name = "wolf_hitbox"
		AttackMode.PORCUPINE:
			_attack_hitbox = null
			_attack_shape = null
			return

	_attack_hitbox = character.get(hitbox_name) as HitboxComponent
	_attack_shape = _attack_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D if _attack_hitbox else null

func _configure_attack_hitbox() -> void:
	if _attack_hitbox == null:
		return

	var damage := 1.0
	if character:
		damage = float(character.get("animal_attack_damage"))

	_attack_hitbox.damage = damage
	_attack_hitbox.hit_owner = "boss"
	_set_attack_hitbox_active(false)

func _set_attack_hitbox_active(active: bool) -> void:
	if _attack_hitbox == null:
		return

	_attack_hitbox.monitoring = active
	_attack_hitbox.monitorable = active
	_attack_hitbox.damage_enabled = active
	if _attack_shape:
		_attack_shape.set_deferred("disabled", not active)

func _update_snake_attack(delta: float) -> void:
	match _snake_phase:
		SnakePhase.TRANSFORM:
			if character.has_method("stop_motion"):
				character.stop_motion()
			if character.has_method("face_target"):
				character.face_target()
			if _animation_finished(_get_snake_transform_animation()):
				_clear_animation_finished(_get_snake_transform_animation())
				_start_snake_slither_phase()
		SnakePhase.SLITHER:
			_play_animation(_get_snake_slither_animation(), false)
			if character.has_method("animal_move_toward_target"):
				character.animal_move_toward_target(delta)
			if character.has_method("is_near_animal_attack_target") and character.is_near_animal_attack_target():
				_start_snake_ouroboros_phase()
		SnakePhase.OUROBOROS:
			if character.has_method("stop_motion"):
				character.stop_motion()
			if _animation_finished(_get_snake_ouroboros_animation()):
				_clear_animation_finished(_get_snake_ouroboros_animation())
				_set_attack_hitbox_active(false)
				_snake_finished = true
				_reset_visual_animation_speed()

func _start_snake_transform_phase() -> void:
	_snake_phase = SnakePhase.TRANSFORM
	_set_attack_hitbox_active(false)
	_reset_visual_animation_speed()
	_play_animation(_get_snake_transform_animation())

func _start_snake_slither_phase() -> void:
	_snake_phase = SnakePhase.SLITHER
	_set_attack_hitbox_active(false)
	_reset_visual_animation_speed()
	_play_animation(_get_snake_slither_animation())

func _start_snake_ouroboros_phase() -> void:
	_snake_phase = SnakePhase.OUROBOROS
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	_set_attack_hitbox_active(true)
	_reset_visual_animation_speed()
	_play_animation(_get_snake_ouroboros_animation())

func _start_porcupine_phase() -> void:
	_phase_elapsed = 0.0
	_phase_duration = _get_porcupine_attack_duration()
	_porcupine_waves_spawned = 0
	_porcupine_finished = false
	_reset_visual_animation_speed()
	_play_animation(_get_porcupine_animation())

func _update_porcupine_attack(delta: float) -> void:
	_phase_elapsed = minf(_phase_elapsed + delta, _phase_duration)
	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()
	_play_animation(_get_porcupine_animation(), false)

	var wave_interval := _get_porcupine_wave_interval()
	var wave_count := _get_porcupine_wave_count()
	while _porcupine_waves_spawned < wave_count and _phase_elapsed >= float(_porcupine_waves_spawned) * wave_interval:
		if character and character.has_method("spawn_porcupine_wave_on_map"):
			character.spawn_porcupine_wave_on_map()
		_porcupine_waves_spawned += 1

	if _porcupine_waves_spawned >= wave_count and _phase_elapsed >= _phase_duration:
		_porcupine_finished = true
		_reset_visual_animation_speed()

func _update_wolf_attack(delta: float) -> void:
	match _wolf_phase:
		WolfPhase.INTRO:
			_update_wolf_intro_phase()
		WolfPhase.APPROACH:
			_update_wolf_approach_phase(delta)
		WolfPhase.ATTACK:
			_update_wolf_attack_phase()

func _update_wolf_intro_phase() -> void:
	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()
	if _animation_finished(_get_wolf_intro_animation()):
		_clear_animation_finished(_get_wolf_intro_animation())
		_start_wolf_approach_phase()

func _update_wolf_approach_phase(delta: float) -> void:
	_phase_elapsed = minf(_phase_elapsed + delta, _phase_duration)
	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("has_target") and character.has_target():
		_attack_anchor_position = character.player.global_position
		character.global_position = character.player.global_position
	if character.has_method("face_target"):
		character.face_target()

	if _current_pair_index >= _get_wolf_animation_pair_count():
		return

	var animation_name := _approach_animations[_current_pair_index]
	if _animation_finished(animation_name):
		_clear_animation_finished(animation_name)
		_start_wolf_attack_phase()

func _update_wolf_attack_phase() -> void:
	if character.has_method("stop_motion"):
		character.stop_motion()
	if character.has_method("face_target"):
		character.face_target()

	if _current_pair_index >= _get_wolf_animation_pair_count():
		return

	var animation_name := _attack_animations[_current_pair_index]
	if _animation_finished(animation_name):
		_clear_animation_finished(animation_name)
		_current_pair_index += 1
		_set_attack_hitbox_active(false)
		_reset_visual_animation_speed()
		if _current_pair_index < _get_wolf_animation_pair_count():
			_start_wolf_approach_phase()

func _start_wolf_intro_phase() -> void:
	_wolf_phase = WolfPhase.INTRO
	_phase_elapsed = 0.0
	_phase_duration = _get_animation_length_or(_get_wolf_intro_animation(), 0.0)
	_reset_visual_animation_speed()
	_play_animation(_get_wolf_intro_animation())

func _start_wolf_approach_phase() -> void:
	_wolf_phase = WolfPhase.APPROACH
	_phase_elapsed = 0.0
	_phase_duration = _get_animation_length_or(_approach_animations[_current_pair_index], 0.0)
	_attack_anchor_position = character.global_position if character else Vector2.ZERO
	_set_attack_hitbox_active(false)
	_reset_visual_animation_speed()
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character and character.has_method("has_target") and character.has_target():
		_attack_anchor_position = character.player.global_position
		character.global_position = character.player.global_position
	if character and character.has_method("face_target"):
		character.face_target()
	if _current_pair_index < _approach_animations.size():
		_play_animation(_approach_animations[_current_pair_index])
	else:
		_start_wolf_attack_phase()

func _start_wolf_attack_phase() -> void:
	_wolf_phase = WolfPhase.ATTACK
	_set_attack_visual_animation_speed()
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character:
		character.global_position = _attack_anchor_position
	if character and character.has_method("face_target"):
		character.face_target()
	_set_attack_hitbox_active(true)
	if _current_pair_index < _attack_animations.size():
		_phase_elapsed = 0.0
		_phase_duration = _get_animation_length_or(_attack_animations[_current_pair_index], 0.0)
		_play_animation(_attack_animations[_current_pair_index])

func _wolf_is_finished() -> bool:
	return _wolf_phase == WolfPhase.ATTACK and _current_pair_index >= _get_wolf_animation_pair_count()

func _play_animation(animation_name: String, restart: bool = true) -> void:
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(animation_name, restart)

func _set_attack_visual_animation_speed() -> void:
	if character and character.has_method("set_visual_animation_speed_scale"):
		character.set_visual_animation_speed_scale(ATTACK_PLAYBACK_SPEED)

func _reset_visual_animation_speed() -> void:
	if character and character.has_method("reset_visual_animation_speed_scale"):
		character.reset_visual_animation_speed_scale()

func _get_snake_transform_animation() -> String:
	if character and character.has_method("get_animal_transform_animation"):
		return character.get_animal_transform_animation()
	return "animal_snake_transform"

func _get_snake_slither_animation() -> String:
	if character and character.has_method("get_animal_slither_animation"):
		return character.get_animal_slither_animation()
	return "animal_snake_slither"

func _get_snake_ouroboros_animation() -> String:
	if character and character.has_method("get_animal_ouroboros_animation"):
		return character.get_animal_ouroboros_animation()
	return "animal_snake_ouroboros"

func _get_porcupine_animation() -> String:
	if character and character.has_method("get_animal_idle_animation"):
		return character.get_animal_idle_animation()
	return "animal_idle"

func _get_porcupine_attack_duration() -> float:
	if character and character.has_method("get_animal_porcupine_attack_duration"):
		return character.get_animal_porcupine_attack_duration()
	return 1.8

func _get_porcupine_wave_count() -> int:
	if character and character.has_method("get_animal_porcupine_wave_count"):
		return character.get_animal_porcupine_wave_count()
	return 3

func _get_porcupine_wave_interval() -> float:
	if character and character.has_method("get_animal_porcupine_wave_interval"):
		return character.get_animal_porcupine_wave_interval()
	return 0.35

func _get_wolf_intro_animation() -> String:
	if character and character.has_method("get_animal_wolf_intro_animation"):
		return character.get_animal_wolf_intro_animation()
	return "wolf_init"

func _get_wolf_approach_animations() -> Array[String]:
	if character and character.has_method("get_animal_wolf_approach_animations"):
		return character.get_animal_wolf_approach_animations()
	return ["wolf_app_1", "wolf_app_2", "wolf_app_3"]

func _get_wolf_attack_animations() -> Array[String]:
	if character and character.has_method("get_animal_wolf_attack_animations"):
		return character.get_animal_wolf_attack_animations()
	return ["wolf_attack_1", "wolf_attack_2", "wolf_attack_3"]

func _get_wolf_animation_pair_count() -> int:
	return mini(_approach_animations.size(), _attack_animations.size())

func _get_animation_length_or(animation_name: String, fallback: float) -> float:
	if character and character.has_method("get_visual_animation_length"):
		return character.get_visual_animation_length(animation_name, fallback)
	if animator and animator.has_animation(animation_name):
		return animator.get_animation(animation_name).length
	return fallback

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return false

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)

func _update_damage_ticks(delta: float) -> void:
	if _attack_hitbox == null or _attack_shape == null:
		return
	if _attack_shape.disabled or not _attack_hitbox.damage_enabled:
		_damage_tick_timer = 0.0
		return

	var player_hurtboxes := _get_overlapping_player_hurtboxes()
	if player_hurtboxes.is_empty():
		_damage_tick_timer = 0.0
		return

	_damage_tick_timer += delta
	if _damage_tick_timer < DAMAGE_TICK_INTERVAL:
		return

	while _damage_tick_timer >= DAMAGE_TICK_INTERVAL:
		_damage_tick_timer -= DAMAGE_TICK_INTERVAL
		for hurtbox in player_hurtboxes:
			if is_instance_valid(hurtbox):
				hurtbox.apply_hitbox(_attack_hitbox)

func _get_overlapping_player_hurtboxes() -> Array[HurtboxComponent]:
	var hurtboxes: Array[HurtboxComponent] = []
	if _attack_hitbox == null:
		return hurtboxes

	for area in _attack_hitbox.get_overlapping_areas():
		if not (area is HurtboxComponent):
			continue
		var hurtbox := area as HurtboxComponent
		if hurtbox.entity_name != "player":
			continue
		hurtboxes.append(hurtbox)

	return hurtboxes
