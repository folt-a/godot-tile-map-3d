#01. @tool
@tool
#02. class_name
@icon("./TileMap3D.svg")
class_name TileMap3D
#03. extends
extends MeshInstance3D
#04. # docstring


## hoge

#region Signal, Enum, Const
#-----------------------------------------------------------
#05. signals
#-----------------------------------------------------------



#-----------------------------------------------------------
#06. enums
#-----------------------------------------------------------



#-----------------------------------------------------------
#07. constants
#-----------------------------------------------------------



#endregion
#-----------------------------------------------------------

#region Variable
#-----------------------------------------------------------
#08. exported variables
#-----------------------------------------------------------
@export var update_mesh_btn:bool:
	set(v):
		update_mesh_btn = false
		if Engine.is_editor_hint() and tile_map_x:
			_ready()

@export_category("BaseTile Settings")

@export var tile_map_x: TileMap
@export var tile_map_y: TileMap
@export var tile_map_z: TileMap
@export var tile_size: Vector2 = Vector2(1.0,1.0)
@export var tile_layer_height: float = 1.0
@export var tile_layer_height_start: float = 0.0
@export var tile_material:Material


@export_category("Grid Map")
@export var init_grid_map_btn: bool:
	set(v):
		init_grid_map_btn = v
		if Engine.is_editor_hint():
			await EditorInterface.get_editor_main_screen().get_tree().create_timer(0.1).timeout
		if Engine.is_editor_hint():
			if v and self.grid_map == null:
				# GridMapがなければ作成する
				var is_exists:bool = false
				for child in get_children():
					if child is GridMap:
						is_exists = true
						break
				if !is_exists:
					var grid_map:= GridMap.new()
					add_child(grid_map)
					grid_map.owner = EditorInterface.get_edited_scene_root()
					self.grid_map = grid_map
		if Engine.is_editor_hint():
			if self.tile_map_x == null:
				# なければ作成する
				var is_exists:bool = false
				for child in get_children():
					if child is TileMap:
						is_exists = true
						break
				if !is_exists:
					var tile_map_x:= TileMap.new()
					add_child(tile_map_x)
					tile_map_x.owner = EditorInterface.get_edited_scene_root()
					tile_map_x.name = "TileMap_X"
					self.tile_map_x = tile_map_x
					var tile_map_y:= TileMap.new()
					add_child(tile_map_y)
					tile_map_y.owner = EditorInterface.get_edited_scene_root()
					tile_map_y.name = "TileMap_Y"
					self.tile_map_y = tile_map_y
					var tile_map_z:= TileMap.new()
					add_child(tile_map_z)
					tile_map_z.owner = EditorInterface.get_edited_scene_root()
					tile_map_z.name = "TileMap_Z"
					self.tile_map_z = tile_map_z

@export var grid_map:GridMap = null
@export var tile_set:TileSet = null:
	set(v):
		tile_set = v
		if Engine.is_editor_hint():
			tile_map_x.tile_set = v
			tile_map_y.tile_set = v
			tile_map_z.tile_set = v

#@export_enum("床","壁 前後","壁 左右","坂 奥","坂 手前", "坂 左", "坂 右") var direction_type:int = 0

@export_range(0,100) var slope_bottom_cell_count:int = 0:
	set(v):
		slope_bottom_cell_count = v
		if v == 0:
			grid_height = 1.0
		else:
			grid_height = 1.0 / float(v)
			tile_layer_height = grid_height
		
		
@export var grid_height:float = 1.0

@export var grid_material:Material

@export var update_gridmap_btn:bool:
	set(v):
		update_gridmap_btn = false
		if Engine.is_editor_hint():
			if !grid_map or !tile_set:
				#printerr("GridMapとTileSetを設定してください")
				return
			make_grid_map()

@export var bake_btn:bool:
	set(v):
		bake_btn = false
		if Engine.is_editor_hint():
			if !grid_map or !tile_set:
				#printerr("GridMapとTileSetを設定してください")
				return
			bake_grid_map()

@export_category("Asset")
@export var export_mesh_path:String = ""
@export var export_mesh_btn:bool:
	set(v):
		export_mesh_btn = false
		if Engine.is_editor_hint():
			if !grid_map or !tile_set:
				#printerr("GridMapとTileSetを設定してください")
				return
			export_mesh()

