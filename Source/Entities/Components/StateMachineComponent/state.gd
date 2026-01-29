class_name State
extends Node

#####################################
# This is the base owner state
# Each state will inherit from this
#####################################

const PLAYER_GROUP: StringName = "PLAYER"
var entity 
var target


func _ready():
	entity = get_owner()
	target = _get_target()

func _get_target():
	if not target:
		target = get_tree().get_first_node_in_group(PLAYER_GROUP)
	return target

## The following are to be implemented by the actual state

signal transitioned(state: State, new_state_name: String)

# This is called directly when transitioning to this state
# Useful for setting up the state to be used
# In Idle, we use this function to decide how long we will idle for
func enter():
	pass

# When the state is active, this is essentially the _process() function
func process_state(_delta: float):
	pass

# When the state is active, this is essentially the _physics_process() function
func physics_process_state(_delta: float):
	pass

# Useful for cleaning up the state
# For example, clearing any timers, disconnecting any signals, etc.
func exit():
	pass
