-- caverealms v.0.8 by HeroOfTheWinds
-- original cave code modified from paramat's subterrain
-- For Minetest 0.4.8 stable
-- Depends default
-- License: code WTFPL

subterrane = {} --create a container for functions and constants

--grab a shorthand for the filepath of the mod
local modpath = minetest.get_modpath(minetest.get_current_modname())

--load companion lua files
dofile(modpath.."/nodes.lua")
dofile(modpath.."/functions.lua") --function definitions
dofile(modpath.."/features.lua")
dofile(modpath.."/player_spawn.lua")

subterrane.disable_mapgen_caverns = function()
	local mg_name = minetest.get_mapgen_setting("mg_name")
	local flags_name
	local default_flags
	
	if mg_name == "v7" then 
		flags_name = "mgv7_spflags"
		default_flags = "mountains,ridges,nofloatlands"
	elseif mg_name == "v5" then
		flags_name = "mgv5_spflags"
		default_flags = ""
	else
		return
	end
	
	local function split(source, delimiters)
		local elements = {}
		local pattern = '([^'..delimiters..']+)'
		string.gsub(source, pattern, function(value) elements[#elements + 1] = value; end);
		return elements
	end
	
	local flags_setting = minetest.get_mapgen_setting(flags_name) or default_flags
	local new_flags = {}
	local flags = split(flags_setting, ", ")
	local nocaverns_present = false
	for _, flag in pairs(flags) do
		if flag ~= "caverns" then
			table.insert(new_flags, flag)
		end
		if flag == "nocaverns" then
			nocaverns_present = true
		end
	end
	if not nocaverns_present then
		table.insert(new_flags, "nocaverns")
	end
	minetest.set_mapgen_setting(flags_name, table.concat(new_flags, ","), true)
end

subterrane.disable_mapgen_caverns() -- defaulting to disabling them, for now. Need to assess how to integrate this feature into subterrane better.

local c_lava = minetest.get_content_id("default:lava_source")
local c_obsidian = minetest.get_content_id("default:obsidian")
local c_stone = minetest.get_content_id("default:stone")
local c_air = minetest.get_content_id("air")

subterrane.default_perlin_cave = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = -400000000089,
	octaves = 3,
	persist = 0.67
}

subterrane.default_perlin_wave = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=256, z=512}, -- squashed 2:1
	seed = 59033,
	octaves = 6,
	persist = 0.63
}

local data = {}
local data_param2 = {}

local nvals_cave_buffer = {}
local nvals_wave_buffer = {}

--{
--	minimum_depth = -- required, the highest elevation this cave layer will be generated in.
--	maximum_depth = -- required, the lowest elevation this cave layer will be generated in.
--	cave_threshold = -- optional, Cave threshold. Defaults to 0.5. 1 = small rare caves, 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume
--	boundary_blend_range = -- optional, range near ymin and ymax over which caves diminish to nothing. Defaults to 128.
--	perlin_cave = -- optional, a 3D perlin noise definition table to define the shape of the caves
--	perlin_wave = -- optional, a 3D perlin noise definition table that's averaged with the cave noise to add floor strata (squash its spread on the y axis relative to perlin_cave to accomplish this)
--}