func make_grid_map():
	var mesh_lib:= MeshLibrary.new()
	var terrains:Array[Dictionary] = []
	var tileset_srcs:Array[TileSetAtlasSource] = []
	for src_id in tile_set.get_source_count():
		## TODO オートタイル以外
		var tile_src:=tile_set.get_source(src_id)
		if !tile_src is TileSetAtlasSource:continue
		var tile_atlas_src:TileSetAtlasSource = tile_src
		## TODO 途中
		tileset_srcs.append(tile_atlas_src)
		
	# オートタイル タイルマップに塗ってそのセルから情報を取得する……遠回り
	tile_map_x.clear()
	tile_map_y.clear()
	tile_map_z.clear()
	var tile_map:TileMap = tile_map_x
	var terrain_set_index2x:int = 0
	for terrain_set_id in tile_set.get_terrain_sets_count():
		var terrain_index2x:int = 0
		for terrain_id in tile_set.get_terrains_count(terrain_set_id):
			#tile_set.get_terrain_color(terrain_set_id, terrain_id)
			tile_map.set_cells_terrain_connect(0,[Vector2i(terrain_index2x, terrain_set_index2x)],terrain_set_id, terrain_id,false)
			terrain_index2x += 2
		terrain_set_index2x += 2

	var index:int = 0
	for cell in tile_map.get_used_cells(0):
		mesh_lib.create_item(index)
		var ary_mesh:= ArrayMesh.new()
		
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tile_texture:Texture2D= tileset_srcs[cell.y/2].texture
		var tilesize:int = tile_set.tile_size.x
		
		var tile_data:= tile_map.get_cell_tile_data(0,cell)
		var tile_atlas_coord:Vector2= Vector2(tile_map.get_cell_atlas_coords(0,cell))
		var uv_tile_size_x:float = tilesize / float(tile_texture.get_width())
		var uv_tile_size_y:float = tilesize / float(tile_texture.get_height())
		var uv_rect:Rect2 = Rect2(Vector2(tile_atlas_coord.x* uv_tile_size_x, tile_atlas_coord.y * uv_tile_size_y), Vector2i(uv_tile_size_x,uv_tile_size_y))

		var height:float = 0 -tile_size.x * grid_height / 2
		var x_point = -tile_size.x / 2
		var z_point = -tile_size.y / 2

		var katamuki_h:float = 0
		var radian = atan2(1,slope_bottom_cell_count)
		if slope_bottom_cell_count != 0:
			katamuki_h = tile_size.x * tan(radian)

			
		var triangle_1:PackedVector3Array
		var triangle_2:PackedVector3Array

		triangle_1 = [
			Vector3(x_point, height + katamuki_h,z_point),
			Vector3(x_point + tile_size.x,height + katamuki_h, z_point),
			Vector3(x_point, height,z_point+tile_size.y)
		]
		triangle_2 = [
			Vector3(x_point + tile_size.x,height + katamuki_h, z_point),
			Vector3(x_point + tile_size.x,height, z_point + tile_size.y),
			Vector3(x_point, height, z_point + tile_size.y)
		]
		

		#-----------------

		st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y))
		st.add_vertex(triangle_1[0])
		st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
		st.add_vertex(triangle_1[1])
		st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))

		st.add_vertex(triangle_1[2])

		# 2
		st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
		st.add_vertex(triangle_2[0])

		st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y + uv_tile_size_y))
		st.add_vertex(triangle_2[1])
		st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))
		st.add_vertex(triangle_2[2])


		st.index()
		
		if grid_material:
			st.set_material(grid_material)
		else:
			var mat = create_material(tile_texture)
			st.set_material(mat)
		ary_mesh = st.commit()
		
		# 1,2の三角ポリゴンの矩形を底面ポリゴンとして、正方形の残りのポリゴンを埋める
		var st_2 = SurfaceTool.new()
		st_2.begin(Mesh.PRIMITIVE_TRIANGLES)

		# 1,2の三角ポリゴンの矩形を底面ポリゴンとして、正方形の残りのポリゴンを埋める

		# 上面
		var triangle_3:PackedVector3Array
		var triangle_4:PackedVector3Array
		triangle_3 = [
			Vector3(x_point, height *3 + katamuki_h,z_point),
			Vector3(x_point + tile_size.x,height *3 + katamuki_h, z_point),
			Vector3(x_point, height *3,z_point+tile_size.y)
		]
		triangle_4 = [
			Vector3(x_point + tile_size.x,height *3 + katamuki_h, z_point),
			Vector3(x_point + tile_size.x,height *3, z_point + tile_size.y),
			Vector3(x_point, height *3, z_point + tile_size.y)
		]
		# 底面
		st_2.add_vertex(triangle_3[0])
		st_2.add_vertex(triangle_3[1])
		st_2.add_vertex(triangle_3[2])
		st_2.add_vertex(triangle_4[0])
		st_2.add_vertex(triangle_4[1])
		st_2.add_vertex(triangle_4[2])
		
		# 囲う4面のポリゴンを作成
		# 左
		var triangle_5:PackedVector3Array
		var triangle_6:PackedVector3Array
		triangle_5 = [
			Vector3(x_point, height *3 + katamuki_h,z_point),
			Vector3(x_point, height *3 + katamuki_h, z_point + tile_size.y),
			Vector3(x_point, height,z_point+tile_size.y)
		]
		triangle_6 = [
			Vector3(x_point, height *3 + katamuki_h,z_point),
			Vector3(x_point, height,z_point+tile_size.y),
			Vector3(x_point, height,z_point)
		]
		# 右
		var triangle_7:PackedVector3Array
		var triangle_8:PackedVector3Array
		triangle_7 = [
			Vector3(x_point + tile_size.x, height *3 + katamuki_h,z_point),
			Vector3(x_point + tile_size.x, height *3 + katamuki_h, z_point + tile_size.y),
			Vector3(x_point + tile_size.x, height,z_point+tile_size.y)
		]
		triangle_8 = [
			Vector3(x_point + tile_size.x, height *3 + katamuki_h,z_point),
			Vector3(x_point + tile_size.x, height,z_point+tile_size.y),
			Vector3(x_point + tile_size.x, height,z_point)
		]
		# 奥
		var triangle_9:PackedVector3Array
		var triangle_10:PackedVector3Array
		triangle_9 = [
			Vector3(x_point, height *3 + katamuki_h,z_point),
			Vector3(x_point + tile_size.x, height *3 + katamuki_h, z_point),
			Vector3(x_point + tile_size.x, height,z_point)
		]
		triangle_10 = [
			Vector3(x_point, height *3 + katamuki_h,z_point),
			Vector3(x_point + tile_size.x, height,z_point),
			Vector3(x_point, height,z_point)
		]
		# 手前
		var triangle_11:PackedVector3Array
		var triangle_12:PackedVector3Array
		triangle_11 = [
			Vector3(x_point, height * 3 + katamuki_h, z_point + tile_size.y),
			Vector3(x_point + tile_size.x, height * 3 + katamuki_h, z_point + tile_size.y),
			Vector3(x_point, height, z_point + tile_size.y)

			# Vector3(x_point, height *3 + katamuki_h,z_point + tile_size.y),
			# Vector3(x_point + tile_size.x, height *3 + katamuki_h, z_point + tile_size.y),
			# Vector3(x_point + tile_size.x, height,z_point + tile_size.y)
		]
		triangle_12 = [
			Vector3(x_point + tile_size.x, height * 3 + katamuki_h, z_point + tile_size.y),
			Vector3(x_point + tile_size.x, height, z_point + tile_size.y),
			Vector3(x_point, height, z_point + tile_size.y),

			# Vector3(x_point, height *3 + katamuki_h,z_point + tile_size.y),
			# Vector3(x_point + tile_size.x, height,z_point + tile_size.y),
			# Vector3(x_point, height,z_point + tile_size.y)
		]
		st_2.add_vertex(triangle_5[0])
		st_2.add_vertex(triangle_5[1])
		st_2.add_vertex(triangle_5[2])
		st_2.add_vertex(triangle_6[0])
		st_2.add_vertex(triangle_6[1])
		st_2.add_vertex(triangle_6[2])
		st_2.add_vertex(triangle_7[0])
		st_2.add_vertex(triangle_7[1])
		st_2.add_vertex(triangle_7[2])
		st_2.add_vertex(triangle_8[0])
		st_2.add_vertex(triangle_8[1])
		st_2.add_vertex(triangle_8[2])
		st_2.add_vertex(triangle_9[0])
		st_2.add_vertex(triangle_9[1])
		st_2.add_vertex(triangle_9[2])
		st_2.add_vertex(triangle_10[0])
		st_2.add_vertex(triangle_10[1])
		st_2.add_vertex(triangle_10[2])
		st_2.add_vertex(triangle_11[0])
		st_2.add_vertex(triangle_11[1])
		st_2.add_vertex(triangle_11[2])
		st_2.add_vertex(triangle_12[0])
		st_2.add_vertex(triangle_12[1])
		st_2.add_vertex(triangle_12[2])
		
		st_2.index()
		
		var mat = create_material(tile_texture)
		st_2.set_material(mat)
		var ary_mesh_2:= ArrayMesh.new()
		ary_mesh_2 = st_2.commit(ary_mesh)
		
		mesh_lib.set_item_mesh(index, ary_mesh_2)
		mesh_lib.set_item_name(index, str(index).pad_zeros(3))
		var shape:=BoxShape3D.new()
		shape.size = Vector3(tile_size.x, grid_height ,tile_size.y)
		mesh_lib.set_item_shapes(index,[shape, Transform3D.IDENTITY])
		# パレットプレビュー画像 Image、ImageTextureを使うとうまくいかないのでやめた
		#var src_image:= tile_texture.get_image()
		#var image:=Image.create(tilesize,tilesize,false,src_image.get_format())
		#image.blit_rect(src_image,Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize)),Vector2i.ZERO)
		#print(tile_atlas_coord)
		#print(tile_atlas_coord * tilesize)
		#image.save_png("res://test.png")

		# パレットプレビュー画像 AtlasTextureを使う
		var tex:= AtlasTexture.new()
		tex.atlas = tile_texture
		tex.region = Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize))
		mesh_lib.set_item_preview(index, tex)
		index += 1
	
	grid_map.cell_size = Vector3(tile_size.x, grid_height, tile_size.y)
	grid_map.mesh_library = mesh_lib
	grid_map.collision_mask = 0b00000000_00000000_00000000_11111111
	grid_map.collision_layer = 0b00000000_00000000_00000000_11111111
	var source_code = "@tool\nextends GridMap\n@export var bake:bool:\n\tset(v):\n\t\tbake=false\n\t\tget_parent().bake_grid_map()\n@export var re_edit:bool:\n\tset(v):\n\t\tre_edit=false\n\t\tget_parent().re_edit_grid_mesh()\n@export var clear_all_cells:bool:\n\tset(v):\n\t\tclear_all_cells=false\n\t\tself.clear()"
	var grid_script = GDScript.new()
	grid_script.source_code = source_code
	grid_script.reload()
	grid_map.set_script(grid_script)

