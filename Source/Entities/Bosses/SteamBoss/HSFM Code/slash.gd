extends HFSM

@export var hit_time := 0.10
var _start_ms := 0
var _hit := false
@export var _hitbox: HitboxComponent
@export var _collision_shape: CollisionShape2D

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	_set_hitbox_enabled(false)
	boss.stop_motion()
	_start_ms = boss.now_ms()
	_hit = false

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	var t := (boss.now_ms() - _start_ms) / 1000.0
	if not _hit and t >= hit_time:
		_hit = true
		_flip_visuals()

func check_transition(_delta: float) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Chase")
	return TransitionData.new(false, "")
	
func on_exit():
	_set_hitbox_enabled(false)
	
func _set_hitbox_enabled(enabled: bool):
	if _collision_shape:
		_collision_shape.set_deferred("disabled", enabled)
	if _hitbox:
		if enabled:
			_hitbox.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			_hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
