@tool
class_name HurtFlashComponent
extends Node2D

@export var hurtbox_component: HurtboxComponent
@export var sprite: CanvasItem
@export var flash_color: Color = Color.RED
@export var flash_duration := 0.01

var flash_timer: Timer

func _ready() -> void:
	if hurtbox_component:
		hurtbox_component.hit_by_hitbox.connect(hit_by_hitbox)

	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.wait_time = flash_duration
	flash_timer.timeout.connect(on_flash_timeout)
	add_child(flash_timer)

func hit_by_hitbox(hitbox: HitboxComponent) -> void:
	sprite.modulate = flash_color
	flash_timer.start()

func on_flash_timeout() -> void:
	sprite.modulate = Color.WHITE
