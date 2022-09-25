
/particles/bullet_impact
	icon = 'mojave/icons/effects/particles/bullet_impact.dmi'
	icon_state = list("hot_impact")
	width = 100
	height = 100
	count = 25
	spawning = 25000
	lifespan = 5 SECONDS
	fade = 0.5 SECONDS
	velocity = generator("num", 30, 60, NORMAL_RAND)
	//gravity = list(0, -3)
	//position = list(0, 0, 0)
	//drift = generator("sphere", 0, 5, NORMAL_RAND)
	//friction = 0.3
	plane = EMISSIVE_PLANE
	appearance_flags = EMISSIVE_APPEARANCE_FLAGS
	color = GLOB.emissive_color
