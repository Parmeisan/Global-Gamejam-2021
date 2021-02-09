extends TextureButton


func _pressed():
	var monster_list = Util.getParent(self, "MonsterCollection")
	var p = get_parent()
	if get_name() in ["AddPartyMember"]:
		monster_list.doAction(get_name())
	elif p.get_name() == "PrimHeadings":
		# Loop through List Members and find either lowest XP or highest,
		# depending on whether this is first click or second.
		print("PrimHeadings")
	else:
		#print(self.get_instance_id())
		monster_list.clickButton(self)
	
