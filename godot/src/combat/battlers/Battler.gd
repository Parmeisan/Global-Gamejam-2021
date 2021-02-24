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


func take_damage(hit):
	stats.take_damage(hit)
	# prevent playing both stagger and death animation if health <= 0
	if stats.health > 0:
		skin.play_stagger()


func _on_health_depleted():
	selectable = false
	yield(skin.play_death(), "completed")
	emit_signal("died", self)


func appear():
	var offset_direction = 1.0 if party_member else -1.0
	skin.position.x += TARGET_OFFSET_DISTANCE * offset_direction
	skin.appear()


func has_point(point: Vector2):
	return skin.battler_anim.extents.has_point(point)


# For enemies only (this stuff is in PartyMember for everyone else)
const growth_curve = preload("res://src/combat/battlers/jobs/Grey01Job.tres")
const level_lookup = [ 0, 4, 24, 69, 149, 274, 454, 699, 1019, 1424, 1924, 2528, 3248, 4093, 5073, 6198, 7478, 8923, 10543, 12348, 14348 ]
var enemy_level : int
func set_level(level : int):
	stats = growth_curve.create_stats(level_lookup[level])
