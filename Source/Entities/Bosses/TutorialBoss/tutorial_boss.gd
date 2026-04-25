extends CharacterBody2D
class_name Dummy

@onready var state_machine = $TutorialBossHFSM as HFSM
@onready var animation_player = $AnimationPlayer
@onready var health_component = $HealthComponent as HealthComponent

func _ready() -> void:
	state_machine.character = self
	state_machine.animator = animation_player
	state_machine._accept_export_fields()
	state_machine._on_enter()
	animation_player.speed_scale = 1.0

func _physics_process(delta: float) -> void:
	state_machine._update(delta)
