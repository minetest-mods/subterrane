-- original cave code modified from paramat's subterrain
-- Modified by HeroOfTheWinds for caverealms
-- Modified by FaceDeer for subterrane
-- Depends default
-- License: code MIT

local c_stone = minetest.get_content_id("default:stone")
local c_clay = minetest.get_content_id("default:clay")
local c_desert_stone = minetest.get_content_id("default:desert_stone")
local c_sandstone = minetest.get_content_id("default:sandstone")

local c_air = minetest.get_content_id("air")
local c_water = minetest.get_content_id("default:water_source")
local c_lava = minetest.get_content_id("default:lava_source")
local c_water_flowing = minetest.get_content_id("default:water_flowing")
local c_lava_flowing = minetest.get_content_id("default:lava_flowing")
local is_open = {[c_air] = true, [c_water] = true, [c_lava] = true, [c_water_flowing] = true, [c_lava_flowing] = true}

local c_cavern_air = c_air
local c_warren_air = c_air

local subterrane_enable_singlenode_mapping_mode = minetest.setting_getbool("subterrane_enable_singlenode_mapping_mode")
if subterrane_enable_singlenode_mapping_mode then
	c_cavern_air = c_stone
	c_warren_air = c_clay
end


subterrane = {} --create a container for functions and constants

subterrane.registered_layers = {}

--grab a shorthand for the filepath of the mod
local modpath = minetest.get_modpath(minetest.get_current_modname())

--load companion lua files
dofile(modpath.."/features.lua") -- some generic cave features useful for a variety of mapgens
dofile(modpath.."/player_spawn.lua") -- Function for spawning a player in a giant cavern
dofile(modpath.."/legacy.lua") -- contains old node definitions and functions, will be removed at some point in the future.

local defaults = dofile(modpath.."/defaults.lua")

local disable_mapgen_caverns = function()
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
disable_mapgen_caverns()

local c_obsidian = minetest.get_content_id("default:obsidian")

local c_air = minetest.get_content_id("air")
local c_water = minetest.get_content_id("default:water_source")
local c_lava = minetest.get_content_id("default:lava_source")
local c_water_flowing = minetest.get_content_id("default:water_flowing")
local c_lava_flowing = minetest.get_content_id("default:lava_flowing")
local is_open = {[c_air] = true, [c_water] = true, [c_lava] = true, [c_water_flowing] = true, [c_lava_flowing] = true}

-- Column stuff
----------------------------------------------------------------------------------

local grid_size = mapgen_helper.block_size * 4

subterrane.get_column_points = function(minp, maxp, column_def)
	local grids = mapgen_helper.get_nearest_regions(minp, grid_size)
	local points = {}
	for _, grid in ipairs(grids) do
		--The y value of the returned point will be the radius of the column
		local minp = {x=grid.x, y = column_def.minimum_radius*100, z=grid.z}
		local maxp = {x=grid.x+grid_size-1, y=column_def.maximum_radius*100, z=grid.z+grid_size-1}
		for _, point in ipairs(mapgen_helper.get_random_points(minp, maxp, column_def.minimum_count, column_def.maximum_count)) do
			point.y = point.y / 100
			if point.x > minp.x - point.y
				and point.x < maxp.x + point.y
				and point.z > minp.z - point.y
				and point.z < maxp.z + point.y then
				table.insert(points, point)
			end			
		end
	end
	return points
end

subterrane.get_column_value = function(pos, points)
	local heat = 0
	for _, point in ipairs(points) do
		local axis_point = {x=point.x, y=pos.y, z=point.z}
		local radius = point.y
		if (pos.x >= axis_point.x-radius and pos.x <= axis_point.x+radius
			and pos.z >= axis_point.z-radius and pos.z <= axis_point.z+radius) then
			
			local dist = vector.distance(pos, axis_point)
			if dist < radius then
				heat = math.max(heat, 1 - dist/radius)
			end
			
		end
	end
	return heat
