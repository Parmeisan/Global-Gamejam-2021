# Base object that represents an attack or a hit

class_name Hit

var damage = 0
var crit_damage = 0
# var effect : StatusEffect = StatusEffect.new()

func _init(actor, additional_damage: int = 0) -> void:
	var strength = actor.stats.strength
	
	damage = strength + additional_damage

func add_crit(strength : int, percent_of_attack : float):
	crit_damage = floor(float(strength) * percent_of_attack / 100.0)
