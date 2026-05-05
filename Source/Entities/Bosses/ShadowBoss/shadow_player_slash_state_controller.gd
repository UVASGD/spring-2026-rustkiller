extends Node
class_name ShadowPlayerSlashStateController

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func can_start_slash() -> bool:
	return boss != null and boss.has_target() and boss._slash_cooldown_remaining <= 0.0

func begin_slash_cooldown() -> void:
	if boss == null:
		return
	boss._slash_cooldown_remaining = boss.slash_cooldown

func teleport_next_to_target() -> void:
	if boss == null or not boss.has_target():
		return

	var side := signf(boss.global_position.x - boss.player.global_position.x)
	if is_zero_approx(side):
		side = -1.0 if randf() < 0.5 else 1.0

	var destination := boss.player.global_position + Vector2(side * boss.slash_teleport_offset, 0.0)
	if not boss._is_valid_world_position(destination):
		return
	boss.global_position = destination
	boss.stop_motion()
	boss.face_target()

func teleport_close_to_target_for_phase_transition() -> void:
	if boss == null or not boss.has_target():
		return

	var side := signf(boss.global_position.x - boss.player.global_position.x)
	if is_zero_approx(side):
		side = -1.0 if randf() < 0.5 else 1.0

	var destination := boss.player.global_position + Vector2(side * boss.phase_transition_teleport_offset, 0.0)
	if not boss._is_valid_world_position(destination):
		return
	boss.global_position = destination
	boss.stop_motion()
	boss.face_target()
