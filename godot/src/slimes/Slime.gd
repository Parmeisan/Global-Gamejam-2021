extends PartyMember
class_name Slime

#export var stats: Resource
#export var hp: int # Starting values
#export var mp: int
#export var xp: int

export(int, "Red", "Blue", "Yellow") onready var colour
var sprite_large : Texture
var sprite_small : Texture
var current_xp = 0
var favourite : bool = false
var party_slot : int = -1

enum ABILITIES { RED=0, BLUE, YELLOW }
enum COLOURS { RED=0, BLUE, YELLOW, PURPLE, ORANGE, GREEN }
const NUM_TIERS = 4
var ability_tiers = []
# Stats are all of these combined: (maybe, I need to test the system)
#var stats : CharacterStats           # Determined solely by XP/level
var artifact_boosts : CharacterStats # Can be equipped & unequipped
#var merged_boosts : CharacterStats   # Bonus each time a merge is done

var battler_path = "assets/sprites/battlers/"
var battler_ext = ".png"

#const battler = "res://src/combat/battlers/enemies/slimes/%sSlimeAlly.tscn"
const battlers = [preload("res://src/combat/battlers/enemies/slimes/RedSlimeAlly.tscn"),
					 preload("res://src/combat/battlers/enemies/slimes/BlueSlimeAlly.tscn"),
				   preload("res://src/combat/battlers/enemies/slimes/YellowSlimeAlly.tscn"),
				   preload("res://src/combat/battlers/enemies/slimes/PurpleSlimeAlly.tscn"),
				   preload("res://src/combat/battlers/enemies/slimes/OrangeSlimeAlly.tscn"),
					preload("res://src/combat/battlers/enemies/slimes/GreenSlimeAlly.tscn")]
const battle_anims = [preload("res://src/combat/animation/RedSlimeAnim.tscn"),
					 preload("res://src/combat/animation/BlueSlimeAnim.tscn"),
				   preload("res://src/combat/animation/YellowSlimeAnim.tscn"),
				   preload("res://src/combat/animation/PurpleSlimeAnim.tscn"),
				   preload("res://src/combat/animation/OrangeSlimeAnim.tscn"),
					preload("res://src/combat/animation/GreenSlimeAnim.tscn")]
const growth_curve = preload("res://src/combat/battlers/jobs/SlimeJob.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_data(colour)

func set_data(c):
	update_colour(c)
	if not battler.display_name:
		battler.display_name = Data.generate_slime_name()
	growth = growth_curve
	pawn_anim_path = "Anim"
	initialize_pm()
	ability_tiers = []
	for a in range(0, ABILITIES.size()):
		if a == colour:
			ability_tiers.append(1)
		else:
			ability_tiers.append(0)

func update_colour(c):
	colour = c
	battler = battlers[colour].instance()
	sprite_large = Data.getTexture(battler_path, Data.COLOURS[colour] + "_Slime", battler_ext)
	sprite_small = Data.getTexture(battler_path, Data.COLOURS[colour] + "_Slime_128", battler_ext)

func init_party_stuff():
	battler._ready()
	battler.initialize()
	visible = true

func get_name():
	return battler.display_name
func get_colour():
	return Data.COLOURS[colour]

func add_to_party(slot : int):
	party_slot = slot
func remove_from_party():
	party_slot = -1
func is_in_party():
	return party_slot >= 0


func duplicate_slime(game):
	var result = game.create_slime(colour)
	for a in range(0, ABILITIES.size()):
		result.ability_tiers[a] = ability_tiers[a]
	result.battler.display_name = battler.display_name
	result.update_colour(result.get_colour_from_abilities())
	result.party_slot = party_slot
	#TODO
	#for m in range(0, stats.size()):
	#	merged_boosts[m] += s.stats[m]
	return result

func merge(game, s : Slime):
	var result = duplicate_slime(game)
	var colours = 0 # If you get to 3, this is invalid
	for a in range(0, ABILITIES.size()):
		result.ability_tiers[a] += s.ability_tiers[a]
		if result.ability_tiers[a] > 1:
			colours += 1
		if result.ability_tiers[a] > NUM_TIERS: # Anything above max is invalid
			return false
	if colours > 2:
		return false
	result.update_colour(result.get_colour_from_abilities())
	result.party_slot = min(party_slot, s.party_slot)
	return result

func is_primary():
	# a primary has exactly one ability at 1 and both others at 0
	var s_total = 0
	#print("Abilities is size %s" %[ABILITIES.size()])
	for a in range(0, ABILITIES.size()):
		s_total += ability_tiers[a]
	return s_total == 1

func get_tier_shorthand():
	var tiers = []
	for a in range(0, ABILITIES.size()):
		for t in ability_tiers[a]:
			tiers.append(a)
	# It will look something like 0 0 0 2 (three reds, one yellow)
	return tiers
	
func get_colour_from_abilities():
	var colours_as_strings = [ "100", "010", "001", "110", "101", "011" ]
	var my_colour_as_string = ""
	for a in ability_tiers:
		#colours.append(a > 0)
		my_colour_as_string += str(int(a > 0))
	for s in range(0, colours_as_strings.size()):
		if my_colour_as_string == colours_as_strings[s]:
			return s
	return -1
	
