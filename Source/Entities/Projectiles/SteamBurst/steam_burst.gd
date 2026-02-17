extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	
func _on_area_entered(other_area: Area2D) -> void:
	if other_area is HitboxComponent and other_area.hit_owner == "player":
		#call function to do damage on player
		pass
