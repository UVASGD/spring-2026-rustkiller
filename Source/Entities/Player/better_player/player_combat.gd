class_name PlayerCombat
extends Node

@export var lunge_distance: float   = 80.0
@export var lunge_duration: float   = 0.12
@export var projectile_speed: float = 500.0
@export var wrench_projectile_damage: float = 1.0
@export var melee_damage: float = 1.0

const BURST_COUNT := 3
const BURST_INTERVAL := 0.08
const WRENCH_PROJECTILE := preload("res://Source/Entities/Projectiles/Wrench/wrench_projectile.tscn")

var a2_available: bool = false
var combo_window: bool = false
var is_shooting: bool = false

var is_melee_hitbox_active: bool = false
var has_melee_hit: bool = false

var lunge_dir: Vector2 = Vector2.ZERO
var lunge_time_left: float = 0.0
var attack_direction: Vector2 = Vector2.ZERO
var _hitstop_generation: int = 0

var _player: CharacterBody2D
var _anim: AnimationPlayer
var _sprite_manager: Node2D
var _muzzle: Node2D
var _hitbox: Area2D
var _parry_window: Area2D

func setup(player: CharacterBody2D) -> void:
	_player = player
	_anim = player.anim_player
	_sprite_manager = player.sprite_manager
	_muzzle = player.get_node("SpriteManager/Muzzle")
	_hitbox = player.get_node("SpriteManager/HitboxComponent")
	_parry_window = player.get_node("SpriteManager/ParryWindow")

	_anim.animation_finished.connect(_on_animation_finished)
	_hitbox.hit_owner = player.entity_name
	_hitbox.damage = melee_damage
	_hitbox.damage_enabled = false
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	_parry_window.monitoring = true
	_parry_window.monitorable = true

func process_attack(delta: float) -> void:
	if lunge_time_left > 0.0:
		var lunge_speed := lunge_distance / lunge_duration
		_player.velocity = lunge_dir * lunge_speed
		lunge_time_left -= delta
	else:
		_player.velocity = Vector2.ZERO
		_check_combo_input()

	if is_melee_hitbox_active:
		for area in _hitbox.get_overlapping_areas():
			_try_hit_area(area)

func handle_attack_input() -> void:
	if _player.curr_weapon == "melee":
		_start_melee()
	elif _player.curr_weapon == "shoot" and not is_shooting:
		fire_burst()

func try_parry() -> void:
	if _player.current_state == "attacking" or _player.current_state == "parrying":
		return

	for area in _parry_window.get_overlapping_areas():
		if area is HitboxComponent:
			var hitbox := area as HitboxComponent
			if hitbox.hit_owner == "boss":
				var hit_source := hitbox.get_parent()
				var parry_receiver := _find_parry_receiver(hit_source)
				var parry_succeeded := false
				if parry_receiver and parry_receiver.has_method("parry_charge_attack"):
					parry_succeeded = parry_receiver.parry_charge_attack()
				elif _is_boss_attack_source(hit_source):
					parry_succeeded = true
				elif _should_destroy_parry_source(hit_source):
					hit_source.queue_free()
					parry_succeeded = true

				if not parry_succeeded:
					continue
				_player.activate_parry_invulnerability()
				_player.set_state("parrying")
				_anim.stop()
				_anim.play("parry")
				_anim.seek(0.0, true)
				return

func fire_burst() -> void:
	is_shooting = true
	for i in BURST_COUNT:
		_shoot_single()
		if i < BURST_COUNT - 1:
			await _player.get_tree().create_timer(BURST_INTERVAL).timeout
	is_shooting = false

func update_melee_active(make_active: bool = false) -> void:
	is_melee_hitbox_active = make_active
	_hitbox.damage = melee_damage
	_hitbox.damage_enabled = make_active
	if not make_active:
		has_melee_hit = false


func update_a2_availability(make_available: bool = false) -> void:
	print("update_a2_availability called:", make_available, " anim:", _anim.current_animation)
	a2_available = make_available

func hitstop(duration: float, emit_parry_signal: bool = true) -> void:
	_hitstop_generation += 1
	var hitstop_generation := _hitstop_generation
	Engine.time_scale = 0.0
	await _player.get_tree().create_timer(duration, true, false, true).timeout
	if hitstop_generation != _hitstop_generation:
		return

	Engine.time_scale = 1.0
	if emit_parry_signal:
		_player.emit_parrying()

