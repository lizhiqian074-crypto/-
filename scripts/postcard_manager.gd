extends Node
signal postcard_available(id: String)
var postcards: Array[PostcardData] = []
func configure(events: Node) -> void:
	for id in GameManager.EVENT_IDS:
		var data = PostcardData.new()
		data.postcard_id = id
		data.image_path = AssetCatalog.path_for("postcards", id)
		data.unlocked = GameManager.completed(id)
		postcards.append(data)
	events.event_triggered.connect(on_event)

func on_event(id: String) -> void:
	for data in postcards:
		if data.postcard_id == id and not data.unlocked:
			data.unlocked = true
			postcard_available.emit(id)
			return
