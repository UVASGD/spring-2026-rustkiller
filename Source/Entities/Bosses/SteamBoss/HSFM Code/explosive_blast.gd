extends HFSM

@export var cooldown := 10.0
@export var fire_time := 0.20

var _start_ms := 0
var _fired := false

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	boss.set_cd("explosive_blast", cooldown)
	boss.stop_motion()
	_start_ms = boss.now_ms()
	_fired = false

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	var t := (boss.now_ms() - _start_ms) / 1000.0
	if not _fired and t >= fire_time:
		_fired = true
		boss.do_explosive_burst()

func check_transition(_delta: float) -> TransitionData:
	if animation_ended():
		return TransitionData.new(true, "Chase")
	return TransitionData.new(false, "")
