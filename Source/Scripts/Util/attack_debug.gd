class_name AttackDebug
extends RefCounted

const ENABLED := false
const MAX_STACK_FRAMES := 10

static func trace_attack_event(event_name: String, hitbox: HitboxComponent = null, hurtbox: HurtboxComponent = null, extra: Dictionary = {}) -> void:
	if not ENABLED or not OS.is_debug_build():
		return

	var lines: PackedStringArray = []
	lines.append("[AttackDebug] %s" % event_name)
	lines.append("  hitbox=%s" % _describe_hitbox(hitbox))
	lines.append("  hurtbox=%s" % _describe_hurtbox(hurtbox))

	if not extra.is_empty():
		for key in extra.keys():
			lines.append("  %s=%s" % [str(key), str(extra[key])])

	lines.append("  stack:")
	for frame in _get_formatted_stack():
		lines.append("    %s" % frame)

	print("\n".join(lines))

static func _get_formatted_stack() -> PackedStringArray:
	var formatted_stack: PackedStringArray = []
	var stack: Array = get_stack()
	var frame_count := mini(stack.size(), MAX_STACK_FRAMES)

	for frame_index in frame_count:
		var frame := stack[frame_index] as Dictionary
		var source := str(frame.get("source", "<unknown>"))
		var function_name := str(frame.get("function", "<unknown>"))
		var line := int(frame.get("line", -1))
		formatted_stack.append("%s:%d -> %s()" % [source, line, function_name])

	return formatted_stack

static func _describe_hitbox(hitbox: HitboxComponent) -> String:
	if not is_instance_valid(hitbox):
		return "<null>"

	return "%s owner=%s damage=%s enabled=%s path=%s" % [
		hitbox.name,
		hitbox.hit_owner,
		str(hitbox.damage),
		str(hitbox.damage_enabled),
		str(hitbox.get_path())
	]

static func _describe_hurtbox(hurtbox: HurtboxComponent) -> String:
	if not is_instance_valid(hurtbox):
		return "<null>"

	return "%s entity=%s detect_only=%s path=%s" % [
		hurtbox.name,
		hurtbox.entity_name,
		str(hurtbox.detect_only),
		str(hurtbox.get_path())
	]
