local sidelen = mapgen_helper.block_size

local snap_to_minp = function(ydepth)
	return ydepth - (ydepth+32) % sidelen -- put ydepth at the minp.y of mapblocks
end

function subterrane:register_cave_spawn(cave_layer_def, start_depth)
	minetest.register_on_newplayer(function(player)
		local ydepth = snap_to_minp(start_depth or cave_layer_def.minimum_depth)
		local spawned = false
		while spawned ~= true do
			spawned = spawnplayer(cave_layer_def, player, ydepth)
			ydepth = ydepth - sidelen
			if ydepth < cave_layer_def.maximum_depth then
				ydepth = snap_to_minp(cave_layer_def.minimum_depth)
			end
		end
	end)

	minetest.register_on_respawnplayer(function(player)
		local ydepth = snap_to_minp(start_depth or cave_layer_def.minimum_depth)
		local spawned = false
		while spawned ~= true do
			spawned = spawnplayer(cave_layer_def, player, ydepth)
			ydepth = ydepth - sidelen
			if ydepth < cave_layer_def.maximum_depth then
				ydepth = snap_to_minp(cave_layer_def.minimum_depth)
			end
		end
		return true
	end)
end

-- Spawn player underground
function spawnplayer(cave_layer_def, player, ydepth)

	local YMIN = cave_layer_def.maximum_depth
	local YMAX = cave_layer_def.minimum_depth
	local BLEND = math.min(cave_layer_def.boundary_blend_range or 128, (YMAX-YMIN)/2)
	local TCAVE = cave_layer_def.cave_threshold or 0.5

	local np_cave = cave_layer_def.perlin_cave or subterrane.default_perlin_cave
	local np_wave = cave_layer_def.perlin_wave or subterrane.default_perlin_wave
	
	local yblmin = YMIN + BLEND * 1.5
	local yblmax = YMAX - BLEND * 1.5	
	
	local layer_range_name = tostring(YMIN).." to "..tostring(YMAX)

	local options = {}
	
	for chunk = 1, 64 do
		minetest.log("info", "[subterrane] searching for spawn "..chunk)
				
		local minp = {x = sidelen * math.random(-32, 32) - 32, z = sidelen * math.random(-32, 32) - 32, y = ydepth}
		local maxp = {x = minp.x + sidelen - 1, z = minp.z + sidelen - 1, y = ydepth + sidelen - 1}
		
		local nvals_cave, cave_area = mapgen_helper.perlin3d("cave "..layer_range_name, minp, maxp, np_cave) --cave noise for structure
		local nvals_wave = mapgen_helper.perlin3d("wave "..layer_range_name, minp, maxp, np_wave) --wavy structure of cavern ceilings and floors
		
		for vi, x, y, z in cave_area:iterp_xyz({x=minp.x, y=minp.y+1, z=minp.z}, {x=maxp.x, y=maxp.y-1, z=maxp.z}) do
		
			local ai = vi + cave_area.ystride
			local bi = vi - cave_area.ystride

			local tcave
			if y < yblmin then
				tcave = TCAVE + ((yblmin - y) / BLEND) ^ 2
			elseif y > yblmax then
				tcave = TCAVE + ((y - yblmax) / BLEND) ^ 2
			else
				tcave = TCAVE
			end
				
			local cave_value_above = (nvals_cave[ai] + nvals_wave[ai])/2
			local cave_value = (nvals_cave[vi] + nvals_wave[vi])/2
			local cave_value_below = (nvals_cave[bi] + nvals_wave[bi])/2
			if cave_value > tcave and cave_value_above > tcave and cave_value_below < tcave-0.01 then -- Try to ensure there's ground underneath the player
				table.insert(options, {x=x, y=y+1, z=z})
			end
		end

		if table.getn(options) > 0 then
			local choice = math.random( table.getn(options) )
			local spawnpoint = options[ choice ]
			minetest.log("action", "[subterrane] spawning player " .. minetest.pos_to_string(spawnpoint))
			player:setpos(spawnpoint)
			return true
		end
	end	
	
	return false
end
