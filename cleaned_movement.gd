extends CharacterBody3D


#@export var crouch_enabled = true
@export var slide_enabled = true

@export var base_speed = 15
@export var sprint_speed = 20
@export var wall_speed = 50
@export var jump_velocity = 6
@export var sensitivity = 0.1
@export var accel = 10
@export var crouch_speed = 3
@export var slide_speed = 0
@export var wall_run_tilt_angle : float = 15.0
@export var dash_dist = 10

signal significant_action

signal enter_flow
signal exit_flow


enum State {
	WALKING,
	JUMPING,
	SLIDING,
	WALL_RUNNING,
	WALL_JUMPING,
	SLAMMING,
	FALLING,
	CLIMBING,
	IDLE,
}

@export var state: State

var is_sigact = false
var speed = base_speed
var camera_fov_extents = [75.0, 85.0] #index 0 is normal, index 1 is sprinting
var base_player_y_scale = 1.0
var crouch_player_y_scale = 0.25
var wall_normal
var w_runnable = false

var slide_started = false  # New variable to track if slide has started

var jump_count = 0

@onready var parts = {
	"head": $Head,
	"camera": $Head/Camera3D,
	"body": $CollisionShape3D,
	"collision": $CollisionShape3D,
	"headrays": $Head/HeadRays,
	"chestrays": $Head/ChestRays,
	"leftray": $Head/SideRays/Left,
	"rightray": $Head/SideRays/Right,
	"timer": $Timer,
	"cam_anim": $Head/Camera3D/AnimationPlayer
}
#@onready var world = get_parent()
@onready var timer = $Timer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3()

var current_tilt_angle: float
var wallrun_angle = 15
var side = Vector3()

var iscaptured: bool


# Functions for movement
func can_climb():
	#print(abs(rad_to_deg(parts.head.rotation.x)))
	if state != State.SLIDING:
		if abs(rad_to_deg(parts.head.rotation.x)) < 20:
			for ray in parts.chestrays.get_children():
				if ray.is_colliding():
					for ray2 in parts.headrays.get_children():
						if ray2.is_colliding():
							return false
					return true
				else:
					return false
		else:
			return false
	else:
		return false

func climb_anim():
	#var cv = direction
	# Movement Restrictions
	#velocity = Vector3.ZERO
	
	var v_move_time := 0.2
	var h_move_time := 0.2
	if state != State.SLIDING || state != State.WALL_RUNNING:
		# Vertical Transforms
		#var vertical_movement = global_transform.origin + Vector3(0,1.85,0)
		#var vm_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		var camera_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		var body_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		#vm_tween.tween_property(self, "global_transform:origin", vertical_movement, v_move_time)
		body_tween.tween_property(self, "scale", 0.5, v_move_time)
		camera_tween.tween_property(parts.camera, "rotation_degrees:x", clamp(parts.camera.rotation_degrees.x - 10,-85,90), v_move_time)
		camera_tween.tween_property(parts.camera, "rotation_degrees:z", -5.0*sign(randf_range(-10000,10000)), v_move_time)
		
		await body_tween.finished
		#
		## Horizontal Transforms
		#var forward_movement = global_transform.origin + (-parts.head.basis.z * 1.2)
		#var fm_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
		#var camera_reset = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		#fm_tween.tween_property(self, "global_transform:origin", forward_movement, h_move_time)
		#camera_reset.tween_property(parts.camera, "rotation_degrees:x", 0.0, h_move_time)
		#camera_reset.tween_property(parts.camera, "rotation_degrees:z", 0.0, h_move_time)
		body_tween.tween_property(self, "scale", 1, v_move_time)
	# Reset Restrictions
	#velocity = Vector3(cv.x * 1.5, cv.y * 1.5, cv.z * 1.5)
	#velocity *= cv

func climb(delta):
	parts.body.scale.y = lerp(parts.body.scale.y, crouch_player_y_scale, delta)
	#climb_anim()
	velocity.y = (jump_velocity)
	var xsign = direction.x / direction.x
	var zsign = direction.z / direction.z
	velocity = Vector3(direction.x * 5 + (3 * xsign), velocity.y, direction.z * 5 + (3 * zsign))
	#await get_tree().create_timer(0.125).timeout

	#velocity += direction * Vector3(2 ,2, 2)
	parts.body.scale.y = lerp(parts.body.scale.y, base_player_y_scale, delta)
	

