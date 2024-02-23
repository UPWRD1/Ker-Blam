extends Node


enum MpStatus {
	HOSTING,
	JOINING,
	CLIENT,
}

@export var mpstat: MpStatus
