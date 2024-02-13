extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	with_websocket() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func with_multiplayer_api():
	var server = ENetMultiplayerPeer.new()
	var err = server.create_server(4242)
	if err != OK:
		print("Unable to start server!")
		set_process(false)
		return
	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	print("Server created")

func with_websocket():
	var server = WebSocketMultiplayerPeer.new()
	var err = server.create_server(4242)
	if err != OK:
		print("Unable to start server!")
		set_process(false)
		return
	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	print("Server created")


func add_player(peer_id):
	var location = Vector3(0,10,0)
	print("Player: ", peer_id, " connected!")
	randomize()
	print("Attempting to instance player ", peer_id, " at ", location)
	rpc("instance_player", peer_id, location)

@rpc("any_peer")
func update_transform(nposition, nrotation, nvelocity):
	print("Updating transform with", nposition, " ", nrotation, " ", nvelocity, " ", )
	var player_id = multiplayer.get_remote_sender_id()
	rpc("update_player_transform", player_id, nposition, nrotation, nvelocity)

@rpc
func instance_player(id, location):
	print("Instancing player ", id, " at ", location)
	
@rpc("unreliable", "any_peer")
func update_player_transform(id, position, rotation, velocity):
	print("Updating player (", id,") transform with", position, " ", rotation, " ", velocity, " ", )

func remove_player(peer_id):
	print("Player: ", peer_id, " disconnected!")
	#var player = get_node_or_null(str(peer_id))
	#if player:
		#player.queue_free()

func _exit_tree():
	multiplayer.connection_failed.emit()