func wall_run(delta):
	if w_runnable and is_on_wall_only() and (parts.leftray.is_colliding() or parts.rightray.is_colliding()):
		parts.camera.rotation_degrees.y = lerp(parts.camera.rotation_degrees.y, float(parts.camera.rotation_degrees.y), 0.0)
		wall_normal = get_slide_collision(0).get_normal()
		velocity = Vector3(velocity.x, 0, velocity.z)
		side = wall_normal.cross(Vector3.UP)
		jump_count = 0
		direction = -wall_normal * wall_speed
		state = State.WALL_RUNNING
		speed = wall_speed
		#speed *= 3
		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.camera.rotation_degrees.y = lerp(parts.camera.rotation_degrees.y, 0.0, 1)
		if Input.is_action_just_pressed("MOVE_JUMP"):
			if state == State.WALL_RUNNING:
				state = State.WALL_JUMPING
				significant_action.emit()
				velocity += wall_normal * base_speed
				w_runnable = true
				jump_count = 0
		if not is_on_floor():
			var to_rot
			if parts.leftray.is_colliding():
				to_rot = -wall_run_tilt_angle
			elif parts.rightray.is_colliding():
				to_rot = wall_run_tilt_angle
			else:
				to_rot = 0.0

		# Set the rotation directly
			parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, float(to_rot), 0.1)

func _reset_camera_rotation():
	parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, 0.0, 0.1)

func _ready():
	if not is_multiplayer_authority(): return
	parts.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	await get_tree().create_timer(0.125).timeout
	parts.collision.disabled = false

func escape():
	if Input.is_action_just_pressed("ACTION_ESCAPE"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func check_flow():
	if abs(velocity.x) >  20.0 or abs(velocity.z) > 20.0:
		enter_flow.emit()
		print(velocity)
	else:
		exit_flow.emit()

func slide(delta):
	if not is_on_floor() and (state != State.WALL_RUNNING):
		velocity = Vector3(direction.x * 15, velocity.y, direction.z * 15)
		state = State.FALLING
	else:
		var slide_direction = Vector3()
		if !slide_started and is_on_floor():
			slide_direction = Vector3(direction.x, 0, direction.z).normalized()
			slide_started = true

		speed = slide_speed
		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.body.scale.y = lerp(parts.body.scale.y, crouch_player_y_scale, 20*delta) #change this to starting a crouching animation or whatever
		parts.collision.scale.y = lerp(parts.collision.scale.y, crouch_player_y_scale, 20*delta)
		velocity.x += (slide_direction.x * slide_speed) / (10 * delta) 
		velocity.z += (slide_direction.z * slide_speed) / (10 * delta) 

func walk(delta):
	parts.cam_anim.play("Head_Bob")
	speed = base_speed
	sensitivity = 0.1
	parts.body.scale.y = lerp(parts.body.scale.y, base_player_y_scale, 20*delta) #change this to starting a crouching animation or whatever

func jump():
	if not is_multiplayer_authority(): return
	if (is_on_floor() or jump_count < 3 or is_on_wall()):
		velocity.y = jump_velocity
		jump_count += 1

func _process(delta):
	if not is_multiplayer_authority(): return
	#print(velocity)
	#print(can_climb())
	#print((parts.leftray.is_colliding() or parts.rightray.is_colliding()))
	check_flow()
	escape()

	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACKWARD")
	direction = input_dir.normalized().rotated(-parts.head.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)

	if Input.is_action_just_pressed("MOVE_JUMP"):
		if can_climb():
			#climb(delta)
			print("canclimb")
		else:
			state = State.JUMPING
			await get_tree().create_timer(0.1).timeout
	if Input.is_action_pressed("MOVE_SLIDE") and not (state == State.WALL_RUNNING):
		state = State.SLIDING
	else:
		if direction != Vector3.ZERO:
			state = State.WALKING
			if slide_enabled:
				parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[0], 10*delta)
		else: 
			state = State.IDLE

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	wall_run(delta)
	if state == State.WALKING:
		walk(delta)
	elif state == State.JUMPING:
		jump()
	elif state == State.CLIMBING:
		climb(delta)
	elif state == State.SLIDING:
		slide(delta)
	elif state == State.IDLE:
		pass

	if not (is_on_floor()):
		velocity.y -= (gravity * 1.3) * delta
		w_runnable = true
		if not is_on_wall():
			velocity.x += direction.x / 10
			velocity.z += direction.z / 10
		state = State.FALLING
	else:
		if not state == State.SLIDING:
			velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
			jump_count = 0
		w_runnable = false
		jump_count = 0  # Reset jump count when the jump key is released
	
	if not is_on_wall():
		_reset_camera_rotation()

	if state == State.WALL_RUNNING:
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)

	move_and_slide()


func _input(event):
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		parts.head.rotation_degrees.y -= event.relative.x * sensitivity
		parts.head.rotation_degrees.x -= event.relative.y * sensitivity
		parts.head.rotation.x = clamp(parts.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))	
