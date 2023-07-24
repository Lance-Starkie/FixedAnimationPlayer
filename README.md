# Fixed Animation Player
Originally made in Godot 3.5.1

The purpose of FixedAnimationPlayer.gd is to serve as a fixed-point deterministic version of the animation player. By placing the FixedAnimatorNode alongside your old animation player, you can take advantage of the AnimationCompiler.gd to compile animations from the old player for use in the new deterministic one.

## Usage
1. Place the #FixedAnimationPlayer.gd script alongside your old animation player in Godot.
2. Use AnimationCompiler.gd to compile animations from the old player into the new Fixed Animation Player.
   (Project > Tools > Compile Animation)
3. Add function from #PlaceholderPlayerScript to your player
   (or just work them in however works best for your project)
4. Both players can now use the same UI and animation data.

## Forewarning
This public version of the Fixed Animation Player originates from my game, Dashwalk Dueling. While it should work well for most cases, some adaptation may be required depending on your project's needs.

## Contribution
Contributions and improvements from the community are welcome. Please consider sharing enhancements through pull requests to benefit the wider Godot community.

## MIT License
The Fixed Animation Player is open-source software released under the MIT License.

Feel free to customize and experiment with the Fixed Animation Player for your projects! Have fun!
