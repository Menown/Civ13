/obj/roof

	name = "wood roof"
	desc = "A wooden roof."
	icon = 'icons/turf/floors.dmi'
	icon_state = "roof"
	var/passable = TRUE
	var/origin_density = FALSE
	var/origin_water_level = 0
	var/origin_move_delay = 0
	var/not_movable = TRUE //if it can be removed by wrenches
	var/health = 100
	is_cover = TRUE
	anchored = TRUE
	opacity = FALSE
	density = FALSE
	layer = 2.1
	level = 2
	var/amount = FALSE
	var/wall = FALSE
	var/wood = TRUE
	var/onfire = FALSE
	invisibility = 101
	var/oldname = "roofed building"
	flammable = TRUE

/obj/roof/New()
	..()
	var/area/caribbean/CURRENTAREA = get_area(src)
	if (CURRENTAREA.location == AREA_OUTSIDE)
		var/area/caribbean/NEWAREA = new/area/caribbean(src.loc)
		oldname = CURRENTAREA.name
		NEWAREA.name = "roofed building"
		NEWAREA.base_turf = CURRENTAREA.base_turf
		NEWAREA.location = AREA_INSIDE
		NEWAREA.update_light()
/obj/roof/Destroy()
	var/area/caribbean/CURRENTAREA = get_area(src)
	if (CURRENTAREA.location == AREA_INSIDE && CURRENTAREA.name == "roofed building")
		var/area/caribbean/NEWAREA = new/area/caribbean(src.loc)
		NEWAREA.name = oldname
		NEWAREA.base_turf = CURRENTAREA.base_turf
		NEWAREA.location = AREA_OUTSIDE
		NEWAREA.update_light()
	visible_message("The roof collapses!")
	..()

/obj/roof/proc/collapse_check()
	var/supportfound = FALSE

	for (var/obj/structure/roof_support/RS in range(2, src))
		supportfound = TRUE

	for (var/turf/wall/W in range(1, src))
		supportfound = TRUE

	for (var/obj/covers/C in range(1, src))
		if (C.wall == TRUE)
			supportfound = TRUE

	//if no support >> roof falls down
	if (!supportfound)
		visible_message("The roof collapses!")
		playsound(src,'sound/effects/rocksfalling.ogg',100,0,6)
		for (var/mob/living/carbon/human/M in range(2, src))
			M.adjustBruteLoss(rand(17,27))
			M.Weaken(18)
		Destroy()
		new/obj/effect/effect/smoke(src)
		spawn(15)
			qdel(src)
	return

/obj/item/weapon/roofbuilder
	name = "roof builder"
	desc = "Use this to build roofs."
	icon = 'icons/turf/floors.dmi'
	icon_state = "roof_builder"
	w_class = 2.0
	flammable = TRUE

/obj/item/weapon/roofbuilder/attack_self(mob/user)
	var/your_dir = "NORTH"

	switch (user.dir)
		if (NORTH)
			your_dir = "NORTH"
		if (SOUTH)
			your_dir = "SOUTH"
		if (EAST)
			your_dir = "EAST"
		if (WEST)
			your_dir = "WEST"

	var/covers_time = 80

	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		covers_time /= H.getStatCoeff("strength")
		covers_time /= (H.getStatCoeff("crafting") * H.getStatCoeff("crafting"))
	for (var/obj/roof/RF in get_step(user, user.dir))
		user << "That area is already roofed!"
		return
	var/confirm = FALSE
	for(var/obj/structure/roof_support/RS in range(2,src))
		confirm = TRUE
	for(var/obj/covers/CV in range(1,src))
		if (CV.wall)
			confirm = TRUE
	if (!confirm)
		user << "This area doesn't have a support for the roof! Build one first!"
		return
	if (WWinput(user, "This will start building a roof [your_dir] of you.", "Roof Construction", "Continue", list("Continue", "Stop")) == "Continue")
		visible_message("<span class='danger'>[user] starts building the roof.</span>", "<span class='danger'>You start building the roof.</span>")
		if (do_after(user, covers_time, user.loc))
			qdel(src)
			new/obj/roof(get_step(user, user.dir), user)
			visible_message("<span class='danger'>[user] finishes building the roof.</span>")
			if (ishuman(user))
				var/mob/living/carbon/human/H = user
				H.adaptStat("crafting", 1)
		return

/obj/structure/roof_support
	name = "roof support"
	desc = "A thick wood beam, used to support roofs in large buildings."
	icon_state = "support_h"
	flammable = TRUE
	anchored = TRUE
	opacity = FALSE
	density = FALSE

/obj/structure/mine_support
	name = "mine support"
	desc = "A set of wood beams placed to support the mine shaft. Prevents cave-ins."
	icon_state = "support_v"
	flammable = TRUE
	anchored = TRUE
	opacity = FALSE
	density = FALSE

/obj/structure/roof_support/Destroy()
	for(var/obj/roof/R in range(2,src))
		R.collapse_check()
	..()

/obj/structure/mine_support/Destroy()
	if (istype(get_turf(src), /turf/floor))
		var/turf/floor/T = get_turf(src)
		T.collapse_check()
	..()