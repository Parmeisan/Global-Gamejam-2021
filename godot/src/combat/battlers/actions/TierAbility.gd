extends CombatAction
class_name TierAbility

var colour
var action
var tier
var skills = [
	["Fireball", "Zap"]
]
enum COLOURS { RED=0, BLUE, YELLOW }

# Red Tiers
enum RED { FIREBALL = 0, ZAP }
var fireball_scaling = [ 0.6, 0.65, 0.70, 0.75, 0.8 ]

func init(c, a, t):
	colour = c
	action = a
	tier = t
	# Get the human-readable action name. Files are expected to be named in a pattern from here,
	# e.g. "Flee" > "flee.png" and "Area Attack" > "area_attack.png"
	description = skills[colour][action]
	name = description # Must rename the node in order for the player to see the name
	var filename : String = description.replace(" ", "_").to_lower()
	icon = load("res://assets/sprites/abilities/%s.png" % filename)


func execute(targets):
	assert(initialized)
	var attack_strength = actor.stats.strength
	match colour:
		COLOURS.RED:
			if action == RED.FIREBALL:
				attack_strength *= 30#fireball_scaling[tier]
	
	if actor.party_member and not targets:
		return false

	for target in targets:
		yield(actor.skin.move_to(target), "completed")
		var hit = Hit.new(attack_strength)
		target.take_damage(hit)
		yield(actor.get_tree().create_timer(1.0), "timeout")
		yield(return_to_start_position(), "completed")
	return true
