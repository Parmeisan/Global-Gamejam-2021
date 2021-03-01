extends CombatAction


func execute(targets):
	assert(initialized)
	var action = {
		"uid": "ATTACK",
		"type": "ability",
		"name": "Attack",
		"icon": "attack.png",
		"attack": "yes",
		"num_targets": 1
	}
	return TierAbility.do_attack(self, actor, targets, action)
#	if actor.party_member and not targets:
#		return false
#
#	for target in targets:
#		yield(actor.skin.move_to(target), "completed")
#		#Util.getParent(self, "Game").music_player.play_slime_hit()
#		var hit = Hit.new(actor)
#		target.take_damage(self, hit)
#		yield(actor.get_tree().create_timer(1.0), "timeout")
#		yield(return_to_start_position(), "completed")
#	return true
