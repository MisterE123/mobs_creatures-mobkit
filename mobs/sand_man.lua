



local sand_man_brain = function(self)

        
	local pos = mobkit.get_stand_pos(self)
	local prty = mobkit.get_queue_priority(self)
	local player = mobkit.get_nearby_player(self)

	mob_core.random_sound(self, 16/self.dtime)
	--death handling
	if self.hp <= 0 then    
			local stored_drops = mobkit.recall(self,"stored_drops")
			if stored_drops then
					for _,item in pairs(stored_drops) do
							if item then
									minetest.add_item(pos,item)
							end
					end
			end
			mob_core.on_die(self)
			minetest.add_particlespawner({
					amount = 100,
					time = 2,
					minpos = {x=pos.x-1, y=pos.y-1, z=pos.z-1},
					maxpos = {x=pos.x+1, y=pos.y+1, z=pos.z+1},
					minvel = {x=-0, y=-0, z=-0},
					maxvel = {x=1, y=1, z=1},
					minacc = {x=-0.5,y=5,z=-0.5},
					maxacc = {x=0.5,y=5,z=0.5},
					minexptime = 0.1,
					maxexptime = 1,
					minsize = 1,
					maxsize = 3,
					collisiondetection = false,
					texture="default_desert_sand.png"
			})
			return
	end
	--light and water damages
	if mobkit.timer(self,2) then
			
			-- extra water damage, sand disintigrates in water
			if self.isinliquid then
					mobs_creatures.flash_red(self)
					mobkit.hurt(self,3)
					if math.random(1,3) == 1 then
							mob_core.make_sound(self, "hurt")
					end
					minetest.add_particlespawner({
							amount = 10,
							time = .1,
							minpos = {x=pos.x-1, y=pos.y-1, z=pos.z-1},
							maxpos = {x=pos.x+1, y=pos.y+1, z=pos.z+1},
							minvel = {x=-0, y=-0, z=-0},
							maxvel = {x=1, y=1, z=1},
							minacc = {x=-0.5,y=5,z=-0.5},
							maxacc = {x=0.5,y=5,z=0.5},
							minexptime = 0.1,
							maxexptime = 1,
							minsize = 1,
							maxsize = 3,
							collisiondetection = false,
							texture="default_desert_sand.png"
					})
			end
	end

	--decision_making, every second
	if mobkit.timer(self,1) then

			mob_core.vitals(self)
			mob_core.growth(self)

			item = mobs_creatures.find_item_inside_radius(self, self.view_range, 'default:desert_sand')
			status = self.status
			if not status then
					mobkit.remember(self, "status", "")
					status = ''
			end

			if status == 'seeking_item' then
					if prty < 40 and player then
							if self.isinliquid then
									mob_core.hq_aqua_attack(self, math.random(41,69) , puncher, 3)
							else
									mob_core.hq_hunt(self, math.random(41,69) , player)
							end
					end
					if prty < 50 and self.isinliquid then
							mobkit.hq_liquid_recovery(self, prty + 1)
					end


			elseif status == 'hunting' then

					if prty < 60 and item then
							mobs_creatures.hq_seek_item(self, prty + 1, 'default:desert_sand')
							
					end
					if prty < 50 and self.isinliquid then
							mobkit.hq_liquid_recovery(self, prty+1)
					end


			else --status == ''

					if prty < 50 and item then
							mobs_creatures.hq_seek_item(self, math.random(1,49), 'default:desert_sand')
					end
					if prty < 70 and player then
							if self.isinliquid then
									mob_core.hq_aqua_attack(self, math.random(41,69) , puncher, 3)
							else
									mob_core.hq_hunt(self, math.random(41,69) , player)
							end
					end
					if prty < 40 and self.isinliquid then
							mobkit.hq_liquid_recovery(self,math.random(41,55))
					end
					


			end

			if mobkit.is_queue_empty_high(self) then
					mob_core.hq_roam(self, 0, 1)
					self.status = mobkit.remember(self,'status','')
			end        
	
			-- if prty < math.random(0,50) and not mobkit.recall(self, 'status') == "seeking_item" and item then 
			--         mobs_creatures.hq_seek_item(self, 20, 'default:sand')
			-- end


			-- if prty < 20 and player and not(player:get_player_name() == self.owner) then
			--         if self.isinliquid then
			--                 mob_core.hq_aqua_attack(self, 20, puncher, 3)
			--         else
			--                 mob_core.hq_hunt(self, 20, player)
			--         end
			-- end



			-- if self.isinliquid and prty < 20 then
			--         mobkit.hq_liquid_recovery(self,20)
			-- end

			-- if mobkit.is_queue_empty_high(self) then
			--         mob_core.hq_roam(self, 0, 1)
			-- end
	end
