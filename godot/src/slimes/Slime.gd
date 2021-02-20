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

const growth_curve = preload("res://src/combat/battlers/jobs/SlimeJob.tres")
const skills_all = [preload("res://src/combat/battlers/actions/Flee.tscn")]

func _ready():
	pass

func _init(c):
	update_colour(c)
	if not battler.display_name:
		battler.display_name = Data.generate_slime_name()
	ability_tiers = []
	for a in range(0, ABILITIES.size()):
		if a == colour:
			ability_tiers.append(1)
		else:
			ability_tiers.append(0)
	update_skills()

func update_colour(c):
	colour = c
	var colour_text = Data.COLOURS[colour]
	var new_slime_resource = "res://src/combat/battlers/enemies/slimes/%sSlimeAlly.tscn" % colour_text
	battler = load(new_slime_resource).instance()
	growth = growth_curve
	pawn_anim_path = "Anim"
	sprite_large = Data.getTexture(battler_path, colour_text + "_Slime", battler_ext)
	sprite_small = Data.getTexture(battler_path, colour_text + "_Slime_128", battler_ext)
	initialize_pm()
	battler._ready()
	battler.initialize()
	visible = true

func update_skills():
	var skill_node = battler.get_node("Actions")
	Util.deleteExtraChildren(skill_node, 1)
	for sk in skills_all:
		var action : CombatAction = sk.instance()
		skill_node.add_child(action)
	var red_tier = ability_tiers[ABILITIES.RED]
	for a in range(red_tier):
	#	if a <= skills_red.size():
	#		var action = TierAbilityRed.new(skills_red[a])
	#		skill_node.add_child(action)
		#var action : TierAbility = TierAbility.new(ABILITIES.RED, a, red_tier)
		var action : TierAbility
		action = load("res://src/combat/battlers/actions/TierAbility.tscn").instance()
		action.init(ABILITIES.RED, a, red_tier) # Set each ability at the strength owned
		skill_node.add_child(action)
	battler.update_actions() # Skills learned by level

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

func get_battler_copy(game):
	return clone(game).battler

func clone(game):
	var result = get_script().new(colour)#game.create_slime(colour)
	for a in range(0, ABILITIES.size()):
		result.ability_tiers[a] = ability_tiers[a]
	result.update_skills()
	result.battler.display_name = battler.display_name
	result.party_slot = party_slot
	#TODO
	#for m in range(0, stats.size()):
	#	merged_boosts[m] += s.stats[m]
	return result

func merge(game, s : Slime):
	# I used to start this function with a clone(), but since battler
	# gets cleared out when the colour changes (we must instance a new
	# e.g. OrangeSlime.tscn), forcing update of all variables kept there,
	# and we have to recalc the abilities and XP and everything anyway,
	# I think it best to just explicitly recalculate absolutely everything
	var result = get_script().new(colour)
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
	result.battler.display_name = battler.display_name # battler just got cleared
	var slot = party_slot
	if slot == -1 or (s.party_slot >= 0 and s.party_slot < slot):
		slot = s.party_slot
	result.party_slot = slot
	return result

func get_battle_anim():
	var colour_text = Data.COLOURS[colour]
	var new_anim_resource = "res://src/combat/animation/%sSlimeAnim.tscn" % colour_text
	return load(new_anim_resource).instance()

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
	
