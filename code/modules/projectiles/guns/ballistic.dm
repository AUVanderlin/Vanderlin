/obj/item/proc/can_trigger_gun(mob/living/user)
	if(!user.can_use_guns(src))
		return FALSE
	return TRUE

///Subtype for any kind of ballistic gun
///This has a shitload of vars on it, and I'm sorry for that, but it does make making new subtypes really easy
/obj/item/gun/ballistic
	desc = ""
	name = "projectile gun"
	icon_state = "pistol"
	w_class = WEIGHT_CLASS_NORMAL

	///sound when inserting magazine
	var/load_sound = 'sound/blank.ogg'
	///sound when inserting an empty magazine
	var/load_empty_sound = 'sound/blank.ogg'
	///volume of loading sound
	var/load_sound_volume = 40
	///whether loading sound should vary
	var/load_sound_vary = TRUE
	///sound of racking
	var/rack_sound = 'sound/blank.ogg'
	///volume of racking
	var/rack_sound_volume = 60
	///whether racking sound should vary
	var/rack_sound_vary = TRUE
	///sound of when the bolt is locked back manually
	var/lock_back_sound = 'sound/blank.ogg'
	///volume of lock back
	var/lock_back_sound_volume = 60
	///whether lock back varies
	var/lock_back_sound_vary = TRUE
	///Sound of ejecting a magazine
	var/eject_sound = 'sound/blank.ogg'
	///sound of ejecting an empty magazine
	var/eject_empty_sound = 'sound/blank.ogg'
	///volume of ejecting a magazine
	var/eject_sound_volume = 40
	///whether eject sound should vary
	var/eject_sound_vary = TRUE
	///sound of dropping the bolt or releasing a slide
	var/bolt_drop_sound = 'sound/blank.ogg'
	///volume of bolt drop/slide release
	var/bolt_drop_sound_volume = 60
	///empty alarm sound (if enabled)
	var/empty_alarm_sound = 'sound/blank.ogg'
	///empty alarm volume sound
	var/empty_alarm_volume = 70
	///whether empty alarm sound varies
	var/empty_alarm_vary = TRUE

	///Whether the gun will spawn loaded with a magazine
	var/spawnwithmagazine = TRUE
	///Compatible magazines with the gun
	var/mag_type =/obj/item/ammo_box/magazine/internal/shot/xbow //Removes the need for max_ammo and caliber info
	///Whether the sprite has a visible magazine or not
	var/mag_display = FALSE
	///Whether the sprite has a visible ammo display or not
	var/mag_display_ammo = FALSE
	///Whether the sprite has a visible indicator for being empty or not.
	var/empty_indicator = FALSE
	///Whether the gun alarms when empty or not.
	var/empty_alarm = FALSE
	///Whether the gun supports multiple special mag types
	var/special_mags = FALSE
	///The bolt type of the gun, affects quite a bit of functionality, see combat.dm defines for bolt types: BOLT_TYPE_STANDARD; BOLT_TYPE_LOCKING; BOLT_TYPE_OPEN; BOLT_TYPE_NO_BOLT
	var/bolt_type = BOLT_TYPE_STANDARD
	///Used for locking bolt and open bolt guns. Set a bit differently for the two but prevents firing when true for both.
	var/bolt_locked = FALSE
	///Whether the gun has to be racked each shot or not.
	var/semi_auto = TRUE
	///Actual magazine currently contained within the gun
	var/obj/item/ammo_box/magazine/magazine
	///whether the gun ejects the chambered casing
	var/casing_ejector = TRUE
	///Whether the gun has an internal magazine or a detatchable one. Overridden by BOLT_TYPE_NO_BOLT.
	var/internal_magazine = FALSE
	///Phrasing of the bolt in examine and notification messages; ex: bolt, slide, etc.
	var/bolt_wording = "bolt"
	///Phrasing of the magazine in examine and notification messages; ex: magazine, box, etx
	var/magazine_wording = "magazine"
	///Phrasing of the cartridge in examine and notification messages; ex: bullet, shell, dart, etc.
	var/cartridge_wording = "bullet"
	///length between individual racks
	var/rack_delay = 5
	///time of the most recent rack, used for cooldown purposes
	var/recent_rack = 0
	///Whether the gun can be tacloaded by slapping a fresh magazine directly on it
	var/tac_reloads = TRUE //Snowflake mechanic no more.
	var/verbage = "load"

