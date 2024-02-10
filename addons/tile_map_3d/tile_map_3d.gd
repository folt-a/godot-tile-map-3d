@tool
extends EditorPlugin

var edit_mode:bool

var current_grid_map:GridMap
var editable_object:bool = false

func _handles(obj) -> bool:
	return editable_object and (obj is GridMap or obj is TileMap3D)

func _forward_3d_gui_input(camera, event) -> int:
	if !edit_mode:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	_raycast(camera, event)

	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _raycast(camera:Node, event:InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_V and event.is_released():
		print("Ray")
		var mouse_position:= camera.get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_position)
		var ray_dir = camera.project_ray_normal(mouse_position)
		var ray_distance = camera.far
		var space_state =  get_viewport().world_3d.direct_space_state

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * ray_distance)
		var hit = space_state.intersect_ray(query)
		
		#collider: The colliding object.
		#collider_id: The colliding object's ID.
		#normal: The object's surface normal at the intersection point, or Vector3(0, 0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters3D.hit_from_inside is true.
		#position: The intersection point.
		#face_index: The face index at the intersection point.
		#Note: Returns a valid number only if the intersected shape is a ConcavePolygonShape3D. Otherwise, -1 is returned.
		#rid: The intersecting object's RID.
		#shape: The shape index of the colliding shape.
		
		if hit.size() != 0:
			print(hit.position)
			current_grid_map.get_parent().set_floor(hit.position, ray_dir)

func _selection_changed() -> void:
	var selection = EditorInterface.get_selection().get_selected_nodes()
	editable_object = selection.size() == 1 and (selection[0] is GridMap or selection[0] is TileMap3D)
	edit_mode = true
	if editable_object:
		if selection[0] is GridMap:
			current_grid_map = selection[0]
		else:
			current_grid_map = selection[0].get_child(0)

func _enter_tree():
	EditorInterface.get_selection().selection_changed.connect(_selection_changed)
