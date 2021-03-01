# Can't extend from StatBar (the class_name) because this won't let us export
# the inherited variables from the base class 
extends "res://src/combat/interface/bars/StatBar.gd"
class_name EffectsBar

onready var grid = $Grid
const ICON_PATH = "assets/sprites/abilities/"
	
func _connect_value_signals(b: Battler) -> void:
	b.connect("effects_changed", self, "_on_effects_changed")

func _on_effects_changed(effects) -> void:
	var eff = grid.get_node("Effect").duplicate()
	eff.visible = true
	Util.deleteExtraChildren(grid, 1)
	for e in effects:
		if effects[e].has("icon"):
			eff.get_node("Icon").texture = Data.getTexture(ICON_PATH, effects[e].icon, "")
			eff.hint_tooltip = effects[e].label
			grid.add_child(eff)