/obj/item/gun/ballistic/Initialize()
	. = ..()
	if (!spawnwithmagazine)
		bolt_locked = TRUE
		update_appearance(UPDATE_ICON)
		return
	if (!magazine)
		magazine = new mag_type(src)
	chamber_round()
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/update_overlays()
	. = ..()
	// if (QDELETED(src))
	// 	return
	// var/used_state = initial(icon_state)
	// if (bolt_type == BOLT_TYPE_LOCKING)
	// 	. += "[used_state]_bolt[bolt_locked ? "_locked" : ""]"
	// if (bolt_type == BOLT_TYPE_OPEN && bolt_locked)
	// 	. += "[used_state]_bolt"
	// if(!chambered && empty_indicator)
	// 	. += "[used_state]_empty"
	// if (magazine)
	// 	if (special_mags)
	// 		. += "[used_state]_mag_[initial(magazine.icon_state)]"
	// 		if (!magazine.ammo_count())
	// 			. += "[used_state]_mag_empty"
	// 	else
	// 		. += "[used_state]_mag"
	// 		var/capacity_number = 0
	// 		switch(get_ammo() / magazine.max_ammo)
	// 			if(0.2 to 0.39)
	// 				capacity_number = 20
	// 			if(0.4 to 0.59)
	// 				capacity_number = 40
	// 			if(0.6 to 0.79)
	// 				capacity_number = 60
	// 			if(0.8 to 0.99)
	// 				capacity_number = 80
	// 			if(1.0)
	// 				capacity_number = 100
	// 		if (capacity_number)
	// 			. += "[used_state]_mag_[capacity_number]"

/obj/item/gun/ballistic/process_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	if(!semi_auto && from_firing)
		return
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(istype(AC)) //there's a chambered round
		if(casing_ejector || !from_firing)
			AC.forceMove(drop_location()) //Eject casing onto ground.
			AC.bounce_away(TRUE)
			chambered = null
		else if(empty_chamber)
			chambered = null
	if (chamber_next_round && (magazine?.max_ammo > 1))
		chamber_round()

///Used to chamber a new round and eject the old one
/obj/item/gun/ballistic/proc/chamber_round(keep_bullet = FALSE)
	if (chambered || !magazine)
		return
	if (magazine.ammo_count())
		chambered = magazine.get_round(keep_bullet || bolt_type == BOLT_TYPE_NO_BOLT)
		if (bolt_type != BOLT_TYPE_OPEN)
			chambered.forceMove(src)

///updates a bunch of racking related stuff and also handles the sound effects and the like
/obj/item/gun/ballistic/proc/rack(mob/user = null)
	if (bolt_type == BOLT_TYPE_NO_BOLT) //If there's no bolt, nothing to rack
		return
	if (bolt_type == BOLT_TYPE_OPEN)
		if(!bolt_locked)	//If it's an open bolt, racking again would do nothing
			if (user)
				to_chat(user, "<span class='notice'>\The [src]'s [bolt_wording] is already cocked!</span>")
			return
		bolt_locked = FALSE
	if (user)
		to_chat(user, "<span class='notice'>I rack the [bolt_wording] of \the [src].</span>")
	process_chamber(!chambered, FALSE)
	if (bolt_type == BOLT_TYPE_LOCKING && !chambered)
		bolt_locked = TRUE
		playsound(src, lock_back_sound, lock_back_sound_volume, lock_back_sound_vary)
	else
		playsound(src, rack_sound, rack_sound_volume, rack_sound_vary)
	update_appearance(UPDATE_ICON)

///Drops the bolt from a locked position
/obj/item/gun/ballistic/proc/drop_bolt(mob/user = null)
	playsound(src, bolt_drop_sound, bolt_drop_sound_volume, FALSE)
	if (user)
		to_chat(user, "<span class='notice'>I drop the [bolt_wording] of \the [src].</span>")
	chamber_round()
	bolt_locked = FALSE
	update_appearance(UPDATE_ICON)

