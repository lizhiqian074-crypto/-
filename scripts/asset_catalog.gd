extends Node
## Asset paths are data, never executable instructions. Missing media are safe.
var config: Dictionary = {}
var warned: Dictionary = {}
func _ready() -> void:
	var file = FileAccess.open("res://data/assets.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			config = parsed

func path_for(key: String, id: String = "") -> String:
	var value = config.get(key, "")
	if value is Dictionary:
		return str(value.get(id, ""))
	return str(value)

func resource(key: String, id: String = "") -> Resource:
	var path = path_for(key, id)
	if path.is_empty() or not ResourceLoader.exists(path):
		if not warned.has(path):
			push_warning("资源尚未导入：" + path)
			warned[path] = true
		return null
	return load(path)

func texture(key: String, id: String) -> Texture2D:
	return resource(key, id) as Texture2D

func model(key: String) -> Node3D:
	var source = resource(key)
	if source is PackedScene:
		return source.instantiate() as Node3D
	if source is Mesh:
		var instance = MeshInstance3D.new()
		instance.mesh = source
		return instance
	return null

func vector_setting(key: String) -> Vector3:
	var values = config.get(key, [0, 0, 0])
	if values is Array and values.size() == 3:
		return Vector3(float(values[0]), float(values[1]), float(values[2]))
	return Vector3.ZERO
