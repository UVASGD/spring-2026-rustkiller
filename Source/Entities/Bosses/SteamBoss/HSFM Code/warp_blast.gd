extends HFSM

@export var cooldown := 10.0

var _start_ms       := 0
var _fired          := false
var _can_transition := false

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	_fired = false
	_can_transition = false
	boss.set_cd("warp_burst", cooldown)
	boss.stop_motion()
	_start_ms = boss.now_ms()
	boss.warp_burst_over.connect(_on_warp_over)
	

func update(_delta: float) -> void:
	var boss := character as HFSMSteamBoss
	if not _fired:
		_fired = true
		boss.do_warp_burst()

func check_transition(_delta: float) -> TransitionData:
	if _can_transition:
		return TransitionData.new(true, "ExplosiveBlast")
	return TransitionData.new(false, "")
	
func _on_warp_over():
	_can_transition = true
	
func on_exit():
	var boss := character as HFSMSteamBoss
	boss.warp_burst_over.disconnect(_on_warp_over)	
	
	
	
