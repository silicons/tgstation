var/datum/subsystem/gravity/SSgravity
var/global/legacy_gravity = FALSE
var/global/mob_base_gravity_slip_chance = 10
var/global/mob_base_gravity_fall_chance = 5
var/global/mob_handhold_gravity_slip_chance = 6
var/global/mob_handhold_gravity_fall_chance = 3
var/global/mob_gravity_strength_slip_mod = 3
var/global/mob_gravity_strength_fall_mod = 1.5


/datum/subsystem/gravity
	name = "Gravity"
	priority = 75
	wait = 1
	init_order = -100
	flags = SS_KEEP_TIMING | SS_BACKGROUND

	var/list/currentrun = list()
	var/list/currentrun_manual = list()
	var/recalculation_cost = 0
	var/do_purge = FALSE
	var/purge_interval = 600
	var/purge_tick = 0
	var/purging = FALSE
	var/error_no_atom = 0
	var/error_mismatched_area = 0
	var/error_mismatched_turf = 0
	var/error_no_area = 0
	var/error_no_turf = 0
	var/list/purging_atoms = list()
	var/list/area_blacklist_typecache
	var/list/area_blacklist = list(/area/lavaland, /area/mine, /area/centcom)
	var/mob_slip_chance = 0
	var/mob_fall_chance = 0
	var/mob_slip_chance_handhold = 0
	var/mob_fall_chance_handhold = 0
	var/mob_slip_chance_mod = 3
	var/mob_fall_chance_mod = 1.5
	var/normal_gravity = 0

/datum/subsystem/gravity/New()
	NEW_SS_GLOBAL(SSgravity)

/datum/subsystem/gravity/Initialize()
	area_blacklist_typecache = typecacheof(area_blacklist)
	mob_slip_chance = mob_base_gravity_slip_chance
	mob_fall_chance = mob_base_gravity_fall_chance
	mob_slip_chance_handhold = mob_handhold_gravity_slip_chance
	mob_fall_chance_handhold = mob_handhold_gravity_fall_chance
	mob_slip_chance_mod = mob_gravity_strength_slip_mod
	mob_fall_chance_mod = mob_gravity_strength_fall_mod
	normal_gravity = legacy_gravity
	. = ..()

/datum/subsystem/gravity/Recover()
	Initialize()	//Force init..
	if(istype(SSgravity))
		do_purge = SSgravity.do_purge
		purge_interval = SSgravity.purge_interval
		error_no_atom = SSgravity.error_no_atom
		error_mismatched_area = SSgravity.error_mismatched_area
		error_mismatched_turf = SSgravity.error_mismatched_turf
		error_no_area = SSgravity.error_no_area
		error_no_turf = SSgravity.error_no_turf
	..()

/datum/subsystem/gravity/proc/sync_to_global_variables()
	world << "Syncing to global vars!"
	mob_base_gravity_slip_chance = mob_slip_chance
	mob_base_gravity_fall_chance = mob_fall_chance
	mob_handhold_gravity_slip_chance = mob_slip_chance_handhold
	mob_handhold_gravity_fall_chance = mob_fall_chance_handhold
	mob_gravity_strength_slip_mod = mob_slip_chance_mod
	mob_gravity_strength_fall_mod = mob_fall_chance_mod
	legacy_gravity = normal_gravity
	if(legacy_gravity)
		SSgravity.can_fire = FALSE
	else
		SSgravity.can_fire = TRUE

/datum/subsystem/gravity/vv_edit_var()
	..()
	sync_to_global_variables()

/datum/subsystem/gravity/SDQL_update()
	..()
	sync_to_global_variables()

/proc/emergency_reset_gravity_force_processing()
	var/count = 0
	while(atoms_forced_gravity_processing.len)
		var/atom/movable/AM = atoms_forced_gravity_processing[atoms_forced_gravity_processing.len]
		atoms_forced_gravity_processing.len--
		if(!istype(AM))
			if(SSgravity)
				SSgravity.error_no_atom++
			continue
		else
			AM.force_gravity_processing = FALSE
			count++
		CHECK_TICK
	LAZYCLEARLIST(atoms_forced_gravity_processing)
	var/atoms_not_found = "ERROR: NO SUBSYSTEM!"
	if(SSgravity)
		atoms_not_found = SSgravity.error_no_atom
	return "[count] atoms purged from forced processing! [atoms_not_found] things found so far that were not atoms!"

/datum/subsystem/gravity/proc/recalculate_atoms()
	currentrun = list()
	currentrun_manual = list()
	var/tempcost = REALTIMEOFDAY
	for(var/I in sortedAreas)
		var/area/A = I
		if(!A.has_gravity && !A.gravity_generator && !A.gravity_overriding)
			continue
		if(!A.gravity_direction)	//Right now we don't need this.
			continue
		if(is_type_in_typecache(A, area_blacklist_typecache))
			continue
		currentrun += A.contents_affected_by_gravity
	currentrun_manual = atoms_forced_gravity_processing.Copy()
	recalculation_cost = REALTIMEOFDAY - tempcost

/datum/subsystem/gravity/fire(resumed = FALSE)
	if(!resumed)
		if(legacy_gravity)
			can_fire = FALSE
			return FALSE
		recalculate_atoms()
		if(do_purge)
			purging = FALSE
			purge_tick++
			if(purge_tick >= purge_interval)
				purging_atoms = list()
				purging = TRUE
				purge_tick = 0
	while(currentrun_manual.len)
		var/atom/movable/AM = currentrun_manual[currentrun_manual.len]
		currentrun_manual.len--
		if(istype(AM))
			AM.gravity_tick += wait
			if(AM.gravity_tick >= AM.gravity_speed)
				AM.manual_gravity_process()
				AM.gravity_tick = 0
		else
			error_no_atom++
		if(purging && do_purge)
			purging_atoms += AM
		if(MC_TICK_CHECK)
			return
	while(currentrun.len)
		var/atom/movable/AM = currentrun[currentrun.len]
		currentrun.len--
		if(AM && !AM.force_gravity_processing)
			AM.gravity_tick += wait
			if(AM.gravity_tick >= AM.gravity_speed)
				AM.gravity_act()
				AM.gravity_tick = 0
		if(purging && do_purge)	//Only do laggy shit occasionally.
			purging_atoms += AM
		if(MC_TICK_CHECK)
			return
	if(purging && do_purge)
		while(purging_atoms.len)
			var/atom/movable/AM = purging_atoms[purging_atoms.len]
			purging_atoms.len--
			if(AM.gravity_ignores_turfcheck || isturf(AM.loc))
				var/current_area = get_area(AM)
				if(AM.current_gravity_area)
					if(AM.current_gravity_area != current_area)
						error_mismatched_area++
						AM.sync_gravity()
				else
					error_no_area++
					AM.sync_gravity()
			else
				error_no_turf++
				if(AM.current_gravity_area)
					AM.current_gravity_area.update_gravity(AM, FALSE)
				AM.sync_gravity()
