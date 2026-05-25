extends SceneTree
func _init():
	var img = Image.load_from_file("res://resources/UI/backpack.png")
	if img:
		print("Image size: ", img.get_size())
	else:
		print("Failed to load image from file")
	quit()
