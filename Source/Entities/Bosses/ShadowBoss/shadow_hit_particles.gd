extends Node2D

@export var hurtbox_component: HurtboxComponent

@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	if hurtbox_component:
		hurtbox_component.hit_by_hitbox.connect(_on_hurtbox_hit_by_hitbox)

func _on_hurtbox_hit_by_hitbox(_hitbox: HitboxComponent) -> void:
	if hurtbox_component:
		global_position = hurtbox_component.global_position
	else:
		global_position = get_parent().global_position

	particles.restart()
	particles.emitting = true
