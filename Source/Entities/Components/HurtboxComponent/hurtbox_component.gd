@tool
class_name HurtboxComponent
extends Area2D

const AttackDebug := preload("res://Source/Scripts/Util/attack_debug.gd")

signal hit_by_hitbox(hitbox_component: HitboxComponent)

@export var health_component: HealthComponent
@export var resistance_component: Node  # add proper type later
@export var bullet_impact_scene: PackedScene
@export var detect_only: bool = false
@export var entity_name:String
@export var knockback_strength: float = 400.0
var _last_processed_physics_frame: int = -1
var _processed_hitboxes_this_frame: Dictionary = {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)

func can_accept_bullet_collision() -> bool:
	return health_component.has_health_remaining if health_component else false

func can_receive_damage() -> bool:
	if not can_accept_bullet_collision():
		return false

	var owner := get_parent()
	if owner and owner.has_method("is_invulnerable") and owner.is_invulnerable():
		return false

	return true

func _deal_damage_with_resistances(damage: float) -> float:
	var final_damage: float = damage
	if resistance_component:
		final_damage = resistance_component.apply_resistance(damage)
	
	if health_component:
		health_component.damage(final_damage)
	
	return final_damage

func apply_hitbox(hitbox_component: HitboxComponent) -> bool:
	if hitbox_component == null:
		AttackDebug.trace_attack_event("apply_hitbox:null_hitbox", hitbox_component, self)
		return false
	if entity_name != "" and hitbox_component.hit_owner == entity_name:
		AttackDebug.trace_attack_event("apply_hitbox:blocked_same_owner", hitbox_component, self)
		return false
	if not hitbox_component.damage_enabled:
		AttackDebug.trace_attack_event("apply_hitbox:blocked_damage_disabled", hitbox_component, self)
		return false
	if not can_receive_damage():
		AttackDebug.trace_attack_event("apply_hitbox:blocked_cannot_receive", hitbox_component, self)
		return false

	var hitbox_source_id := hitbox_component.get_instance_id()
	var current_physics_frame := Engine.get_physics_frames()
	if _last_processed_physics_frame != current_physics_frame:
		_last_processed_physics_frame = current_physics_frame
		_processed_hitboxes_this_frame.clear()

	if _processed_hitboxes_this_frame.has(hitbox_source_id):
		AttackDebug.trace_attack_event("apply_hitbox:blocked_duplicate_frame", hitbox_component, self, {
			"physics_frame": current_physics_frame
		})
		return false
	_processed_hitboxes_this_frame[hitbox_source_id] = true

	AttackDebug.trace_attack_event("apply_hitbox:accepted", hitbox_component, self, {
		"physics_frame": current_physics_frame
	})

	if !detect_only:
		_deal_damage_with_resistances(hitbox_component.damage)
	hit_by_hitbox.emit(hitbox_component)
	_disable_projectile_hitbox_after_successful_hit(hitbox_component)
	return true

func _on_area_entered(other_area: Area2D) -> void:
	if not (other_area is HitboxComponent):
		return

	var hitbox_component := other_area as HitboxComponent
	if hitbox_component.manual_damage_application:
		return

	AttackDebug.trace_attack_event("hurtbox_area_entered", hitbox_component, self)
	apply_hitbox(hitbox_component)

func _disable_projectile_hitbox_after_successful_hit(hitbox_component: HitboxComponent) -> void:
	if hitbox_component == null:
		return

	var hit_source := hitbox_component.get_parent()
	if hit_source == null:
		return

	if hit_source.is_in_group("shadow_projectile"):
		hitbox_component.damage_enabled = false
		if hit_source.has_method("disable_active"):
			hit_source.disable_active()
		return

	var script := hit_source.get_script() as Script
	if script == null:
		return

	if script.resource_path.contains("/Projectiles/"):
		hitbox_component.damage_enabled = false
		if hit_source.has_method("disable_active"):
			hit_source.disable_active()
