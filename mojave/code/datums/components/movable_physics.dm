#define MOVABLE_PHYSICS_PRECISION 0.01
#define CONSERVATION_OF_MOMENTUM 0.8
#define MINIMAL_VELOCITY 1

// physics flags
/// Remove the component as soon as there's zero velocity, useful for movables that will no longer move after being initially moved (blood splatters)
#define QDEL_WHEN_NO_MOVEMENT (1<<0)
///Upon hitting the ground, immediately stops movement
#define STICK_TO_GROUND (1<<1)

/// Stores information related to the movable's physics and keeping track of relevant signals to trigger movement
/datum/component/movable_physics
	/// Flags for turning on certain physic properties, see the top of the file for more information on flags
	var/physics_flags
	/// Modifies the pixel_x/pixel_y of an object every process()
	var/horizontal_velocity
	/// Modifies the pixel_z of an object every process(), movables aren't Move()'d into another turf if pixel_z exceeds 16, so try not to supply a super high vertical value if you don't want the movable to clip through multiple turfs
	var/vertical_velocity
	/// The horizontal_velocity is reduced by this every process(), this doesn't take into account the object being in the air vs gravity pushing it against the ground
	var/horizontal_friction
	/// The vertical_velocity is reduced by this every process()
	var/vertical_friction
	/// The pixel_z that the object will no longer be influenced by gravity for a 32x32 turf, keep this value between -16 to 0 so it's visuals matches up with it physically being in the turf
	var/z_floor
	/// The angle of the path the object takes on the x/y plane
	var/angle
	/// For calling spinanimation at the start of movement
	var/spin_speed
	/// For calling spinanimation at the start of movement
	var/spin_loops
	/// For calling spinanimation at the start of movement
	var/spin_clockwise
	/// For calling spinanimation when bouncing
	var/bounce_spin_speed
	/// For calling spinanimation when bouncing
	var/bounce_spin_loops
	/// For calling spinanimation when bouncing
	var/bounce_spin_clockwise
	/// The sound effect to play when bouncing off of something
	var/bounce_sound
	/// If we have this callback, it gets invoked when stopping movement
	var/datum/callback/stop_callback

	/// The cached animate_movement of the parent; any kind of gliding when doing Move() makes the physics look derpy, so we'll just make Move() be instant
	var/cached_animate_movement
	/// Cached transform of the parent, in case some fucking idiot decides its a good idea to make the damn movable spin forever
	var/cached_transform

	var/time_since_last = 0

// It's a BAD IDEA to use this on something that is not an item, even though you can
/datum/component/movable_physics/Initialize(
	physics_flags = QDEL_WHEN_NO_MOVEMENT,
	horizontal_velocity = 0,
	vertical_velocity = 0,
	horizontal_friction = 0,
	vertical_friction = 0.5,
	z_floor = 0,
	angle = 0,
	spin_speed = 0,
	spin_loops = 0,
	spin_clockwise = TRUE,
	bounce_spin_speed = 0,
	bounce_spin_loops = 0,
	bounce_spin_clockwise = 0,
	bounce_sound,
	stop_callback,
)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	src.physics_flags = physics_flags
	src.horizontal_velocity = horizontal_velocity
	src.vertical_velocity = vertical_velocity
	src.horizontal_friction = horizontal_friction
	src.vertical_friction = vertical_friction
	src.z_floor = z_floor
	src.angle = angle
	src.spin_speed = spin_speed
	src.spin_loops = spin_loops
	src.spin_clockwise = spin_clockwise
	src.bounce_spin_speed = bounce_spin_speed
	src.bounce_spin_loops = bounce_spin_loops
	src.bounce_spin_clockwise = bounce_spin_clockwise
	src.bounce_sound = bounce_sound
	src.stop_callback = stop_callback
	set_angle(angle)

/datum/component/movable_physics/Destroy(force, silent)
	. = ..()
	if(stop_callback)
		QDEL_NULL(stop_callback)
	cached_transform = null

/datum/component/movable_physics/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_BUMP, .proc/on_bump)
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, .proc/on_item_pickup)
	if(vertical_velocity || horizontal_velocity)
		start_movement()
	else if(physics_flags & QDEL_WHEN_NO_MOVEMENT)
		qdel(src)

/datum/component/movable_physics/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOVABLE_IMPACT)
	if(isitem(parent))
		UnregisterSignal(parent, COMSIG_ITEM_PICKUP)
	stop_movement()

// NOTE: This component will basically NOT work properly at anything less than 10 ticks per second, don't bother
/datum/component/movable_physics/process(seconds_per_tick)
	var/atom/movable/moving_atom = parent
	if(!isturf(moving_atom.loc))
		stop_movement()
		return PROCESS_KILL
	if(abs(horizontal_velocity) <= MINIMAL_VELOCITY && abs(vertical_velocity) <= MINIMAL_VELOCITY && moving_atom.pixel_z <= z_floor)
		stop_movement()
		return PROCESS_KILL
