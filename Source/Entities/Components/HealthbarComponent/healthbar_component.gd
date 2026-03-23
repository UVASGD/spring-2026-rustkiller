extends ProgressBar

@export var health_component: HealthComponent
@export var damage_bar_tween_duration: float = 0.35

@export var timer: Timer
@export var damage_bar: ProgressBar 

var _damage_tween: Tween

func _ready() -> void:
	if health_component == null:
		return

	max_value = health_component.max_health
	value = health_component.health
	damage_bar.max_value = health_component.max_health
	damage_bar.value = health_component.health
	health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(health_update: HealthComponent.HealthUpdate) -> void:
	max_value = health_update.max_health
	value = health_update.health
	damage_bar.max_value = health_update.max_health

	if health_update.health < health_update.previous_health:
		timer.start()
	else:
		if _damage_tween:
			_damage_tween.kill()
		damage_bar.value = health_update.health

func _on_timer_timeout() -> void:
	if _damage_tween:
		_damage_tween.kill()

	_damage_tween = create_tween()
	_damage_tween.set_trans(Tween.TRANS_BACK)
	_damage_tween.set_ease(Tween.EASE_OUT)
	_damage_tween.tween_property(damage_bar, "value", value, damage_bar_tween_duration)
