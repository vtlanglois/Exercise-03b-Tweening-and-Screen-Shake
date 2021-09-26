extends Node2D

export (String) var color
var is_matched
var is_counted
var selected = false
var target_position = Vector2.ZERO

var Effects = null
var dying = false
var wiggle = 0.0
export var wiggle_amount = 3

export var transparent_time = 1.0
export var scale_time = 1.5
export var rot_time = 1.5

var Explosion = preload("res://Explosion/Explosion.tscn")

func _ready():
	$Select.texture = $Sprite.texture
	$Select.scale = $Sprite.scale
	wiggle = randf()

func _physics_process(_delta):
#	if dying:
#		queue_free()
#	elif position != target_position:
#		position = target_position
	if dying and not $Tween.is_active():
		queue_free()
	elif position != target_position and not $Tween.is_active():
		position = target_position
	if selected:
		$Select.show()
		$Selected.emitting = true
	else:
		$Select.hide()
		$Selected.emitting = false
	wiggle += 0.1
	position.x = target_position.x + (sin(wiggle)*wiggle_amount)

func generate(pos):
	position = Vector2(pos.x,-100)
	target_position = pos
	$Tween.interpolate_property(self, "position", position, target_position, randf()+0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.start()

func move_piece(change):
	target_position = target_position + change
	$Tween.interpolate_property(self, "position", position, target_position, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func die():
	if Effects == null:
		Effects = get_node_or_null("/root/Game/Effects")
	if Effects != null:
		get_parent().remove_child(self)
		Effects.add_child(self)
		$Timer.wait_time = 0.5 + (randf() / 10.0)
		$Timer.start()
		$Falling.emitting = true
		$Tween.interpolate_property(self, "modulate:a", 1, 0, transparent_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		$Tween.interpolate_property(self, "scale", scale, Vector2(3,3), scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		$Tween.interpolate_property($Sprite, "rotation",rotation, (randf()*4*PI)-2*PI, rot_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()


func _on_Timer_timeout():
	if Effects == null:
		Effects = get_node_or_null("/root/Game/Effects")
	if Effects != null:
		var explosion = Explosion.instance()
		explosion.position = position
		Effects.add_child(explosion)
	dying = true;
