@tool
class_name HurtFlashComponent
extends Node2D

@export var hurtbox_component: HurtboxComponent
@export var sprite: CanvasItem
@export var flash_color: Color = Color.RED
@export var flash_duration := 0.01
@export var use_solid_flash: bool = false
@export_range(0.0, 1.0, 0.01) var flash_strength: float = 0.35

var flash_timer: Timer
var _original_material: Material
var _flash_material: ShaderMaterial
var _is_flashing: bool = false

const SOLID_FLASH_SHADER := preload("res://Source/Entities/Components/HurtFlashComponent/solid_flash.gdshader")

func _ready() -> void:
	if hurtbox_component:
		hurtbox_component.hit_by_hitbox.connect(hit_by_hitbox)

	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.wait_time = flash_duration
	flash_timer.timeout.connect(on_flash_timeout)
	add_child(flash_timer)

func hit_by_hitbox(hitbox: HitboxComponent) -> void:
	if use_solid_flash:
		_apply_solid_flash()
	else:
		sprite.modulate = flash_color
	flash_timer.start()
	_is_flashing = true

func on_flash_timeout() -> void:
	if use_solid_flash:
		sprite.material = _original_material
	else:
		sprite.modulate = Color.WHITE
	_is_flashing = false

func _apply_solid_flash() -> void:
	if sprite == null:
		return

	if _flash_material == null:
		_flash_material = ShaderMaterial.new()
		_flash_material.shader = SOLID_FLASH_SHADER

	if not _is_flashing:
		_original_material = sprite.material
	_flash_material.set_shader_parameter("flash_color", flash_color)
	_flash_material.set_shader_parameter("flash_strength", flash_strength)
	sprite.material = _flash_material