function subterrane:register_cave_layer(cave_layer_def)

	local YMIN = cave_layer_def.maximum_depth
	local YMAX = cave_layer_def.minimum_depth
	local BLEND = math.min(cave_layer_def.boundary_blend_range or 128, (YMAX-YMIN)/2)
	local TCAVE = cave_layer_def.cave_threshold or 0.5

	local np_cave = cave_layer_def.perlin_cave or subterrane.default_perlin_cave
	local np_wave = cave_layer_def.perlin_wave or subterrane.default_perlin_wave
	
	local yblmin = YMIN + BLEND * 1.5
	local yblmax = YMAX - BLEND * 1.5	
	
	-- noise objects
	local nobj_cave = nil
	local nobj_wave = nil
	
	-- On generated function
	minetest.register_on_generated(function(minp, maxp, seed)
		--if out of range of cave definition limits, abort
		if minp.y > YMAX or maxp.y < YMIN then
			return
		end
		
		-- Create a table of biome ids for use with the biomemap.
		if not subterrane.biome_ids then
			subterrane.biome_ids = {}
			for name, desc in pairs(minetest.registered_biomes) do
				local i = minetest.get_biome_id(desc.name)
				subterrane.biome_ids[i] = desc.name
			end
		end
	
		--easy reference to commonly used values
		local t_start = os.clock()
		local x_max = maxp.x
		local y_max = maxp.y
		local z_max = maxp.z
		local x_min = minp.x
		local y_min = minp.y
		local z_min = minp.z
		
		print ("[subterrane] chunk minp ("..x_min.." "..y_min.." "..z_min..")") --tell people you are generating a chunk
		
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		vm:get_data(data)
		vm:get_param2_data(data_param2)
	
		local biomemap = minetest.get_mapgen_object("biomemap")
		
		--mandatory values
		local sidelen = x_max - x_min + 1 --length of a mapblock
		local chunk_lengths = {x = sidelen, y = sidelen, z = sidelen} --table of chunk edges
		local chunk_lengths2D = {x = sidelen, y = sidelen, z = 1}
		local minposxyz = {x = x_min, y = y_min, z = z_min} --bottom corner
		local minposxz = {x = x_min, y = z_min} --2D bottom corner
		
		nobj_cave = nobj_cave or minetest.get_perlin_map(np_cave, chunk_lengths)
		nobj_wave = nobj_wave or minetest.get_perlin_map(np_wave, chunk_lengths)
	
		local nvals_cave = nobj_cave:get3dMap_flat(minposxyz, nvals_cave_buffer) --cave noise for structure
		local nvals_wave = nobj_wave:get3dMap_flat(minposxyz, nvals_wave_buffer) --wavy structure of cavern ceilings and floors
		
		local index_3d = 1 --3D node index
		local index_2d = 1 --2D node index
		
		for z = z_min, z_max do -- for each xy plane progressing northwards
			--structure loop, hollows out the cavern
			for y = y_min, y_max do -- for each x row progressing upwards
				local tcave --declare variable
				--determine the overall cave threshold
				if y < yblmin then
					tcave = TCAVE + ((yblmin - y) / BLEND) ^ 2
				elseif y > yblmax then
					tcave = TCAVE + ((y - yblmax) / BLEND) ^ 2
				else
					tcave = TCAVE
				end
	
				local vi = area:index(x_min, y, z) --current node index
				for x = x_min, x_max do -- for each node do
	
					local biome_name = subterrane.biome_ids[biomemap[index_2d]]
					local biome = minetest.registered_biomes[biome_name]
									
					local fill_node = c_air
					if biome and biome._subterrane_fill_node then
						fill_node = biome._subterrane_fill_node
					end
	
					if (nvals_cave[index_3d] + nvals_wave[index_3d])/2 > tcave then --if node falls within cave threshold
						data[vi] = fill_node --hollow it out to make the cave
					elseif biome and biome._subterrane_cave_fill_node and data[vi] == c_air then
						data[vi] = biome._subterrane_cave_fill_node
					end
					
					if biome and biome._subterrane_mitigate_lava and (nvals_cave[index_3d] + nvals_wave[index_3d])/2 > tcave - 0.1 then -- Eliminate nearby lava to keep it from spilling in
						if data[vi] == c_lava then
							data[vi] = c_obsidian
						end
					end
					--increment indices
					index_3d = index_3d + 1
					index_2d = index_2d + 1
					vi = vi + 1
				end
				index_2d = index_2d - sidelen --shift the 2D index back
			end
			index_2d = index_2d + sidelen --shift the 2D index up a layer
		end
		
		local index_3d = 1 --3D node index
		local index_2d = 1 --2D node index
	
		for z = z_min, z_max do -- for each xy plane progressing northwards
	
			--decoration loop, places nodes on floor and ceiling
			for y = y_min, y_max do -- for each x row progressing upwards
				local tcave --same as above
				if y < yblmin then
					tcave = TCAVE + ((yblmin - y) / BLEND) ^ 2
				elseif y > yblmax then
					tcave = TCAVE + ((y - yblmax) / BLEND) ^ 2
				else
					tcave = TCAVE
				end
				local vi = area:index(x_min, y, z)
				for x = x_min, x_max do -- for each node do
				
					local biome_name = subterrane.biome_ids[biomemap[index_2d]]
					local biome = minetest.registered_biomes[biome_name]
					local fill_node = c_air
					local cave_fill_node = c_air
	
					if biome then
						-- only check nodes near the edges of caverns
						if math.floor(((nvals_cave[index_3d] + nvals_wave[index_3d])/2)*50) == math.floor(tcave*50) then
							if biome._subterrane_fill_node then
								fill_node = biome._subterrane_fill_node
							end					
							--ceiling
							local ai = area:index(x,y+1,z) --above index
							local bi = area:index(x,y-1,z) --below index
													
							if biome._subterrane_ceiling_decor
								and data[ai] ~= fill_node
								and data[vi] == fill_node
								and y < y_max
								then --ceiling
								biome._subterrane_ceiling_decor(area, data, ai, vi, bi, data_param2)
							end
							--ground
							if biome._subterrane_floor_decor
								and data[bi] ~= fill_node
								and data[vi] == fill_node
								and y > y_min
								then --ground
								biome._subterrane_floor_decor(area, data, ai, vi, bi, data_param2)
							end
							
						elseif (nvals_cave[index_3d] + nvals_wave[index_3d])/2 <= tcave then --if node falls outside cave threshold
							-- decorate other "native" caves and tunnels
							if biome._subterrane_cave_fill_node then
								cave_fill_node = biome._subterrane_cave_fill_node
								if data[vi] == c_air then
									data[vi] = cave_fill_node
								end
							end
	
							local ai = area:index(x,y+1,z) --above index
							local bi = area:index(x,y-1,z) --below index
													
							if biome._subterrane_cave_ceiling_decor
								and data[ai] ~= cave_fill_node
								and data[vi] == cave_fill_node
								and y < y_max
								then --ceiling
								biome._subterrane_cave_ceiling_decor(area, data, ai, vi, bi, data_param2)
							end
							if biome._subterrane_cave_floor_decor
								and data[bi] ~= cave_fill_node
								and data[vi] == cave_fill_node
								and y > y_min
								then --ground
								biome._subterrane_cave_floor_decor(area, data, ai, vi, bi, data_param2)
							end
						end	
					end
					index_3d = index_3d + 1
					index_2d = index_2d + 1
					vi = vi + 1
				end
				index_2d = index_2d - sidelen --shift the 2D index back
			end
			index_2d = index_2d + sidelen --shift the 2D index up a layer
		end
		
		--send data back to voxelmanip
		vm:set_data(data)
		vm:set_param2_data(data_param2)
		--calc lighting
		vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		--write it to world
		vm:write_to_map()
	
		local chunk_generation_time = math.ceil((os.clock() - t_start) * 1000) --grab how long it took
		print ("[subterrane] "..chunk_generation_time.." ms") --tell people how long
	end)