end



minetest.register_entity("mobs_creatures:sand_man",{
	max_hp = 45,
	view_range = 10,
	reach = 2,
	armor = 100,
	damage = 4,
	passive = false,
	armor_groups = {fleshy=75},
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.35,-1.0,-0.35, 0.35,0.8,0.35},
	visual_size = {x=1,y=1},
	scale_stage1 = 0.5,
	scale_stage2 = 0.65,
	scale_stage3 = 0.80,
	visual = "mesh",

	mesh = "mobs_character.b3d",
	textures = {"mobs_creatures_sand_man.png"},
	animation = {
			stand = {range={x=0,y=79},speed=30,loop=true},
			walk={range={x=168,y=187},speed=30,loop=true},		-- single
			run={range={x=168,y=187},speed=40,loop=true},		-- single
			attack={range={x=200,y=219},speed=30,loop=true},		-- single
	},
	obstacle_avoidance_range = 5,
	surface_avoidance_range = 0,
	floor_avoidance_range = 1,
	sounds = {
			random = "mobs_creatures_sand_man_random",
			hurt = "mobs_creatures_sand_man_random",
			attack = "default_sand_footstep",
			jump = "default_sand_footstep",
			death = "default_item_smoke",
	},
	max_speed = 4,					-- m/s
	stepheight = 1.1,				
	jump_height = 1.1,
	buoyancy = .7,
	lung_capacity = 10, 		-- seconds
	ignore_liquidflag = false,			
	timeout = 500,	
	semiaquatic = false,
	core_growth = false,	
	push_on_collide = true,
	catch_with_net = false,
	follow = {},                
	drops = {{name = "default:desert_sand", chance = 1, min = 3, max = 5},},
	on_step = better_fauna.on_step,
	on_activate = better_fauna.on_activate,		
	get_staticdata = mobkit.statfunc,
	logic = sand_man_brain,		        
	attack={range=2,damage_groups={fleshy=4}},	
	damage_groups={{fleshy=4}},
	knockback = .05,
	defend_owner = true,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
			if time_from_last_punch < .5 then return end --dont hurt more than every .5 sec, cant make this tooo easy


			mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
			local prty = mobkit.get_queue_priority(self)
			if prty < 60 then
					mobkit.clear_queue_high(self)
			end
			local new_prty = prty + 5
			if self.status ~= 'hunting' then
					new_prty = math.random(60,100)
			end
			if new_prty > 95 then
					new_prty = 100
			end
			if self.hp > 5 then
					if mobkit.is_alive(self) then
							local pos = self.object:get_pos()
							if not(self.isinliquid) then
									mob_core.hq_hunt(self, new_prty, puncher)
							else
									mob_core.hq_aqua_attack(self, new_prty, puncher, 1) 
							end
					end
			else
					if mobkit.is_alive(self) then
							local pos = self.object:get_pos()
							if not(self.isinliquid) then
									mobkit.hq_runfrom(self, new_prty, puncher)
							else
									mob_core.hq_swimfrom(self, new_prty, puncher, 1)
							end
					end 
			end
			
			
			
	end,
})



mob_core.register_spawn({
name = 'mobs_creatures:sand_man',
nodes = {"default:sand", "default:desert_sand"},
min_light = 0,
max_light = 7,
min_height = -500,
max_height = 100,
group = 3,
optional = {
			reliability = 3
}
}, 10, 60)


mob_core.register_spawn_egg("mobs_creatures:sand_man", "f5cc5b" ,"b57b24")
-- mob_core.register_set("mobs_walrus:walrus", "mobs_walrus_walrus1.png", true)