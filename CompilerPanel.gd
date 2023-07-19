tool
extends EditorPlugin

var animation_compiler_script = preload("res://addons/FixedAnimationCompiler/AnimationCompiler.gd")
var fixed_point_animation_player_script = preload("res://addons/FixedAnimationCompiler/FixedAnimator.gd")
var hard_coded_directory = "res://CompiledAnimations/"

func _enter_tree():
	add_custom_type("FixedPointAnimationPlayer", "Node2D", fixed_point_animation_player_script, preload("res://icon.png"))
	add_tool_menu_item("Compile Animation", self, "_on_compile_animation")

func _exit_tree():
	remove_custom_type("FixedPointAnimationPlayer")
	remove_tool_menu_item("Compile Animation")

func _on_compile_animation(_unused):
	var path = hard_coded_directory + "compiled_animation.anim"
	animation_compiler_script.new().compile(path)
