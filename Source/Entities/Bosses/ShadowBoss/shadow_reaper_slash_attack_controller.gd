extends Node
class_name ShadowReaperSlashAttackController

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func can_start_reaper_slash() -> bool:
	return boss != null and boss.has_target() and boss._reaper_slash_cooldown_remaining <= 0.0

func begin_reaper_slash_cooldown() -> void:
	if boss == null:
		return
	boss._reaper_slash_cooldown_remaining = boss.reaper_slash_cooldown

func stop_reaper_slash_movement() -> void:
	if boss == null:
		return
	boss._reaper_slash_should_stop = true
	boss.stop_motion()

func should_stop_reaper_slash_movement() -> bool:
	return boss != null and boss._reaper_slash_should_stop

func reset_reaper_slash_movement() -> void:
	if boss == null:
		return
	boss._reaper_slash_should_stop = false

func set_reaper_hitbox_slash_damage() -> void:
	if boss == null or boss.reaper_hitbox == null:
		return
	boss.reaper_hitbox.damage = boss.get_reaper_slash_damage()

func set_reaper_hitbox_triple_damage() -> void:
	if boss == null or boss.reaper_hitbox == null:
		return
	boss.reaper_hitbox.damage = boss.get_reaper_triple_damage()

func set_reaper_hitbox_active(enabled: bool) -> void:
	if boss == null or boss.reaper_hitbox == null:
		return

	boss.reaper_hitbox.monitoring = enabled
	boss.reaper_hitbox.monitorable = enabled
	boss.reaper_hitbox.damage_enabled = enabled

	for child in boss.reaper_hitbox.get_children():
		boss._set_collision_shapes_disabled_recursive(child, not enabled)

func set_reaper_hitbox_enabled(enabled: bool) -> void:
	if boss == null or boss.reaper_hitbox == null:
		return

	boss.reaper_hitbox.monitoring = true
	boss.reaper_hitbox.monitorable = true
	boss.reaper_hitbox.damage_enabled = enabled
