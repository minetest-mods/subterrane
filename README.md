# subterrane

This mod was based off of Caverealms by HeroOfTheWinds, which was in turn based off of Subterrain by Paramat.

It is intended as a utility mod for other mods to use when creating a more interesting underground experience in Minetest, primarily through the creation of enormous underground "natural" caverns with biome-based features. Installing this mod by itself will not do anything.

The API has the following methods:

# Cavern registration 

## subterrane:register_cave_layer(cave_layer_def)

cave_layer_def is a table of the form:

```
{
	minimum_depth = -- required, the highest elevation this cave layer will be generated in.
	maximum_depth = -- required, the lowest elevation this cave layer will be generated in.
	cave_threshold = -- optional, Cave threshold. Defaults to 0.5. 1 = small rare caves, 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume
	boundary_blend_range = -- optional, range near ymin and ymax over which caves diminish to nothing. Defaults to 128.
	perlin_cave = -- optional, a 3D perlin noise definition table to define the shape of the caves
	perlin_wave = -- optional, a 3D perlin noise definition table that's averaged with the cave noise to add floor strata (squash its spread on the y axis relative to perlin_cave to accomplish this)
}
```

This causes large caverns to be hollowed out during map generation. By default these caverns are just featureless cavities, but you can add extra subterrane-specific properties to biomes and the mapgen code will use them to add features of your choice. Subterrane's biome properties are:

- biome._subterrane_mitigate_lava  -- If this is set to a non-false value, subterrane will try to turn all lava within about 10-20 nodes of the cavern into obsidian. This attempts to prevent lava from spilling into the cavern when the player visits, though it is by no means a perfect solution.
- biome._subterrane_fill_node -- The nodeid that subterrane will fill the excavated cavern with. You could use this to create enormous underground oceans or lava pockets. If not provided, will default to "air"
- biome._subterrane_cave_fill_node -- If this is set to a nodeid, subterrane will use that to replace the air in existing default caves.
- biome._subterrane_ceiling_decor = function (area, data, ai, vi, bi, data_param2)
- biome._subterrane_floor_decor = function (area, data, ai, vi, bi, data_param2)

If defined, these functions will be executed once for each floor or ceiling node in the excavated cavern. "area" is the mapgen voxelarea, data and data_param2 are the voxelmanip's data arrays, "ai" is the index of the node "above" the current node, "vi" is the index of the current node, and "bi" is the index of the node "below" the current node.

The node pointed to by index vi will always start out filled with the cavern's fill node (air by default).

- biome._subterrane_cave_ceiling_decor = function(area, data, ai, vi, bi, data_param2)
- biome._subterrane_cave_floor_decor = function(area, data, ai, vi, bi, data_param2)

These are basically the same as the previous two methods, but these get executed for pre-existing tunnels instead of the caverns excavated by subterrane.

## subterrane:register_cave_decor(minimum_depth, maximum_depth) 

Use this method when you want the following biome methods to be applied to pre-existing caves within a range of y values but don't want to excavate giant caverns there:

- biome._subterrane_cave_fill_node -- If this is set to a nodeid, subterrane will use that to replace the air in existing default caves.
- biome._subterrane_cave_ceiling_decor = function(area, data, ai, vi, bi, data_param2)
- biome._subterrane_cave_floor_decor = function(area, data, ai, vi, bi, data_param2)

It's essentially a trimmed-down version of register_cave_layer.

# Utilities

## subterrane:vertically_consistent_random(vi, area)

Takes a voxelmanip index and the corresponding area object, and returns a pseudorandom float from 0-1 based on the x and z coordinates of the index's location.

This is mainly intended for use when placing stalactites and stalagmites, since in a natural cavern these two features are almost always paired with each other spatially. If you use the following test in both the floor and ceiling decoration methods:

```
if subterrane:vertically_consistent_random(vi, area) > 0.05 then
	--stuff
end
```

then you'll get a random distribution that's identical on the floor and ceiling.

## subterrane:override_biome(biome_def)

Unfortunately there's no easy way to override a single biome, so this method does it by clearing and re-registering all existing biomes.
Not only that, but the decorations also need to be wiped and re-registered - it appears they keep track of the biome they belong to via an internal ID that gets changed when the biomes are re-registered, resulting in them being left assigned to the wrong biomes.

This method is provided in subterrane because the default mod includes and "underground" biome that covers everything below -113 and would be annoying to work around. Any mod using subterrane in conjunction with the default mod should probably override the "underground" biome.

# Common cavern features

## subterrane:stalagmite(vi, area, data, param2_data, param2, height, is_wet)

Subterrane comes with a set of simple stalactite and stalagmite nodes. This method can be used to create a small stalactite or stalagmite, generally no more than 5 nodes tall. Use a negative height to generate a stalactite.

## subterrane:giant_stalagmite(vi, area, data, min_height, max_height, base_material, root_material, shaft_material)

Generates a very large multi-node stalagmite three nodes in diameter (with a five-node-diameter "root").

## subterrane:giant_stalactite(vi, area, data, min_height, max_height, base_material, root_material, shaft_material)

Similar to above, but generates a stalactite instead.

## subterrane:giant_shroom(vi, area, data, stem_material, cap_material, gill_material, stem_height, cap_radius)

Generates an enormous mushroom. Cap radius works well in the range of around 2-6, larger or smaller than that may look odd.

# Player spawn

## subterrane:register_cave_spawn(cave_layer_def, start_depth)

When the player spawns (or respawns due to death), this method will tell Minetest to attempt to locate a subterrane-generated cavern to place the player in. cave_layer_def is the same format as the cave definition above. Start_depth is the depth at which the game will start searching for a location to place the player. If the game doesn't find a location immediately it may wind up restarting the search for a spawn location at the top of the cave definition, so start_depth is not a guarantee that the player will start at least that deep; he could spawn anywhere within the cave layer's depth range.