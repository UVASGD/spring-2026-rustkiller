extends ProgressBar

@export var parent_node: Node
@export var target_entity_name: String = ""
@export var damage_bar_tween_duration: float = 0.35
@export var timer: Timer
@export var damage_bar: ProgressBar 
@export var face: HealthFace


var health_component: HealthComponent
var _damage_tween: Tween

func _ready() -> void:
	var target_parent := parent_node if parent_node != null else get_parent()
	if target_parent == null:
		return

	if target_entity_name != "":
		health_component = _find_health_component_for_entity(target_parent, target_entity_name)
	if health_component == null and parent_node != null:
		health_component = _find_health_component(target_parent)
	if health_component == null:
		health_component = _find_health_component(target_parent)
	if health_component == null:
		push_warning("No HealthComponent found for health bar target")
		return

	max_value = health_component.max_health
	value = health_component.health
	damage_bar.max_value = health_component.max_health
	damage_bar.value = health_component.health
	health_component.health_changed.connect(_on_health_changed)

func _find_health_component(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child

		var found := _find_health_component(child)
		if found != null:
			return found

	return null

func _find_hurtbox_by_entity_name(node: Node, entity_name: String) -> HurtboxComponent:
	if node is HurtboxComponent:
		var hurtbox := node as HurtboxComponent
		if hurtbox.entity_name == entity_name:
			return hurtbox

	for child in node.get_children():
		var found := _find_hurtbox_by_entity_name(child, entity_name)
		if found != null:
			return found

	return null

func _find_health_component_for_entity(start_node: Node, entity_name: String) -> HealthComponent:
	var current: Node = start_node
	while current != null:
		var hurtbox := _find_hurtbox_by_entity_name(current, entity_name)
		if hurtbox != null and hurtbox.health_component != null:
			return hurtbox.health_component
		current = current.get_parent()

	return null

func _on_health_changed(health_update: HealthComponent.HealthUpdate) -> void:
	max_value = health_update.max_health
	value = health_update.health
	damage_bar.max_value = health_update.max_health

	if health_update.health < health_update.previous_health:
		if face != null:
			face.play_hurt()
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
