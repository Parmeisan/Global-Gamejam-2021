extends CombatAction

func _ready():
	icon = load("res://assets/sprites/icons/flee.png")
	description = "Flee"
	num_targets = 0

func execute(targets):
	assert(initialized)
	if actor.party_member and not targets:
		return false

	var arena = Util.getParent(self, "CombatArena")
	arena.battle_end()
	
	for target in targets:
		yield(actor.get_tree().create_timer(1.0), "timeout")
	return false







