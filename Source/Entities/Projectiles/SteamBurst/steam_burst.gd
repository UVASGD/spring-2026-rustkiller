#The boss or game manager will call to spawn the steam blasts 
#When created, after some amount of time, the blast will trigger, 
#and if the player is in the blast they take damage

extends Area2D

@export var time_until_burst : float
@export var damage : int
var exploding = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(time_until_burst).timeout
	exploding = true
	
	
func _on_area_entered(other_area: Area2D) -> void:
	if other_area is HitboxComponent and other_area.hit_owner == "player":
		if(exploding):
			#call function to do damage on player (only once)
			#basically player.health -= damage
			pass
		pass