end


function subterrane:register_cave_decor(minimum_depth, maximum_depth)

	-- On generated function
	minetest.register_on_generated(function(minp, maxp, seed)
		--if out of range of cave definition limits, abort
		if minp.y > minimum_depth or maxp.y < maximum_depth then
			return
		end
		
		-- Create a table of biome ids for use with the biomemap.
		if not subterrane.biome_ids then
			subterrane.biome_ids = {}
			for name, desc in pairs(minetest.registered_biomes) do
				local i = minetest.get_biome_id(desc.name)
				subterrane.biome_ids[i] = desc.name
			end
		end
	
		--easy reference to commonly used values
		local t_start = os.clock()
		local x_max = maxp.x
		local y_max = maxp.y
		local z_max = maxp.z
		local x_min = minp.x
		local y_min = minp.y
		local z_min = minp.z
		
		print ("[subterrane] chunk minp ("..x_min.." "..y_min.." "..z_min..")") --tell people you are generating a chunk
		
		local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
		vm:get_data(data)
		vm:get_param2_data(data_param2)
	
		local biomemap = minetest.get_mapgen_object("biomemap")
		
		local sidelen = x_max - x_min + 1 --length of a mapblock
	
		local index_3d = 1 --3D node index
		local index_2d = 1 --2D node index
		
		for z = z_min, z_max do -- for each xy plane progressing northwards
			--decoration loop, places nodes on floor and ceiling
			for y = y_min, y_max do -- for each x row progressing upwards
				local vi = area:index(x_min, y, z)
				for x = x_min, x_max do -- for each node do
				
					local biome_name = subterrane.biome_ids[biomemap[index_2d]]
					local biome = minetest.registered_biomes[biome_name]
					local cave_fill_node = c_air
	
					if biome then
						-- decorate "native" caves and tunnels
						if biome._subterrane_cave_fill_node then
							cave_fill_node = biome._subterrane_cave_fill_node
							if data[vi] == c_air then
								data[vi] = cave_fill_node
							end
						end

						local ai = area:index(x,y+1,z) --above index
						local bi = area:index(x,y-1,z) --below index

						if biome._subterrane_cave_ceiling_decor
							and data[ai] ~= cave_fill_node
							and data[vi] == cave_fill_node
							and y < y_max
							then --ceiling
							biome._subterrane_cave_ceiling_decor(area, data, ai, vi, bi, data_param2)
						end
						--ground
						if biome._subterrane_cave_floor_decor
							and data[bi] ~= cave_fill_node
							and data[vi] == cave_fill_node
							and y > y_min
							then --ground
							biome._subterrane_cave_floor_decor(area, data, ai, vi, bi, data_param2)
						end
					end	
					index_3d = index_3d + 1
					index_2d = index_2d + 1
					vi = vi + 1
				end
				index_2d = index_2d - sidelen --shift the 2D index back
			end
			index_2d = index_2d + sidelen --shift the 2D index up a layer
		end
		
		--send data back to voxelmanip
		vm:set_data(data)
		vm:set_param2_data(data_param2)
		--calc lighting
		vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		--write it to world
		vm:write_to_map()
	
		local chunk_generation_time = math.ceil((os.clock() - t_start) * 1000) --grab how long it took
		print ("[subterrane] "..chunk_generation_time.." ms") --tell people how long
	end)
end

print("[Subterrane] loaded!")
