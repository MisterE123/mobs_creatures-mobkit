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





-- register arrow for shoot attack
function mobs_creatures.register_arrow(name, def)

	if not name or not def then return end -- errorcheck

	minetest.register_entity(name, {

		physical = false,
		visual = def.visual,
		visual_size = def.visual_size,
		textures = def.textures,
		velocity = def.velocity,
		hit_player = def.hit_player,
		hit_node = def.hit_node,
		hit_mob = def.hit_mob,
		hit_object = def.hit_object,
		drop = def.drop or false, -- drops arrow as registered item when true
		collisionbox = def.collisionbox or {-.1, -.1, -.1, .1, .1, .1},
		timer = 0,
		lifetime = def.lifetime or 4.5,
		switch = 0,
		owner_id = def.owner_id,
		rotate = def.rotate,
		automatic_face_movement_dir = def.rotate
			and (def.rotate - (pi / 180)) or false,

		on_activate = def.on_activate,

		on_punch = def.on_punch or function(
				self, hitter, tflp, tool_capabilities, dir)
		end,

		on_step = def.on_step or function(self, dtime)

			self.timer = self.timer + dtime

			local pos = self.object:get_pos()

			if self.switch == 0 or self.timer > self.lifetime then

				self.object:remove() ; -- print("removed arrow")

				return
			end

			-- does arrow have a tail (fireball)
			if def.tail and def.tail == 1 and def.tail_texture then

				minetest.add_particle({
					pos = pos,
					velocity = {x = 0, y = 0, z = 0},
					acceleration = {x = 0, y = 0, z = 0},
					expirationtime = def.expire or 0.25,
					collisiondetection = false,
					texture = def.tail_texture,
					size = def.tail_size or 5,
					glow = def.glow or 0
				})
			end

            if self.hit_node then
                

                local node = minetest.get_node(pos) or minetest.registered_nodes['default_dirt']
                node = node.name

				if minetest.registered_nodes[node].walkable then

					self:hit_node(pos, node)

					if self.drop == true then

						pos.y = pos.y + 1

						self.lastpos = (self.lastpos or pos)

						minetest.add_item(self.lastpos,
								self.object:get_luaentity().name)
					end

					self.object:remove() ; -- print("hit node")

					return
				end
			end

			if self.hit_player or self.hit_mob or self.hit_object then

				for _,player in pairs(
						minetest.get_objects_inside_radius(pos, 1.0)) do

					if self.hit_player and player:is_player() then

						self:hit_player(player)

						self.object:remove() ; -- print("hit player")

						return
					end

					local entity = player:get_luaentity()

					if entity
					and self.hit_mob
					and entity._cmi_is_mob == true
					and tostring(player) ~= self.owner_id
					and entity.name ~= self.object:get_luaentity().name then

						self:hit_mob(player)

                        self.object:remove() 
                        minetest.chat_send_all("hit mob")

						return
					end

					if entity
					and self.hit_object
					and (not entity._cmi_is_mob)
					and tostring(player) ~= self.owner_id
					and entity.name ~= self.object:get_luaentity().name then

						self:hit_object(player)

                        self.object:remove()
                        minetest.chat_send_all("hit object")

						return
					end
				end
			end

			self.lastpos = pos
		end
	})
end





function mobs_creatures.lq_dumb_shoot(self, t_pos)
    local func = function(self)
        minetest.chat_send_all('shooting')
        local vel = self.object:get_velocity()
        --self.object:set_velocity({x = 0, y = vel.y, z = 0})
        local pos = self.object:get_pos()
        local yaw = self.object:get_yaw()
        
        local tyaw = minetest.dir_to_yaw(vector.direction(pos, t_pos))
        if math.abs(tyaw - yaw) > 0.1 then mobkit.turn2yaw(self, tyaw, 4) end
        local dist = vector.distance(t_pos,pos)
        
        local p = self.object:get_pos() -- p is for the shooting height position
        p.y = p.y + (self.collisionbox[2] + self.collisionbox[5]) / 2 --here we edit p for the shooting height

        ---------Calculate shoot vector --------
        local s = pos
        s.y = s.y + .5
        t_pos.y = t_pos.y - .5

        local vec = {x = t_pos.x - s.x, y = t_pos.y - s.y, z = t_pos.z - s.z}
        ----------------------------------------
        
        if dist > self.view_range then --if target is out of range, then forget it (later, we can add walk to last known target pos)
            mobkit.animate(self, "stand")  
            return true 
        end
            
        local obj = minetest.add_entity(p, self.arrow)
        local ent = obj:get_luaentity()
        local amount = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
        local v = ent.velocity or 1 -- or set to default

        ent.switch = 1
        ent.owner_id = tostring(self.object) -- add unique owner id to arrow

        -- offset makes shoot aim accurate
        vec.y = vec.y + self.shoot_offset
        vec.x = vec.x * (v / amount)
        vec.y = vec.y * (v / amount)
        vec.z = vec.z * (v / amount)

        obj:set_velocity(vec)
        
        return true
    end
    mobkit.queue_low(self, func)
end




--reqd props: arrow, shoot_offset, run_dist, meele_dist
function mobs_creatures.hq_shoot_arrow(self,prty,target)

    if not self.arrow then return end
    if not (target) then return end --nil checks
    if not minetest.registered_entities[self.arrow] then return end


    local func = function(self)
  
        
        local shoot_pos = self.object:get_pos()
        shoot_pos.y = shoot_pos.y + (self.collisionbox[2] + self.collisionbox[5]) / 2
        local t_pos = target:get_pos()
       
        local dist = vector.distance(t_pos,shoot_pos)
        local scan_pos = t_pos
        scan_pos.y = scan_pos.y + 1
        local line_of_sight = minetest.line_of_sight(shoot_pos, scan_pos, .9)
        if line_of_sight and line_of_sight == true then

            mobs_creatures.lq_dumb_shoot(self, t_pos)
        else

            return true
        end


    end
    mobkit.queue_high(self, func, prty)

end






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

