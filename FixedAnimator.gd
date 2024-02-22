extends Node

# Constants for the animation system.
const DEFAULT_SPEED_SCALE = 10080
const FALL_ANIMATION = "fall"
const IDLE_ANIMATION = "idle"
const SPECIAL_ANIMATIONS = [IDLE_ANIMATION, FALL_ANIMATION]

# Exported variables for assigning animation player and resource paths.
export (NodePath) var animation_player_path = NodePath("../AnimationPlayerLegacy")
export (String) var animation_resource_path = "res://animations/player_animations.res"

# Variables for the animation system.
onready var animation_player = get_node(animation_player_path)
var animation_resource = preload("res://animations/player_animations.res")
var current_animation = ""
var assigned_animation = ""
var current_frame = 0
var speed_scale = DEFAULT_SPEED_SCALE
var animation_queue = []
var paused = false
var looping = false
var instant_simulation = true

# SECURITY WARNING:
# Exposing function calls in a P2P game directly to the Godot engine poses significant risks, including potential 
# arbitrary code execution and data breaches. Ensure strict validation of allowed functions and consider the 
# security implications of each function exposed. Limit the use of `allowed_functions` to those necessary 
# and restricted to from any function call arbitration (use of call(input_var: str)), or injection vulnerabilities.

# List of whitelisted functions. Add any functions you use here, don't expose any vulnerabilities here.
var allowed_functions = ["insert","all_animator_called","functions","here"]

var frame_accumulator = 0
var playing = false

func _ready():
	# Free the AnimationPlayerLegacy node if not in the editor.
	if not Engine.editor_hint:
		get_node("../AnimationPlayerLegacy").call_deferred("free")

func play(animation_name = "", no_simulate = false):
	if animation_name in SPECIAL_ANIMATIONS:
		if len(animation_queue) == 0:
			get_parent().fully_actionable()
		return
	# Set default animation_name if not provided or empty.
	if animation_name == "":
		animation_name = assigned_animation

	# Play the animation if it's not already playing.
	if current_animation == animation_name:
		get_parent().state = animation_name
		if not playing:
			playing = true
			return
		elif get_current_animation_length() != current_frame:
			return

	# Set the new animation and play it.
	get_parent().state = animation_name
	current_animation = animation_name
	assigned_animation = animation_name
	current_frame = -1
	playing = true
	if (instant_simulation and not no_simulate):
		current_frame += 1
		run_frame()

func queue(animation_name):
	# Queue the animation if it's not already queued.
	if animation_name in animation_queue:
		return
	if current_animation == "":
		play(animation_name)
		return
	elif not animation_name in SPECIAL_ANIMATIONS:
		animation_queue.erase(IDLE_ANIMATION)
		animation_queue.erase(FALL_ANIMATION)
	animation_queue.append(animation_name)

func is_playing():
	return playing

func stop(keep_state: bool = false):
	# Stop the animation and dequeue the next one.
	looping = false
	playing = false
	current_frame = -1
	current_animation = ""
#	if animation_queue.size() > 0:
#		play(animation_queue.pop_front())

func find_keyframes(frame):
	# Find all keyframes for each frame in the current animation.
	var keyframes = []
	looping = false
	for track in animation_resource.animation_data[assigned_animation].keys():
		if track in ["<length>", "<loop>"]:
			if track == "<loop>":
				looping = animation_resource.animation_data[assigned_animation]["<loop>"]
			continue

		var keyframe_list = animation_resource.animation_data[assigned_animation][track]
		for keyframe in keyframe_list:
			if keyframe["time"] == frame:
				keyframe["track"] = track
				if track == "":
					if "method" in keyframe:
						keyframes.append(keyframe)
				else:
					keyframes.append(keyframe)
	return keyframes

func pause():
	paused = true

func resume():
	paused = false

func frame_pass():
	#Iterate frames in animation player
	if paused:
		return
	if not playing or current_animation == "":
		run_queue()
		return
	frame_accumulator += speed_scale
	if current_animation in SPECIAL_ANIMATIONS and animation_queue.size() > 0:
		frame_accumulator = max(DEFAULT_SPEED_SCALE, frame_accumulator)
	while frame_accumulator >= DEFAULT_SPEED_SCALE:
		frame_accumulator -= DEFAULT_SPEED_SCALE
		current_frame += 1
		if current_frame > get_current_animation_length() or current_animation == "":
			run_queue()
		run_frame()

