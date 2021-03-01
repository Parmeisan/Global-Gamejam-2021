# Base entity that represents a character or a monster in combat
# Every battler has an AI node so all characters can work as a monster
# or as a computer-controlled player ally
extends Position2D

class_name Battler
#-HELP:
# How to add an enemy:
# Duplicate any node from Enemies
# Make editable, make local
# Change icon, turn order, stats, etc
# Save as scene
# Update combat weights, difficulties in Data

signal died(battler)

export var TARGET_OFFSET_DISTANCE: float = 120.0

export var stats: Resource
onready var drops := $Drops
onready var skin = $Skin
onready var actions = $Actions
onready var bars = $Bars
onready var skills = $Skills
onready var ai = $AI

var target_global_position: Vector2
var parent : int # Instance ID

var selected: bool = false setget set_selected
var selectable: bool = false setget set_selectable
var display_name: String

export var party_member = false
export var turn_order_icon: Texture


func _ready() -> void:
	var direction: Vector2 = Vector2(-1.0, 0.0) if party_member else Vector2(1.0, 0.0)
	# FIXME I don't know if this will work, but I kept getting this error without the if:
	# get_global_transform: Condition "!is_inside_tree()" is true.  Returned: get_transform()
	if $TargetAnchor.is_inside_tree():
		target_global_position = $TargetAnchor.global_position + direction * TARGET_OFFSET_DISTANCE
	selectable = true


func initialize():
	skin.initialize()
	update_actions()
	stats = stats.copy()
	stats.connect("health_depleted", self, "_on_health_depleted")

func update_actions():
	actions.initialize(skills.get_children())

func is_able_to_play() -> bool:
	# Returns true if the battler can perform an action
	return stats.health > 0


func set_selected(value):
	selected = value
	skin.blink = value


func set_selectable(value):
	selectable = value
	if not selectable:
		set_selected(false)

func _on_health_depleted():
	selectable = false
	stats.died()
	clear_effects(effect_icons)
	emit_signal("health_depleted")
	yield(skin.play_death(), "completed")
	emit_signal("died", self)


func appear():
	var offset_direction = 1.0 if party_member else -1.0
	skin.position.x += TARGET_OFFSET_DISTANCE * offset_direction
	skin.appear()


func has_point(point: Vector2):
	return skin.battler_anim.extents.has_point(point)


# ======= Stat and status interface/setget functions ===========================
enum STAT { MAX_HEALTH, DEFENSE, STRENGTH, SPEED, MAX_MANA,
	CRIT_CHANCE, CRIT_DMG, MISS_CHANCE, DODGE_CHANCE }
const VARS = [ "health", "defense", "strength", "speed", "mana",
	"crit_chance", "crit_dmg", "miss_chance", "dodge_chance" ]
var stat_modifiers = {}
var stat_multipliers = {}
var ongoing_damage = {}
var effect_icons = {}

signal effects_changed()
func add_effect(arr, uid, val):
	arr[uid] = val
	update_icons(arr)
func remove_effect(arr, uid):
	arr.erase(uid)
	update_icons(arr)
func clear_effects(arr):
	arr.clear()
	update_icons(arr)
func update_icons(arr):
	if arr == effect_icons:
		emit_signal("effects_changed", arr)

var remember_ai
func temporary_ai(temp):
	remember_ai = ai.get_script().resource_path
	ai.set_script(load("res://src/combat/battlers/ai/%s.gd" % temp))
func reset_ai(i):
	ai.set_script(load(remember_ai))
	if party_member:
		ai.set("interface", i)

func get_level() -> int:
	return stats.level
# For enemies only (this stuff is in PartyMember for everyone else)
func set_level(growth_curve, level : int):
	stats = growth_curve.create_stats(growth_curve.level_lookup[level])

func get_final_stat(s : int):
	var st_name = VARS[s]
	var result = stats.get(st_name)
	for m in stat_multipliers:
		result *= (stat_multipliers[m].get(st_name))
	for m in stat_modifiers:
		result += stat_modifiers[m].get(st_name)
	return result

func get_strength() -> int:
	return get_final_stat(STAT.STRENGTH)
func get_defense() -> int:
	return get_final_stat(STAT.DEFENSE)
func get_speed() -> int:
	return get_final_stat(STAT.SPEED)
func get_max_health() -> int:
	return get_final_stat(STAT.MAX_HEALTH)
func get_max_mana() -> int:
	return get_final_stat(STAT.MAX_MANA)
func get_crit_chance() -> int:
	return get_final_stat(STAT.CRIT_CHANCE)
func get_crit_dmg() -> int:
	return get_final_stat(STAT.CRIT_DMG)
func get_miss_chance() -> int:
	return get_final_stat(STAT.MISS_CHANCE)
func get_dodge_chance() -> int:
	return get_final_stat(STAT.DODGE_CHANCE)

# Healing etc

func _is_alive() -> bool:
	# Creating a new slime programmatically during combat will
	# cause this to be nil *just* long enough to crash everything
	if not stats.health:
		return false
	return stats.health > 0

func heal(amount: int):
	stats.update_health(amount)

func take_damage(skill, hit):
	if Data.roll_100() <= get_dodge_chance():
		if skill:
			skill.emit_signal("missed", "Miss!")
	else:
		var att = hit.damage
		var def = get_defense()
		# Defense halves the damage up to its value
		# e.g. a=5, d=10, hit is 2.5.  a=10, def=5, hit is 7.5
		var dmg = (min(att, def) / 2.0) + max(0, att - def)
		var crit = hit.crit_damage # Bypasses defense
		hit.damage = dmg + crit
		stats.update_health(-hit.damage)
	# prevent playing both stagger and death animation if health <= 0
	if _is_alive():
		skin.play_stagger()

func use_mana(amount: int):
	stats.update_mana(-amount)

func set_max_health(value: int):
	if value == null:
		return
	stats.max_health = max(1, value)

func set_max_mana(value: int):
	if value == null:
		return
	stats.max_mana = max(0, value)
