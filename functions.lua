--subterrane functions.lua

--FUNCTIONS--

local grid_size = mapgen_helper.block_size * 4

function subterrane:vertically_consistent_randomp(pos)
	local next_seed = math.random(1, 1000000000)
	math.randomseed(pos.x + pos.z * 2 ^ 8)
	local output = math.random()
	math.randomseed(next_seed)
	return output
end

function subterrane:vertically_consistent_random(vi, area)
	local pos = area:position(vi)
	return subterrane:vertically_consistent_randomp(pos)
end

local get_scatter_grid = function(pos_xz, gridscale, column_def)
	local grids = mapgen_helper.get_nearest_regions(pos_xz, gridscale)
	local points = {}
	for _, grid in pairs(grids) do
		--The y value of the returned point will be the radius of the column
		local minp = {x=grid.x, y = column_def.min_column_radius*100, z=grid.z}
		local maxp = {x=grid.x+gridscale-1, y=column_def.max_column_radius*100, z=grid.z+gridscale-1}
		for _, point in pairs(mapgen_helper.get_random_points(minp, maxp, column_def.minimum_count, column_def.maximum_count)) do
			point.y = point.y / 100
			table.insert(points, point)
		end
	end

	return points
end

local prune_points = function(minp, maxp, points)
	local result = {}
	for _, point in pairs(points) do
		-- point.y is the radius of the column
		if point.x > minp.x - point.y and point.x < maxp.x + point.y and point.z > minp.z - point.y and point.z < maxp.z + point.y then
			table.insert(result, point)
		end
	end
	return result
end

subterrane.get_column_points = function(minp, maxp, column_def)
	local column_points = get_scatter_grid(minp, grid_size, column_def)
	column_points = prune_points(minp, maxp, column_points)
	return column_points
end

subterrane.get_point_heat = function(pos, points)
	local heat = 0
	for _, point in pairs(points) do
		local axis_point = {x=point.x, y=pos.y, z=point.z}
		local dist = vector.distance(pos, axis_point)
		if dist < point.y then
			heat = math.max(heat, 1 - dist/point.y)
		end
	end
	return heat
end

-- Unfortunately there's no easy way to override a single biome, so do it by wiping everything and re-registering
-- Not only that, but the decorations also need to be wiped and re-registered - it appears they keep
-- track of the biome they belong to via an internal ID that gets changed when the biomes
-- are re-registered, resulting in them being left assigned to the wrong biomes.
function subterrane:override_biome(biome_def)

	--Minetest 0.5 adds this "unregister biome" method
	if minetest.unregister_biome and biome_def.name then
		minetest.unregister_biome(biome_def.name)
		minetest.register_biome(biome_def)
		return
	end	

	local registered_biomes_copy = {}
	for old_biome_key, old_biome_def in pairs(minetest.registered_biomes) do
		registered_biomes_copy[old_biome_key] = old_biome_def
	end
	local registered_decorations_copy = {}
	for old_decoration_key, old_decoration_def in pairs(minetest.registered_decorations) do
		registered_decorations_copy[old_decoration_key] = old_decoration_def
	end

	registered_biomes_copy[biome_def.name] = biome_def

	minetest.clear_registered_decorations()
	minetest.clear_registered_biomes()
	for biome_key, new_biome_def in pairs(registered_biomes_copy) do
		minetest.register_biome(new_biome_def)
	end
	for decoration_key, new_decoration_def in pairs(registered_decorations_copy) do
		minetest.register_decoration(new_decoration_def)
	end
end


