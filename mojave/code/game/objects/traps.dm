/obj/item/restraints/legcuffs/beartrap/ms13
	icon = 'mojave/icons/objects/ms_traps.dmi'

/obj/item/restraints/legcuffs/beartrap/ms13/spring_trap(datum/source, atom/movable/AM, thrown_at = FALSE)
	var/has_sprung = armed
	. = ..()
	if((has_sprung != armed) && ishuman(AM))
		var/mob/living/carbon/human/the_human = AM
		the_human.emote("scream")

//Very hacky, consider refactoring
/obj/item/shotgun_trap
	icon = 'mojave/icons/objects/ms_traps.dmi'
	icon_state = "oneshot_armed"
	var/obj/machinery/door/unpowered/ms13/trigger_door
	var/obj/item/gun/the_gun

/obj/item/shotgun_trap/Initialize(mapload)
	. = ..()
	the_gun = new /obj/item/gun/ballistic/rifle/ms13/hunting/surplus(src)
	dir = 8
	for(var/obj/machinery/door/unpowered/ms13/door in range(7))
		if(door && get_dir(src, door) == dir)
			trigger_door = door
			RegisterSignal(door, COMSIG_ATOM_ATTACK_HAND, .proc/trigger)
			break

/obj/item/shotgun_trap/proc/trigger(datum/source)
	addtimer(CALLBACK(src, .proc/trigger_trap, source), 0.5 SECONDS)

/obj/item/shotgun_trap/proc/trigger_trap(datum/source)
	var/obj/projectile/bullet = new /obj/projectile/bullet/pellet/ms13/buckshot/triple(get_turf(src))
	bullet.preparePixelProjectile(get_turf(source), get_turf(src), null, 0)
	bullet.firer = src
	bullet.fire()
	playsound(get_turf(src), "mojave/sound/ms13weapons/gunsounds/levershot/levershot2.ogg", 50, TRUE)
