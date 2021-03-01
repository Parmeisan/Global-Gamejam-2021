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

static func get_slime_abilities(b : Battler, abil_type : String = "ability"):
	var dict = Data.getDict("src/combat/battlers/AbilityConfig.json")
	var abilities = []
	for a in dict: # If dict is throwing a nil error here, check your syntax in AbilityConfig.json
		if a.type == abil_type and StatusManager.has_record(abil_type, b, a):
			abilities.append(a)
	return abilities

func is_possible():
	if not action.mp_cost:
		return true
	return action.mp_cost <= actor.stats.mana

func execute(targets):
	assert(initialized)
	return do_attack(self, actor, targets, action)
	
static func do_attack(source, actor, targets, action):
	var arena = Util.getParent(source, "CombatArena")
	
	if actor.party_member and not targets:
		return false

	var passives = get_slime_abilities(actor, "passive")
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
	