func re_edit_grid_mesh():
	self.mesh = null
	grid_map.visible = true
	tile_map_x.clear()
	tile_map_y.clear()
	tile_map_z.clear()

func bake_grid_map():
	var ary_mesh:ArrayMesh = ArrayMesh.new()
	var tileset_src:TileSetAtlasSource= tile_set.get_source(0)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tile_texture:Texture2D= tileset_src.texture
	
	# TODO
	# 面の角度で投影する高さレイヤーの取得方法を変更する
	# 射影?　切る断面みたいな・・・
	# そんなことなさそう　角度つけても1セル1セルの階段状になるので床と壁と階段（坂だけど）の3パターンになるはず
	#@export_enum("床","壁 前後","壁 左右","坂 奥","坂 手前", "坂 左", "坂 右") var direction_type:int = 0
	
	var xyz_layer_mesh_xycoords_ary:Dictionary = {}
	# {0(xyz) : {0(layer): {0(mesh):[coords]}}
	# GridMapの座標からTileMapを埋めていく
	for cell in grid_map.get_used_cells():

		var mesh_index:int = grid_map.get_cell_item(cell)
		var mesh_basis = grid_map.get_cell_item_basis(cell)
		
		#print(mesh_basis)
		
		var slice_side:int = 0
		var mesh_vec2i:Vector2i = Vector2i.ZERO
		#軸判定
		
		var xyz:int = 0

		# 左右壁(X)
		if mesh_basis.y == Vector3.LEFT or mesh_basis.y == Vector3.RIGHT:
			slice_side = cell.x
			if mesh_basis.y == Vector3.LEFT:
				slice_side = cell.x + tile_layer_height
			mesh_vec2i = Vector2i(-cell.z, -cell.y)
			#print(cell,"左右壁")
			#レイヤーがなければ追加する
			while tile_map_x.get_layers_count() < slice_side + 1:
				tile_map_x.add_layer(-1)
			xyz = 0

		# 床(Y)
		if mesh_basis.y == Vector3.UP or mesh_basis.y == Vector3.DOWN:
			slice_side = cell.y
			if mesh_basis.y == Vector3.DOWN:
				slice_side = cell.y + tile_layer_height
			mesh_vec2i = Vector2i(cell.x, cell.z)
			#print(cell,"床")
			#レイヤーがなければ追加する
			while tile_map_y.get_layers_count() < slice_side + 1:
				tile_map_y.add_layer(-1)
			xyz = 1
		
		# 前後壁(Z)
		if mesh_basis.y == Vector3.FORWARD or mesh_basis.y == Vector3.BACK:
			slice_side = cell.z
			if mesh_basis.y == Vector3.FORWARD:
				slice_side = cell.z + tile_layer_height
			mesh_vec2i = Vector2i(-cell.x, -cell.y)
			#print(cell,"前後壁")
			#レイヤーがなければ追加する
			while tile_map_z.get_layers_count() < slice_side + 1:
				tile_map_z.add_layer(-1)
			xyz = 2

		if !xyz_layer_mesh_xycoords_ary.has(xyz):
			xyz_layer_mesh_xycoords_ary[xyz] = {}
		if !xyz_layer_mesh_xycoords_ary[xyz].has(slice_side):
			xyz_layer_mesh_xycoords_ary[xyz][slice_side] = {}
		if !xyz_layer_mesh_xycoords_ary[xyz][slice_side].has(mesh_index):
			xyz_layer_mesh_xycoords_ary[xyz][slice_side][mesh_index] = []
		xyz_layer_mesh_xycoords_ary[xyz][slice_side][mesh_index].append({"cell" : mesh_vec2i, "basis": mesh_basis})

	tile_map_x.clear()
	tile_map_y.clear()
	tile_map_z.clear()
	
	# カスタムデータレイヤーをクリア
	for i in tile_set.get_custom_data_layers_count():
		tile_set.remove_custom_data_layer(i)
	tile_set.add_custom_data_layer(-1)
	tile_set.set_custom_data_layer_name(0, &"basis")
	tile_set.set_custom_data_layer_type(0, TYPE_BASIS)
	
	for xyz in xyz_layer_mesh_xycoords_ary.keys():
		var tile_map:TileMap
		if xyz == 0:
			tile_map = tile_map_x
		if xyz == 1:
			tile_map = tile_map_y
		if xyz == 2:
			tile_map = tile_map_z
		for layer_index in xyz_layer_mesh_xycoords_ary[xyz].keys():
			for mesh_index in xyz_layer_mesh_xycoords_ary[xyz][layer_index].keys():
				#print(xyz_layer_mesh_xycoords_ary[layer_index][mesh_index])
				var cells:Array= xyz_layer_mesh_xycoords_ary[xyz][layer_index][mesh_index].map(func(i): return i.cell)
				tile_map.set_cells_terrain_connect(layer_index,cells, 0, mesh_index,false)
				for cell_info in xyz_layer_mesh_xycoords_ary[xyz][layer_index][mesh_index]:
					var tiledata = tile_map.get_cell_tile_data(layer_index,cell_info.cell,false)
					#tiledata.set_custom_data(&"mesh_index", mesh_index)
					tiledata.set_custom_data(&"basis", cell_info.basis)
		tile_map.update_internals()
	
		for layer_index in tile_map.get_layers_count():
			var cells:=tile_map.get_used_cells(layer_index)
			var tilesize:int = tile_set.tile_size.x
			
			#var surface_vertex_array:Array = []
			#surface_vertex_array.resize(ArrayMesh.ARRAY_MAX)
			for cell in cells:
				var tile_data:= tile_map.get_cell_tile_data(layer_index,cell)
				var tile_atlas_coord:Vector2= Vector2(tile_map.get_cell_atlas_coords(layer_index,cell))
				#var real_image_rect:Rect2i = Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize))
				var uv_tile_size_x:float = tilesize / float(tile_texture.get_width())
				var uv_tile_size_y:float = tilesize / float(tile_texture.get_height())
				var uv_rect:Rect2 = Rect2(Vector2(tile_atlas_coord.x* uv_tile_size_x, tile_atlas_coord.y * uv_tile_size_y), Vector2i(uv_tile_size_x,uv_tile_size_y))
				
				var height:float = layer_index * tile_layer_height + tile_layer_height_start
				
				var mesh_basis:Basis = tile_data.get_custom_data(&"basis")
				
				#print(basis_)
				
				# Basisのとおりに回転する
				## 左右壁(X)
				#if mesh_basis.y == Vector3.LEFT or mesh_basis.y == Vector3.RIGHT:
					#xyz = 0

				## 床(Y)
				#if mesh_basis.y == Vector3.UP or mesh_basis.y == Vector3.DOWN:
					#xyz = 1
				#
				## 前後壁(Z)
				#if mesh_basis.y == Vector3.FORWARD or mesh_basis.y == Vector3.BACK:
					#xyz = 2
				
				
				##print(
					##{
						##"cell": cell,
						##"texture_origin": tile_data.texture_origin,
						###'transpose': tile_data.transpose,
						###"terrain_set" : tile_data.terrain_set,
						##"terrain" : tile_data.terrain,
						##"tilesetatlas?" : tile_atlas
					##}
				##)
				
				var katamuki_h:float = 0
				var radian = atan2(1,slope_bottom_cell_count)
				if slope_bottom_cell_count != 0:
					katamuki_h = tile_size.x * tan(radian)
				
				
				var triangle_1:PackedVector3Array
				var triangle_2:PackedVector3Array
				
				var uv_1:PackedVector2Array
				var uv_2:PackedVector2Array
				uv_1 = [
					Vector2(uv_rect.position.x, uv_rect.position.y),
					Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
				]
				uv_2 = [
					Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y + uv_tile_size_y),
					Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
				]

				if xyz == 0: # 左右 X
					cell =-cell
					triangle_1 = [
						Vector3(height + katamuki_h, cell.y,cell.x),
						Vector3(height + katamuki_h, cell.y,cell.x + tile_size.x),
						Vector3(height, cell.y + tile_size.y, cell.x),
					]
					triangle_2 = [
						Vector3(height + katamuki_h, cell.y,cell.x + tile_size.x),
						Vector3(height, cell.y + tile_size.y,cell.x + tile_size.x),
						Vector3(height, cell.y + tile_size.y, cell.x),
					]

					# UVを180度回転
					uv_1 = [
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					]
					uv_2 = [
						Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x, uv_rect.position.y),
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					]

				elif xyz == 1: # 床 Y
					triangle_1 = [
						Vector3(cell.x, height + katamuki_h,cell.y),
						Vector3(cell.x + tile_size.x,height + katamuki_h, cell.y),
						Vector3(cell.x, height,cell.y + tile_size.y),
					]
					triangle_2 = [
						Vector3(cell.x + tile_size.x,height + katamuki_h, cell.y),
						Vector3(cell.x + tile_size.x,height, cell.y + tile_size.y),
						Vector3(cell.x, height, cell.y + tile_size.y),
					]
				elif xyz == 2: # 前後 Z
					cell =-cell
					triangle_1 = [
						Vector3(cell.x, cell.y, height + katamuki_h),
						Vector3(cell.x +tile_size.x, cell.y, height + katamuki_h),
						Vector3(cell.x, cell.y + tile_size.y, height),
					]
					triangle_2 = [
						Vector3(cell.x + tile_size.x, cell.y, height + katamuki_h),
						Vector3(cell.x + tile_size.x, cell.y + tile_size.y, height),
						Vector3(cell.x, cell.y + tile_size.y, height),
					]

					# UVを180度回転
					uv_1 = [
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					]
					uv_2 = [
						Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y),
						Vector2(uv_rect.position.x, uv_rect.position.y),
						Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y),
					]


				#st.set_uv(real_image_rect.position)
				st.set_uv(uv_1[0])
				st.add_vertex(triangle_1[0])
				st.set_uv(uv_1[1])
				#print(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
				st.add_vertex(triangle_1[1])
				st.set_uv(uv_1[2])
				#print(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))
				st.add_vertex(triangle_1[2])

				# 2
				st.set_uv(uv_2[0])
				st.add_vertex(triangle_2[0])
				st.set_uv(uv_2[1])
				st.add_vertex(triangle_2[1])
				st.set_uv(uv_2[2])
				st.add_vertex(triangle_2[2])
		
	st.index()
	
	if tile_material:
		tile_material.albedo_texture = tile_texture
		st.set_material(tile_material)
	else:
		var mat = create_material(tile_texture)
		st.set_material(mat)
		#ResourceSaver.save(mat,"res://mat.tres")
	ary_mesh = st.commit()
	grid_map.set_meta(&"_editor_floor_", Vector3(1,1,1))
	#ResourceSaver.save(ary_mesh,"res://ary_mesh.tres")
		
		#ary_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_vertex_array)
		
		
		#for cell in cells:
			#var tile_data:= tile_map.get_cell_tile_data(layer_index,cell)
			#var tile_atlas_coord:Vector2i= tile_map.get_cell_atlas_coords(0,cell)
			#
			#var real_image_rect:Rect2i = Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize))
		#
			#for i in range(mdt.get_vertex_count()):
				#var vertex = mdt.get_vertex(i)
				## In this example we extend the mesh by one unit, which results in separated faces as it is flat shaded.
				#vertex += mdt.get_vertex_normal(i)
				#print(vertex)
				#
				##mdt.set_vertex_uv()
				#mdt.set_vertex_color(i,Color(randf_range(0,1),randf_range(0,1),randf_range(0,1)))
				#mdt.set_material(NEW_STANDARD_MATERIAL_3D)
				## Save your change.
				#mdt.set_vertex(i, vertex)
			##ary_mesh.clear_surfaces()
			##ary_mesh.surface_set_material(0,NEW_STANDARD_MATERIAL_3D)
			##mdt.commit_to_surface(ary_mesh)
	self.mesh = ary_mesh
	grid_map.visible = false
	
	## export
	
	## Save a new glTF scene.
	#var gltf_document_save := GLTFDocument.new()
	#var gltf_state_save := GLTFState.new()
	#gltf_document_save.append_from_scene(self, gltf_state_save)
	#
	## The file extension in the output `path` (`.gltf` or `.glb`) determines
	## whether the output uses text or binary format.
	## `GLTFDocument.generate_buffer()` is also available for saving to memory.
	#gltf_document_save.write_to_filesystem(gltf_state_save, "res://aaa.gltf")

	
	
	pass

