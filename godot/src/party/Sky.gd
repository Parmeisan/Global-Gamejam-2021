extends PartyMember

func _ready():
	update_skills(battler)

func update_skills(b):
	var skill_node = b.get_node("Actions")
	Util.deleteExtraChildren(skill_node, 3)
	for a in TierAbility.get_abilities(b):
		var action : TierAbility
		action = load("res://src/combat/battlers/actions/TierAbility.tscn").instance()
		action.init(a)
		skill_node.add_child(action)

func get_battler_copy(game):
	var b = battler.duplicate()
	b.parent = battler.parent
	update_skills(b)
	return b

func get_class():
	return "Sky"
