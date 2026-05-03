extends Node
class_name ShadowPlayerPhaseController

@onready var boss: ShadowBoss = get_parent() as ShadowBoss

func enter_phase() -> void:
	if boss == null:
		return
	if not boss._player_phase_active:
		boss._refill_health_for_phase(boss.player_phase_health)
	boss._player_phase_active = true
	boss._reaper_phase_active = false
	boss._player_phase_switch_ready = false
	boss._reaper_phase_complete = false
	boss._machine_pending_phase = ""
	boss._animal_next_idle_duration_override = -1.0
	boss.reset_reaper_slash_movement()
	boss._reaper_attack_bag.clear()
	boss._last_reaper_attack_state = ""
	boss._restore_after_machine_intermission()
	boss.enable_phase_hitboxes()
	boss.stop_motion()
	if boss.sfx_manager:
		boss.sfx_manager.play_player_arrival_audio()