func export_mesh():
	if !export_mesh_path.validate_filename()\
	or (!export_mesh_path.ends_with(".gltf") and !export_mesh_path.ends_with(".glb")):
		printerr("gltfかglbにしてくださーい")
		return
	# 子ノードを退避
	var tmp_children:Array[Node] = []
	for child in get_children():
		child.owner = null
		remove_child(child)
		tmp_children.append(child)
	
	# メッシュ書き出し
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.append_from_scene(self, gltf_state_save)
	gltf_document_save.write_to_filesystem(gltf_state_save, export_mesh_path)
	
	# 子ノードを復帰
	for child in tmp_children:
		print(child)
		add_child(child)
		child.owner = EditorInterface.get_edited_scene_root()

#-----------------------------------------------------------
#09. public variables
#-----------------------------------------------------------



#-----------------------------------------------------------
#10. private variables
#-----------------------------------------------------------


#-----------------------------------------------------------
#11. onready variables
#-----------------------------------------------------------



#endregion
#-----------------------------------------------------------

#region _init, _ready
#-----------------------------------------------------------
#12. optional built-in virtual _init method
#-----------------------------------------------------------



#-----------------------------------------------------------
#13. built-in virtual _ready method
#-----------------------------------------------------------

#
#func make_tile_3d():
	#var ary_mesh:ArrayMesh = ArrayMesh.new()
	#var tile_map:TileMap
	#var tileset:= tile_map.tile_set
	#var tileset_src:TileSetAtlasSource= tileset.get_source(0)
	#var st:=SurfaceTool.new()
	#st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#var tile_texture:Texture2D= tileset_src.texture
	#for layer_index in tile_map.get_layers_count():
		#var cells:=tile_map.get_used_cells(layer_index)
		##print(cells)
		#var tilesize:int = tileset.tile_size.x
		#
		##var surface_vertex_array:Array = []
		##surface_vertex_array.resize(ArrayMesh.ARRAY_MAX)
		#for cell in cells:
			#var tile_data:= tile_map.get_cell_tile_data(layer_index,cell)
			#var tile_atlas_coord:Vector2= Vector2(tile_map.get_cell_atlas_coords(layer_index,cell))
			##var real_image_rect:Rect2i = Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize))
			#var uv_tile_size_x:float = tilesize / float(tile_texture.get_width())
			#var uv_tile_size_y:float = tilesize / float(tile_texture.get_height())
			#var uv_rect:Rect2 = Rect2(Vector2(tile_atlas_coord.x* uv_tile_size_x, tile_atlas_coord.y * uv_tile_size_y), Vector2i(uv_tile_size_x,uv_tile_size_y))
			#
			#var height:float = layer_index * tile_layer_height + tile_layer_height_start
			#
			##print(
				##{
					##"cell": cell,
					##"texture_origin": tile_data.texture_origin,
					###'transpose': tile_data.transpose,
					###"terrain_set" : tile_data.terrain_set,
					##"terrain" : tile_data.terrain,
					##"tilesetatlas?" : tile_atlas
				##}
			##)
			#
			##st.set_uv(real_image_rect.position)
			#st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y))
			#print(Vector2(uv_rect.position.x, uv_rect.position.y))
			#st.add_vertex(Vector3(cell.x, height,cell.y))
			#print(Vector3(cell.x, height,cell.y))
			#st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
			##print(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
			#st.add_vertex(Vector3(cell.x + tile_size.x,height, cell.y))
			#st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))
			##print(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))
			#st.add_vertex(Vector3(cell.x, height,cell.y+tile_size.y))
