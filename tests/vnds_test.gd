extends Control

var waiting = false
var menu = false

func _on_vnds_script_node_selected(script_node):
	if $VNDS.next2scene():
		waiting = true

func _on_vnds_call(call_name):
	print("VNDS CALL: %s"%[call_name])

func _on_vnds_show_menu(slots):
	menu = true
	for slot in range(len(slots)):
		var menu_button = Button.new()
		menu_button.text = slots[slot]
		menu_button.pressed.connect(_on_menu_button_pressed.bind(slot))
		$ScenePanel/SceneContainer/MenuContainer.add_child(menu_button)

func _on_menu_button_pressed(slot):
	if waiting and menu:
		for child in $ScenePanel/SceneContainer/MenuContainer.get_children():
			$ScenePanel/SceneContainer/MenuContainer.remove_child(child)
			child.queue_free()
		waiting = false
		menu = false
		$VNDS.next(slot)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and waiting and not menu:
			waiting = false
			$VNDS.next()

func _on_vnds_finished(last_script_node):
	get_tree().quit()
