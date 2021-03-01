extends Node

class_name CombatAction

var initialized = false

# Since Actions can be instanced by code (ie skills) these
# actions doesn't have an owner, that's why we get the owner
# from it's parent (BattlerActions.gd)
onready var actor: Battler = get_parent().get_owner()

export (Texture) var icon = load("res://assets/sprites/icons/slash.png")
export (String) var description: String = "Base combat action"
export (int) var num_targets = 1

func initialize(battler: Battler) -> void:
	actor = battler
	initialized = true

func is_possible():
	return true

func execute(targets: Array):
	assert(initialized)
	print("%s missing overwrite of the execute method" % name)
	return false

func send_end_signals(targets):
	for target in targets:
		yield(actor.get_tree().create_timer(1.0), "timeout")

func return_to_start_position():
	yield(actor.skin.return_to_start(), "completed")


func can_use() -> bool:
	return true
