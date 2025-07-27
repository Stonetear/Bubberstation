/obj/item/circuitboard/machine/meteor_magnet
	name = "Meteor Magnet"
	desc = "The powerator is a machine that allows stations to sell their power to other stations that require additional sources."
	greyscale_colors = CIRCUIT_COLOR_GENERIC
	build_path = /obj/machinery/powerator
	req_components = list(
		/obj/item/stack/sheet/plasteel = 10,
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 10,
		/obj/item/assembly/signaler/anomaly/grav = 1,
	)
	needs_anchored = TRUE

/datum/supply_pack/engineering/meteor_magnet
name = "Meteor Magnet control board"
desc = "A machine capable of pulling meterors into the station.  Sounds dangerous."
cost = CARGO_CRATE_VALUE * 25 // 5,000
contains = list(/obj/item/circuitboard/machine/meteor_magnet)
crate_name = "Station destroyer 5000 parts kit"
crate_type = /obj/structure/closet/crate/engineering

/obj/machinery/meteor_magnet
	name = "Meteor Magnet"
	desc = "An absolutely massive gravionic-electromagnet machine capable of pulling meteors out of their orbit."
	icon = 'modular_zubbers/icons/obj/machines/nanite_machines.dmi' // Temporary
	icon_state = "nanite_program_hub" // Temporary

	/// the attached cable to the machine
	var/obj/structure/cable/attached_cable
	/// precent to attract current meteor
	var/meteor_progress = 0
	/// Max power draw
	var/max_power_draw = 100 KILO WATTS
	/// Is the machine active?
	var/active = FALSE
	/// Should we repeat?
	var/repeat_pull = FALSE
	/// current meteor type
	var/meteor_type
	///Possible meteor types
	var/list/possible_types = list(
		/obj/effect/meteor/dust = 10 KILO WATTS,
		/obj/effect/meteor/medium = 500 KILO WATTS,
		/obj/effect/meteor/big = 800 KILO WATTS,
		/obj/effect/meteor/flaming = 800 KILO WATTS,
		/obj/effect/meteor/irradiated = 800 KILO WATTS,
		/obj/effect/meteor/cluster = 800 KILO WATTS,
		/obj/effect/meteor/carp = 800 KILO WATTS,
		/obj/effect/meteor/bluespace = 800 KILO WATTS,
		/obj/effect/meteor/banana = 1 MEGA WATTS,
		/obj/effect/meteor/emp = 1 MEGA WATTS,
		/obj/effect/meteor/meaty = 500 KILO WATTS,
		/obj/effect/meteor/meaty/xeno = 500 KILO WATTS,
		/obj/effect/meteor/tunguska = 500 MEGA WATTS // lol
	) // to do: add more meteor types



/obj/machinery/meteor_magnet/Initialize(mapload)
	. = ..()
	register_context() //not sure if I need this


/obj/machinery/meteor_magnet/ui_state(mob/user)
	return GLOB.physical_state


/obj/machinery/meteor_magnet/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MeteorMagnetUI", name) // placeholder

/obj/machinery/meteor_magnet/ui_data()
	var/list/data = list()
	var/list/meteor_names = list()
	for var/obj/effect/meteor/pos_meteor_type in possible_types:
		meteor_names = pos_meteor_type.name



	data["max_power"] = max_power_draw
	data["meteor_progress"] = meteor_progress
	data["possible_meteors"] = meteor_names
	data["repeat_pull"] = repeat_pull
	if(meteor_type)
		data["meteor_type"] = meteor_type
	return data

/obj/machinery/meteor_magnet/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("activate")
			active = TRUE
			. = TRUE
		if("set_target")
			var/meteor_name = params["target_meteor_type"]
			for(var/obj/effect/meteor/req_meteor_type in possible_types)
				if(meteor_name == req_meteor_type.name)
					meteor_type = req_meteor_type
					. = TRUE
				else:
					. = FALSE



	update_appearance()


/obj/machinery/meteor_magnet/RefreshParts()
	. = ..()
	var/efficiency = 1
	max_power = 100 KILO WATTS
	for(var/datum/stock_part/capacitor/capacitor_part in component_parts)
		efficiency += capacitor_part.tier
	max_power += (efficiency * 1650 KILO WATTS)



/obj/machinery/meteor_magnet/process()
	update_appearance()
	attached_cable = locate() in src_turf
	if(machine_stat & (NOPOWER | BROKEN) || !anchored || panel_open || !attached_cable) //no power, broken, unanchored, maint panel open, or no cable? lets reset
		return

	if(!attached_cable)
		return

	if(current_power <= 0)
		current_power = 0 //this is just for the fringe case, wouldn't want it to somehow produce power for money! unless...
		return

	if(!attached_cable.avail(current_power))
		if(!attached_cable.newavail())
			return
		current_power = attached_cable.newavail()
	attached_cable.add_delayedload(current_power)

