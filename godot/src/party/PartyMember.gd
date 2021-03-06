# Represents a playable character to add in the player's party
# Holds the data and nodes for the character's battler, pawn on the map,
# and the character's stats to save the game
extends Node2D

class_name PartyMember

signal level_changed(new_value, old_value)

export var pawn_anim_path: NodePath
export var growth: Resource

export var experience: int setget _set_experience
#var stats: Resource

onready var battler: Battler = $Battler
onready var SAVE_KEY: String = "party_member_" + name


func _ready():
	if battler:
		initialize_pm()

func initialize_pm():
	assert(pawn_anim_path)
	assert(growth)
	battler.stats = growth.create_stats(experience)
	battler.parent = self.get_instance_id()


func update_stats(before_stats: CharacterStats):
	# Update this character's stats to match select changes
	# that occurred during combat or through menu actions
	var before_level = before_stats.level
	var after_level = growth.get_level(experience)
	if before_level != after_level:
		battler.stats = growth.create_stats(experience)
		emit_signal("level_changed", after_level, before_level)


func get_battler_copy(game): #used in child function
	# Returns a copy of the battler to add to the CombatArena
	# at the start of a battle
	var b = battler.duplicate()
	b.parent = battler.parent
	return b


func get_pawn_anim():
	# Returns a copy of the PawnAnim that represents this character,
	# e.g. to add it as a child of the currently loaded game map
	return get_node(pawn_anim_path).duplicate()


func _set_experience(value: int):
	if value == null:
		return
	experience = max(0, value)
	if battler and battler.stats:
		update_stats(battler.stats)

func get_experience():
	return experience

func save(save_game: Resource):
	save_game.data[SAVE_KEY] = {
		'experience': experience,
		'health': battler.stats.health,
		'mana': battler.stats.mana,
	}


func load(save_game: Resource):
	var data: Dictionary = save_game.data[SAVE_KEY]
	experience = data['experience']
	battler.stats.health = data['health']
	battler.stats.mana = data['mana']