end


-- Decoration node lists
----------------------------------------------------------------------------------

-- States any given node can be in. Used to detect boundaries
local outside_region = 1
local inside_ground = 2
local inside_tunnel = 3
local inside_cavern = 4
local inside_warren = 5
local inside_column = 6

-- These arrays will contain the indices of various nodes relevant to decoration
local node_arrays = {}
local cavern_floor_nodes = {}
node_arrays.cavern_floor_nodes = cavern_floor_nodes
local cavern_ceiling_nodes = {}
node_arrays.cavern_ceiling_nodes = cavern_ceiling_nodes
local warren_floor_nodes = {}
node_arrays.warren_floor_nodes = warren_floor_nodes
local warren_ceiling_nodes = {}
node_arrays.warren_ceiling_nodes = warren_ceiling_nodes
local tunnel_floor_nodes = {}
node_arrays.tunnel_floor_nodes = tunnel_floor_nodes
local tunnel_ceiling_nodes = {}
node_arrays.tunnel_ceiling_nodes = tunnel_ceiling_nodes
local column_nodes = {}
node_arrays.column_nodes = column_nodes

-- clear the tables without deleting them - easer on memory management this way
local clear_node_arrays = function()
	for k, _ in pairs(cavern_ceiling_nodes) do
		cavern_ceiling_nodes[k] = nil
	end
	for k, _ in pairs(cavern_floor_nodes) do
		cavern_floor_nodes[k] = nil
	end
	for k, _ in pairs(warren_ceiling_nodes) do
		warren_ceiling_nodes[k] = nil
	end
	for k, _ in pairs(warren_floor_nodes) do
		warren_floor_nodes[k] = nil
	end
	for k, _ in pairs(tunnel_ceiling_nodes) do
		tunnel_ceiling_nodes[k] = nil
	end
	for k, _ in pairs(tunnel_floor_nodes) do
		tunnel_floor_nodes[k] = nil
	end
	for k, _ in pairs(column_nodes) do
		column_nodes[k] = nil
	end
end

-- cave_layer_def
--{
--	y_max = -- required, the highest elevation this cave layer will be generated in.
--	y_min = -- required, the lowest elevation this cave layer will be generated in.
--	cave_threshold = -- optional, Cave threshold. Defaults to 0.5. 1 = small rare caves, 0 = 1/2 ground volume
--	warren_region_threshold = -- optional, defaults to 0.25. Used to determine how much volume warrens take up around caverns. Set it to be equal to or greater than the cave threshold to disable warrens entirely.
--	warren_region_variability_threshold = -- optional, defaults to 0.25. Used to determine how much of the region contained within the warren_region_threshold actually has warrens in it.
--	warren_threshold = -- Optional, defaults to 0.25. Determines how "spongey" warrens are, lower numbers make tighter, less-connected warren passages.
--	boundary_blend_range = -- optional, range near ymin and ymax over which caves diminish to nothing. Defaults to 128.
--	perlin_cave = -- optional, a 3D perlin noise definition table to define the shape of the caves
--	perlin_wave = -- optional, a 3D perlin noise definition table that's averaged with the cave noise to add more horizontal surfaces (squash its spread on the y axis relative to perlin_cave to accomplish this)
--	perlin_warren_area = -- optional, a 3D perlin noise definition table for defining what places warrens form in
--	perlin_warrens = -- optional, a 3D perlin noise definition table for defining the warrens
--	solidify_lava = -- when set to true, lava near the edges of caverns is converted into obsidian to prevent it from spilling in.
--	columns = -- optional, a column_def table for producing truly enormous dripstone formations. See below for definition. Set to nil to disable columns.
--	double_frequency = -- when set to true, uses the absolute value of the cavern field to determine where to place caverns instead. This effectively doubles the number of large non-connected caverns.
--	decorate = -- optional, a function that is given a table of indices and a variety of other mapgen information so that it can place custom decorations on floors and ceilings.
--}

