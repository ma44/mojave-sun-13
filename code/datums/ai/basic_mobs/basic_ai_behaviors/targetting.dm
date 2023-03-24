/datum/ai_behavior/find_potential_targets
	action_cooldown = 2 SECONDS
	///List of potentially dangerous objs
	var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/vehicle/sealed/mecha))

/datum/ai_behavior/find_potential_targets/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key, vision_range_key = BB_VISION_RANGE)
	. = ..()
	var/list/potential_targets
	var/mob/living/living_mob = controller.pawn
	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]

	if(!targetting_datum)
		CRASH("No target datum was supplied in the blackboard for [controller.pawn]")

	if(!controller.blackboard[vision_range_key])
		controller.blackboard[vision_range_key] = 9

	potential_targets = hearers(controller.blackboard[vision_range_key], controller.pawn) - living_mob //Remove self, so we don't suicide

	for(var/HM in typecache_filter_list(range(controller.blackboard[vision_range_key], living_mob), hostile_machines)) //Can we see any hostile machines?
		if(can_see(living_mob, HM, controller.blackboard[vision_range_key]))
			potential_targets += HM

	if(!potential_targets.len)
		finish_action(controller, FALSE)
		return

	var/list/filtered_targets = list()

	for(var/atom/pot_target in potential_targets)
		if(targetting_datum.can_attack(living_mob, pot_target))//Can we attack it?
			filtered_targets += pot_target
			continue

	if(!filtered_targets.len)
		finish_action(controller, FALSE)
		return

	var/atom/target = pick(filtered_targets)
	controller.blackboard[target_key] = target

	var/atom/potential_hiding_location = targetting_datum.find_hidden_mobs(living_mob, target)

	if(potential_hiding_location) //If they're hiding inside of something, we need to know so we can go for that instead initially.
		controller.blackboard[hiding_location_key] = potential_hiding_location

	finish_action(controller, TRUE)
