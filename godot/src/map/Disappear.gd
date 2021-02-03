extends Node

func interact() -> void:
	var p = get_parent().get_parent()
	p.visible = false
	var myMap = Util.getParent(p, "GameBoard").get_parent()
	Data.disappeared.append(myMap.get_name() + "." + p.get_name())
