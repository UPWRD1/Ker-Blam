extends CharacterBody3D

var ptween = get_tree().create_tween()
var base_speed = 15
var puppet_pos = Vector3()
var puppet_rot = Vector3()
var puppet_vel = Vector3()

func _physics_process(delta):
	rotation_degrees = lerp(rotation_degrees, puppet_rot, 15*delta)

func update_transform(npuppet_pos, npuppet_rot, npuppet_vel):
	new_puppet_pos(npuppet_pos)
	puppet_rot = npuppet_rot
	puppet_vel = npuppet_vel

func new_puppet_pos(value):
	puppet_pos = value
	ptween.tween_property(self, "global_position", puppet_pos, 0.05)
