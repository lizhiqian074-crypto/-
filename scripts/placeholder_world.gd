class_name PlaceholderWorld
extends RefCounted
## Temporary geometry for missing assets; no replacement artwork is generated.
static func mesh(parent: Node3D, shape: Mesh, position: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = shape
	node.position = position
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	node.material_override = material
	parent.add_child(node)
	return node

static func deer_marker() -> Node3D:
	var root = Node3D.new()
	root.name = "MissingDeerPlaceholder"
	var body = CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.3
	var torso = mesh(root, body, Vector3(0, 1, 0), Color("#977955"))
	torso.rotation.x = PI / 2
	var head = SphereMesh.new()
	head.radius = 0.25
	head.height = 0.5
	mesh(root, head, Vector3(0, 1.6, -0.6), Color("#846947"))
	for x in [-0.22, 0.22]:
		for z in [-0.36, 0.36]:
			var leg = CylinderMesh.new()
			leg.top_radius = 0.05
			leg.bottom_radius = 0.045
			leg.height = 0.85
			mesh(root, leg, Vector3(x, 0.43, z), Color("#574c3d"))
	var label = Label3D.new()
	label.text = "毛冠鹿 · 模型待导入"
	label.font_size = 42
	label.pixel_size = 0.005
	label.position = Vector3(0, 2.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ddd8b8")
	root.add_child(label)
	return root

static func forest_marker() -> Node3D:
	var root = Node3D.new()
	root.name = "MissingForestPlaceholder"
	var ground = PlaneMesh.new()
	ground.size = Vector2(120, 120)
	mesh(root, ground, Vector3(0, -0.025, 0), Color("#3b4b31"))
	# Sparse perimeter markers leave the nav rectangle unobstructed.
	var rng = RandomNumberGenerator.new()
	rng.seed = 1704
	for i in range(90):
		var angle = rng.randf_range(0, TAU)
		var radius = rng.randf_range(22, 52)
		var p = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var trunk = CylinderMesh.new()
		trunk.top_radius = 0.15
		trunk.bottom_radius = 0.3
		trunk.height = rng.randf_range(5, 10)
		mesh(root, trunk, p + Vector3(0, trunk.height / 2, 0), Color("#4e4935"))
		var crown = SphereMesh.new()
		crown.radius = rng.randf_range(2, 4)
		crown.height = crown.radius * 1.5
		mesh(root, crown, p + Vector3(0, trunk.height, 0), Color("#2b4535"))
	return root
