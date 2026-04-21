@tool
class_name HurtboxComponent
extends Area2D

signal hit_by_hitbox(hitbox_component: HitboxComponent)

@export var health_component: HealthComponent
@export var resistance_component: Node  # add proper type later
@export var bullet_impact_scene: PackedScene
@export var detect_only: bool = false
@export var entity_name:String
@export var knockback_strength: float = 400.0


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
		return false
	if entity_name != "" and hitbox_component.hit_owner == entity_name:
		return false
	if not hitbox_component.damage_enabled:
		return false
	if not can_receive_damage():
		return false

	if !detect_only:
		_deal_damage_with_resistances(hitbox_component.damage)
	hit_by_hitbox.emit(hitbox_component)
	return true

func _on_area_entered(other_area: Area2D) -> void:
	if not (other_area is HitboxComponent):
		return

	apply_hitbox(other_area as HitboxComponent)
