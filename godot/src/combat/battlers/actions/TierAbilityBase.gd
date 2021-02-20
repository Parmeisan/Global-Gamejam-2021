extends CombatAction
class_name TierAbilityBase

var action
var tier
var skills = []

enum ACTIONS { FIREBALL = 0, ZAP }
var fireball_scaling = [ 0.6, 0.65, 0.70, 0.75, 0.8 ]

func fillSkills():
	pass # This should be overridden in the child class

func setAbility(a, t):
	action = a
	tier = t
	fillSkills()
	init(skills[action])

func init(descr):
	# Takes the human-readable action name. Files are expected to be named in a pattern from here,
	# e.g. "Flee" > "flee.png" and "Area Attack" > "area_attack.png"
	description = descr
	name = descr # Must rename the node in order for the player to see the name
	var filename : String = descr.replace(" ", "_").to_lower()
	icon = load("res://assets/sprites/abilities/%s.png" % filename)

# Default (mainly for testing) - just attacks
func execute(targets):
	assert(initialized)
	if actor.party_member and not targets:
		return false

	for target in targets:
		yield(actor.skin.move_to(target), "completed")
		var hit = Hit.new(actor.stats.strength)
		target.take_damage(hit)
		yield(actor.get_tree().create_timer(1.0), "timeout")
		yield(return_to_start_position(), "completed")
	return true
