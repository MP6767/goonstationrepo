/obj/machinery/computer/engine/req_access = list(access_eject_engine)

/obj/machinery/computer/engine/ex_act(severity)
	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				for(var/x in src.verbs)
					src.verbs -= x
				src.icon_state = "broken"
		if(3.0)
			if (prob(25))
				for(var/x in src.verbs)
					src.verbs -= x
				src.icon_state = "broken"
		else
	return

/obj/machinery/computer/engine/New()
	if (!( engine_eject_control ))
		engine_eject_control = new /datum/engine_eject(  )
	..()

	spawn(5)
		for(var/obj/machinery/gas_sensor/G in machines)
			if(G.id == src.id)
				gs = G
				break
	return

/obj/machinery/computer/engine/attackby(var/obj/O, mob/user)
	return src.attack_hand(user)

/obj/machinery/computer/engine/attack_ai(var/mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/engine/attack_paw(var/mob/user as mob)

	return src.attack_hand(user)
	return

/obj/machinery/computer/engine/attack_hand(var/mob/user as mob)
	if(..())
		return
	user.machine = src
	var/dat
	if (src.temp)
		dat = "<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>"
	else
		if (engine_eject_control.status == 0)

			dat = "<B>Engine Gas Monitor</B><HR>"
			if(gs)
				dat += "[gs.sense_string()]"

			else
				dat += "No sensor found."


			dat += "<BR><B>Engine Ejection Module</B><HR>\nStatus: Docked<BR>\n<BR>\nCountdown: [engine_eject_control.timeleft]/60 <A href='?src=\ref[src];reset=1'>\[Reset\]</A><BR>\n<BR>\n<A href='?src=\ref[src];eject=1'>Eject Engine</A><BR>\n<BR>\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"
		else
			if (engine_eject_control.status == 1)
				dat = text("<B>Engine Ejection Module</B><HR>\nStatus: Ejecting<BR>\n<BR>\nCountdown: []/60 \[Reset\]<BR>\n<BR>\n<A href='?src=\ref[];stop=1'>Stop Ejection</A><BR>\n<BR>\n<A href='?src=\ref[];mach_close=computer'>Close</A>", engine_eject_control.timeleft, src, user)
			else
				dat = text("<B>Engine Ejection Module</B><HR>\nStatus: Ejected<BR>\n<BR>\nCountdown: N/60 \[Reset\]<BR>\n<BR>\nEngine Ejected!<BR>\n<BR>\n<A href='?src=\ref[];mach_close=computer'>Close</A>", user)
	user << browse(dat, "window=computer;size=400x500")
	return

/obj/machinery/computer/engine/process()
	if(stat & (NOPOWER|BROKEN))
		return
	use_power(250)
	src.updateDialog()
	return

/obj/machinery/computer/engine/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1 || usr.telekinesis == 1) && istype(src.loc, /turf))) || (istype(usr, /mob/ai)))
		usr.machine = src

		if (href_list["eject"])
			if (engine_eject_control.status == 0)
				src.temp = "Eject Engine?<BR><BR><B><A href='?src=\ref[src];eject2=1'>\[Swipe ID to initiate eject sequence\]</A></B><BR><A href='?src=\ref[src];temp=1'>Cancel</A>"

		else if (href_list["eject2"])
			var/obj/item/weapon/card/id/I = usr.equipped()
			if (istype(I))
				if(src.check_access(I))
					if (engine_eject_control.status == 0)
						engine_eject_control.ejectstart()
						src.temp = null
				else
					usr << "\red Access Denied."
		else if (href_list["stop"])
			if (engine_eject_control.status > 0)
				src.temp = text("Stop Ejection?<BR><BR><A href='?src=\ref[];stop2=1'>Yes</A><BR><A href='?src=\ref[];temp=1'>No</A>", src, src)

		else if (href_list["stop2"])
			if (engine_eject_control.status > 0)
				engine_eject_control.stopcount()
				src.temp = null

		else if (href_list["reset"])
			if (engine_eject_control.status == 0)
				engine_eject_control.resetcount()

		else if (href_list["temp"])
			src.temp = null

		src.add_fingerprint(usr)
	src.updateUsrDialog()
	return

/turf/station/engine/attack_paw(var/mob/user as mob)
	return src.attack_hand(user)

/turf/station/engine/attack_hand(var/mob/user as mob)
	if ((!( user.canmove ) || user.restrained() || !( user.pulling )))
		return
	if (user.pulling.anchored)
		return
	if ((user.pulling.loc != user.loc && get_dist(user, user.pulling) > 1))
		return
	if (ismob(user.pulling))
		var/mob/M = user.pulling
		var/mob/t = M.pulling
		M.pulling = null
		step(user.pulling, get_dir(user.pulling.loc, src))
		M.pulling = t
	else
		step(user.pulling, get_dir(user.pulling.loc, src))
	return

/turf/station/engine/floor/ex_act(severity)
	switch(severity)
		if(1.0)
			var/turf/space/S = src.ReplaceWithSpace()
			S.buildlinks()
			del(src)
			return
		if(2.0)
			if (prob(50))
				var/turf/space/S = src.ReplaceWithSpace()
				S.buildlinks()
				del(src)
				return
		else
	return

