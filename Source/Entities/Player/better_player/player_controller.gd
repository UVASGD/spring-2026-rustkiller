class_name PlayerController
extends CharacterBody2D

@export var entity_name: String = "player"
@export var speed: float = 200.0
@export var hp: int = 3
@export var damage_hitstop_duration: float = 0.08
@export var damage_flash_duration: float = 0.08
@export var parry_invulnerability_duration: float = 0.5

var current_state: String = "idle"
var curr_weapon: String = "melee"
var last_move_dir: Vector2 = Vector2.RIGHT
var _damage_flash_generation: int = 0
var _invulnerability_generation: int = 0
var _is_invulnerable: bool = false

signal parrying

@onready var sprite_manager: Node2D       = $SpriteManager
@onready var anim_player: AnimationPlayer = $PlayerAnimation
@onready var cursor: Node2D               = $Cursor
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

@onready var _movement: PlayerMovement = $PlayerMovement
@onready var _combat: PlayerCombat     = $PlayerCombat

func _ready() -> void:
	health_component.max_health = hp
	health_component.health = hp
	health_component.died.connect(_on_health_died)
	hurtbox_component.hit_by_hitbox.connect(_on_hurtbox_hit_by_hitbox)
	_combat.setup(self)
	_movement.setup(self)
	_set_damage_flash_enabled(false)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("blitz"):
		_movement.try_blitz()

func _physics_process(delta: float) -> void:
	_handle_weapon_switch()

	match current_state:
		"parrying":
			velocity = Vector2.ZERO
			move_and_slide()
			return
		"attacking":
			_combat.process_attack(delta)
			move_and_slide()
			return

	_handle_movement_input(delta)
	move_and_slide()

func _handle_weapon_switch() -> void:
	if Input.is_action_just_pressed("switch_weapon"):
		cursor.set_weapon_mode(curr_weapon)
		curr_weapon = "shoot" if curr_weapon == "melee" else "melee"

func _handle_movement_input(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0.0:
		last_move_dir = direction.normalized()

	_flip_sprite(direction)

	if Input.is_action_just_pressed("better_parry"):
		_combat.try_parry()
		return

	if Input.is_action_just_pressed("attack"):
		_combat.handle_attack_input()
		return

	velocity = _movement.compute_velocity(direction, delta)

	if direction.length() > 0.0:
		anim_player.play("shoot" if curr_weapon == "shoot" else "WalkLeft")
	else:
		anim_player.play("idle")

func _flip_sprite(direction: Vector2) -> void:
	var facing := direction if direction.length() > 0.0 else last_move_dir
	if facing.x < 0.0:
		sprite_manager.scale.x = 1
	elif facing.x > 0.0:
		sprite_manager.scale.x = -1

func set_state(new_state: String) -> void:
	current_state = new_state

func emit_parrying() -> void:
	emit_signal("parrying")

func is_invulnerable() -> bool:
	return _is_invulnerable

func activate_parry_invulnerability() -> void:
	_invulnerability_generation += 1
	var invulnerability_generation := _invulnerability_generation
	_is_invulnerable = true
	await get_tree().create_timer(parry_invulnerability_duration, true, false, true).timeout
	if invulnerability_generation == _invulnerability_generation:
		_is_invulnerable = false

func _on_hurtbox_hit_by_hitbox(_hitbox: HitboxComponent) -> void:
	_flash_damage_white()
	_combat.hitstop(damage_hitstop_duration, false)

func _on_health_died() -> void:
	set_physics_process(false)
	set_process_input(false)
	velocity = Vector2.ZERO
	hide()

func _flash_damage_white() -> void:
	_damage_flash_generation += 1
	var flash_generation := _damage_flash_generation
	_set_damage_flash_enabled(true)
	await get_tree().create_timer(damage_flash_duration, true, false, true).timeout
	if flash_generation == _damage_flash_generation:
		_set_damage_flash_enabled(false)

func _set_damage_flash_enabled(enabled: bool) -> void:
	var shader_material := sprite_manager.material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("color", Color.WHITE)
	shader_material.set_shader_parameter("fade", 0.0)
	shader_material.set_shader_parameter("tint_factor", 1.0 if enabled else 0.0)
