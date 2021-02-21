extends MapAction
class_name StartCombatAction

#export var formation: PackedScene
export (Array, String) var enemy_list

func interact() -> void:
	get_tree().paused = false
	
	var game = Util.getParent(self, "Game")
	var acting_pawn = get_parent().get_parent()
	
	var formation = []
	for e in enemy_list:
		var b : Battler = game.get_node("Enemies/" + e)
		formation.append(b.duplicate())

	local_map.start_encounter(formation, acting_pawn)
	emit_signal("finished")
