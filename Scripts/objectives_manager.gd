extends Node

func _ready() -> void:
	var i: int = 0
	var probability: float = (1.0 / get_child_count())
	var all_equal = Global.house_list.all(func(e): return e == Global.house_list.front())
	for house in get_children():
		var aux: InteractableExterior = house
		if Global.house_list.size() < get_child_count():
			aux.completed = randf() > probability
			if !aux.completed:
				Global.house_list.append(randi_range(1, 10))
				probability = (1.0 / get_child_count())
			else:
				Global.house_list.append(0)
				probability += (1.0 / get_child_count())
		elif all_equal:
			aux.completed = randf() > probability
			if !aux.completed:
				Global.house_list[i] = randi_range(1, 10)
				probability = 0.5
			else:
				Global.house_list.append(0)
				probability += (1.0 / get_child_count())
		aux.gifts_deserved = Global.house_list[i]
		if aux.gifts_deserved == 0:
			aux.completed = true
		i += 1
