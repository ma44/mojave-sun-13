/// An element to add a NV FOV trait to the wearer, removing it when an item is unequipped, but only as long as the visor is up.
/datum/component/clothing_nv_visor
	/// What's the FOV angle of the trait we're applying to the wearer
	var/fov_angle
	/// What's the alpha of the trait we're applying to the wearer
	var/alpha
	/// What's the color of the trait we're applying to the wearer
	var/color
	/// Keeping track of the visor of our clothing.
	var/visor_up = FALSE
	/// Because of clothing code not being too good, we need keep track whether we are worn.
	var/is_worn = FALSE

/datum/component/clothing_nv_visor/Initialize(fov_angle = FOV_180_DEGREES, alpha = 255, color = "#aaffaa")
	. = ..()
	if(!isclothing(parent))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/clothing/clothing_parent = parent
	src.fov_angle = fov_angle
	src.alpha = alpha
	src.color = color
	src.visor_up = clothing_parent.up //Initial values could vary, so we need to get it.

/datum/component/clothing_nv_visor/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, .proc/on_equip)
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, .proc/on_drop)
	RegisterSignal(parent, COMSIG_CLOTHING_VISOR_TOGGLE, .proc/on_visor_toggle)

/datum/component/clothing_nv_visor/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED, COMSIG_CLOTHING_VISOR_TOGGLE))
	return ..()

/// On dropping the item, remove the FoV trait if visor was down.
/datum/component/clothing_nv_visor/proc/on_drop(datum/source, mob/living/dropper)
	SIGNAL_HANDLER

	is_worn = FALSE
	if(visor_up)
		return
	dropper.remove_nv_trait(source.type, fov_angle)
	dropper.update_nv()

/// On equipping the item, add the FoV trait if visor isn't up.
/datum/component/clothing_nv_visor/proc/on_equip(obj/item/source, mob/living/equipper, slot)
	SIGNAL_HANDLER

	if(!(source.slot_flags & slot)) //If EQUIPPED TO HANDS FOR EXAMPLE
		return
	is_worn = TRUE
	if(visor_up)
		return
	equipper.add_nv_trait(source.type, fov_angle, alpha, color)
	equipper.update_nv()

/// On toggling the visor, we may want to add or remove FOV trait from the wearer.
/datum/component/clothing_nv_visor/proc/on_visor_toggle(datum/source, visor_state)
	SIGNAL_HANDLER

	visor_up = visor_state
	if(!is_worn)
		return
	var/obj/item/clothing/clothing_parent = parent
	var/mob/living/wearer = clothing_parent.loc //This has to be the case due to equip/dropped keeping track.
	if(!visor_up)
		wearer.add_nv_trait("[REF(source)]", fov_angle, alpha, color)
		wearer.update_nv()
	else
		wearer.remove_nv_trait("[REF(source)]")
		wearer.update_nv()
