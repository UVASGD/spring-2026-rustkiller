extends HFSM

@export var fire_time := 1

var _start_ms := 0
var _fired := false

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	if boss == null:
		return
	boss.stop_motion()
	_start_ms = boss.now_ms()
	_fired = false

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if boss == null:
		return
	_flip_visuals()	
	var t := (boss.now_ms() - _start_ms) / 1000.0
	if not _fired and t >= fire_time:
		_fired = true
		boss.spawn_grate_steam_bursts()

func check_transition(_delta: float) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Chase")
	return TransitionData.new(false, "")
