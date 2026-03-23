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

func _deal_damage_with_resistances(damage: float) -> float:
	var final_damage: float = damage
	if resistance_component:
		final_damage = resistance_component.apply_resistance(damage)
	
	if health_component:
		health_component.damage(final_damage)
	
	return final_damage

func _on_area_entered(other_area: Area2D) -> void:
	if not (other_area is HitboxComponent):
		return

	var hitbox_component := other_area as HitboxComponent
	if entity_name != "" and hitbox_component.hit_owner == entity_name:
		return

	if !detect_only:
		_deal_damage_with_resistances(hitbox_component.damage)
	hit_by_hitbox.emit(hitbox_component)
