extends Node
class_name StatusEffects

signal added(status)
signal removed(status)

#var statuses_active = {}
# Example status
#const POISON = {
#	'name': "Poison",
#	'effect': {
#		'periodic_damage': {
#			'cycles': 5, 'stat': 'health', 'damage': 1,
#		} } }
#const INVINCIBLE = {
#	'name': "Invincible",
#	'effect': {'stat_modifier': {'add': {'defense': 1000, 'magic_defense': 1000}}}
#}
#
#Name,Modified_Stat,Mod_Type,Modified_Value
#Shaken,Strength,%Strength,75
#Shaken,Defense,%Defense,75
#
#Miss Turn
#Alter AI
#Take Damage (% of original hit)



var modifiers_list = {}   # The flat values, e.g. crit chance = 0.05
var multipliers_list = {} # The values dependent on base stat, e.g. crit damage = 25% of attack
func _ready():
	var dict = {} # read from Data (CSV)
	for st in dict:
		var stats : CharacterStats
		stats = CharacterStats.create_stats_simple(st.hp, st.def, st.att, st.sp, st.mp)

#func add(id, status):
#	statuses_active[id] = status
#func remove(id):
#	statuses_active.erase(id)


func as_string():
	var string = ""
	for status in statuses_active.values():
		string += "%s.%s: %s" % [status['id'], status['name'], status['effect']]
	return string
