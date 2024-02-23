extends Node


func instance_node(node, parent, location):
	var node_instance = node.instantiate()
	node_instance.position = location
	parent.add_child(node_instance)
	return node_instance
