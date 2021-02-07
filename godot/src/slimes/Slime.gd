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

enum ABILTIES { RED=0, BLUE, YELLOW }
var ability_tiers = []
# Stats are all of these combined: (maybe, I need to test the system)
#var stats : CharacterStats           # Determined solely by XP/level
var artifact_boosts : CharacterStats # Can be equipped & unequipped
#var merged_boosts : CharacterStats   # Bonus each time a merge is done

var battler_path = "assets/sprites/battlers/"
var battler_ext = ".png"

# Called when the node enters the scene tree for the first time.
func _ready():
	for a in range(0, ABILTIES.size()):
		if a == colour:
			ability_tiers.append(1)
		else:
			ability_tiers.append(0)
	sprite_large = Data.getTexture(battler_path, Data.COLOURS[colour] + "_Slime", battler_ext)
	sprite_small = Data.getTexture(battler_path, Data.COLOURS[colour] + "_Slime_128", battler_ext)

func get_name():
	if battler:
		if not battler.display_name:
			battler.display_name = Data.generate_slime_name()
		return battler.display_name
	else:
		return "unknown"
	

func merge(s : Slime):
	# you can only merge with a primary
	assert(s.is_primary())
	# then add to my own abilities
	for a in range(0, ABILTIES.size()):
		ability_tiers[a] = s.ability_tiers[a]
	#TODO
	#for m in range(0, stats.size()):
	#	merged_boosts[m] += s.stats[m]

func is_primary():
	# a primary has exactly one ability at 1 and both others at 0
	var s_total = 0
	for a in range(0, ABILTIES.size()):
		s_total += ability_tiers[a]
	return s_total == 1

func get_tier_shorthand():
	var tiers = []
	for a in range(0, ABILTIES.size()):
		for t in ability_tiers[a]:
			tiers.append(a)
	# It will look something like 0 0 0 2 (three reds, one yellow)
	return tiers
	