#
			## 2
			#st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y))
			#st.add_vertex(Vector3(cell.x + tile_size.x,height, cell.y))
			#st.set_uv(Vector2(uv_rect.position.x + uv_tile_size_x, uv_rect.position.y + uv_tile_size_y))
			#st.add_vertex(Vector3(cell.x + tile_size.x,height, cell.y + tile_size.y))
			#st.set_uv(Vector2(uv_rect.position.x, uv_rect.position.y + uv_tile_size_y))
			#st.add_vertex(Vector3(cell.x, height, cell.y + tile_size.y))
			#
	#st.index()
	#
	#var mat = create_material(tile_texture)
	#st.set_material(mat)
	#ResourceSaver.save(mat,"res://mat.tres")
	#ary_mesh = st.commit()
	#ResourceSaver.save(ary_mesh,"res://ary_mesh.tres")
		#
		##ary_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_vertex_array)
		#
		#
		##for cell in cells:
			##var tile_data:= tile_map.get_cell_tile_data(layer_index,cell)
			##var tile_atlas_coord:Vector2i= tile_map.get_cell_atlas_coords(0,cell)
			##
			##var real_image_rect:Rect2i = Rect2i(tile_atlas_coord * tilesize, Vector2i(tilesize,tilesize))
		##
			##for i in range(mdt.get_vertex_count()):
				##var vertex = mdt.get_vertex(i)
				### In this example we extend the mesh by one unit, which results in separated faces as it is flat shaded.
				##vertex += mdt.get_vertex_normal(i)
				##print(vertex)
				##
				###mdt.set_vertex_uv()
				##mdt.set_vertex_color(i,Color(randf_range(0,1),randf_range(0,1),randf_range(0,1)))
				##mdt.set_material(NEW_STANDARD_MATERIAL_3D)
				### Save your change.
				##mdt.set_vertex(i, vertex)
			###ary_mesh.clear_surfaces()
			###ary_mesh.surface_set_material(0,NEW_STANDARD_MATERIAL_3D)
			###mdt.commit_to_surface(ary_mesh)
	#self.mesh = ary_mesh
	#
	### export
	#
	### Save a new glTF scene.
	##var gltf_document_save := GLTFDocument.new()
	##var gltf_state_save := GLTFState.new()
	##gltf_document_save.append_from_scene(self, gltf_state_save)
	##
	### The file extension in the output `path` (`.gltf` or `.glb`) determines
	### whether the output uses text or binary format.
	### `GLTFDocument.generate_buffer()` is also available for saving to memory.
	##gltf_document_save.write_to_filesystem(gltf_state_save, "res://aaa.gltf")

	
