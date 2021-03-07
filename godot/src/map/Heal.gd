extends MapAction
class_name HealAction

func interact() -> void:
	var game = Util.getParent(self, "Game")
	game.heal_all()
	emit_signal("finished")

func get_class(): return "HealAction"
