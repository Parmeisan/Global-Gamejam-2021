extends MapAction
class_name MapTransition

export var target_map: String
export var current_map: String
export var spawn_x: int
export var spawn_y: int

func interact():
	var game_node = Util.getParent(self, "Game")
	local_map = Util.getParent(self, "GameBoard").get_parent()

	var new_map
	print("Target map ", target_map)
	local_map.queue_free()
	#if target_map in Data.loaded_maps:
	#	new_map = Data.loaded_maps[target_map]
	#else:
	new_map = load(target_map).instance()
	#	Data.loaded_maps[target_map] = new_map
	game_node.add_child(new_map)
	game_node.switch_maps(new_map)
	Data.map_difficulty = new_map.map_difficulty
	
	var spawn_point = new_map.get_node("GameBoard/SpawningPoint")
	spawn_point.set_global_position(Vector2(spawn_x, spawn_y))
	
	var gb = new_map.get_node("GameBoard")
	var ysort = gb.get_node("Pawns")
	# turn off auto-interaction, spawn party, turn back on
	#toggleAuto(false) # nvm, doesn't help, will just place further away
	ysort.spawn_party(gb, game_node.get_node("Party"))
	#toggleAuto(true)
	
	
	#ysort.rebuild_party()
	emit_signal("finished")

func toggleAuto(val : bool):
	for p in get_tree().get_nodes_in_group("transition_point"):
		p.AUTO_START_INTERACTION = val

func get_class(): return "MapTransition"

#func _ready():
#	var game_node = Util.getParent(self, "Game")
#	Data.loaded_maps["res://src/map/LocalMap.tscn"] = game_node.get_node("LocalMap")
