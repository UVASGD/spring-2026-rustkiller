extends HFSM

@export var hit_time := 0.10
var _start_ms := 0
var _hit := false

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	boss.stop_motion()
	_start_ms = boss.now_ms()
	_hit = false

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	var t := (boss.now_ms() - _start_ms) / 1000.0
	if not _hit and t >= hit_time:
		_hit = true
		boss.do_slash()

func check_transition(_delta: float) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Chase")
	return TransitionData.new(false, "")