#const NEW_STANDARD_MATERIAL_3D = preload("res://new_standard_material_3d.tres")

func create_material(tex:Texture) -> Material:
	var mat = StandardMaterial3D.new()
	#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	#mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	#mat.albedo_texture = tex
	mat.albedo_color = Color.from_string("#b5ffff76",Color.WHITE)
	mat.albedo_color = Color(0.8, 1.0, 1.0, 0.25)
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = 1.0
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 0.0
	mat.distance_fade_max_distance = 28.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func set_floor(hit_position:Vector3,ray_dir:Vector3) -> void:
	# ray_dirがX軸かY軸かZ軸か判断する
	var axis = 0
	var axis_dir = 0

	var floor_vec3:Vector3
	if grid_map.has_meta(&"_editor_floor_"):
		floor_vec3 = grid_map.get_meta(&"_editor_floor_")
	else:
		return
	
	# X軸
	if abs(ray_dir.x) > abs(ray_dir.y) and abs(ray_dir.x) > abs(ray_dir.z):
		axis = 0
		axis_dir = sign(ray_dir.x)

		# Hitした座標のX座標を切り捨てして床の座標にする
		hit_position.x = floor(hit_position.x)
		grid_map.set_meta(&"_editor_floor_", Vector3(hit_position.x, floor_vec3.y, floor_vec3.z))

	# Y軸
	elif abs(ray_dir.y) > abs(ray_dir.x) and abs(ray_dir.y) > abs(ray_dir.z):
		axis = 1
		axis_dir = sign(ray_dir.y)	

		# Hitした座標のY座標を四捨五入して床の座標にする
		hit_position.y = floor(hit_position.y)
		grid_map.set_meta(&"_editor_floor_", Vector3(floor_vec3.x, hit_position.y, floor_vec3.z))

	# Z軸
	elif abs(ray_dir.z) > abs(ray_dir.x) and abs(ray_dir.z) > abs(ray_dir.y):
		axis = 2
		axis_dir = sign(ray_dir.z)

		# Hitした座標のZ座標を四捨五入して床の座標にする
		hit_position.z = floor(hit_position.z)
		grid_map.set_meta(&"_editor_floor_", Vector3(floor_vec3.x, floor_vec3.y, hit_position.z))

	EditorInterface.get_selection().clear()
	await get_tree().process_frame
	EditorInterface.get_selection().add_node(grid_map)

