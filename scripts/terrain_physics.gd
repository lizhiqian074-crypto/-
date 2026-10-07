class_name TerrainPhysics
extends RefCounted
## Static forest meshes are world geometry (layer 1); actors never teleport through them.
static func add_mesh_collisions(root: Node3D) -> int:
	var count = 0
	var meshes = root.find_children("*","MeshInstance3D",true,false)
	if root is MeshInstance3D: meshes.append(root)
	for body in root.find_children("*","PhysicsBody3D",true,false):
		body.collision_layer |= 1
	for mesh in meshes:
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var ancestor = mesh.get_parent()
		var has_body = false
		while ancestor != null and ancestor != root.get_parent():
			if ancestor is PhysicsBody3D:
				ancestor.collision_layer |= 1
				has_body = true
				break
			ancestor = ancestor.get_parent()
		for child in mesh.get_children():
			if child is PhysicsBody3D and not child.find_children("*","CollisionShape3D",true,false).is_empty():
				has_body = true
		if has_body or mesh.has_node("TerrainCollision"): continue
		var shape = mesh.mesh.create_trimesh_shape()
		if shape == null: continue
		shape.backface_collision = true
		var body = StaticBody3D.new()
		body.name = "TerrainCollision"
		body.collision_layer = 1
		body.collision_mask = 0
		var collider = CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		mesh.add_child(body)
		count += 1
	return count

static func ground_at(world: Node3D, point: Vector3) -> Vector3:
	var query = PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point-Vector3.UP*50,1)
	var hit = world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < cos(deg_to_rad(45)): return Vector3.INF
	return hit.position
