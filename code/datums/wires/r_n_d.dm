/datum/wires/r_n_d
	holder_type = /obj/machinery/rnd
	randomize = TRUE

/datum/wires/r_n_d/New(atom/holder)
	wires = list(
		WIRE_HACK, WIRE_DISABLE,
		WIRE_SHOCK
	)
	add_duds(5)
	..()

/datum/wires/r_n_d/interactable(mob/user)
	var/obj/machinery/rnd/R = holder
	if(R.panel_open)
		return TRUE

/datum/wires/r_n_d/get_status()
	var/obj/machinery/rnd/R = holder
	var/list/status = list()
	status += "The red light is [R.disabled ? "off" : "on"]."
	status += "The green light is [R.shocked ? "off" : "on"]."
	status += "The blue light is [R.hacked ? "off" : "on"]."
	return status

/datum/wires/r_n_d/on_pulse(wire)
	set waitfor = FALSE
	var/obj/machinery/rnd/R = holder
	switch(wire)
		if(WIRE_HACK)
			R.hacked = !R.hacked
		if(WIRE_DISABLE)
			R.disabled = !R.disabled
		if(WIRE_SHOCK)
			R.shocked = TRUE
			sleep(100)
			if(R)
				R.shocked = FALSE

/datum/wires/r_n_d/on_cut(wire, mend)
	var/obj/machinery/rnd/R = holder
	switch(wire)
		if(WIRE_HACK)
			R.hacked = !mend
		if(WIRE_DISABLE)
			R.disabled = !mend
		if(WIRE_SHOCK)
			R.shocked = !mend
