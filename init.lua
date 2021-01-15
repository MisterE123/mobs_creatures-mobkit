-- TODO: ADD GLOBAL VARIABLES FOR CONTROLLING HEIGHT SPAWNS VIA MINETEST SETTING OR MINETEST.CONF
mobs_creatures = {}
function mobs_creatures.flash_red(self)
    minetest.after(0.0, function(self)
		self.object:settexturemod("^[colorize:#FF000040")
		minetest.after(0.2, function(self)
			if mobkit.is_alive(self) then
				self.object:settexturemod("")
			end
		end,self)
	end,self)
end




function mobs_creatures.on_punch_basic(self, puncher, tool_capabilities, dir)
	local item = puncher:get_wielded_item()
    if mobkit.is_alive(self) then
        
        local apply_damage = tool_capabilities.damage_groups.fleshy or 1

		if self.immune_to then
			for i = 1, #self.immune_to do
				if item:get_name() == self.immune_to[i] then
					return
				end
			end
        end

        if self.damage_mods then
            for _,table in self.damage_mods do
                if table[1] and table[1] == item:get_name() then 
                    apply_damage = 0
                    if table[2] then
                        apply_damage = table[2]
                    end
                end
            end
        end

		if self.protected == true and puncher:get_player_name() ~= self.owner then
			return
		else
		    
			if self.isonground then
				local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
				self.object:add_velocity({x=hvel.x,y=2,z=hvel.z})
            end
            if apply_damage and apply_damage < 0 then
                local heal = -apply_damage
                mobkit.heal(self,heal)
                mob_core.make_sound(self, "random")
            end
            if apply_damage and apply_damage > 0 then
                mobs_creatures.flash_red(self)
			    mobkit.hurt(self,apply_damage)
                mob_core.make_sound(self, "hurt")
            end
		end
	end
end

-- function mobs_creatures.pick_up_drops(self,range,item)
--     local pos = mobkit.get_stand_pos(self)
--     local obj_list = minetest.get_objects_inside_radius(pos, range)
--     for _,obj in ipairs(obj_list) do
--         local ent = obj:get_luaentity()
--         if ent then
--             if ent.name and ent.name == "__builtin:item" then
--                 local itemstring = ent.itemstring
--                 if item == nil or item == 'any' or ItemStack(itemstring):get_name() == ItemStack(item):get_name() then
--                     minetest.chat_send_all('dirt should be picked up')
--                     local drop = {name = itemstring, chance = 1, min = 1, max = 1}
--                     table.insert(self.drops, drop)
--                     ent:remove()
--                 end
--             end
--         end
        
--     end

-- end





function mobs_creatures.pick_up_drops(self, radius, item)
    local pos = mobkit.get_stand_pos(self)
    local objects = minetest.get_objects_inside_radius(pos, radius)
    --minetest.chat_send_all('92')
    if #objects < 1 then return end
    for _, object in ipairs(objects) do
        local ent = object:get_luaentity()
        if ent and ent.name == "__builtin:item" then
            local itemstring = ent.itemstring
            local stack = ItemStack(itemstring)
            local count = stack:get_count()
            --minetest.chat_send_all(dump(ent))
            if item == nil or item == 'any' or ItemStack(itemstring):get_name() == ItemStack(item):get_name() then
                local stored_drops = {} --stored_drops is a table of itemstrings
                local prev_drops = mobkit.recall(self,"stored_drops")
                if prev_drops then
                    stored_drops = prev_drops
                end
                table.insert(stored_drops,itemstring)

                mobkit.remember(self, "stored_drops", stored_drops)

                object:remove()
            end
        end
    end
end




function mobs_creatures.find_item_inside_radius(self, radius, item)
    local pos = mobkit.get_stand_pos(self)
    local objects = minetest.get_objects_inside_radius(pos, radius)
    if #objects < 1 then return end
    for _, object in ipairs(objects) do
        local ent = object:get_luaentity()
        if ent and ent.name == "__builtin:item" then
            local itemstring = ent.itemstring
            if item == nil or item == 'any' or ItemStack(itemstring):get_name() == ItemStack(item):get_name() then
                return object
            end
        end
    end
end


function mobs_creatures.hq_seek_item(self, prty, itemstring)
    local init = false
    local timer = 2
    local func = function(self)
        local item = mobs_creatures.find_item_inside_radius(self, self.view_range, itemstring)
        if not item then return true end
        if not init then
            timer = timer - self.dtime
            
            if timer <= 0 or vector.distance(self.object:get_pos(), item:get_pos()) < 8 then
                init = true
                mobkit.animate(self, "run")
            end
        end
        self.status = mobkit.remember(self, "status", "seeking_item")
        if mobkit.is_queue_empty_low(self) and self.isonground then
            local pos = mobkit.get_stand_pos(self)
            local opos = item:get_pos()
            if vector.distance(pos, opos) < self.view_range * 1.1 then

                mob_core.goto_next_waypoint(self, opos)
                mobs_creatures.pick_up_drops(self,0.8,itemstring)

            else
                
                mobkit.lq_idle(self, 1, "stand")
                self.status = mobkit.remember(self, "status", "seeking_item")
                
                -- self.object:set_velocity({x = 0, y = 0, z = 0})
                
                return true
            end
        end
    end
    mobkit.queue_high(self, func, prty)
end


local path = minetest.get_modpath("mobs_creatures")

--staging area for new mobs that are incomplete
--dofile(path .. "/mobs/facehugger.lua")


