extends Node3D
@export var debug_mode = false
@onready var events = $EventManager
@onready var hud = $CanvasLayer/GameHUD
@onready var viewer = $CanvasLayer/PostcardViewer
@onready var collection = $CanvasLayer/PostcardCollection

func _ready() -> void:
	InputSetup.install()
	load_environment()
	prepare_navigation()
	var height = float(AssetCatalog.config.get("ground_height", 0.0))
	if AssetCatalog.config.get("use_flat_navigation", true):
		for key in ["MainDeer", "CompanionDeer", "MossDeer", "AmberDeer", "CloudDeer", "ForagePatch", "HomeArea", "ExploreArea_A", "ExploreArea_B", "CompanionSpawn"]:
			get_node(key).position.y = height
		$ObservationRig.position.y += height
	events.debug_mode = events.debug_mode or debug_mode
	$HerdManager.configure(self)
	$CanvasLayer/HerdViewer.herd = $HerdManager
	hud.herd = $HerdManager
	hud.herd_viewer = $CanvasLayer/HerdViewer
	events.configure(self)
	$PostcardManager.configure(events)
	$PostcardManager.postcard_available.connect(viewer.show_postcard)
	hud.collection_requested.connect(collection.open)
	collection.postcard_selected.connect(viewer.show_postcard)
	hud.animal = $MainDeer
	hud.events = events
	# Missing resources are explicit in the HUD, without crashing the demo.
	if AssetCatalog.path_for("deer_model").is_empty() or not ResourceLoader.exists(AssetCatalog.path_for("deer_model")):
		hud.notice.text = "资源适配预览 · 森林与毛冠鹿使用临时几何占位；请导入现有资产。"
	start_audio()

func load_environment() -> void:
	var forest = AssetCatalog.model("forest_model")
	if forest == null:
		forest = PlaceholderWorld.forest_marker()
	else:
		forest.scale *= float(AssetCatalog.config.get("forest_scale", 1.0))
		forest.position = AssetCatalog.vector_setting("forest_offset")
	$EnvironmentRoot.add_child(forest)
	if not forest.find_children("*", "Light3D", true, false).is_empty():
		$DirectionalLight3D.visible = false

func prepare_navigation() -> void:
	var half_extent = float(AssetCatalog.config.get("navigation_half_extent", 18.0))
	$MainDeer.fallback_half_extent = half_extent
	$CompanionDeer.fallback_half_extent = half_extent
	for node in [$MossDeer,$AmberDeer,$CloudDeer]:
		node.fallback_half_extent = half_extent
	var region: NavigationRegion3D = $NavigationRegion3D
	if not AssetCatalog.config.get("use_flat_navigation", true):
		return # Keep a hand-baked NavigationMesh; no mesh means bounded fallback.
	var nav = NavigationMesh.new()
	var h = float(AssetCatalog.config.get("ground_height", 0.0))
	nav.vertices = PackedVector3Array([Vector3(-half_extent,h,-half_extent), Vector3(-half_extent,h,half_extent), Vector3(half_extent,h,half_extent), Vector3(half_extent,h,-half_extent)])
	nav.add_polygon(PackedInt32Array([0,1,2,3]))
	region.navigation_mesh = nav

func start_audio() -> void:
	var stream = AssetCatalog.resource("forest_ambience") as AudioStream
	if stream == null:
		return
	var audio = AudioStreamPlayer.new()
	audio.name = "ForestAmbience"
	audio.stream = stream
	audio.volume_db = -18
	add_child(audio)
	audio.finished.connect(audio.play)
	audio.play()
