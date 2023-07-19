#FixedAnimator.gd runs the animation files created by #AnimationCompiler.gd for seamless integration with a preexisting animation player.

#FixedAnimator.gd is not a perfect analogue to the actual animation player but functions very close to the same

Modify the old animation player to delete it's own node on boot, it's just a placeholder used solely for UI and animation compilation. Compile your animations through "Project > Tools > Compile Animation" when you have the legacy/original animation player selected.

The code is pretty simple so feel free to fiddle as always!