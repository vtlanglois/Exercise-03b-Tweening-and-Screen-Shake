# Exercise-03b-Tweening-and-Screen-Shake

Exercise for MSCH-C220, 23 September 2021

A demonstration of this exercise is available at [https://youtu.be/kIHNR2RrnPw](https://youtu.be/kIHNR2RrnPw)

This exercise will add several juicy features to our match-3 game. You may not want to use them all at the same time, but this is a chance to explore a variety of techniques. The exercise will provide you with several features that should move you towards the implementation of Project 03.

Fork this repository. When that process has completed, make sure that the top of the repository reads [your username]/Exercise-03b-Tweening-and-Screen-Shake. Edit the LICENSE and replace BL-MSCH-C220-F21 with your full name. Commit your changes.

Press the green "Code" button and select "Open in GitHub Desktop". Allow the browser to open (or install) GitHub Desktop. Once GitHub Desktop has loaded, you should see a window labeled "Clone a Repository" asking you for a Local Path on your computer where the project should be copied. Choose a location; make sure the Local Path ends with "Exercise-03b-Tweening-and-Screen-Shake" and then press the "Clone" button. GitHub Desktop will now download a copy of the repository to the location you indicated.

Open Godot. In the Project Manager, tap the "Import" button. Tap "Browse" and navigate to the repository folder. Select the project.godot file and tap "Open".

If you run the project, you will see a main menu followed by a simple match-3 game (using Godot icons as tiles). Your task will be to modify (by adding more juiciness to) the tiles.

---

Start by opening the Piece scene (res://Pieces/Piece.tscn). Right-click on the Piece node and "Add Child Node". Add a Particles2D node (rename it Falling). Then add a Tween node and a Timer.

Select the Falling node. In the Inspector panel, update the following parameters:
 * Particles2D->Amount = 20
 * Time->Lifetime = 1.5
 * Time->Explosiveness = 1
 * Textures->Texture = res://Assets/star_small.png
 * Process Material->Material = New ParticlesMaterial (edit the ParticlesMaterial)
   * Emission Shape->Shape = Box
   * Emission Shape->Box Extents = (50,50,0)
   * Direction->Direction = (0, 0, 0)
   * Direction->Spread = 180
   * Gravity->Gravity = (0, 0, 0)
   * Radial Accel->Accel = -500
   * Radial Accel->Accel Random = 1
   * Scale->Scale Curve = new CurveTexture
     * Right-click in the middle of the curve and Add Point
     * Set the beginning and end of the curve to 0, and set the middle point to 1
   * Color->Color Ramp = new GradientTexture (edit the GradientTexture)
     * create a new Gradient and create a break point in the middle of the gradient. Make the gradient go from transparent to white back to transparent
   * Hue Variation->Variation = 0.25
   * Hue Variation->Variation Random = 0.25
 * Time->One Shot = On
 * Particles2D->Emitting = Off

Select the Timer. In the Inspector, set One Shot = 1. Then add a timeout() Signal. Attach the signal to Piece.gd. We will fill in the `_on_Timer_timeout()` function later. Save the Piece scene.

---

Create a new Scene. Choose Other Node->AnimatedSprite. Rename the AnimatedSprite Explosion. Select the Explosion node. In the Inspector, set AnimatedSprite->Frames = new SpriteFrames. Then edit the SpriteFrames. This will display a panel at the bottom of the window. In the Animation Frames panel, tap the 3x3 grid icon. When the file picker appears, choose res://Assets/explosion.png. In the Select Frames window, set Horizontal = 8, Vertical = 3. Then select all the frames and press the Add 24 Frame(s) button.

Back in the Inspector, set Speed Scale = 8. 

Attach a script to the Explosion node (res://Explosion/Explosion.gd). Add a animation_finished() signal to the node and select the Explosion script. The script should be as follows:
```
extends AnimatedSprite

func _ready():
	play()

func _on_Explosion_animation_finished():
	queue_free()
```

Save the scene as res://Explosion/Explosion.tscn.

---

Back in the res://Pieces/Piece.gd script, add the following on line 18:
```
var Explosion = preload("res://Explosion/Explosion.tscn")
```

Replace the `_on_Timer_timeout()` function with the following:
```
func _on_Timer_timeout():
	if Effects == null:
		Effects = get_node_or_null("/root/Game/Effects")
	if Effects != null:
		var explosion = Explosion.instance()
		explosion.position = position
		Effects.add_child(explosion)
	dying = true;
```

Then update the die function with this:
```
func die():
	if Effects == null:
		Effects = get_node_or_null("/root/Game/Effects")
	if Effects != null:
		get_parent().remove_child(self)
		Effects.add_child(self)
		$Timer.wait_time = 0.5 + (randf() / 10.0)
		$Timer.start()
		$Falling.emitting = true
```

If you save the scene and run the program, you should now see explosions when you match the tiles.

Let's make the tiles drop in from the top of the window as they are generated. Replace the `generate(pos)` function with this:
```
func generate(pos):
	position = Vector2(pos.x,-100)
	target_position = pos
	$Tween.interpolate_property(self, "position", position, target_position, randf()+0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()
```

And then update the if and elif statements on lines 25–27 with this:
```
	if dying and not $Tween.is_active():
		queue_free()
	elif position != target_position and not $Tween.is_active():
		position = target_position
```
That will make everything wait for any animations to complete before deleting the tile or updating its position.

We can also animate the pieces sliding into new positions by updating the `move_piece(change)` function:
```
func move_piece(change):
	target_position = target_position + change
	$Tween.interpolate_property(self, "position", position, target_position, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
```

Let's give the pieces a little wiggle as we wait for them to be matched. Add this line to the `_ready()` function:
```
	wiggle = randf()
```

And then add this to `_physics_process(_delta)`:
```
	wiggle += 0.1
	position.x = target_position.x + (sin(wiggle)*wiggle_amount)
```

If you run the program now, you should see the tiles gently swaying back and forth.

Finally, let's add a few more effects for when the tiles are matched. Append the following to the `die()` function:
```
		$Tween.interpolate_property(self, "modulate:a", 1, 0, transparent_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		$Tween.interpolate_property(self, "scale", scale, Vector2(3,3), scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		$Tween.interpolate_property($Sprite, "rotation",rotation, (randf()*4*PI)-2*PI, rot_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
```

Test it again, and see what happens when matching the tiles.

Open the Game scene, and right-click on the Game node. Add Child Node. Select Camera2D and rename it Camera. In the Inspector, set Camera2D->Current = On and Camera2D->Anchor Mode = Fixed TopLeft. Attach a script to the Camera (res://Camera.gd), and replace the resulting script with the following:
```
extends Camera2D
# Originally developed by Squirrel Eiserloh (https://youtu.be/tu-Qe66AvtY)
# Refined by KidsCanCode (https://kidscancode.org/godot_recipes/2d/screen_shake/)

export var decay = 0.8                      # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 50)    # Maximum hor/ver shake in pixels.
export var max_roll = 0.1                   # Maximum rotation in radians (use sparingly).
export (NodePath) var target                # Assign the node this camera will follow.

var trauma = 0.0                            # Current shake strength.
var trauma_power = 2                        # Trauma exponent. Use [2, 3].
var max_trauma = 4.0
onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func _process(delta):
	if target:
		global_position = get_node(target).global_position
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
		
func shake():
	var amount = pow(min(trauma,1.0), trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	print(trauma)
	
func add_trauma(amount):
	trauma = min(trauma + amount, max_trauma)
```
 
 Then, in res://Global.gd, append this to the `change_score(s)` function:
 ```
	if camera == null:
		camera = get_node_or_null("/root/Game/Camera")
	if camera != null:
		camera.add_trauma(s/20.0)
```
---

Test the game and make sure it is working correctly. You should be able to see all the effects we added to the tiles.

Quit Godot. In GitHub desktop, you should now see the updated files listed in the left panel. In the bottom of that panel, type a Summary message (something like "Completes the exercise") and press the "Commit to master" button. On the right side of the top, black panel, you should see a button labeled "Push origin". Press that now.

If you return to and refresh your GitHub repository page, you should now see your updated files with the time when they were changed.

Now edit the README.md file. When you have finished editing, commit your changes, and then turn in the URL of the main repository page (https://github.com/[username]/Exercise-03b-Tweening-and-Screen-Shake) on Canvas.

The final state of the file should be as follows (replacing my information with yours):
```
# Exercise-03b-Tweening-and-Screen-Shake

Exercise for MSCH-C220, 23 September 2021

Adding several "juicy" features to a simple match-3 game.

## To play

Select and drag tiles using the mouse.


## Implementation

Built using Godot 3.3.3

## References
 * [Juice it or lose it — a talk by Martin Jonasson & Petri Purho](https://www.youtube.com/watch?v=Fy0aCDmgnxg)
 * The match-3 game is derived from code provided by [MisterTaftCreates](https://github.com/mistertaftcreates/Godot_match_3), with an accompanying [YouTube series](https://www.youtube.com/playlist?list=PL4vbr3u7UKWqwQlvwvgNcgDL1p_3hcNn2)
 * [Animal Pack Redux, provided by kenney.nl](https://kenney.nl/assets/animal-pack-redux)
 * [Puzzle Pack 2, provided by kenney.nl](https://kenney.nl/assets/puzzle-pack-2)
 * Explosion spritesheet provided by [Ville Seppanen](https://opengameart.org/content/explosion-animated)
 * [Ignotum Typeface](https://fontesk.com/ignotum-font/)
 * [Nepszabadag Typeface](https://fontesk.com/nepszabadsag-font/)
 * Screen Shake script provided by [KidsCanCode](https://kidscancode.org/godot_recipes/2d/screen_shake/)
 

## Future Development

Typeface changes, Music and Sound, Shaders

## Created by 

Jason Francis
```
