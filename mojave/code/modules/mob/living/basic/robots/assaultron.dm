/mob/living/basic/ms13/robot/assaultron
	name = "assaultron"
	desc = "A robot designed with a sole concept in mind. Combat efficiency. It boasts a strong range laser attack, and devestating up-close piercing blade hands."
	icon_state = "assaultron"
	icon_living = "assaultron"
	idlesound = list('mojave/sound/ms13items/tracker_far.ogg')
	health = 150
	maxHealth = 150
	melee_damage_lower = 10
	melee_damage_upper = 15
	wound_bonus = 5
	bare_wound_bonus = 5
	sharpness = SHARP_POINTY
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	ai_controller = /datum/ai_controller/basic_controller/ms13/robot/assaultron

/mob/living/basic/ms13/robot/assaultron/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ranged_attacks, /obj/item/ammo_casing/energy/ms13/assaultron)

/datum/ai_controller/basic_controller/ms13/robot/assaultron
	planning_subtrees = list(
		///datum/ai_planning_subtree/random_speech/robot,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/ms13/robot/assaultron,
		/datum/ai_planning_subtree/basic_ranged_attack_subtree/robot/assaultron, //If we are attacking someone, this will prevent us from hunting
		/datum/ai_planning_subtree/find_and_hunt_target
	)

/datum/ai_planning_subtree/basic_melee_attack_subtree/ms13/robot/assaultron
	melee_attack_behavior = /datum/ai_behavior/basic_melee_attack/ms13/robot/assaultron

/datum/ai_behavior/basic_melee_attack/ms13/robot/assaultron
	action_cooldown = 2 SECONDS

/datum/ai_planning_subtree/basic_ranged_attack_subtree/robot/assaultron
	ranged_attack_behavior = /datum/ai_behavior/basic_ranged_attack/robot/assaultron

/datum/ai_behavior/basic_ranged_attack/robot/assaultron
	action_cooldown = 10 SECONDS


/mob/living/basic/ms13/robot/assaultron/death()
	. = ..()
	do_sparks(3, TRUE, src)

/obj/item/ammo_casing/energy/ms13/assaultron
	name = "Assaultron Laser"
	desc = "A ammo casing meant for shooting lasers, this one appeared to belong to an assaultron."
	projectile_type = /obj/projectile/beam/ms13/laser/assaultron
	fire_sound= 'mojave/sound/ms13weapons/gunsounds/lasrifle/laser_heavy.ogg'
