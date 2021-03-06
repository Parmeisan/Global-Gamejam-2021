# Initializes the map's pawns and emits signals so the
# Game node can start encounters
# Processes in pause mode
extends Node
class_name LocalMap

signal enemies_encountered(formation)
signal dialogue_finished

export (int) var map_difficulty

onready var dialogue_box = $MapInterface/DialogueBox
onready var grid = $GameBoard

func _ready() -> void:
	assert(dialogue_box)
	for action in get_tree().get_nodes_in_group("map_action"):
		(action as MapAction).initialize(self)
	# Disappeared things should stay that way
	for i in range(0, Data.disappeared.size()):
		var obj = Data.disappeared[i]
		if grid.has_node(obj):
			grid.get_node(obj).visible = false


func spawn_party(party) -> void:
	grid.pawns.spawn_party(grid, party)


func start_encounter(formation, pawn = null) -> void:
	emit_signal("enemies_encountered", formation, pawn)#formation.instance())


func play_dialogue(data, obj):
	dialogue_box.start(data, obj)
	yield(dialogue_box, "dialogue_ended")
