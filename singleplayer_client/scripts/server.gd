extends Node


func _ready():
	pass

func join_server():
	var client = ENetMultiplayerPeer.new()
	var err = client.create_client("LOCALHOST", 4242)
	if err != OK:
		print("Unable to connect")
		return
	multiplayer.multiplayer_peer = client
	connected_to_server()

func connection_failed():
	print("Connection failed!")
	
func server_disconnected():
	print("Server disconnected")
	
func connected_to_server():
	print("Connected to server")
