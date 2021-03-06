# Represents a Battler's actual stats: health, strength, etc.
# See the child class GrowthStats.gd for stats growth curves
# and lookup tables
extends Resource
class_name CharacterStats

signal health_changed(new_health, old_health)
signal health_depleted
signal mana_changed(new_mana, old_mana)
signal mana_depleted

var level: int
var health: int
var mana: int
# If adding a stat, look at StatusManager and Battler too!
export var max_health: float = 1 # These are float so that multiplier stats can be like 0.75
export var defense: float = 1
export var strength: float = 1
export var speed: float = 1
export var max_mana: float = 0
export var crit_chance: float = 0
export var crit_dmg: float = 0
export var miss_chance: float = 0
export var dodge_chance: float = 0
var is_alive: bool = true

func reset():
	health = self.max_health
	mana = self.max_mana
func died():
	health = 0 # This should always be the case, but just to be safe
	update_mana(-mana) # Set this to 0 so that the mana bar disappears
					   # Mana should be some fixed value on rez anyway (0? full? 10%?)

func ressurect():
	health = self.max_health * 0.10
	mana = self.max_mana * 0.10

func copy() -> CharacterStats:
	# Perform a more accurate duplication, as normally Resource duplication
	# does not retain any changes, instead duplicating from what's registered
	# in the ResourceLoader
	var copy = duplicate()
	copy.health = health
	copy.mana = mana
	return copy

func update_health(amount : int):
	var old_health = health
	health += amount
	health = max(0, health)
	health = min(health, max_health)
	if health != old_health:
		emit_signal("health_changed", health, old_health)
		if health == 0:
			emit_signal("health_depleted")

func update_mana(amount: int):
	var old_mana = mana
	mana += amount
	mana = max(0, mana)
	mana = min(mana, max_mana)
	if mana != old_mana:
		emit_signal("mana_changed", mana, old_mana)
		if mana == 0:
			emit_signal("mana_depleted")