func animation_complete():
	return current_frame > get_current_animation_length()

func run_queue():
	playing = false
	if animation_queue.size() > 0:
		play(animation_queue.pop_front())
		if instant_simulation:
			return
	elif looping:
		current_frame = -1
		play('', false)
		if instant_simulation:
			return
	else:
		stop()
		return

func run_frame(force = false):
	if (paused or not playing or current_animation == "") and not force:
		return
	#print(current_animation + ": " + str(current_frame) + " out of " +str(get_current_animation_length()) + " queue: " + str(animation_queue))
	apply_frame(find_keyframes(current_frame))

func apply_frame(keyframes):
	var player = animation_player.get_parent()
	var properties_changed = false
	keyframes.sort_custom(self, "compare_keyframes")

	var expected_properties = {}

	for keyframe in keyframes:
		if "property" in keyframe:
			var node_path = animation_resource.property_lookup_table[keyframe["property"]]["node_path"]
			if not get_parent().get_node(node_path):
				continue

			var property_name = keyframe["property"]
			var value = keyframe["value"]
			get_parent().animate_property(node_path, property_name, value)
			properties_changed = true
			expected_properties[property_name] = value

		elif "method" in keyframe:
			var method_name = keyframe["method"]
			var args = keyframe["args"]
			get_parent().animate_method(method_name, allowed_functions, args)
		else:
			pass

	if properties_changed:
		if expected_properties.size() == 0:
			push_error("Error: Expected Properties Empty: " + str(expected_properties))
			breakpoint
		property_comparison_test(expected_properties)

func property_comparison_test(expected_properties):
	var player = animation_player.get_parent()

	for property_name in expected_properties.keys():
		var expected_value = expected_properties[property_name]
		var node_path = animation_resource.property_lookup_table[property_name]["node_path"]
		var actual_value = get_parent().get_node(node_path).get(property_name)

		if actual_value != expected_value and not property_name in ["ignore_move_cancel"]:
			push_error("Error: Property value mismatch for " + property_name + ". Expected: " + str(expected_value) + " Got: " + str(actual_value))

func compare_keyframes(a, b):
	var track_order = animation_resource.animation_data[assigned_animation].keys()
	var a_index = track_order.find(a["track"])
	var b_index = track_order.find(b["track"])

	return a_index - b_index

func seek(animation_name, frame):
	play(animation_name, false)
	current_frame = clamp(frame, -1, get_current_animation_length())
	#if animation_complete():pass# run_queue()
	#elif current_frame != -1: run_frame()

func get_current_frame():
	return current_frame

func set_speed_scale(scale: int):
	speed_scale = scale

func get_animation_list():
	var animation_list = []
	for animation_name in animation_resource.animation_data.keys():
		animation_list.append(animation_name)
	return animation_list

func get_current_animation():
	return current_animation

func get_current_animation_length():
	if current_animation == "":
		return 1
	return animation_resource.animation_data[assigned_animation]["<length>"]

func get_animation_queue():
	return animation_queue

func set_animation_queue(new_queue):
	animation_queue = new_queue

func clear_queue():
	set_animation_queue([])

func _save():
	var gamestate = {}
	var restored_animation_queue = []
	for index in animation_queue:
		restored_animation_queue.append(subloads.AnimationMap.ANIMATION_MAP.keys()[index])
	gamestate["animation_queue"] = restored_animation_queue
	gamestate["animation_state"] = current_animation
	var frame = get_current_frame()
	gamestate["animation_frame"] = frame
	return gamestate

func _load(gamestate: Dictionary):
	var restored_animation_queue = []
	for index in gamestate["animation_queue"]:
		restored_animation_queue.append(subloads.AnimationMap.ANIMATION_MAP.keys()[index])

	animation_player.set_animation_queue(restored_animation_queue)

	current_animation = gamestate["animation_state"]

	if gamestate["animation_frame"] > 0:
		animation_player.seek(current_animation, (gamestate["animation_frame"])-1)
