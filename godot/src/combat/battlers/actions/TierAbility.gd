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
	if not action.mp_cost:
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
	if not effect.type == type:
		return false
	var pm = instance_from_id(b.parent)
	if effect.has("class") and pm and effect.class != pm.get_class():
		var appl = effect.get(type)
		# The ability is applicable if it appears anywhere in the definition of "applicable"
		for pid in appl:
			if pid == "level": # by level
				if b.stats.level >= appl[pid]:
					return true
			
			if pm.get_class() == "Slime": # by contains colour and tier
				var tier = int(pid.right(1))
				var c_name = pid.substr(0, pid.length() - 1)
				var c_idx = Data.COLOURS.find(c_name) 
				if c_idx >= 0:
					if pm.ability_tiers[c_idx] == tier:
						return true
				else:
					print("Invalid colour/tier definition: ", pid)
	return false

static func do_attack(source, actor, targets, action):
	var arena = Util.getParent(source, "CombatArena")
	if actor.party_member and not targets:
		return false

	var passives = get_abilities(actor, "passive")#TEXT[TYPE.PASSIVE])
	if action.has("mp_cost"):
		actor.use_mana(action.mp_cost)
	if action.has("actor_effect"):
		arena.status_manager.add_effect(actor, action.actor_effect)

	var att = action.num_targets > 0
	for target in targets:
		if att:
			yield(actor.skin.move_to(target), "completed")
			if action.has("attack") and action.attack == "yes":
				var hit = Hit.new(actor)
				target.take_damage(source, hit)
			apply_effects(arena, action, actor, target)
			for passive in passives:
				apply_effects(arena, passive, actor, target)
			
	yield(actor.get_tree().create_timer(1.0), "timeout") # THIS MUST ALWAYS HAPPEN
	yield(actor.skin.return_to_start(), "completed") # Looks funny without this, too
	
	return true

static func apply_effects(arena, action, actor, target):
	if action.has("target_effect"):
		arena.status_manager.add_effect(target, action.target_effect, actor)

