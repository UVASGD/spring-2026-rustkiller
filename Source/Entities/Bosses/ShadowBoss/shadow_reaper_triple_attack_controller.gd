extends Node
class_name ShadowReaperTripleAttackController

@onready var boss: ShadowBoss = get_parent().get_parent() as ShadowBoss

func triple_attack() -> void:
	if boss == null:
		return
	boss._reaper_triple_should_follow_target = false

func begin_reaper_triple_follow() -> void:
	if boss == null:
		return
	boss._reaper_triple_should_follow_target = true

func should_follow_during_reaper_triple() -> bool:
	return boss != null and boss._reaper_triple_should_follow_target
