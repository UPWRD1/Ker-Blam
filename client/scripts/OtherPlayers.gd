extends CharacterBody3D

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
	global_position = lerp(global_position, puppet_pos, 1)

func remove_puppet():
	queue_free()
