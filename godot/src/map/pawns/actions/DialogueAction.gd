extends MapAction
class_name DialogueAction

export (String, FILE, "*.json") var dialogue_file_path: String
signal dialogue_loaded(data)


func interact() -> void:
	var dialogue: Dictionary
	if not Util.isnull(dialogue_file_path):
		dialogue = load_dialogue(dialogue_file_path)
	else:
		#print("Attempting to parse full-script.txt")
		dialogue = load_from_text()
	
	yield(local_map.play_dialogue(dialogue, get_base_object()), "completed")
	emit_signal("finished")


func load_dialogue(file_path) -> Dictionary:
	# Parses a JSON file and returns it as a dictionary
	var file = File.new()
	assert(file.file_exists(file_path))

	file.open(file_path, file.READ)
	var dialogue = parse_json(file.get_as_text())
	assert(dialogue.size() > 0)
	return dialogue

# For programmatic interaction
func load_and_run(file_path):
	dialogue_file_path = file_path
	interact()
	yield(self, "finished")

# Because I'm too lazy to keep making json out of plain text
func load_from_text():
	var file = File.new()
	var path = "src/dialogue/full-script.txt"
	if not file.open(path, file.READ) == OK:
		return
	file.seek(0)
	# We expect the file to start with character names and end those with a blank line
	var charnames = {}
	var line_count = 0     # For reporting errors
	var current_line : String = "x" # For this bit, we'll stop at first ""
	while current_line != "" and !file.eof_reached():
		current_line = file.get_line()
		line_count += 1 # Human-readable, so first line is 1
		var dash = current_line.find("-")
		if dash >= 0:
			var cid = current_line.substr(0, dash).strip_edges()
			var cname = current_line.substr(dash + 1).strip_edges()
			cname = cname.replace("-", "").strip_edges()
			#print("Character name: %s=%s" % [cid, cname])
			charnames[cid] = cname

	# Now find a line exactly matching this object's name
	# If we are in a node other than "Actions" (a non-default state)
	# then zoom to this line and then zoom again to [If <state>:]
	var my_name = get_object_name()
	while current_line != my_name and !file.eof_reached():
		current_line = file.get_line()
		line_count += 1
		#print("Skipping: ", current_line)
	if get_parent().name != "Actions":
		var find_line = "[If %s:]" % get_parent().name
		#print("Looking for ", find_line)
		while current_line != find_line and !file.eof_reached():
			current_line = file.get_line()
			line_count += 1
		line_count += 1 # Next after If, as If is a signal to stop reading
	
	# Then read until the next empty line or EOF
	var dialogue = {}
	var uid = 1
	while current_line != "" and !file.eof_reached():
		current_line = file.get_line()
		line_count += 1
		if len(current_line) == 1 and len(current_line[0]) == 0:
			print("Line %s of %s could not be read" % [line_count, path])
			return
		var this_dialogue_line = {}
		# Ignore square brackets
		var firstchar = current_line.substr(0, 1)
		if firstchar == "[" or current_line == "":
			if "Choice" in current_line:
				this_dialogue_line["name"] = ""
				this_dialogue_line["type"] = 'options'
				var colon = current_line.find(":") + 1
				var end = current_line.find("]") - colon
				var opts = current_line.substr(colon, end).strip_edges()
				this_dialogue_line["options"] = opts
				dialogue[Util.padNum(uid, 3)] = this_dialogue_line
				# This has to be the last line in a dialogue
				return dialogue
			if current_line.begins_with("[If"):
				return dialogue
			else:
				pass # Comments (for humans)
		elif firstchar == "+" or firstchar == "-":
			Data.setFlagValue(current_line.substr(1), firstchar == "+")
		else:
			# Replace character names when given
			# Assume main character otherwise
			var cid = "MC"
			var text = current_line
			var colon = current_line.find(":")
			if colon >= 0 and colon <= 4: # if it comes later, it'll be part of text
				cid = current_line.substr(0, colon).strip_edges()
				text = current_line.substr(colon + 1).strip_edges()
			this_dialogue_line["name"] = charnames[cid]
			this_dialogue_line["expression"] = "normal"
			this_dialogue_line["text"] = text
			#print("Line %s: %s" % [Util.padNum(uid, 3), this_dialogue_line])
			dialogue[Util.padNum(uid, 3)] = this_dialogue_line
			uid += 1
	return dialogue

func get_base_object():
	if not get_parent():
		return null
	return get_parent().get_parent()
	
func get_object_name():
	return get_base_object().get_name()

