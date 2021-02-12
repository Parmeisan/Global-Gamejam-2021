extends TextureButton


func _pressed():
	var monster_list = Util.getParent(self, "MonsterCollection")
	var p = get_parent()
	if get_name() in ["De-Party"]:
		#var pm = Util.getParent(self, "PartyMember")
		# Can't do that, it has a generated name like @PartyMember@43
		var pm = get_parent().get_parent()
		monster_list.selected_1ST = int(pm.get_node("InstanceID").text)
	if get_name() in ["AddPartyMember", "De-Party"]:
		monster_list.doAction(get_name())
	elif p.get_name() == "PrimHeadings":
		# Loop through List Members and find either lowest XP or highest,
		# depending on whether this is first click or second.
		print("PrimHeadings")
	else:
		#print(self.get_instance_id())
		monster_list.clickButton(self)
	
