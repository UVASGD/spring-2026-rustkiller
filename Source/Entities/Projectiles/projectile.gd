extends Node2D
class_name Projectile


var damage: float
var direction: Vector2 = Vector2.DOWN
var speed: float = 800.0
var lifetime: float = 0.5
var hit_owner: String

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox.damage = damage
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.hit_owner = hit_owner

func _on_hitbox_area_entered(_area: Area2D) -> void:
	pass # does nothing by default, override
