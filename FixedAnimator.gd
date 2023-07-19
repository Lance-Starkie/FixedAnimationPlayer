extends Node

# Constants for the animation system.
const DEFAULT_SPEED_SCALE = 10080

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

# List of whitelisted functions.
var allowed_functions = ["shoot_lazer","sheilds"]

var frame_accumulator = 0
var playing = false

func _ready():
	# Free the AnimationPlayerLegacy node if not in the editor.
	if not Engine.editor_hint:
		get_node("../AnimationPlayerLegacy").call_deferred("free")

func play(animation_name = ""):
	# Set default animation_name if not provided or empty.
	if animation_name == "":
		animation_name = assigned_animation

	# Play the animation if it's not already playing.
	if current_animation == animation_name:
		get_parent().state = animation_name
		if not playing:
			playing = true
			return
		else:#if get_current_animation_length() != current_frame:
			return

	# Set the new animation and play it.
	get_parent().state = animation_name
	current_animation = animation_name
	assigned_animation = animation_name
	current_frame = -1
	playing = true
	if instant_simulation:
		run_frame()

func queue(animation_name):
	# Queue the animation if it's not already queued.
	if animation_name in animation_queue:
		return
	if current_animation == "":
		play(animation_name)
		return
	animation_queue.append(animation_name)

func is_playing():
	return playing

func stop(keep_state: bool = false):
	# Stop the animation and dequeue the next one.
	playing = false
	current_frame = -1
	current_animation = ""
#	if animation_queue.size() > 0:
#		play(animation_queue.pop_front())

func find_keyframes(frame):
	# Find all keyframes for a given frame in the current animation.
	var keyframes = []
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
	if paused or not playing or current_animation == "":
		return
	frame_accumulator += speed_scale
	if animation_queue.size() > 0:
		frame_accumulator = max(DEFAULT_SPEED_SCALE, frame_accumulator)
	while frame_accumulator >= DEFAULT_SPEED_SCALE:
		frame_accumulator -= DEFAULT_SPEED_SCALE
		current_frame += 1
		if current_frame > get_current_animation_length() or current_animation == "":
			run_queue()
		run_frame()

func run_queue():
	if animation_queue.size() > 0:
		play(animation_queue.pop_front())
		if instant_simulation:
			return
	elif looping:
		current_frame = -1
		play()
		if instant_simulation:
			return
	else:
		stop(false)
		return

func run_frame():
	if paused or not playing or current_animation == "":
		return
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
	play(animation_name)
	current_frame = clamp(frame, 0, get_current_animation_length())

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

