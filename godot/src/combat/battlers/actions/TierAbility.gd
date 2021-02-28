extends CombatAction
class_name TierAbility

var action
var uses = -1

func init(ability):
	action = ability
	name = ability.name # Must rename the node in order for the player to see the name\
	icon = load("res://assets/sprites/abilities/%s" % ability.icon)
	num_targets = ability.num_targets
	if ability.has("uses"):
		uses = ability.uses

static func get_slime_abilities(dict, b : Battler):
	var abilities = []
	for a in dict: # If dict is throwing a nil error here, check your syntax in AbilityConfig.json
		if a.type == "ability" and StatusManager.has_record("ability", b, a):
			abilities.append(a)
	return abilities

func is_possible():
	if not action.mp_cost:
		return true
	return action.mp_cost <= actor.stats.mana

func execute(targets):
	assert(initialized)
	var arena = Util.getParent(self, "CombatArena")
	
	if actor.party_member and not targets:
		return false

	if action.mp_cost:
		actor.use_mana(action.mp_cost)
	if action.actor_effect:
		arena.status_manager.add_effect(actor, action.actor_effect)

	var att = action.num_targets > 0
	for target in targets:
		if att:
			yield(actor.skin.move_to(target), "completed")
			var hit = Hit.new(actor)
			target.take_damage(self, hit)
		yield(actor.get_tree().create_timer(1.0), "timeout") # THIS MUST ALWAYS HAPPEN
		yield(return_to_start_position(), "completed") # Looks funny without this, too
	
	return true

