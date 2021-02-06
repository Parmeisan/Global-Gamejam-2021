extends MapAction
class_name DialogueAction

export (String, FILE, "*.json") var dialogue_file_path: String
signal dialogue_loaded(data)


func interact() -> void:
	var dialogue: Dictionary
	if not Util.isnull(dialogue_file_path):
		dialogue = load_dialogue(dialogue_file_path)
	else:
		print("Attempting to parse full-script.txt")
		dialogue = load_from_text()
	
	yield(local_map.play_dialogue(dialogue), "completed")
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
	# We expect to start with character names and end those with a blank line
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
	var my_name = get_object_name()
	while current_line != my_name and !file.eof_reached():
		current_line = file.get_line()
		line_count += 1
		#print("Skipping: ", current_line)
	
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
			pass
		elif firstchar == "+" or firstchar == "-":
			Data.flags[current_line.substr(1)] = (firstchar == "+")
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

func get_object_name():
	var p = get_parent().get_parent()
	return p.get_name()