/turf/station/engine/floor/blob_act()
	if (prob(15))
		var/turf/space/S = src.ReplaceWithSpace()
		S.buildlinks()
		del(src)
		return
	return

/datum/engine_eject/proc/ejectstart()
	if (!( src.status ))
		if (src.timeleft <= 0)
			src.timeleft = 60
		world << "\red <B>Alert: Ejection Sequence for Engine Module has been engaged.</B>"
		world << text("\red <B>Ejection Time in T-[] seconds!</B>", src.timeleft)
		src.resetting = 0

		var/list/EA = engine_areas()

		for(var/area/A in EA)
			A.eject = 1
			A.updateicon()

		src.status = 1
		for(var/obj/machinery/computer/engine/E in machines)
			E.icon_state = "engaging"
			//Foreach goto(113)
		spawn( 0 )
			src.countdown()
			return
	return

/datum/engine_eject/proc/resetcount()

	if (!( src.status ))
		src.resetting = 1
	sleep(50)
	if (src.resetting)
		src.timeleft = 60
		world << "\red <B>Alert: Ejection Sequence Countdown for Engine Module has been reset.</B>"
	return

/datum/engine_eject/proc/countdone()

	src.status = -1.0

	var/list/E = engine_areas()

	var/list/engineturfs = list()
	for(var/area/EA in E)
		EA.eject = 0
		EA.updateicon()
		for(var/turf/ET in EA)
			engineturfs += ET

	defer_powernet_rebuild = 1
	for(var/turf/T in engineturfs)
		var/turf/S = new T.type( locate(T.x, T.y, ENGINE_EJECT_Z) )

		var/area/A = T.loc

		for(var/atom/movable/AM as mob|obj in T)
			AM.loc = S
			S.oxygen = T.oxygen
			S.oldoxy = T.oldoxy
			S.tmpoxy = T.tmpoxy
			S.poison = T.poison
			S.oldpoison = T.oldpoison
			S.tmppoison = T.tmppoison
			S.co2 = T.co2
			S.oldco2 = T.oldco2
			S.tmpco2 = T.tmpco2
			S.sl_gas = T.sl_gas
			S.osl_gas = T.osl_gas
			S.tsl_gas = T.tsl_gas
			S.n2 = T.n2
			S.on2 = T.on2
			S.tn2 = T.tn2
			S.temp = T.temp
			S.ttemp = T.ttemp
			S.otemp = T.otemp
			S.buildlinks()


		A.contents += S
		var/turf/P = new T.type( locate(T.x, T.y, T.z) )
		var/area/D = locate(/area/dummy)
		D.contents += P

		//T = null

		del(T)
		P.buildlinks()

	defer_powernet_rebuild = 0
	makepowernets()
	world << "\red <B>Engine Ejected!</B>"
	for(var/obj/machinery/computer/engine/CE in machines)
		CE.icon_state = "engaged"
	return

/datum/engine_eject/proc/stopcount()

	if (src.status > 0)
		src.status = 0
		world << "\red <B>Alert: Ejection Sequence for Engine Module has been disengaged!</B>"

		var/list/E = engine_areas()

		for(var/area/A in E)
			A.eject = 0
			A.updateicon()

		for(var/obj/machinery/computer/engine/CE in machines)
			CE.icon_state = null
			//Foreach goto(84)
	return

/datum/engine_eject/proc/countdown()

	if (src.timeleft <= 0)
		spawn( 0 )
			countdone()
			return
		return
	if (src.status > 0)
		src.timeleft--
		if ((src.timeleft <= 15 || src.timeleft == 30))
			world << text("\red <B>[] seconds until engine ejection.</B>", src.timeleft)
		spawn( 10 )
			src.countdown()
			return
	return


//returns a list of areas that are under /area/engine
/datum/engine_eject/proc/engine_areas()
	var/list/L = list()
	for(var/area/A in world)
		if(istype(A, /area/engine))
			L += A

	return L

/obj/machinery/gas_sensor/proc/sense_string()

	var/t = ""

	var/turf/T = src.loc

	var/turf_total = T.tot_gas()

	var/t1 = add_tspace("[round(turf_total / CELLSTANDARD * 100, 0.1)]%",6)
	t += "<PRE>Pressure: [t1] Temperature: [round(T.temp - T0C,0.1)]&deg;C<BR>"

	if(turf_total == 0)
		t+="O2: 0 N2: 0 CO2: 0><BR>Plasma: 0 N20: 0"
	else
		t1 = add_tspace(round(T.oxygen/turf_total * 100, 0.1),5)

		t += "O2: [t1] "

		t1 = add_tspace(round(T.n2/turf_total * 100, 0.1),5)

		t += "N2: [t1] "

		t1 = add_tspace(round(T.co2/turf_total * 100, 0.01),5)

		t += "CO2: [t1]<BR>"

		t1 = add_tspace(round(T.poison/turf_total * 100, 0.001),5)

		t += "Plasma: [t1] "

		t1 = add_tspace(round(T.sl_gas/turf_total * 100, 0.001),5)

		t += "N2O: [t1]"

	t += "</PRE>"

	return t