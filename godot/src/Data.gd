extends Node


static func getDict(f):
	var file = File.new()
	var json
	if file.open("%s" % [f], file.READ) == OK:
		json = parse_json(file.get_as_text())
	else:
		print("Error reading file %s" % [f])
	file.close()
	return json

static func fillProps(folder, tab):
	var file = File.new()
	var dict
	var path = folder + tab + ".csv"
	if file.open(path, file.READ) == OK:
		#Game.debugMessage(Game.CAT.FILE, "Found file " + tab)
		dict = Data.parseCSV(path, file)
	else:
		null#Game.reportError(Game.CAT.FILE, "Error reading file %s" % path)
	file.close()
	return dict

static func filter(d, prop, value, multi, asDict):
	var res = {} # Only one of these two will be returned
	var arr = [] # Unless multi is false, in which case neither will be
	for row in d.values():
		var matches = true
		for i in range(0, len(prop)):
			if Util.isnull(row[prop[i]]) and Util.isnull(value[i]):
				pass # Two nulls are equal
			elif row[prop[i]] != value[i]:
				matches = false
		if (matches):
			if (!multi): return row
			res[row.ID] = row
			arr.append(row)
	if (asDict): return res.values()
	else: return arr

static func parseCSV(path, file):
	var props = []
	var defaults = []
	file.seek(0)
	var list = {}
	var line_count = 0
	while !file.eof_reached():
		var line = file.get_csv_line()
		line_count += 1 # Human-readable, so first line is 1
		if len(props) == 0: # First (header) row
			props = line
		elif len(defaults) == 0 and line[0] == "DEFAULT":
			defaults = line
		elif len(line) >= len(props):
			var dict = {}
			for i in range(0, props.size()):
				if len(defaults) > 0 and Util.isnull(line[i]):
					dict[props[i]] = defaults[i]
				else:
					dict[props[i]] = line[i]
				pass
			list[list.size()] = dict
		elif len(line) == 1 and len(line[0]) == 0:
			pass#Game.reportError(Game.CAT.FILE, "Line %s of %s could not be read" % [line_count, path])
	return list

static func saveCSV(folder, fdata, filename, arr):
	#Game.debugMessage(Game.CAT.SAVE, "Saving file: %s" % [fdata + filename])
	var file = File.new()
	var count = 0
	if file.open(folder + fdata + filename, file.WRITE) == OK:
		var dataRow : PoolStringArray = []
		for i in range(arr.size()):
			var cell = arr[i]
			dataRow.push_back(cell)
		file.store_line(dataRow.join(","))
	file.close()
	#Game.verboseMessage(Game.CAT.SAVE, "Wrote %s lines" % [count])


static func getImage(folder, file, ext):
	var img = Image.new()
	var fname = folder + file + ext
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		img.load(fname)
	else:
		pass#Game.reportError(Game.CAT.FILE, "Error reading image file " + fname)
	f.close()
	return img

# https://godotengine.org/qa/30210/how-do-load-resource-works
static func getTexture(folder, file, ext):
	var img = Data.getImage(folder, file, ext)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex

static func getFont(folder, file, ext):
	var fname = folder + file + ext
	var font = DynamicFont.new()
	# Report error
	var f = File.new()
	if f.open(fname, f.READ) == OK:
		font.font_data = load(fname)
	else:
		pass#Game.reportWarning(Game.CAT.FILE, "Error reading font file " + fname)
	return font

# https://github.com/godotengine/godot/issues/17748
static func getAudio(folder, file, ext):
	var fname = folder + file + ext
	var stream = AudioStreamOGGVorbis.new()
	var afile = File.new()
	if afile.open(fname, File.READ) == OK:
		var bytes = afile.get_buffer(afile.get_len())
		stream.data = bytes
	else:
		pass#Game.reportWarning(Game.CAT.FILE, "Error reading sound file " + fname)
	afile.close()
	return stream

# http://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func getFileList(path):
	var list = []
	var dir = Directory.new()
	if dir.dir_exists(path):
		dir.open(path)
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with(".") and not file.begins_with("_") and dir.current_is_dir():
				list.append(file)
		dir.list_dir_end()
	return list

func getFileAccessTime(fname):
	var file = File.new()
	file.open(fname, file.READ)
	return file.get_modified_time(fname)

# Random encounter config
var curr_combat_chance = 0.0
const max_combat_chance = 15.0
const combat_chance_inc = 0.75
var encounters_on = true

var RNG = RandomNumberGenerator.new()
var weight_total
func prep_random():
	weight_total = 0.0
	for w in range(0, Data.combat_weights.size()):
		weight_total += Data.combat_weights[w]
	RNG.randomize()
func roll_100():
	return Data.RNG.randi_range(1, 100)

var syll1 = ['b','b','b','d','d','f','g','k','k','k','l','m','m','p','q','r','r','t','v','w','x','x','z','z']
var syll2 = ['', '', '', 'gl', 'r', 'rl', 'rg', 'lr']
func generate_slime_name():
	var slime_name = ""
	RNG.randomize()
	var syllables = RNG.randi_range(3, 5)
	for s in range(0, syllables):
		var s1 = RNG.randi_range(0, syll1.size() - 1)
		var s2 = RNG.randi_range(0, syll2.size() - 1)
		slime_name += syll1[s1] + syll2[s2]
	slime_name = slime_name.substr(0, 1).to_upper() + slime_name.substr(1)
	return slime_name



# Combat weights start spread out between greys, but change over time
var combat_weights = []
var grey_weights = [ 40, 40, 40, 10, 10, 10, 0, 0, 0 ]
var locked_start = 6



const DEBUG_MULTIPLIER = 1#200
var locked_weights = [ 10, 12, 15 ]
var combat_diffs = [ 1, 1, 1, 2, 2, 3, 2, 2, 2 ] # How much does it count toward the fight difficulty
var combat_jobs = ["GreyJobSingle", "GreyJobSingle", "GreyJobSingle", "GreyJobDuo", "GreyJobDuo",
	"GreyJobTrio", "SlimeJob", "SlimeJob", "SlimeJob" ]
func setStartingWeights():
	combat_weights = grey_weights.duplicate()
	prep_random()
func addSlimeToRandom(i):
	combat_weights[locked_start + i] = locked_weights[i] * DEBUG_MULTIPLIER
	prep_random()


# Flags & flag interface functions
var flags = {} # DO NOT TOUCH EXCEPT THROUGH setFlagVal

func hasFlag(flname, i):
	var fl = flname + str(i)
	if !flags.has(fl):
		return false
	else:
		return flags[fl]
func hasSlime(i):
	return hasFlag("SLIME", i)
func hasArtifact(i):
	return hasFlag("ARTIFACT", i)
func hasMonster(i):
	return hasFlag("MONSTER", i)

func setFlag(flname, i, val):
	var fl = flname + str(i)
	setFlagValue(fl, val)
func setSlime(i, val):
	setFlag("SLIME", i, val)
func setArtifact(i, val):
	setFlag("ARTIFACT", i, val)
func setMonster(i, val):
	setFlag("MONSTER", i, val)

func setFlagValue(fl, val):
	flags[fl] = val
	# Some flags also update arrays etc
	get_node("/root/Game").flag_changed(fl, val)


# A bit hacky, but will contain MapName.ObjName e.g. LocalMap2.FriendlyBlue
var disappeared = []
var loaded_maps = {}
var map_difficulty

const COLOURS = [ "Red", "Blue", "Yellow", "Purple", "Orange", "Green" ]