///Handles all the logic needed for magazine insertion
/obj/item/gun/ballistic/proc/insert_magazine(mob/user, obj/item/ammo_box/magazine/AM, display_message = TRUE)
	if(!istype(AM, mag_type))
		to_chat(user, "<span class='warning'>\The [AM] doesn't seem to fit into \the [src]...</span>")
		return FALSE
	if(user.transferItemToLoc(AM, src))
		magazine = AM
		if (display_message)
			to_chat(user, "<span class='notice'>I load a new [magazine_wording] into \the [src].</span>")
		playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
		if (bolt_type == BOLT_TYPE_OPEN && !bolt_locked)
			chamber_round(TRUE)
		update_appearance(UPDATE_ICON)
		return TRUE
	else
		to_chat(user, "<span class='warning'>I cannot seem to get \the [src] out of your hands!</span>")
		return FALSE

///Handles all the logic of magazine ejection, if tac_load is set that magazine will be tacloaded in the place of the old eject
/obj/item/gun/ballistic/proc/eject_magazine(mob/user, display_message = TRUE, obj/item/ammo_box/magazine/tac_load = null)
	if(bolt_type == BOLT_TYPE_OPEN)
		chambered = null
	if (magazine.ammo_count())
		playsound(src, load_sound, load_sound_volume, load_sound_vary)
	else
		playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
	magazine.forceMove(drop_location())
	var/obj/item/ammo_box/magazine/old_mag = magazine
	if (tac_load)
		if (insert_magazine(user, tac_load, FALSE))
			to_chat(user, "<span class='notice'>I perform a tactical reload on \the [src].</span>")
		else
			to_chat(user, "<span class='warning'>I dropped the old [magazine_wording], but the new one doesn't fit. How embarassing.</span>")
			magazine = null
	else
		magazine = null
	user.put_in_hands(old_mag)
	old_mag.update_appearance()
	if (display_message)
		to_chat(user, "<span class='notice'>I pull the [magazine_wording] out of \the [src].</span>")
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/can_shoot()
	return chambered

/obj/item/gun/ballistic/attackby(obj/item/A, mob/user, params)
	. = ..()
	if (.)
		return
	if (!internal_magazine && istype(A, /obj/item/ammo_box/magazine))
		var/obj/item/ammo_box/magazine/AM = A
		if (!magazine)
			insert_magazine(user, AM)
		else
			if (tac_reloads)
				eject_magazine(user, FALSE, AM)
			else
				to_chat(user, "<span class='notice'>There's already \a [magazine_wording] in \the [src].</span>")
		return
	if (istype(A, /obj/item/ammo_casing) || istype(A, /obj/item/ammo_box))
		if (bolt_type == BOLT_TYPE_NO_BOLT || internal_magazine)
			if (chambered && !chambered.BB)
				chambered.forceMove(drop_location())
				chambered = null
			var/num_loaded = magazine.attackby(A, user, params, TRUE)
			if (num_loaded)
				to_chat(user, "<span class='notice'>I [verbage] \a [cartridge_wording]\s on \the [src].</span>")
				playsound(src, load_sound, load_sound_volume, load_sound_vary)
				if (chambered == null && bolt_type == BOLT_TYPE_NO_BOLT)
					chamber_round()
				A.update_appearance()
				update_appearance(UPDATE_ICON)
			return
	user.update_inv_hands()
	return FALSE


