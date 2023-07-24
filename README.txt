#FixedAnimator.gd runs the animation files created by #AnimationCompiler.gd for seamless integration with a preexisting animation player.

#FixedAnimator.gd is not a perfect analogue to the actual animation player but functions very close to the same

Modify the old animation player to delete it's own node on boot, it's just a placeholder used solely for UI and animation compilation. Compile your animations through "Project > Tools > Compile Animation" when you have the legacy/original animation player selected.

The animator as it exists was stripped straight out of my actual games code (Dashwalk Dueling wishlist on steam ;) ). So it may well need adaptation, some of the code in the Player script is sort of loose and that's in #PlaceholderPlayerScript.gd. You can reintegrate it or whatever as you please. If you end up with something modular feel free to share make a request. I'm happy to merge any community driven updates, although I don't plan to touch it much more myself.

The code doesn't have a ton going so I encourage you to fiddle around!