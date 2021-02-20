extends TierAbilityBase
class_name TierAbilityRed

enum ACTIONS { FIREBALL = 0, ZAP }
var fireball_scaling = [ 0.6, 0.65, 0.70, 0.75, 0.8 ]

func fillSkills():
	skills = ["Fireball", "Zap"]


func execute(targets):
	assert(initialized)
	var attack_strength = actor.stats.strength
	if action == ACTIONS.FIREBALL:
		attack_strength *= fireball_scaling[tier]
	
	if actor.party_member and not targets:
		return false

	for target in targets:
		yield(actor.skin.move_to(target), "completed")
		var hit = Hit.new(attack_strength)
		target.take_damage(hit)
		yield(actor.get_tree().create_timer(1.0), "timeout")
		yield(return_to_start_position(), "completed")
	return true
