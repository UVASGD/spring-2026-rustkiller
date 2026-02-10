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
	
func set_damage(new_damage: float) -> void:	
	damage = new_damage
	if hitbox:
		hitbox.damage = new_damage
		
func shoot(initial_loc: Vector2, new_direction: Vector2, new_speed: float, new_hit_owner: String) -> void:
	global_position = initial_loc
	direction = new_direction.normalized()
	speed = new_speed
	hit_owner = new_hit_owner
	if hitbox:
		hitbox.hit_owner = new_hit_owner
		
func set_lifetime(new_lifetime: float) -> void:		
	lifetime = new_lifetime
