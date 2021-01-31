# Player-controlled pawn.
# Set to Stop during pause
extends PawnActor
class_name PawnLeader

onready var destination_point := $DestinationPoint

var _path_current := PoolVector3Array()
var _direction := Vector2()

var map
var weight_total

func _ready() -> void:
	destination_point.set_as_toplevel(true)
	destination_point.hide()
	# Random encounters
	map = get_parent().get_parent().get_parent()
	weight_total = 0.0
	for w in range(0, Data.combat_weights.size()):
		weight_total += Data.combat_weights[w]
	randomize()

func _process(delta: float) -> void:
	if _path_current.size() > 0:
		var next_point := Vector2(_path_current[0].x, _path_current[0].y)
		_direction = next_point - game_board.world_to_map(global_position)
		_path_current.remove(0)

	if _direction != Vector2():
		update_look_direction(_direction)
		var target_position: Vector2 = game_board.request_move(self, _direction)
		if target_position:
			move_to(target_position)
			random_encounter()
		else:
			bump()

	if _path_current.size() == 0:
		destination_point.hide()
		_direction = Vector2()


func random_encounter():
	#print("Chance of encounter: %s%%" % curr_combat_chance)
	var rnd = rand_range(0.0, 100.0)
	if rnd < Data.curr_combat_chance:
		var enc_rnd = rand_range(0.0, weight_total)
		var enc_check = 0.0
		var enc_type = 0
		for w in range(0, Data.combat_weights.size()):
			enc_check += Data.combat_weights[w]
			if enc_rnd > enc_check:
				enc_type += 1
		print("Encountered a %s!" % Data.combat_types[enc_type])
		Data.curr_combat_chance = 0.0
		var enc = map.get_node("GameBoard/Pawns/" + Data.combat_types[enc_type])
		enc.start_interaction()
	else:
		if Data.curr_combat_chance < Data.max_combat_chance:
			Data.curr_combat_chance += Data.combat_chance_inc

func get_key_input_direction(event: InputEventKey) -> Vector2:
	return Vector2(
		int(event.is_action_pressed("ui_right")) - int(event.is_action_pressed("ui_left")),
		int(event.is_action_pressed("ui_down")) - int(event.is_action_pressed("ui_up"))
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_direction = get_key_input_direction(event)
#	elif (
#		event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed
#		or event is InputEventScreenTouch and event.pressed
#	):
#		_path_current = game_board.find_path(global_position, get_global_mouse_position())
#		if _path_current.size() > 0:
#			var pos := _path_current[_path_current.size() - 1]
#			destination_point.position = game_board.map_to_world(Vector2(pos.x, pos.y))
#			destination_point.show()
