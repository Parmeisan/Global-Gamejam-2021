extends Node
class_name StatusManager

signal added(status)
signal removed(status)

var arena
var effect_templates = {}
var active_effects = {}

func init(a):
	arena = a
	var dict = Data.getDict("src/combat/battlers/AbilityConfig.json")
	for st in dict:
		if st.type in ['passive', 'effect']:
			effect_templates[st.uid] = st

# I think I want this class in charge of what each possible status effect does
# (read from a config file) as well as tracking which battlers have which effects
# and when the effects should go away.  The battlers have a copy of the active
# effects but those should be refreshed each turn from this class's info.

# Statuses are applied fresh at the start of the battle
func start_combat(battlers, arena):
	init(arena)
	for b in battlers:
		active_effects[b] = []
		b.stat_modifiers = {}
		b.stat_multipliers = {}
		for e in effect_templates:
			if has_passive(b, effect_templates[e]):
				add_effect(b, effect_templates[e].uid)

func has_passive(b : Battler, effect : Dictionary):
	return TierAbility.has_ability("passive", b, effect)

# and may be added at any time during a turn
func add_effect(b : Battler, uid : String, attacker : Battler = null):
	assert(effect_templates.has(uid))
	var effect = effect_templates[uid].duplicate()
	active_effects[b].append(effect)
	# Alter stats
	if effect.has("flat_modifier"):
		var stats = create_flat_modifier()
		stats = update_stats(stats, effect.flat_modifier)
		b.add_effect(b.stat_modifiers, uid, stats)
	if effect.has("multiplier"):
		var stats = create_multiplier()
		stats = update_stats(stats, effect.multiplier)
		b.add_effect(b.stat_multipliers, uid, stats)
	if effect.has("dot"):
		b.add_effect(b.ongoing_damage, uid, attacker)
	b.add_effect(b.effect_icons, uid, effect)
	if effect.has("ai"):
		b.temporary_ai(effect.ai)

func update_stats(stats, mods : Dictionary):
	for m in mods:
		if m in stats:
			stats.set(m, mods[m])
		else:
			print("Stat not found: ", m)
	return stats

# then are ticked down and possible removed at the end of each battler's turn
func turn_ended(b):
	for effect in active_effects[b]:
		if effect.has("duration"):
			effect.duration -= 1
			if effect.duration <= 0:
				remove_effect(b, effect.uid)
				active_effects[b].erase(effect.uid)

func remove_effect(b : Battler, uid : String):
	b.remove_effect(b.stat_modifiers, uid)
	b.remove_effect(b.stat_multipliers, uid)
	b.remove_effect(b.effect_icons, uid)
	if effect_templates[uid].has("ai"):
		b.reset_ai(arena.get_node("CombatInterface"))
	active_effects[b].erase(uid)
	
# some effects go off before the turn begins
func turn_started(b):
	for effect in active_effects[b]:
		if effect.has("dot"):
			var ongoing = b.ongoing_damage[effect.uid]
			#var attacker = ongoing.duplicate()
			#attacker.stats.strength *= effect.dot # Multiplier for this damage
			var hit = Hit.new(ongoing)#attacker)
			hit.multiply_bonus(effect.dot)
			b.take_damage(null, hit)


func end_combat(battlers):
	for b in battlers:
		active_effects[b] = {}
		b.stat_modifiers = {}
		b.stat_multipliers = {}

func create_flat_modifier():
	# A version of stats that modifies the character's actual stats
	# Everything should be 0 unless otherwise altered
	var m = CharacterStats.new()
	m.max_health = 0
	m.defense = 0
	m.strength = 0
	m.speed = 0
	m.crit_chance = 0
	m.crit_dmg = 0
	m.miss_chance = 0
	m.dodge_chance = 0
	return m

func create_multiplier():
	# A version of stats that modifies the character's actual stats
	# Everything should be 1 unless otherwise altered
	var m = CharacterStats.new()
	m.max_health = 1
	m.defense = 1
	m.strength = 1
	m.speed = 1
	m.crit_chance = 1
	m.crit_dmg = 1
	m.miss_chance = 1
	m.dodge_chance = 1
	return m
