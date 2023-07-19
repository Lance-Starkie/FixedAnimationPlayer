tool
extends EditorScript

export (NodePath) var old_animation_player_path
export (int) var fps = 60

export var logging = false 

func debug_log(message):
	if logging:
		print(message)

func compile(path):
	var old_animation_player = get_editor_interface().get_selection().get_selected_nodes()[0]
	var animation_data_resource = AnimationDataResource.new()
	var data = extract_animation_data(old_animation_player)
	animation_data_resource.animation_data = data[0]
	animation_data_resource.property_lookup_table = data[1]
	print(data[1])
	print(ResourceSaver.save(path, animation_data_resource))
	breakpoint

func extract_animation_data(animation_player):
	var animation_data = {}
	var animation_list = animation_player.get_animation_list()
	var property_lookup_table = {}

	for animation_name in animation_list:
		var animation = animation_player.get_animation(animation_name)
		var tracks_data = {
			"<length>":int(round(animation.length*60)),
			"<loop>":animation.loop
			}

		for track_index in range(0, animation.get_track_count()):
			var track_path = animation.track_get_path(track_index)
			var track_keyframes = []

			if animation.track_get_type(track_index) == Animation.TYPE_VALUE:
				for key_index in range(0, animation.track_get_key_count(track_index)):
					var key_time = int(round(animation.track_get_key_time(track_index, key_index)*60))
					var value = animation.track_get_key_value(track_index, key_index)
					
					# Update the property_lookup_table
					var node_path
					var property_name = track_path.get_concatenated_subnames()
					print(track_path)
					
					node_path = str(track_path).substr(2)
					if node_path.find(":") != -1:
						node_path = node_path.split(':')[0]
					else:
						node_path = "."
					
					property_lookup_table[property_name] = {
						"node_path": node_path
					}
					if key_time>tracks_data["<length>"]:
						tracks_data["<length>"] = key_time
					track_keyframes.append({
						"property": property_name,
						"time": key_time,
						"value": value
					})

			elif animation.track_get_type(track_index) == Animation.TYPE_METHOD:
				for key_index in range(0, animation.track_get_key_count(track_index)):
					var key_time = int(round(animation.track_get_key_time(track_index, key_index)*60))
					var method_name = animation.method_track_get_name(track_index, key_index)
					var args = animation.method_track_get_params(track_index, key_index)

					# Update the property_lookup_table
					var track_path_str = track_path.get_concatenated_subnames()
					var node_path = str(track_path).substr(2)
					var property_name = track_path.get_concatenated_subnames()

					if key_time>tracks_data["<length>"]:
						tracks_data["<length>"] = key_time
					if node_path.find(":") != -1:
						node_path = node_path.split(':')[0]
					else:
						node_path = "."
					
					property_lookup_table[property_name] = {
						"node_path": node_path
					}


					track_keyframes.append({
						"time": key_time,
						"method": method_name,
						"args": args
					})

			if animation.track_get_type(track_index) == Animation.TYPE_VALUE:
				tracks_data[track_path.get_concatenated_subnames()] = track_keyframes
			elif animation.track_get_type(track_index) == Animation.TYPE_METHOD:
				if not "" in tracks_data:
					tracks_data[""] = []
				for keyframe in track_keyframes:
					tracks_data[""].append(keyframe)


		animation_data[animation_name] = tracks_data

	return [animation_data, property_lookup_table]
