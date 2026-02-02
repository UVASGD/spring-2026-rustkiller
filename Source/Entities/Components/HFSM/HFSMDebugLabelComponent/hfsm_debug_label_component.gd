extends Label

@export var hfsm: HFSM

func _ready() -> void:
	# Optional: clear the label at start
	text = "HFSM Debug"

func _physics_process(delta: float) -> void:
	if hfsm:
		var active_state := hfsm.get_lowest_active_state()
		var progress = floor(active_state.get_progress() * 100) / 100  # 2 decimals
		text = "%s | %ss" % [active_state.move_name, progress]
	else:
		text = "HFSM not assigned"