-- column_def
--{
--	maximum_radius = -- Maximum radius for individual columns, defaults to 10
--	minimum_radius = -- Minimum radius for individual columns, defaults to 4 (going lower that this can increase the likelihood of "intermittent" columns with floating sections)
--	node = -- node name to build columns out of. Defaults to default:stone
--	weight = -- a floating point value (usually in the range of 0.5-1) to modify how strongly the column is affected by the surrounding cave. Lower values create a more variable, tapered stalactite/stalagmite combination whereas a value of 1 produces a roughly cylindrical column. Defaults to 0.25
--	maximum_count = -- The maximum number of columns placed in any given column region (each region being a square 4 times the length and width of a map chunk). Defaults to 50
--	minimum_count = -- The minimum number of columns placed in a column region. The actual number placed will be randomly selected between this range. Defaults to 0.
--}

subterrane.register_layer = function(cave_layer_def)
	table.insert(subterrane.registered_layers, cave_layer_def)

	local YMIN = cave_layer_def.y_min
	local YMAX = cave_layer_def.y_max
	local BLEND = math.min(cave_layer_def.boundary_blend_range or 128, (YMAX-YMIN)/2)

	local TCAVE = cave_layer_def.cave_threshold or 0.5
	local warren_area_threshold = cave_layer_def.warren_region_threshold or 0.25 -- determines how much volume warrens are found in around caverns
	local warren_area_variability_threshold = cave_layer_def.warren_region_variability_threshold or 0.25 -- determines how much of the warren_area_threshold volume actually has warrens in it
	local warren_threshold = cave_layer_def.warren_threshold or 0.25 -- determines narrowness of warrens themselves

	local solidify_lava = cave_layer_def.solidify_lava
	
	local np_cave = cave_layer_def.perlin_cave or defaults.perlin_cave
	local np_wave = cave_layer_def.perlin_wave or defaults.perlin_wave
	local np_warren_area = cave_layer_def.perlin_warren_area or defaults.perlin_warren_area
	local np_warrens = cave_layer_def.perlin_warrens or defaults.perlin_warrens 
	
	local y_blend_min = YMIN + BLEND * 1.5
	local y_blend_max = YMAX - BLEND * 1.5	
	
	local column_def = cave_layer_def.columns
	local c_column

	if column_def then
		column_def.maximum_radius = column_def.maximum_radius or defaults.column_def.maximum_radius
		column_def.minimum_radius = column_def.minimum_radius or defaults.column_def.minimum_radius
		c_column = column_def.node or defaults.column_def.node
		column_def.weight = column_def.weight or defaults.column_def.weight
		column_def.maximum_count = column_def.maximum_count or defaults.column_def.maximum_count
		column_def.minimum_count = column_def.minimum_count or defaults.column_def.minimum_count
	end

	local double_frequency = cave_layer_def.double_frequency
		
	local decorate = cave_layer_def.decorate

	if minetest.setting_getbool("subterrane_enable_singlenode_mapping_mode") then
		decorate = nil
		c_column = c_air
	end
	
-- On generated
----------------------------------------------------------------------------------

