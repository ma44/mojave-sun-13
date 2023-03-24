#define COMSIG_BASIC_AI_WAKE_UP "comsig_basic_ai_wake_up"

///When initially aggro'd, increase vision range and change icon sprite, otherwise keep the vision range down low, basically enables stealth as a strategy against basic AI
/datum/ai_planning_subtree/simple_find_target/sleeping
	var/initial_vision_range = 1
	var/aggro_vision_range = 9
	var/is_awake = FALSE

/datum/ai_planning_subtree/simple_find_target/sleeping/SelectBehaviors(datum/ai_controller/controller, delta_time)
	//. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!QDELETED(target))
		if(!is_awake)
			for(var/mob/living/mob in view(controller.pawn, 5))
				SEND_SIGNAL(mob, COMSIG_BASIC_AI_WAKE_UP)
		wake_up()
		return
	else
		go_sleep(controller)
	controller.queue_behavior(/datum/ai_behavior/find_potential_targets, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION, BB_VISION_RANGE)

/datum/ai_planning_subtree/simple_find_target/sleeping/Setup(datum/ai_controller/controller)
	..()
	RegisterSignal(controller.pawn, COMSIG_BASIC_AI_WAKE_UP, .proc/wake_up)

/datum/ai_planning_subtree/simple_find_target/sleeping/proc/wake_up()
	addtimer(CALLBACK(src, .proc/actually_wake_up), rand(5, 10)) //0.5 to 1 second delay before truly waking up

/datum/ai_planning_subtree/simple_find_target/sleeping/proc/actually_wake_up()
	is_awake = TRUE
	controller.blackboard[BB_VISION_RANGE] = aggro_vision_range
	controller.pawn.icon_state = "[initial(controller.pawn.icon_state)]"
	playsound(controller.pawn, 'mojave/sound/ms13npc/ghoul_death1.ogg', 25, FALSE)

/datum/ai_planning_subtree/simple_find_target/sleeping/proc/go_sleep()
	is_awake = FALSE
	controller.blackboard[BB_VISION_RANGE] = initial_vision_range
	controller.pawn.icon_state = "[initial(controller.pawn.icon_state)]_sleeping"
