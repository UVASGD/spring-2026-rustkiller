@tool
class_name HealthComponent
extends Node2D

signal health_changed(health_update: HealthUpdate)
signal died()

@export var max_health: float:
	get: 
		return max_health
	set(value):
		max_health = value
		if health > max_health:
			health = max_health

func _ready() -> void:
	health = max_health

var health: float:
	get:
		return health
	set(value):
		var previous_health: float = health
		health = clampf(value, 0, max_health)
		
		var health_update := HealthUpdate.new()
		health_update.previous_health = previous_health
		health_update.health = health
		health_update.max_health = max_health
		health_update.health_percent = health_percent
		
		health_changed.emit(health_update)
		
		if !has_health_remaining && !has_died:
			has_died = true
			died.emit()

var has_health_remaining: bool:
	get: return !is_equal_approx(health, 0.0)

var health_percent: float:
	get: return (health / max_health) if max_health > 0 else 0.0

var has_died: bool = false

func damage(damage_amount: float) -> void:
	health -= damage_amount

func heal(heal_amount: float) -> void:
	damage(-heal_amount)

class HealthUpdate extends RefCounted:
	var previous_health: float
	var health: float
	var max_health: float
	var health_percent: float
