class_name Bullet
extends Node2D

var damage: float
var direction: Vector2 = Vector2.DOWN
var speed: float = 800.0
var lifetime: float = 0.5

var _lifetime_timer: float = 0.0
var _has_hit: bool = false

@onready var hitbox: HitboxComponent = $HitboxComponent
@export var hit_owner:String

func _ready() -> void:
	hitbox.damage = damage
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.hit_owner = hit_owner

func _process(delta: float) -> void:
	if _has_hit:
		return

	global_position += direction * speed * delta
	
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		
		if hurtbox.can_accept_bullet_collision() and hurtbox.entity_name != "boss":
			_has_hit = true
			
			# Spawn impact effect if available
			if hurtbox.bullet_impact_scene:
				var impact = hurtbox.bullet_impact_scene.instantiate()
				impact.global_position = global_position
				get_tree().current_scene.add_child(impact)
			
			queue_free()
