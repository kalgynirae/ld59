extends Node

func break_all():
	for child in get_children():
		child.breaks()
