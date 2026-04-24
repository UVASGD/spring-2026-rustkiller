extends HFSM

enum AttackPhase {
	TRANSFORM,
	SLITHER,
	OUROBOROS,
}

var _phase := AttackPhase.TRANSFORM
var _timer := 0.0
@onready var _attack_hitbox: HitboxComponent = $Area2D
@onready var _attack_shape: CollisionShape2D = $Area2D/CollisionShape2D

const DAMAGE_TICK_INTERVAL := 0.1

var _damage_tick_timer := 0.0
var _is_player_in_radius := false
var _player_hurtbox_in_radius: HurtboxComponent
var _was_parried := false

func _ready() -> void:
	if _attack_hitbox:
		if not _attack_hitbox.area_entered.is_connected(_on_attack_area_entered):
			_attack_hitbox.area_entered.connect(_on_attack_area_entered)
		if not _attack_hitbox.area_exited.is_connected(_on_attack_area_exited):
			_attack_hitbox.area_exited.connect(_on_attack_area_exited)

func on_enter() -> void:
	_configure_attack_hitbox()
	_damage_tick_timer = 0.0
	_is_player_in_radius = false
	_player_hurtbox_in_radius = null
	_was_parried = false
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	_start_transform_phase()

func on_exit() -> void:
	if _attack_hitbox:
		_attack_hitbox.damage_enabled = false
	_damage_tick_timer = 0.0
	_is_player_in_radius = false
	_player_hurtbox_in_radius = null
	_was_parried = false

func update(delta: float) -> void:
	if character == null:
		return

	_timer = maxf(_timer - delta, 0.0)
	_update_damage_ticks(delta)

	if _phase == AttackPhase.TRANSFORM:
		if character.has_method("stop_motion"):
			character.stop_motion()
		if character.has_method("face_target"):
			character.face_target()
		if _animation_finished(_get_transform_animation()):
			_clear_animation_finished(_get_transform_animation())
			_start_slither_phase()
	elif _phase == AttackPhase.SLITHER:
		if character.has_method("play_visual_animation"):
			character.play_visual_animation(_get_slither_animation(), false)
		if character.has_method("face_target"):
			character.face_target()
		if character.has_method("animal_move_toward_target"):
			character.animal_move_toward_target(delta)
		if character.has_method("is_near_animal_attack_target") and character.is_near_animal_attack_target():
			_start_ouroboros_phase()
	elif _phase == AttackPhase.OUROBOROS:
		if character.has_method("stop_motion"):
			character.stop_motion()

func check_transition(_delta: float) -> TransitionData:
	if _was_parried:
		return TransitionData.new(true, "AnimalIdle")
	if _phase == AttackPhase.OUROBOROS and _animation_finished(_get_ouroboros_animation()):
		_clear_animation_finished(_get_ouroboros_animation())
		return TransitionData.new(true, "AnimalIdle")
	return TransitionData.new(false, "")

func parry_charge_attack() -> bool:
	if _phase != AttackPhase.OUROBOROS:
		return false

	_was_parried = true
	if _attack_hitbox:
		_attack_hitbox.damage_enabled = false
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	return true

func _start_transform_phase() -> void:
	_phase = AttackPhase.TRANSFORM
	_timer = _get_animation_length_or(_get_transform_animation(), 0.8)
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_transform_animation())

func _start_slither_phase() -> void:
	_phase = AttackPhase.SLITHER
	_timer = 0.0
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_slither_animation())

func _start_ouroboros_phase() -> void:
	_phase = AttackPhase.OUROBOROS
	_timer = _get_animation_length_or(_get_ouroboros_animation(), 1.0)
	if character and character.has_method("stop_motion"):
		character.stop_motion()
	if character and character.has_method("play_visual_animation"):
		character.play_visual_animation(_get_ouroboros_animation())

func _get_transform_animation() -> String:
	if character and character.has_method("get_animal_transform_animation"):
		return character.get_animal_transform_animation()
	return "animal_snake_transform"

func _get_slither_animation() -> String:
	if character and character.has_method("get_animal_slither_animation"):
		return character.get_animal_slither_animation()
	return "animal_snake_slither"

func _get_ouroboros_animation() -> String:
	if character and character.has_method("get_animal_ouroboros_animation"):
		return character.get_animal_ouroboros_animation()
	return "animal_snake_ouroboros"

func _get_animation_length_or(animation_name: String, fallback: float) -> float:
	if character and character.has_method("get_visual_animation_length"):
		return character.get_visual_animation_length(animation_name, fallback)
	if animator and animator.has_animation(animation_name):
		return animator.get_animation(animation_name).length
	return fallback

func _animation_finished(animation_name: String) -> bool:
	if character and character.has_method("was_visual_animation_finished"):
		return character.was_visual_animation_finished(animation_name)
	return _timer <= 0.0

func _clear_animation_finished(animation_name: String) -> void:
	if character and character.has_method("clear_visual_animation_finished"):
		character.clear_visual_animation_finished(animation_name)

func _configure_attack_hitbox() -> void:
	if _attack_hitbox == null:
		return

	var damage := 1.0
	if character and "animal_attack_damage" in character:
		damage = character.animal_attack_damage

	_attack_hitbox.damage = damage
	_attack_hitbox.hit_owner = "boss"
	_attack_hitbox.damage_enabled = true

func _update_damage_ticks(delta: float) -> void:
	if _attack_hitbox == null or _attack_shape == null:
		return

	if _attack_shape.disabled:
		_damage_tick_timer = 0.0
		return

	if not _is_player_in_radius or _player_hurtbox_in_radius == null:
		_damage_tick_timer = 0.0
		return

	_damage_tick_timer += delta
	if _damage_tick_timer < DAMAGE_TICK_INTERVAL:
		return

	while _damage_tick_timer >= DAMAGE_TICK_INTERVAL:
		_damage_tick_timer -= DAMAGE_TICK_INTERVAL
		_apply_damage_tick()

func _apply_damage_tick() -> void:
	if _player_hurtbox_in_radius == null:
		return

	if not is_instance_valid(_player_hurtbox_in_radius):
		_is_player_in_radius = false
		_player_hurtbox_in_radius = null
		return

	_player_hurtbox_in_radius.apply_hitbox(_attack_hitbox)

func _on_attack_area_entered(area: Area2D) -> void:
	if not (area is HurtboxComponent):
		return

	var hurtbox := area as HurtboxComponent
	if hurtbox.entity_name != "player":
		return

	_is_player_in_radius = true
	_player_hurtbox_in_radius = hurtbox

func _on_attack_area_exited(area: Area2D) -> void:
	if area != _player_hurtbox_in_radius:
		return

	_is_player_in_radius = false
	_player_hurtbox_in_radius = null
	_damage_tick_timer = 0.0