/obj/item/gun/ballistic/AltClick(mob/user)
	if (unique_reskin && !current_skin && user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		reskin_obj(user)
		return

///Prefire empty checks for the bolt drop
/obj/item/gun/ballistic/proc/prefire_empty_checks()
	if (!chambered && !get_ammo())
		if (bolt_type == BOLT_TYPE_OPEN && !bolt_locked)
			bolt_locked = TRUE
			playsound(src, bolt_drop_sound, bolt_drop_sound_volume)
			update_appearance(UPDATE_ICON)

///postfire empty checks for bolt locking and sound alarms
/obj/item/gun/ballistic/proc/postfire_empty_checks(last_shot_succeeded)
	if (!chambered && !get_ammo())
		if (empty_alarm && last_shot_succeeded)
			playsound(src, empty_alarm_sound, empty_alarm_volume, empty_alarm_vary)
			update_appearance(UPDATE_ICON)
		if (last_shot_succeeded && bolt_type == BOLT_TYPE_LOCKING)
			bolt_locked = TRUE
			update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	prefire_empty_checks()
	. = ..() //The gun actually firing
	postfire_empty_checks(.)

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/gun/ballistic/attack_hand(mob/user)
	if(!internal_magazine && loc == user && user.is_holding(src) && magazine)
		eject_magazine(user)
		return
	return ..()

/obj/item/gun/ballistic/attack_self(mob/living/user, params)
	if(!internal_magazine && magazine)
		if(!magazine.ammo_count())
			eject_magazine(user)
			return
	if(bolt_type == BOLT_TYPE_NO_BOLT)
		chambered = null
		var/num_unloaded = 0
		for(var/obj/item/ammo_casing/CB in get_ammo_list(FALSE, TRUE))
			CB.forceMove(drop_location())
			CB.bounce_away(FALSE, NONE)
			num_unloaded++
			var/turf/T = get_turf(drop_location())
			if(T && is_station_level(T.z))
				SSblackbox.record_feedback("tally", "station_mess_created", 1, CB.name)
		if (num_unloaded)
			to_chat(user, "<span class='notice'>I remove [(num_unloaded == 1) ? "the" : "[num_unloaded]"] [cartridge_wording]\s from [src].</span>")
			playsound(user, eject_sound, eject_sound_volume, eject_sound_vary)
			update_appearance(UPDATE_ICON)
		else
			to_chat(user, "<span class='warning'>[src] is empty!</span>")
		return
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		drop_bolt(user)
		return
	if (recent_rack > world.time)
		return
	recent_rack = world.time + rack_delay
	rack(user)

///Gets the number of bullets in the gun
/obj/item/gun/ballistic/proc/get_ammo(countchambered = TRUE)
	var/boolets = 0 //mature var names for mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.ammo_count()
	return boolets

///gets a list of every bullet in the gun
/obj/item/gun/ballistic/proc/get_ammo_list(countchambered = TRUE, drop_all = FALSE)
	var/list/rounds = list()
	if(chambered && countchambered)
		rounds.Add(chambered)
		if(drop_all)
			chambered = null
	rounds.Add(magazine.ammo_list(drop_all))
	return rounds

#define BRAINS_BLOWN_THROW_RANGE 3
#define BRAINS_BLOWN_THROW_SPEED 1
/obj/item/gun/ballistic/suicide_act(mob/user)
	var/obj/item/organ/brain/B = user.getorganslot(ORGAN_SLOT_BRAIN)
	if (B && chambered && chambered.BB && can_trigger_gun(user) && !chambered.BB.nodamage)
		user.visible_message("<span class='suicide'>[user] is putting the barrel of [src] in [user.p_their()] mouth. It looks like [user.p_theyre()] trying to commit suicide!</span>")
		sleep(25)
		if(user.is_holding(src))
			var/turf/T = get_turf(user)
			process_fire(user, user, FALSE, null, BODY_ZONE_HEAD)
			user.visible_message("<span class='suicide'>[user] blows [user.p_their()] brain[user.p_s()] out with [src]!</span>")
			var/turf/target = get_ranged_target_turf(user, turn(user.dir, 180), BRAINS_BLOWN_THROW_RANGE)
			B.Remove(user)
			B.forceMove(T)
			var/datum/callback/gibspawner = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(spawn_atom_to_turf), /obj/effect/gibspawner/generic, B, 1, FALSE, user)
			B.throw_at(target, BRAINS_BLOWN_THROW_RANGE, BRAINS_BLOWN_THROW_SPEED, callback=gibspawner)
			return(BRUTELOSS)
		else
			user.visible_message("<span class='suicide'>[user] panics and starts choking to death!</span>")
			return(OXYLOSS)
	else
		user.visible_message("<span class='suicide'>[user] is pretending to blow [user.p_their()] brain[user.p_s()] out with [src]! It looks like [user.p_theyre()] trying to commit suicide!</b></span>")
		playsound(src, dry_fire_sound, 30, TRUE)
		return (OXYLOSS)
#undef BRAINS_BLOWN_THROW_SPEED
#undef BRAINS_BLOWN_THROW_RANGE
