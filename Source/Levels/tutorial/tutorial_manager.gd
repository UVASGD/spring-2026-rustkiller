extends CanvasLayer

@onready var tutorial_label: Label = $TutorialLabel
@onready var hint_label: Label = $HintLabel
@onready var move_zone: Area2D = $"../MoveZone"
@onready var projectile_spawner: Node2D = $"../ProjectileSpawner"
@onready var dummy_spawn_point: Marker2D = $"../DummySpawnPoint"

@export var dummy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var player: PlayerController
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 0.0  
@export var projectile_lifetime: float = 5.0
@export var time_between_projectiles: float = 2.5

enum Step { MOVE, PARRY_OR_DASH, DUMMY, SANDBOX }
var _current_step: Step = Step.MOVE
var _dummy_spawned := false
var _firing := false
var _dummy_hit := false
var _projectile_parry_count := 0
var _dummy_parry_count := 0
var _dummy_parry_goal_complete := false

func _ready() -> void:
	tutorial_label.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	move_zone.body_entered.connect(_on_move_zone_entered)
	player.parrying.connect(_on_player_parried)
	show_hint("Use WASD to move around!")
	_show_text("Make your way to the marker!")

func _on_move_zone_entered(body: Node2D) -> void:
	if body != player or _current_step != Step.MOVE:
		return
	move_zone.hide()
	_advance_to_parry_step()

func _advance_to_parry_step() -> void:
	_current_step = Step.PARRY_OR_DASH
	_projectile_parry_count = 0
	show_hint("Use Right Click to Parry, which heals you, and Shift to Dodge!")
	_show_text("Parry or Dash to dodge the incoming projectiles! Parry 5 projectiles to move on to the next stage!")
	_start_firing()

func _start_firing() -> void:
	if _firing:
		return
	_firing = true
	_fire_loop()

func _fire_loop() -> void:
	if _current_step != Step.PARRY_OR_DASH:
		_firing = false
		return
	_fire_projectile()
	await get_tree().create_timer(time_between_projectiles).timeout
	_fire_loop()

func _fire_projectile() -> void:
	if not projectile_scene or not player:
		return
	var projectile := projectile_scene.instantiate()
	var direction := (player.global_position - projectile_spawner.global_position).normalized()

	HitboxComponent.get_child_component(projectile).init(projectile_damage, "boss")
	var motion := ProjectileMotionComponent.get_child_component(projectile)
	motion.shoot(
		projectile_spawner.global_position,
		direction,
		projectile_speed,
		projectile_lifetime
	)
	get_tree().current_scene.add_child(projectile)

func _on_player_parried() -> void:
	match _current_step:
		Step.PARRY_OR_DASH:
			_handle_projectile_parry()
		Step.DUMMY:
			_handle_dummy_parry()

# call this from player blitz/dash if you also want dash to count:
func notify_dashed() -> void:
	if _current_step != Step.PARRY_OR_DASH:
		return

func _handle_projectile_parry() -> void:
	if _current_step != Step.PARRY_OR_DASH:
		return

	_projectile_parry_count += 1
	if _projectile_parry_count < 5:
		return

	_advance_to_dummy_step()

func _advance_to_dummy_step() -> void:
	_current_step = Step.DUMMY
	_firing = false
	_dummy_parry_count = 0
	_dummy_parry_goal_complete = false
	if not _dummy_spawned and dummy_scene:
		var dummy := dummy_scene.instantiate()
		dummy.global_position = dummy_spawn_point.global_position
		get_tree().current_scene.add_child(dummy)
		_dummy_spawned = true
		
		var health = dummy.get_node("HealthComponent") as HealthComponent
		if health:
			health.health_changed.connect(_on_dummy_hit)
		
	_show_text("Parrying also works on boss attacks! Parry the boss three times when its attacking to move on!")

func _handle_dummy_parry() -> void:
	if _current_step != Step.DUMMY or _dummy_parry_goal_complete:
		return

	_dummy_parry_count += 1
	if _dummy_parry_count < 3:
		return

	_dummy_parry_goal_complete = true
	_show_text("Press q to lock on and lock off the dummy. Switch between melee and range with f and click to attack!")

func _on_dummy_hit(health_update: HealthComponent.HealthUpdate) -> void:
	var damage := health_update.previous_health - health_update.health
	if damage <= 0.0:
		return
	if _current_step != Step.DUMMY or not _dummy_parry_goal_complete:
		return
	_current_step = Step.SANDBOX
	show_hint("Great job! Keep practicing!")
	_tutorial_sandbox()
	_spawn_exit_marker()
	
		
func _tutorial_sandbox() -> void:
	# This function can be used to set up a sandbox environment after the tutorial is completed.
	# For example, you could spawn some enemies, give the player new abilities, or just let them practice.
	_fire_loop_infinite()
	
	pass

func _fire_loop_infinite() -> void:
	while _current_step == Step.SANDBOX:
		_fire_projectile()
		await get_tree().create_timer(time_between_projectiles).timeout

func _spawn_exit_marker() -> void:
	move_zone.show()
	move_zone.body_entered.connect(_on_exit_zone_entered)
	_show_text("Head back to the marker to return to the main menu!")

func _on_exit_zone_entered(body: Node2D) -> void:
	if body != player:
		return
	var game_container := _find_game_container()
	if game_container:
		game_container.call_deferred("return_to_main_menu", self)

func _show_text(text: String) -> void:
	var tween := create_tween()
	tween.tween_property(tutorial_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		tutorial_label.text = text
	)
	tween.tween_property(tutorial_label, "modulate:a", 1.0, 0.4)

func show_hint(text: String) -> void:
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		hint_label.text = text
	)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.4)

func _find_game_container() -> GameContainer:
	var current: Node = get_parent()
	while current:
		if current is GameContainer:
			return current as GameContainer
		current = current.get_parent()
	return null
