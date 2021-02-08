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
var ability_tiers = []
# Stats are all of these combined: (maybe, I need to test the system)
#var stats : CharacterStats           # Determined solely by XP/level
var artifact_boosts : CharacterStats # Can be equipped & unequipped
#var merged_boosts : CharacterStats   # Bonus each time a merge is done

var battler_path = "assets/sprites/battlers/"
var battler_ext = ".png"

const battlers = [preload("res://src/combat/battlers/enemies/slimes/RedSlimeAlly.tscn"),
					 preload("res://src/combat/battlers/enemies/slimes/BlueSlimeAlly.tscn"),
				   preload("res://src/combat/battlers/enemies/slimes/YellowSlimeAlly.tscn")]
const battle_anims = [preload("res://src/combat/animation/RedSlimeAnim.tscn"),
					 preload("res://src/combat/animation/BlueSlimeAnim.tscn"),
				   preload("res://src/combat/animation/YellowSlimeAnim.tscn")]
const growth_curve = preload("res://src/combat/battlers/jobs/SlimeJob.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_data(colour)

func set_data(c):
	colour = c
	battler = battlers[colour].instance()
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

func merge(s : Slime):
	# you can only merge with a primary
	assert(s.is_primary())
	# then add to my own abilities
	for a in range(0, ABILITIES.size()):
		ability_tiers[a] = s.ability_tiers[a]
	#TODO
	#for m in range(0, stats.size()):
	#	merged_boosts[m] += s.stats[m]

func is_primary():
	# a primary has exactly one ability at 1 and both others at 0
	var s_total = 0
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
	
