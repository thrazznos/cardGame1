## Shared texture loading utility for UI controllers.
##
## Attempts Godot's ResourceLoader first (for imported assets), then falls back
## to Image.load_from_file() for raw image files on disk.
class_name TextureLoader
extends RefCounted


## Try to load a texture from [param path].
## Returns [code]null[/code] when the asset cannot be found or loaded.
static func try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
