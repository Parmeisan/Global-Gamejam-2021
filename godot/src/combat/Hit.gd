# Base object that represents an attack or a hit

class_name Hit

var damage = 0
var crit_damage = 0
# var effect : StatusEffect = StatusEffect.new()

func _init(actor) -> void:
	damage = actor.get_strength()
	if Data.roll_100() <= actor.get_miss_chance():
		#skill.emit_signal("missed", "Miss!")
		damage = 0
	else:
		if Data.roll_100() <= actor.get_crit_chance():
			crit_damage = actor.get_crit_dmg()

#func add_crit(strength : int, percent_of_attack : float):
#	crit_damage = floor(float(strength) * percent_of_attack / 100.0)

func add_flat_bonus(additional_damage: int = 0):
	damage += additional_damage
	
func multiply_bonus(multiplier: int = 1):
	damage *= multiplier
