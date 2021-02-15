extends CombatAction

func execute(targets):
	assert(initialized)
	if actor.party_member and not targets:
		return false

	for target in targets:
		yield(actor.skin.move_to(target), "completed")
		if target.stats.health < 1000:#10:#FIXME For testing
			var hit = Hit.new(1000)
			#var combat_arena = target.get_parent().get_parent()
			#combat_arena.capture_reward()
			#target.drops.get_children().push_back({'item': 'Slime.tres', 'amount': '1'})
			var monster_collection: MonsterCollection = get_node("/root/Game/MonsterCollection")
			
			var enemy_type = target.get_name()
			print("Capturing ", enemy_type)
			if "Grey" in enemy_type:
				if "Duo" in enemy_type:
					monster_collection.add_grey(1)
				elif "Trio" in enemy_type:
					monster_collection.add_grey(2)
				else:
					monster_collection.add_grey(0)
			else:
				var colour
				if "Red" in enemy_type:
					colour = 0
				elif "Blue" in enemy_type:
					colour = 1
				elif "Yellow" in enemy_type:
					colour = 2
				var slime: Slime = Slime.new(colour)
				
				# Purely aesthetic - turn the target happy
				var battle_anim = target.get_node("Skin")
				Util.deleteExtraChildren(battle_anim, 2)
				battle_anim.add_child(slime.battle_anims[slime.colour].instance())
				
				monster_collection.add_slime(slime)
			
			target.take_damage(hit)
		yield(actor.get_tree().create_timer(1.0), "timeout")
		yield(return_to_start_position(), "completed")
	return true
	
#func temp() -> void:
#	var monster_collection: MonsterCollection = get_node("/root/Game/MonsterCollection")

#	#This is not the most sensible place to be constructing the slime
#	#Its stats should instead get figured from what was capture
#	print("woo")
#	var slime: Slime = Slime.new()
#	slime.stats = load("res://src/slimes/CherrySlime.tres")
#	slime.hp = slime.stats.max_health
#	slime.xp = 0
#	monster_collection.add_slime(slime)


#func _ready() -> void:
#	temp()







