extends Label

@export var health_component: HealthComponent
@export var state_machine: StateMachineComponent

func _ready() -> void:
	return

	#_update_label()
#
#func _on_state_transition(_state: State, _new_state_name: String) -> void:
	#_update_label()
#
#func _on_health_transition(health_state: HealthComponent.HealthUpdate) -> void:
	#_update_label()
#
#func _update_label() -> void:
	#text = "%s | HP: %.1f" % [state_machine.current_state_name, health_component.health]
