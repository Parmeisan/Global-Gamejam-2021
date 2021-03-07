extends Item
class_name Artifact

var slime = null
var stats : Resource

func _init(n):
	name = n
	description = n + " Artifact"
	unique = true
	stats = load("res://src/combat/battlers/stats/Artifact_%s.tres" % n)

func assign(s):
	slime = s
	slime.ascend(self)

func unassign():
	if slime:
		slime.descend()
		slime = null

func is_assigned():
	if slime:
		return true
	return false
