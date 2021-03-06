extends PartyMember

func _ready():
	print("init sky")
	var skill_node = battler.get_node("Actions")
	Util.deleteExtraChildren(skill_node, 3)
	for a in TierAbility.get_abilities(battler):
		var action : TierAbility
		action = load("res://src/combat/battlers/actions/TierAbility.tscn").instance()
		action.init(a)
		skill_node.add_child(action)

func get_class():
	return "Sky"
