class_name PlayerController
extends CharacterBody2D

@export var entity_name: String = "player"
@export var speed: float = 200.0
@export var hp: int = 3

var sfx_melee_attack: AudioStream = preload("res://Source/Entities/Player/better_player/SFX/Single Swipe.mp3")
var sfx_shoot: AudioStream 
var sfx_parry: AudioStream = preload("res://Source/Entities/Player/better_player/SFX/Parry.mp3")
var sfx_walk: AudioStream = preload("res://Source/Entities/Player/better_player/SFX/Footstep.mp3")
var walk_step_interval: float = 0.34
var walk_step_interval_fast: float = 0.24
var walk_min_speed_ratio: float = 0.35
var walk_pitch_min: float = 0.96
var walk_pitch_max: float = 1.04

var current_state: String = "idle"
var curr_weapon: String = "melee"
var last_move_dir: Vector2 = Vector2.RIGHT

signal parrying

@onready var sprite_manager: Node2D       = $SpriteManager
@onready var anim_player: AnimationPlayer = $PlayerAnimation
@onready var cursor: Node2D               = $Cursor

@onready var _movement: PlayerMovement = $PlayerMovement
@onready var _combat: PlayerCombat     = $PlayerCombat

@export var _sfx_player: AudioStreamPlayer2D
@export var _walk_sfx_player: AudioStreamPlayer2D
var _walk_sfx_timer: float = 0.0

func _ready() -> void:
	_combat.setup(self)
	_movement.setup(self)
	parrying.connect(_on_parrying)

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
		curr_weapon = "shoot" if curr_weapon == "melee" else "melee"
		cursor.set_weapon_mode(curr_weapon)

func _handle_movement_input(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0.0:
		last_move_dir = direction.normalized()

	_flip_sprite(direction)

	if Input.is_action_just_pressed("better_parry"):
		_combat.try_parry()
		return

	if Input.is_action_just_pressed("attack"):
		_play_sound_for_weapon()
		_combat.handle_attack_input()
		return

	velocity = _movement.compute_velocity(direction, delta)
	_update_walk_sfx(delta, direction)

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
	parrying.emit()

func _play_sound_for_weapon() -> void:
	if curr_weapon == "melee":
		_play_stream(sfx_melee_attack)
	else:
		_play_stream(sfx_shoot)

func _on_parrying() -> void:
	_play_stream(sfx_parry)

func _play_stream(sound: AudioStream) -> void:
	if sound == null:
		return

	_sfx_player.stream = sound
	_sfx_player.play()

func _update_walk_sfx(delta: float, direction: Vector2) -> void:
	if direction.length() <= 0.0:
		_stop_walk_sfx()
		return

	var speed_ratio := clampf(velocity.length() / max(speed, 0.001), 0.0, 1.0)
	if speed_ratio < walk_min_speed_ratio:
		_stop_walk_sfx()
		return

	_walk_sfx_timer -= delta
	if _walk_sfx_timer > 0.0:
		return

	var step_interval := lerpf(walk_step_interval, walk_step_interval_fast, speed_ratio)
	_walk_sfx_player.pitch_scale = randf_range(walk_pitch_min, walk_pitch_max)
	_walk_sfx_player.play()
	_walk_sfx_timer = step_interval

func _stop_walk_sfx() -> void:
	_walk_sfx_timer = 0.0
	if _walk_sfx_player != null and _walk_sfx_player.playing:
		_walk_sfx_player.stop()
