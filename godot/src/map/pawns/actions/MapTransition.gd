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
	ysort.spawn_party(gb, game_node.get_node("Party"))
	
	
	#ysort.rebuild_party()
	emit_signal("finished")

func get_class(): return "MapTransition"

#func _ready():
#	var game_node = Util.getParent(self, "Game")
#	Data.loaded_maps["res://src/map/LocalMap.tscn"] = game_node.get_node("LocalMap")