//	if(time_since_last != 0)
//		to_chat(world, "time since last call; [(world.time - time_since_last) / 10] secomds")
//	time_since_last = world.time
	var/tick_amount = 20 * seconds_per_tick
	while(tick_amount)
		tick_amount--
		animate(moving_atom, pixel_x = moving_atom.pixel_x + (horizontal_velocity * sin(angle)), time = seconds_per_tick, easing = ELASTIC_EASING, flags = ANIMATION_PARALLEL)
		moving_atom.pixel_x = round(moving_atom.pixel_x + (horizontal_velocity * sin(angle)), MOVABLE_PHYSICS_PRECISION)
		moving_atom.pixel_y = round(moving_atom.pixel_y + (horizontal_velocity * cos(angle)), MOVABLE_PHYSICS_PRECISION)

		moving_atom.pixel_z = round(max(z_floor, moving_atom.pixel_z + vertical_velocity), MOVABLE_PHYSICS_PRECISION)

		horizontal_velocity = max(0, horizontal_velocity - horizontal_friction)
		if(moving_atom.pixel_z > z_floor)
			vertical_velocity -= vertical_friction
		else if(moving_atom.pixel_z <= z_floor && vertical_velocity)
			if(physics_flags & STICK_TO_GROUND)
				var/obj/effect/decal/cleanable/blood/drip = parent
				if(istype(drip))
					var/obj/effect/decal/cleanable/blood/splatter/split = new(get_turf(parent))
					split.icon_state = pick(split.random_icon_states)
					qdel(drip)
				stop_movement()
				return
			z_floor_bounce(moving_atom)

		// the code below only really works if we don't happen to move more than one tile at once
		// if we do, fuck...
		var/move_direction = NONE
		var/effective_pixel_x = moving_atom.pixel_x - moving_atom.base_pixel_x
		var/effective_pixel_y = moving_atom.pixel_y - moving_atom.base_pixel_y
		var/sign_x = 0
		var/sign_y = 0
		if(effective_pixel_x > world.icon_size/2)
			move_direction |= EAST
			sign_x = -1
		else if(effective_pixel_x < -world.icon_size/2)
			move_direction |= WEST
			sign_x = 1

		if(effective_pixel_y > world.icon_size/2)
			move_direction |= NORTH
			sign_y = -1
		else if(effective_pixel_y < -world.icon_size/2)
			move_direction |= SOUTH
			sign_y = 1

		var/step = get_step(moving_atom, move_direction)
		if(move_direction && moving_atom.Move(step, get_dir(moving_atom, step)))
			moving_atom.pixel_x = round(moving_atom.base_pixel_x + (sign_x * world.icon_size/2), MOVABLE_PHYSICS_PRECISION)
			moving_atom.pixel_y = round(moving_atom.base_pixel_y + (sign_y * world.icon_size/2), MOVABLE_PHYSICS_PRECISION)

/datum/component/movable_physics/proc/start_movement()
	START_PROCESSING(SSmovable_physics, src)
	var/atom/movable/moving_atom = parent
	cached_animate_movement = moving_atom.animate_movement
	moving_atom.animate_movement = NO_STEPS
	if(!spin_speed || !spin_loops)
		return
	moving_atom.SpinAnimation(speed = spin_speed, loops = spin_loops)
	if(spin_loops == INFINITE)
		cached_transform = matrix(moving_atom.transform)

/datum/component/movable_physics/proc/stop_movement()
	STOP_PROCESSING(SSmovable_physics, src)
	var/atom/movable/moving_atom = parent
	if(cached_animate_movement)
		moving_atom.animate_movement = cached_animate_movement
	if(cached_transform)
		animate(moving_atom, transform = cached_transform, time = 0, loop = 0)
	if(stop_callback)
		stop_callback.Invoke()
	if((physics_flags & QDEL_WHEN_NO_MOVEMENT) && !QDELING(src))
		qdel(src)

/datum/component/movable_physics/proc/set_angle(new_angle)
	angle = SIMPLIFY_DEGREES(new_angle)

/datum/component/movable_physics/proc/z_floor_bounce(atom/movable/moving_atom)
	moving_atom.pixel_z = round(z_floor, MOVABLE_PHYSICS_PRECISION)
	moving_atom.SpinAnimation(speed = bounce_spin_speed, loops = max(0, bounce_spin_loops))
	vertical_velocity = abs(vertical_velocity * CONSERVATION_OF_MOMENTUM)


/datum/component/movable_physics/proc/on_bump(atom/movable/source, atom/bumped_atom)
	SIGNAL_HANDLER
	if(physics_flags & STICK_TO_GROUND)
		stop_movement()
		return
	horizontal_velocity = horizontal_velocity * CONSERVATION_OF_MOMENTUM
	var/face_direction = get_dir(bumped_atom, source)
	var/face_angle = dir2angle(face_direction)
	var/incidence = GET_ANGLE_OF_INCIDENCE(face_angle, angle + 180)
	var/new_angle = SIMPLIFY_DEGREES(face_angle + incidence)
	set_angle(new_angle)

/datum/component/movable_physics/proc/on_item_pickup(obj/item/source)
	SIGNAL_HANDLER

	stop_movement()

/**
 * DEBUG PROC
 */
/atom/movable/proc/physics_chungus_deluxe(atom/target, deviation = 0)
	var/angle_to_target = get_angle(src, target)
	var/angle_of_movement = angle_to_target
	if(deviation)
		angle_of_movement += SIMPLIFY_DEGREES(rand(-deviation * 100, deviation * 100) * 0.01)
	AddComponent(/datum/component/movable_physics, \
		horizontal_velocity = rand(4.5 * 100, 5.5 * 100) * 0.01, \
		vertical_velocity = rand(4 * 100, 4.5 * 100) * 0.01, \
		horizontal_friction = rand(0.2 * 100, 0.24 * 100) * 0.01, \
		vertical_friction = round(10 * 0.05, 0.01), \
		z_floor = 0, \
		angle = angle_of_movement, \
	)
#undef CONSERVATION_OF_MOMENTUM
