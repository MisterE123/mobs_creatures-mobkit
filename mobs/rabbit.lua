
local function rabbit_logic(self)

	if self.hp <= 0 then
		mob_core.on_die(self)
		return
	end
	local prty = mobkit.get_queue_priority(self)
	local player = mobkit.get_nearby_player(self)

	if mobkit.timer(self,1) then

		mob_core.vitals(self)
		mob_core.random_drop(self, 10, 1800, "mobs_creatures:poop_turd")
		mob_core.random_sound(self, 8)


		
        if prty < 9 and player then
			if self.isinliquid then --if for some reason we have been knocked into water, then we will swim away from the player
				mob_core.hq_swimfrom(self, 10, player, 1)  --mob_core.hq_swimfrom(self, prty, target, speed), speed is a multiplier on normal speed
			else
				mob_core.hq_runfrom(self, 10, player)   --mob_core.hq_runfrom(self, prty, tgtobj)
			end
		end

		if prty < 9 then
			if self.is_in_liquid then
				mob_core.hq_liquid_recovery(self, 9, 'walk') --mob_core.hq_liquid_recovery(self, prty, anim)
			end
		end

		if mobkit.is_queue_empty_high(self) then
			mob_core.hq_roam(self, 0)
		end
	end
end


minetest.register_entity("mobs_creatures:rabbit",{
	physical = true, 
	collide_with_objects = true,
	collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.49, 0.2}, --pulled from mobs_redo definition verbatim
	visual_size = {x=1.5, y=1.5},						--pulled from mobs_redo definition verbatim, if present
	visual = "mesh",                                    --pulled from mobs_redo definition verbatim
	mesh = "mobs_creatures_rabbit.b3d",                 --pulled from mobs_redo definition verbatim
	textures = {"mobs_creatures_rabbit_brown.png",
				"mobs_creatures_rabbit_gold.png",
				"mobs_creatures_rabbit_white.png",
				"mobs_creatures_rabbit_white_splotched.png",
				"mobs_creatures_rabbit_salt.png",
				"mobs_creatures_rabbit_black.png",
				"mobs_creatures_rabbit_toast.png"
			},

			--Woah, that is different from mobs_redo!

	timeout = 500, --how long until the mob is removed, 0 for never
	buoyancy = .7, 
	lung_capacity = 5, --how many seconds it can hold its breath before taking water damage
	max_hp = 3, -- we can take this from the mobs_redo def
	on_step = mob_core.on_step,
	on_activate = mob_core.on_activate,
	get_staticdata = mobkit.statfunc,
	logic = rabbit_logic,
	animation = {									-- has to be translated
		walk={range={x=0,y=20},speed=25,loop=true},
		run={range={x=0,y=20},speed=50,loop=true},
		stand={range={x=0,y=0},speed=25,loop=true},
	},
	sounds = {										--can be copied from redo
		random = "mobs_creatures_rabbit_random",
		jump = "mobs_creatures_rabbit_jump",
		damage = "mobs_creatures_rabbit_pain",
		death = "mobs_creatures_rabbit_death",	
	},
	max_speed = 4, --taken from mobs_redo's run_velocity
	jump_height = 1.1,
	stepheight = 1.1,
	view_range = 8, --copied from mobs_redo
	attack={range=2,damage_groups={fleshy=1}},
	armor_groups = {fleshy=100},
		

	fall_damage = true,
	
	reach = 2,
	damage = 1,
	knockback = 0,
	defend_owner = false,
	drops = {
		{name = "mobs_creatures:rabbit_raw", chance = 1, min = 0, max = 1},
		{name = "mobs_creatures:rabbit_hide", chance = 1, min = 0, max = 1},
	},


	obstacle_avoidance_range = 5,
	surface_avoidance_range = 0,
	floor_avoidance_range = 0,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if time_from_last_punch < .2 then return end --prevent jitterclicking 
		mobkit.clear_queue_high(self)
		mob_core.on_punch_basic(self, puncher, tool_capabilities, dir) --calls damage functions and flashes red
		mob_core.on_punch_runaway(self, puncher, false, true)
	end,
})

mob_core.register_spawn_egg("mobs_creatures:rabbit", "ab7e35", "26231f")


mob_core.register_spawn({
	name = "mobs_creatures:rabbit",
	nodes = {"group:crumbly"},
	min_light = 0,
	max_light = 15,
	min_height = -100,
	max_height = 500,
	min_rad = 24,
	max_rad = 256,
	group = 2,
	optional = {
		
		reliability = 3,
	}
}, 16, 6)