#func conv_coord_to_triangles_arrays(coord:Vector2i) -> Array:
	#var arrays = []
	#arrays.resize(2)
	#
	## 1
	#var vertices1 = PackedVector3Array()
	#var vertice_arrays1 = []
#
	#vertices1.push_back(Vector3(coord.x, 0,coord.y))
	#vertices1.push_back(Vector3(coord.x+1,0, coord.y))
	#vertices1.push_back(Vector3(coord.x, 0,coord.y+1))
#
	#vertice_arrays1.resize(Mesh.ARRAY_MAX)
	#vertice_arrays1[Mesh.ARRAY_VERTEX] = vertices1
	#
	## 2
	#var vertices2 = PackedVector3Array()
	#var vertice_arrays2 = []
#
	#vertices2.append(Vector3(coord.x+1,0, coord.y))
	#vertices2.append(Vector3(coord.x+1,0, coord.y+1))
	#vertices2.append(Vector3(coord.x,0, coord.y+1))
#
	#vertice_arrays2.resize(Mesh.ARRAY_MAX)
	#vertice_arrays2[Mesh.ARRAY_VERTEX] = vertices2
#
	#arrays[0] = vertice_arrays1
	#arrays[1] = vertice_arrays2
#
	#return arrays

#endregion
#-----------------------------------------------------------

#region _virtual Function
#-----------------------------------------------------------
#14. remaining built-in virtual methods
#-----------------------------------------------------------



#endregion
#-----------------------------------------------------------

#region Public Function
#-----------------------------------------------------------
#15. public methods
#-----------------------------------------------------------



#endregion
#-----------------------------------------------------------

#region _private Function
#-----------------------------------------------------------
#16. private methods
#-----------------------------------------------------------



#endregion
#-----------------------------------------------------------

