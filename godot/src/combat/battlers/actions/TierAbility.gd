extends CombatAction
class_name TierAbility

var action
var uses = -1

func init(ability):
	action = ability
	name = ability.name # Must rename the node in order for the player to see the name
	icon = load("res://assets/sprites/abilities/%s" % ability.icon)
	num_targets = ability.num_targets
	if ability.has("uses"):
		uses = ability.uses

func is_possible():
	if not action.has("mp_cost"):
		return true
	return action.mp_cost <= actor.stats.mana

func execute(targets):
	assert(initialized)
	return do_attack(self, actor, targets, action)

# ======= Static functions ==============================================

#enum TYPE { PASSIVE = 0 }
#const TEXT = [ "passive" ]

static func get_abilities(b : Battler, abil_type : String = "ability"):
	var dict = Data.getDict("src/combat/battlers/AbilityConfig.json")
	var abilities = []
	for a in dict: # If dict is throwing a nil error here, check your syntax in AbilityConfig.json
		if a.type == abil_type and has_ability(abil_type, b, a):
			abilities.append(a)
	return abilities


static func has_ability(type : String, b : Battler, effect : Dictionary):
	var debug = false
	if debug: print("checking %s %s" % [type, effect.uid])
	if not effect.type == type:
		return false
	var pm = instance_from_id(b.parent)
	var matches_class = true
	if pm and effect.has("class"):
		if debug: print("my class: %s, skill class: %s" % [ pm.get_class(), effect.get("class")])
		matches_class = (pm.get_class() == effect.get("class"))
	if pm and matches_class:
		if debug: print("matches so far")
		var appl = effect.get(type)
		# The ability is applicable if it appears anywhere in the definition of "applicable"
		for pid in appl:
			if pid == "level" or pid == pm.get_class(): # by level
				if b.stats.level >= appl[pid]:
					if debug: print("matches level")
					return true
			
			if pm.get_class() == "Slime": # by contains colour and tier
				var tier = int(pid.right(1))
				var c_name = pid.substr(0, pid.length() - 1)
				var c_idx = Data.COLOURS.find(c_name) 
				if c_idx >= 0:
					if pm.ability_tiers[c_idx] == tier:
						if debug: print("matches tier")
						return true
				else:
					print("Invalid colour/tier definition for %s: %s" % [effect.uid, pid])
	return false

static func do_attack(source, actor, targets, action):
	var arena = Util.getParent(source, "CombatArena")
	if actor.party_member and not targets:
		return false

	# Actor effects happen immediately
	if action.has("mp_cost"):
		actor.use_mana(action.mp_cost)
	apply_effects("actor", arena, action, actor, actor)
	update_health("actor", action, actor, actor)
	#var passives = get_abilities(actor, "passive")#TEXT[TYPE.PASSIVE])
	

	var att = action.num_targets > 0
	for target in targets:
		if att:
			yield(actor.skin.move_to(target), "completed")
			if action.has("attack") and action.attack == "yes":
				var hit = Hit.new(actor)
				target.take_damage(source, hit)
		apply_effects("target", arena, action, actor, target)
		update_health("target", action, actor, target)
			#for passive in passives:
			#	apply_effects(arena, passive, actor, target)
			
	yield(actor.get_tree().create_timer(1.0), "timeout") # THIS MUST ALWAYS HAPPEN
	yield(actor.skin.return_to_start(), "completed") # Looks funny without this, too
	
	return true

static func update_health(type, action, actor, target):
	if action.has("%s_hp" % type):
		var effects = action.get("%s_hp" % type)
		var amount = 0
		if effects.has("target_health"):
			# I could call heal_fraction here, but then we see 2 numbers float by
			amount += effects.target_health * target.get_max_health()
		if effects.has("actor_health"):
			amount += effects.actor_health * actor.get_max_health()
		target.heal(amount)
	

static func apply_effects(type, arena, action, actor, target):
	if action.has("%s_effect" % type):
		arena.status_manager.add_effect(target, action.get("%s_effect" % type), actor)