minetest.register_on_generated(function(minp, maxp, seed)

	--if out of range of cave definition limits, abort
	if minp.y > YMAX or maxp.y < YMIN then
		return
	end
	local t_start = os.clock()

	local vm, data, data_param2, area = mapgen_helper.mapgen_vm_data_param2()
	local nvals_cave, cave_area = mapgen_helper.perlin3d("subterrane:cave", minp, maxp, np_cave) --cave noise for structure
	local nvals_wave = mapgen_helper.perlin3d("subterrane:wave", minp, maxp, np_wave) --wavy structure of cavern ceilings and floors

	local warren_area_uninitialized = true
	local nvals_warren_area
	local warrens_uninitialized = true
	local nvals_warrens

	-- The interp_yxz iterator iterates upwards in columns along the y axis.
	-- starts at miny, goes to maxy, then switches to a new x,z and repeats.
	local cave_iterator = cave_area:iterp_yxz(minp, maxp)
	
	local previous_y = minp.y
	local previous_node_state = outside_region
	
	local column_points = nil
	local column_weight = nil
	
	-- This information might be of use to the decorate function, but an entire node list
	-- is less likely to be of use so just store a bool to save on memory.
	node_arrays.contains_cavern = false
	node_arrays.contains_warren = false
	node_arrays.contains_negative_zone = 0
	
	for vi, x, y, z in area:iterp_yxz(minp, maxp) do
		local vi3d = cave_iterator() -- for use with noise data
		
		if y < previous_y then
			-- we've switched to a new column
			previous_node_state = outside_region
		end
		previous_y = y
	
		local cave_local_threshold
		if y < y_blend_min then
			cave_local_threshold = TCAVE + ((y_blend_min - y) / BLEND) ^ 2
		elseif y > y_blend_max then
			cave_local_threshold = TCAVE + ((y - y_blend_max) / BLEND) ^ 2
		else
			cave_local_threshold = TCAVE
		end

		local cave_value = (nvals_cave[vi3d] + nvals_wave[vi3d])/2
		
		if double_frequency then
			if cave_value < 0 then
				cave_value = -cave_value
				-- May be useful to the decorate function if it wants to place two
				-- completely distinct types of cavern decor in alternating caverns
				-- in theory this could give inconsistent results if the positive and
				-- negative caverns are close enough to touch the same map chunk,
				-- hopefully this will not come up often
				node_arrays.contains_negative_zone = node_arrays.contains_negative_zone + 1
				if subterrane_enable_singlenode_mapping_mode then
						c_cavern_air = c_desert_stone
						c_warren_air = c_sandstone
				end
			else
				node_arrays.contains_negative_zone = node_arrays.contains_negative_zone - 1
				if subterrane_enable_singlenode_mapping_mode then
						c_cavern_air = c_stone
						c_warren_air = c_clay
				end

			end			
		end
		
		-- inside a giant cavern
		if cave_value > cave_local_threshold then

			local column_value = 0
			if column_def then
				if column_points == nil then
					column_points = subterrane.get_column_points(minp, maxp, column_def)
					column_weight = column_def.weight
				end
				column_value = subterrane.get_column_value({x=x, y=y, z=z}, column_points)
			end
			
			if column_value > 0 and cave_value - column_value * column_weight < cave_local_threshold then
				data[vi] = c_column -- add a column node
				previous_node_state = inside_column
			else
				data[vi] = c_cavern_air --hollow it out to make the cave
				node_arrays.contains_cavern = true
				if previous_node_state == inside_ground then
					-- we just entered the cavern from below
					table.insert(cavern_floor_nodes, vi - area.ystride)
				end
				previous_node_state = inside_cavern
			end
		end
		
		-- If there's lava near the edges of the cavern, solidify it.
		if solidify_lava and cave_value > cave_local_threshold - 0.05 and data[vi] == c_lava then
			data[vi] = c_obsidian
		end
			
		--borderlands of a giant cavern, possible warren area
		if cave_value <= cave_local_threshold and cave_value > warren_area_threshold then
		
			if warren_area_uninitialized then
				nvals_warren_area = mapgen_helper.perlin3d("subterrane:warren_area", minp, maxp, np_warren_area) -- determine which areas are spongey with warrens
				warren_area_uninitialized = false
			end
			
			local warren_area_value = nvals_warren_area[vi3d]
			if warren_area_value > warren_area_variability_threshold then
				-- we're in a warren-containing area
				
				if solidify_lava and data[vi] == c_lava then
					data[vi] = c_obsidian					
				end
				
				if warrens_uninitialized then
					nvals_warrens = mapgen_helper.perlin3d("subterrane:warrens", minp, maxp, np_warrens) --spongey warrens
					warrens_uninitialized = false
				end
				
				-- we don't want warrens "cutting off" abruptly at the large-scale boundary noise thresholds, so turn these into gradients
				-- that can be applied to choke off the warren gradually.
				local cave_value_edge = math.min(1, (cave_value - warren_area_threshold) * 20) -- make 0.3 = 0 and 0.25 = 1 to produce a border gradient
				local warren_area_value_edge = math.min(1, warren_area_value * 50) -- make 0 = 0 and 0.02 = 1 to produce a border gradient
				
				local warren_value = nvals_warrens[vi3d]
				local warren_local_threshold = warren_threshold + (2 - warren_area_value_edge - cave_value_edge)
				if warren_value > warren_local_threshold then

					local column_value = 0
					if column_def then
						if column_points == nil then
							column_points = subterrane.get_column_points(minp, maxp, column_def)
							column_weight = column_def.weight
						end
						column_value = subterrane.get_column_value({x=x, y=y, z=z}, column_points)
					end

					if column_value > 0 and column_value + (warren_local_threshold - warren_value) * column_weight > 0 then
						data[vi] = c_column -- add a column node
						previous_node_state = inside_column
					else
						data[vi] = c_warren_air --hollow it out to make the cave
						node_arrays.contains_warren = true
						if previous_node_state == inside_ground then
							-- we just entered the warren from below
							table.insert(warren_floor_nodes, vi - area.ystride)
						end
						previous_node_state = inside_warren
					end
				end
			end
		end
		
		-- If decorate is defined, we want to track all this stuff
		if decorate ~= nil then
			local c_current_node = data[vi]
			local current_node_is_open = is_open[c_current_node]
		
			if previous_node_state == inside_column then 
				-- in this case previous node state is actually current node state,
				-- we placed a column node during this loop
				table.insert(column_nodes, vi)
			elseif previous_node_state == inside_ground and current_node_is_open then
				-- we just entered a tunnel from below
				table.insert(tunnel_floor_nodes, vi-area.ystride)
				previous_node_state = inside_tunnel
			elseif previous_node_state ~= inside_ground and not current_node_is_open then
				if previous_node_state == inside_cavern then
					--we just left the cavern from below
					table.insert(cavern_ceiling_nodes, vi)
				elseif previous_node_state == inside_warren then
					--we just left the cavern from below
					table.insert(warren_ceiling_nodes, vi)
				elseif previous_node_state == inside_tunnel then
					-- we just left a tunnel from below
					table.insert(tunnel_ceiling_nodes, vi)
				end
				
				-- if we laid down a column node we don't want to switch to "inside ground",
				-- if we hit air next node then it'll get flagged as a floor node and we don't want that for columns
				if previous_node_state ~= inside_column then
					previous_node_state = inside_ground
				end
			end
		else
			-- This will prevent any values from being inserted into the node lists, saving
			-- a bunch of memory and processor time
			previous_node_state = outside_region
		end
	end
	
	if decorate then
		node_arrays.contains_negative_zone = node_arrays.contains_negative_zone > 0
		decorate(minp, maxp, seed, vm, node_arrays, area, data)
		clear_node_arrays() -- if decorate is not defined these arrays will never have anything added to them
	end
	
	--send data back to voxelmanip
	vm:set_data(data)
	--calc lighting
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:update_liquids()
	--write it to world
	vm:write_to_map()
	
	local chunk_generation_time = math.ceil((os.clock() - t_start) * 1000) --grab how long it took
	if chunk_generation_time < 1000 then
		minetest.log("info", "[subterrane] "..chunk_generation_time.." ms") --tell people how long
	else
		minetest.log("warning", "[subterrane] took "..chunk_generation_time.." ms to generate map block "
			.. minetest.pos_to_string(minp) .. minetest.pos_to_string(maxp))
	end
end)

end

minetest.log("info", "[Subterrane] loaded!")
