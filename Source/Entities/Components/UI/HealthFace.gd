class_name HealthFace
extends Sprite2D

@export var animator: AnimationPlayer
@export var hurt_face_duration: float = 0.05

var face_tween: Tween


func _ready() -> void:
	play_normal()


func play_normal() -> void:
	if animator == null:
		return

	if animator.has_animation("normal"):
		animator.play("normal")


func play_hurt() -> void:
	if animator == null:
		return

	if face_tween:
		face_tween.kill()

	if animator.has_animation("hurt"):
		animator.play("hurt")

	face_tween = create_tween()
	face_tween.tween_interval(hurt_face_duration)
	face_tween.tween_callback(play_normal)