func _find_parry_receiver(hit_source: Node) -> Node:
	var current := hit_source
	while current != null:
		if current.has_method("parry_charge_attack"):
			return current
		current = current.get_parent()
	return null

func _is_boss_attack_source(hit_source: Node) -> bool:
	var current := hit_source
	while current != null:
		if current.is_in_group("boss"):
			return true
		if current.has_node("HealthComponent"):
			return true
		current = current.get_parent()
	return false

func _should_destroy_parry_source(hit_source: Node) -> bool:
	if hit_source == null:
		return false

	if _is_boss_attack_source(hit_source):
		return false

	if hit_source.is_in_group("shadow_projectile"):
		return true

	var script := hit_source.get_script() as Script
	if script:
		var script_path := script.resource_path
		if script_path.contains("/Projectiles/"):
			return true

	return false

func _start_melee() -> void:
	if combo_window:
		combo_window = false
		has_melee_hit = false
		_play_attack_anim("a2")
	else:
		_begin_lunge("a1")

func _begin_lunge(anim_name: String) -> void:
	_player.set_state("attacking")

	lunge_dir = (_player.get_global_mouse_position() - _player.global_position).normalized()
	if lunge_dir == Vector2.ZERO:
		lunge_dir = _player.last_move_dir

	lunge_time_left = lunge_duration
	_flip_to_lunge_dir()
	_play_attack_anim(anim_name)

func _check_combo_input() -> void:
	if Input.is_action_just_pressed("attack") and a2_available and _player.curr_weapon == "melee":
		a2_available = false
		has_melee_hit = false

		lunge_dir = (_player.get_global_mouse_position() - _player.global_position).normalized()
		if lunge_dir == Vector2.ZERO:
			lunge_dir = _player.last_move_dir

		lunge_time_left = lunge_duration
		_flip_to_lunge_dir()
		_play_attack_anim("a2")

func _play_attack_anim(anim_name: String) -> void:
	_player.set_state("attacking")
	is_melee_hitbox_active = false
	_hitbox.damage_enabled = false
	_anim.stop()
	_anim.play(anim_name)
	_anim.seek(0.0, true)

func _flip_to_lunge_dir() -> void:
	if lunge_dir.x < 0.0:
		_sprite_manager.scale.x = 1
	elif lunge_dir.x > 0.0:
		_sprite_manager.scale.x = -1

func _shoot_single() -> void:
	var projectile := WRENCH_PROJECTILE.instantiate()
	var dir := (_player.get_global_mouse_position() - _muzzle.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = attack_direction

	projectile.rotation = dir.angle()
	ProjectileMotionComponent.get_child_component(projectile).shoot(
		_muzzle.global_position, dir, projectile_speed, -1
	)
	HitboxComponent.get_child_component(projectile).init(wrench_projectile_damage, "player")
	_player.get_tree().current_scene.add_child(projectile)

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"a1":
			_player.set_state("idle")
			is_melee_hitbox_active = false
			_hitbox.damage_enabled = false
			has_melee_hit = false
			a2_available = false
			_start_combo_window()
		"a2":
			_player.set_state("idle")
			is_melee_hitbox_active = false
			_hitbox.damage_enabled = false
			has_melee_hit = false
		"parry":
			_player.set_state("idle")

func _start_combo_window() -> void:
	combo_window = true
	await _player.get_tree().create_timer(0.5).timeout
	combo_window = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	print("area entered:", area.name, " anim:", _anim.current_animation, " active:", is_melee_hitbox_active)
	_try_hit_area(area)

func _try_hit_area(area: Area2D) -> void:
	if not (area is HurtboxComponent):
		print("not a hurtbox, skipping")
		return

	var hurtbox := area as HurtboxComponent
	print("hurtbox entity:", hurtbox.entity_name)
	print("can_accept_bullet:", hurtbox.can_accept_bullet_collision())
	print("is_melee_hitbox_active:", is_melee_hitbox_active)
	print("has_melee_hit:", has_melee_hit)

	if hurtbox.can_accept_bullet_collision() \
	and hurtbox.entity_name == "boss" \
	and is_melee_hitbox_active \
	and not has_melee_hit:
		has_melee_hit = true
		hurtbox._on_area_entered(_hitbox)

		if hurtbox.bullet_impact_scene:
			var impact = hurtbox.bullet_impact_scene.instantiate()
			impact.global_position = _player.global_position
			_player.get_tree().current_scene.add_child(impact)
