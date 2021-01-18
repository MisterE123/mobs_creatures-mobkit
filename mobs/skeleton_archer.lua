



local skeleton_archer_brain = function(self)

        
	local pos = mobkit.get_stand_pos(self)
	local prty = mobkit.get_queue_priority(self)
	
	mob_core.random_sound(self, 16/self.dtime)
	--death handling
	if self.hp <= 0 then    
			mob_core.on_die(self)
			return
	end
	--light and water damages
	if mobkit.timer(self,2) then
        if minetest.get_node_light(pos) > 10 then
            mobs_creatures.flash_red(self)
            mobkit.hurt(self,4)
            if math.random(1,3) == 1 then
                    mob_core.make_sound(self, "hurt")
            end

        end
        -- extra water damage, dirt disintigrates in water
        if self.isinliquid then
            mobs_creatures.flash_red(self)
            mobkit.hurt(self,1)
            if math.random(1,3) == 1 then
                    mob_core.make_sound(self, "hurt")
            end      
        end
    end

	--decision_making, every second
    if mobkit.timer(self,1) then
        
			local player = mobkit.get_nearby_player(self)


			local t_pos
			local dist
			local p
			local line_of_sight
			local scan_pos

			if player then 
				t_pos = player:get_pos()
				scan_pos = t_pos
       			scan_pos.y = scan_pos.y + 1
				dist = vector.distance(pos,t_pos) 
				p = self.object:get_pos() -- p is for the shooting height position
				p.y = p.y + (self.collisionbox[2] + self.collisionbox[5]) / 2 --here we edit p for the shooting height
				line_of_sight = minetest.line_of_sight(p, scan_pos, 0.9)
			end
			
			local status = self.status
	

			mob_core.vitals(self)
			mob_core.growth(self)

			
			if not status then
					mobkit.remember(self, "status", "")
                    status = ''
                    self.status = ''
			end
			minetest.chat_send_all(dump(line_of_sight))
			if player and line_of_sight and line_of_sight == true and prty < 20 then
				mobs_creatures.hq_shoot_arrow(self,21,player)
			end



			if mobkit.is_queue_empty_high(self) then
					mob_core.hq_roam(self, 0, 1)
					self.status = mobkit.remember(self,'status','')
			end        
	
	end
end







mobs_creatures.register_arrow("mobs_creatures:skeleton_archer_arrow", {
    visual = "sprite",
    visual_size = {x = 0.75, y = 0.75},
 --   collisionbox = {-1/8,-1/8,-1/8, 1/8,1/8,1/8},
    textures = {"mobs_creatures_arrow_arrow.png"},
    velocity = 10,
    tail = 1, -- enable tail
    expire = 0.25,
    glow = 5,
    tail_texture = "mobs_creatures_arrow_arrow_trail.png",
    tail_size = 3,
    hit_player = function(self, player)
       player:punch(self.object, 1.0, {
          full_punch_interval = 1.0,
          damage_groups = {fleshy = 10},
       }, nil)
        minetest.sound_play({name = "mobs_creatures_common_shoot_arrow_hit", gain = 1.0}, {pos=player:getpos(), max_hear_distance = 12})
    end,
 
    hit_object = function(self, object)
		if not object then return end
		if not mob_core.is_mobkit_mob(object) then return end
        local ent =  object:get_lua_entity() 
        if not ent then return end
        mobkit.hurt(ent,1)
        
    end,
    hit_node = function(self, pos, node)
        minetest.sound_play({name = "mobs_creatures_common_shoot_arrow_hit", gain = 1.0}, {pos=pos, max_hear_distance = 12})
        --minetest.add_entity(pos, "bweapons_bows_pack:arrow") 	--Needs to not be added at pos, but rather right before.
        self.object:remove()
    end,
 })


















minetest.register_entity("mobs_creatures:skeleton_archer",{
	max_hp = 20,
	view_range = 20,
	reach = 1,
	armor = 100,
	damage = 5,
    passive = false,
    arrow = "mobs_creatures:skeleton_archer_arrow",
    shoot_interval = 2.5,
	shoot_offset = 1,
	meele_dist = 3,
	run_dist = 7,

	armor_groups = {fleshy=100},
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.98, 0.3},
	visual_size = {x=3,y=3},
	scale_stage1 = 0.5,
	scale_stage2 = 0.65,
	scale_stage3 = 0.80,
	visual = "mesh",

	mesh = "mobs_creatures_skeleton.b3d",
	textures = {"mobs_creatures_skeleton.png^mobs_creatures_skeleton_bow.png"},
	animation = {
			stand = {range={x=0,y=40},speed=5,loop=true},
			walk={range={x=40,y=60},speed=15,loop=true},		-- single
			run={range={x=40,y=60},speed=30,loop=true},		-- single
			attack = {range={x=70,y=90},speed=30,loop=true},		-- single
            die = {range={x=120,y=130},speed=5,loop=false},
        },
	obstacle_avoidance_range = 10,
	surface_avoidance_range = 0,
	floor_avoidance_range = 1,
	sounds = {
			random = "mobs_creatures_skeleton_random",
			hurt = "mobs_creatures_skeleton_damage",
            attack = "mobs_creatures_skeleton_attack",
            shoot_attack = "mobs_creatures_common_shoot_arrow",
			jump = "mobs_creatures_skeleton_jump",
			death = "mobs_creatures_skeleton_death",
	},
	max_speed = 2.4,					-- m/s
	stepheight = 1.1,				
	jump_height = 1.1,
	buoyancy = 0,
	lung_capacity = 100, 		-- seconds
	ignore_liquidflag = false,			
	timeout = 500,	
	semiaquatic = false,
	core_growth = false,	
	push_on_collide = true,
	catch_with_net = false,
	follow = {},                
	drops = {
		{name = "bweapons_bows_pack:arrow", chance = 1, min = 0, max = 5,},
		{name = "mobs_creatures:bone", chance = 1, min = 0, max = 5,},
		{name = "bweapons_bows_pack:wooden_bow", chance = 12, min = 1, max = 1,},
	},
	on_step = better_fauna.on_step,
	on_activate = better_fauna.on_activate,		
	get_staticdata = mobkit.statfunc,
	logic = skeleton_archer_brain,		        
	attack={range=1,damage_groups={fleshy=5}},	
	damage_groups={{fleshy=5}},
	knockback = .005,
	defend_owner = true,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if time_from_last_punch < .4 then return end --dont hurt more than every .4 sec, cant make this tooo easy


        mob_core.on_punch_basic(self, puncher, tool_capabilities, dir)
        local prty = mobkit.get_queue_priority(self)
        if prty < 10 then
                mobkit.clear_queue_high(self)
        end
        mob_core.on_punch_retaliate(self, puncher, water, group)
        
			
			
	end,
})
