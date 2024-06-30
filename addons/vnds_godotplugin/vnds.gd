##Visual novels engine (Visual Novel Development Studio)[br]
##https://github.com/lb357/VNDS-GodotPlugin
@icon("res://addons/vnds_godotplugin/icon.png")
extends Node
class_name VNDS


##VNDS project path 
##[br][i](Export)[/i] 
@export_file("*json") var project_path: String = "res://project.json/"

##Path to screen node (usually [TextureRect])
##[br][i](Export)[/i] 
@export var screen_node_path: NodePath = ""
##Screen node
@onready var screen_node = get_node(screen_node_path)

##Path to label node (usually [RichTextLabel] with
##[member RichTextLabel.bbcode_enabled] == true) 
##[br][i](Export)[/i] 
@export var label_node_path: NodePath = ""
##label node
@onready var label_node = get_node(label_node_path)

##Path to text node (usually [RichTextLabel] with
##[member RichTextLabel.bbcode_enabled] == true) 
##[br][i](Export)[/i] 
@export var text_node_path: NodePath = ""
##Text node
@onready var text_node = get_node(text_node_path)

##Path to audio node (usually [AudioStreamPlayer])
##[br][i](Export)[/i] 
@export var audio_node_path: NodePath = ""
##Text node
@onready var audio_node = get_node(audio_node_path)

##Select start script node on ready
@export var autostart: bool = false

##Current script node
var current_node = ""

##Project data
var project: Dictionary = {}
##Meta from project data
var pmeta: Dictionary = {}
##Replacements from project data
var preplacements: Dictionary = {}
##Script from project data
var pscript: Dictionary = {}

##Called by the call script node
signal call(call_name: String)
##Called when the script node is selected
signal script_node_selected(script_node: String)
##Called to show the menu
signal show_menu(slots: Array[String])
##Called at the end of the script by [method next]
signal finished(last_script_node: String)


func _ready():
	project = get_project(project_path)
	pmeta = project["Meta"]
	preplacements = project["Data"]["Replacements"]
	pscript = project["Data"]["Script"]
	if autostart:
		start()


##Get project [Dictionary]
func get_project(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	var json_parser = JSON.new()
	var fdata = json_parser.parse_string(file.get_as_text())
	file.close()
	if "Type" in fdata:
		if fdata["Type"] == "Visual Novel Development Studio" and \
		"Meta" in fdata and "Data" in fdata:
			if "Script" in fdata["Data"] and "Replacements" in fdata["Data"]:
				return fdata
			else:
				push_error("VNDS: no script/replacements")
		else:
			push_error("VNDS: no data/meta")
	else:
		push_error("VNDS: file is not VNDS project")
	return {}

##Select script node
func select(script_node: String) -> void:
	if script_node in pscript:
		current_node = script_node
		if pscript[script_node]["Type"] == "Start":
			pass
		elif pscript[script_node]["Type"] == "Scene":
			label_node.text = apply_replacements(pscript[script_node]["Fields"]["Label"])
			text_node.text = apply_replacements(pscript[script_node]["Fields"]["Text"])
			if bool(int(pscript[script_node]["Fields"]["Menu"])):
				emit_signal("show_menu", pscript[script_node]["Fields"]["Slots"])
		elif pscript[script_node]["Type"] == "Screen":
			for obj in screen_node.get_children():
				remove_child(obj)
				obj.queue_free()
			screen_node.texture = load_image(pscript[script_node]["Fields"]["Background"])
			for obj_name in pscript[script_node]["Fields"]["Objects"]:
				var obj = TextureRect.new()
				var obj_data = pscript[script_node]["Fields"]["Objects"][obj_name]
				obj.set_name(obj_name)
				obj.expand_mode = obj.EXPAND_IGNORE_SIZE
				obj.flip_h = bool(int(obj_data["Flip"]))
				obj.texture = load_image(obj_data["Path"])
				obj.anchor_bottom = obj_data["Layout"]["AnchorBottom"]
				obj.anchor_left = obj_data["Layout"]["AnchorLeft"]
				obj.anchor_right = obj_data["Layout"]["AnchorRight"]
				obj.anchor_top = obj_data["Layout"]["AnchorTop"]
				obj.offset_bottom = obj_data["Layout"]["OffsetBottom"]
				obj.offset_left = obj_data["Layout"]["OffsetLeft"]
				obj.offset_right = obj_data["Layout"]["OffsetRight"]
				obj.offset_top = obj_data["Layout"]["OffsetTop"]
				screen_node.add_child(obj)
		elif pscript[script_node]["Type"] == "Sound":
			audio_node.stream = load_sound(pscript[script_node]["Fields"]["Sound"])
			audio_node.play()
		elif pscript[script_node]["Type"] == "Sound":
			audio_node.stream = load_sound(pscript[script_node]["Fields"]["Sound"])
			audio_node.play()
		elif pscript[script_node]["Type"] == "Call":
			emit_signal("call", pscript[script_node]["Fields"]["Call"])
		else:
			push_error("VNDS: unknown node")
		emit_signal("script_node_selected", screen_node)
	else:
		push_error("VNDS: node not in script")

##Load image from resources
func load_image(img_path: String) -> ImageTexture:
		var endpoint_path = project_path.left(project_path.rfind("/"))+\
		"/Resources/Images/"+img_path
		var img = Image.load_from_file(endpoint_path)
		var texture = ImageTexture.create_from_image(img)
		return texture

##Load sound from resources
func load_sound(sound_path: String) -> AudioStream:
		var endpoint_path = project_path.left(project_path.rfind("/"))+\
		"/Resources/Sounds/"+sound_path
		var sound = load(endpoint_path)
		return sound

##Apply project replacements
func apply_replacements(text: String) -> String:
	for replacement in preplacements:
		text = text.replace(replacement, preplacements[replacement])
	return text

##Select next script node
func next(connection: int = 0) -> void:
	if str(connection) in pscript[current_node]["Connections"]:
		select(pscript[current_node]["Connections"][str(connection)].keys()[0])
	else:
		emit_signal("finished", current_node)

##Select start script node
func start() -> void:
	select("Start")

##Select the next script node if current script node is not a scene[br]
##When used on a signal [signal script_node_selected], the next scene will be
##recursively selected[br]
##Returns whether the current script node is a scene
func next2scene() -> bool:
	if pscript[current_node]["Type"] != "Scene":
		next()
		return false
	else:
		return true
