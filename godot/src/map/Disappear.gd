extends Node

func interact() -> void:
	var p = get_parent().get_parent()
	p.visible = false
