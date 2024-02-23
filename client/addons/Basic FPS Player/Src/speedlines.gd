extends ColorRect

@onready var rc = $"."

var vis = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	rc.material.set("shader_parameter/alpha", 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_basic_fps_player_enter_flow():
	while vis <= 1:
		rc.material.set("shader_parameter/alpha", vis)
		vis += 0.1
		await get_tree().create_timer(0.5).timeout# Replace with function body.


func _on_basic_fps_player_exit_flow():
	while vis >= 0.0:
		rc.material.set("shader_parameter/alpha", vis)
		vis -= 0.1
		await get_tree().create_timer(0.5).timeout# Replace with function body. # Replace with function body.
