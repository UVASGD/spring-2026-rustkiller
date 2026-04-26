extends HFSM

@export var cooldown := 4.0     # set to something if you want (e.g., 4.0)
@export var thrust_time := 0.18 # when to apply thrust hitbox within lunge

var _start_ms := 0
var _dir := Vector2.ZERO
var _thrusted := false

func on_enter() -> void:
	var boss := character as HFSMSteamBoss
	if cooldown > 0.0:
		boss.set_cd("lunge", cooldown)

	boss.stop_motion()
	_dir = boss.dir_to_player()
	_start_ms = boss.now_ms()
	_thrusted = false

func update(delta: float) -> void:
	var boss := character as HFSMSteamBoss
	var t := (boss.now_ms() - _start_ms) / 1000.0

	# move for configured lunge_time
	if t <= boss.lunge_time:
		boss.do_lunge_step(delta, _dir)

	# thrust moment
	if not _thrusted and t >= thrust_time:
		_thrusted = true
		_flip_visuals()
		boss.do_lunge_thrust()

func check_transition(_delta: float) -> TransitionData:
	var boss := character as HFSMSteamBoss
	var t := (boss.now_ms() - _start_ms) / 1000.0
	if t >= boss.lunge_time or animation_ended():
		return TransitionData.new(true, "Chase")
	return TransitionData.new(false, "")
