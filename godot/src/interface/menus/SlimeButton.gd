extends TextureButton


func _pressed():
	var monster_list = Util.getParent(self, "MonsterCollection")
	var p = get_parent()
	if p.get_name() == "PrimHeadings":
		# Loop through List Members and find either lowest XP or highest,
		# depending on whether this is first click or second.
		print("PrimHeadings")
	else:
		monster_list.clickButton(self)
	
