tool
extends EditorPlugin

var animation_compiler_script = preload("res://addons/FixedAnimationCompiler/AnimationCompiler.gd")
var fixed_point_animation_player_script = preload("res://addons/FixedAnimationCompiler/FixedAnimator.gd")
var loading_bar
var hard_coded_directory = "res://animations/"

func _enter_tree():
	add_custom_type("FixedPointAnimationPlayer", "Node2D", fixed_point_animation_player_script, preload("res://icon.png"))
	add_tool_menu_item("Compile Animation", self, "_on_compile_animation")

func _exit_tree():
	remove_custom_type("FixedPointAnimationPlayer")
	remove_tool_menu_item("Compile Animation")
	remove_control_from_bottom_panel(loading_bar)

func _on_compile_animation(_unused):
	var path = hard_coded_directory + "player_animations.res"
	animation_compiler_script.new().compile(path)

func _on_compile_complete():
	print("Animation compiled successfully.")