--testing node for getting info about in-world items
-- minetest.register_node("mobs_creatures:block", {
--     description = "Alien Diamond",
--     tiles = {"default_dirt.png"},
--     is_ground_content = true,
-- 	groups = {cracky=3, stone=1,oddly_breakable_by_hand = 1},
-- 	on_punch = function(pos, node, player, pointed_thing)
--         local obj = minetest.add_item(pos,'default:dirt')
--         local ent = obj:get_luaentity()
--         if ent then
--             if ent.name and ent.name == "__builtin:item" then

--                 minetest.chat_send_all(dump(ent.itemstring))
--             end
--         end
-- 	end,
-- })


--Simplified Monsters
dofile(path .. "/mobs/bogeyman.lua")
dofile(path .. "/mobs/boomer.lua")
dofile(path .. "/mobs/demon_eye.lua")
dofile(path .. "/mobs/dirt_man.lua")            --CONVERTED 2 MOBKIT
dofile(path .. "/mobs/ghost.lua")
dofile(path .. "/mobs/ghost_restless.lua")
dofile(path .. "/mobs/sand_man.lua")
dofile(path .. "/mobs/snowman.lua")
dofile(path .. "/mobs/stone_man.lua")
dofile(path .. "/mobs/skeleton_archer.lua")
dofile(path .. "/mobs/skeleton_fighter.lua")
dofile(path .. "/mobs/tree_monster.lua")
--dofile(path .. "/mobs/zombie.lua")

-- Animals (surface and subterrane)
dofile(path .. "/mobs/bat.lua")                 --CONVERTED 2 MOBKIT
--dofile(path .. "/mobs/cow.lua")
--dofile(path .. "/mobs/deer.lua") -- Needs SFX.
dofile(path .. "/mobs/kangaroo.lua")
dofile(path .. "/mobs/ocelot.lua")
dofile(path .. "/mobs/mooshroom.lua")
dofile(path .. "/mobs/panda.lua") -- Needs spawn.
dofile(path .. "/mobs/parrot.lua")
dofile(path .. "/mobs/penguin.lua") -- Needs SFX, and Follow items.
dofile(path .. "/mobs/polar_bear.lua")
dofile(path .. "/mobs/rabbit.lua")
dofile(path .. "/mobs/rat.lua")
--dofile(path .. "/mobs/sheep.lua") -- Needs SFX.
dofile(path .. "/mobs/spider.lua")
--dofile(path .. "/mobs/wolf.lua")

-- Farm Animals
--dofile(path .. "/mobs/pig.lua")
--dofile(path .. "/mobs/chicken.lua")

-- Sea Animals (aquatic)
dofile(path .. "/mobs/clownfish.lua")
dofile(path .. "/mobs/cod.lua")
--dofile(path .. "/mobs/crocodile.lua")
dofile(path .. "/mobs/dolphin.lua")
dofile(path .. "/mobs/salmon.lua")
--dofile(path .. "/mobs/shark.lua")
dofile(path .. "/mobs/snapper.lua")
dofile(path .. "/mobs/turtle.lua")

-- Cave Creatures (anywhere)
dofile(path .. "/mobs/fire_imp.lua")
dofile(path .. "/mobs/ghost_murderous.lua") -- (-500)
dofile(path .. "/mobs/water_man.lua")

-- Cave Creatures (df_caverns, layer 1+2)
dofile(path .. "/mobs/cave_crocodile.lua")
dofile(path .. "/mobs/giant_bat.lua")
dofile(path .. "/mobs/giant_cave_spider.lua")

-- Cave Creatures (df_caverns, layers 2+3)
dofile(path .. "/mobs/cave_floater.lua")
dofile(path .. "/mobs/jabberer.lua")

-- Cave Creatures (df_caverns, layer 3)
dofile(path .. "/mobs/blood_man.lua")
dofile(path .. "/mobs/diamond_man.lua")
dofile(path .. "/mobs/gold_man.lua")
dofile(path .. "/mobs/iron_man.lua")
dofile(path .. "/mobs/magma_man.lua")

-- Cave Creatures (df_caverns, layer 3+4)
dofile(path .. "/mobs/fire_man.lua")

-- Moon Creatures (planet_moon)
dofile(path .. "/mobs/astronaut.lua")  -- trader npc
dofile(path .. "/mobs/flying_saucer.lua")
dofile(path .. "/mobs/grey_enlisted.lua")
dofile(path .. "/mobs/grey_civilian.lua")
dofile(path .. "/mobs/reptilian_elite.lua")
dofile(path .. "/mobs/zombie_space.lua")

-- Items (usually these are mob drops)
dofile(path .. "/items/blood.lua")
dofile(path .. "/items/bone.lua")
dofile(path .. "/items/butter.lua")
dofile(path .. "/items/cheese.lua")
dofile(path .. "/items/chicken_items.lua")
dofile(path .. "/items/clownfish_items.lua")
dofile(path .. "/items/cod_items.lua")
dofile(path .. "/items/death_items.lua")
dofile(path .. "/items/milk.lua")
dofile(path .. "/items/mutton.lua")
dofile(path .. "/items/poop.lua")
dofile(path .. "/items/pork.lua")
dofile(path .. "/items/rabbit_items.lua")
dofile(path .. "/items/rotten_flesh.lua")
dofile(path .. "/items/salmon_items.lua")
dofile(path .. "/items/spider_items.lua")
dofile(path .. "/items/snapper_items.lua")

-- DOOMed Creatures
dofile(path .. "/mobs/cacodemon.lua")
dofile(path .. "/mobs/cyberdemon.lua")
dofile(path .. "/mobs/hellbaron.lua")
dofile(path .. "/mobs/imp.lua")
dofile(path .. "/mobs/mancubus.lua")
dofile(path .. "/mobs/pinky.lua")
dofile(path .. "/mobs/skull.lua")
