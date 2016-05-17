/*
 * Paper
 * also scraps of paper
 */

/obj/item/weapon/paper
	name = "paper"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	throwforce = 0
	w_class = 1.0
	throw_range = 1
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	slot_flags = SLOT_HEAD
	body_parts_covered = HEAD
	attack_verb = list("bapped")

	var/info		//What's actually written on the paper.
	var/info_links	//A different version of the paper which includes html links at fields and EOF
	var/stamps		//The (text for the) stamps on the paper.
	var/fields		//Amount of user created fields
	var/list/stamped
	var/list/signatures = list()
	var/ico[0]      //Icons and
	var/offset_x[0] //offsets stored for later
	var/offset_y[0] //usage by the photocopier
	var/rigged = 0
	var/spam_flag = 0
	var/encode_html = 1

	var/deffont = "Verdana"
	var/const/signfont = "Times New Roman"
	var/const/crayonfont = "Comic Sans MS"

//lipstick wiping is in code/game/objects/items/weapons/cosmetics.dm!

/obj/item/weapon/paper/New()
	..()
	pixel_y = rand(-8, 8)
	pixel_x = rand(-9, 9)
	stamps = ""

	if(name != "paper")
		desc = "This is a paper titled '" + name + "'."

	if( encode_html && info != initial(info))
		info = html_encode(info)
		info = replacetext(info, "\n", "<BR>")
		info = parsepencode(info)

	spawn(2)
		update_icon()
		updateinfolinks()
		return

/obj/item/weapon/paper/update_icon()
	if(icon_state == "paper_talisman")
		return
	if(info)
		icon_state = "paper_words"
		return
	icon_state = "paper"

/obj/item/weapon/paper/examine(mob/user)
	..()
	if(in_range(user, src) || istype(user, /mob/dead/observer))
		show_content(usr)
	else
		user << "<span class='notice'>You have to go closer if you want to read it.</span>"
	return

/obj/item/weapon/paper/proc/show_content(var/mob/user, var/forceshow=0)
	if(!(istype(user, /mob/living/carbon/human) || istype(user, /mob/dead/observer) || istype(user, /mob/living/silicon)) && !forceshow)
		user << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[stars(info)][stamps]</BODY></HTML>", "window=[name]")
		onclose(user, "[name]")
	else
		user << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[info][stamps]</BODY></HTML>", "window=[name]")
		onclose(user, "[name]")

/obj/item/weapon/paper/verb/rename()
	set name = "Rename paper"
	set category = "Object"
	set src in usr

	if((CLUMSY in usr.mutations) && prob(50))
		usr << "<span class='warning'>You cut yourself on the paper.</span>"
		return
	var/n_name = sanitizeSafe(input(usr, "What would you like to label the paper?", "Paper Labelling", null)  as text, MAX_NAME_LEN)
	if((loc == usr && usr.stat == 0))
		name = "[(n_name ? text("[n_name]") : initial(name))]"
	if(name != "paper")
		desc = "This is a paper titled '" + name + "'."
	add_fingerprint(usr)
	return

/obj/item/weapon/paper/attack_self(mob/living/user as mob)
	user.examinate(src)
	if(rigged && (Holiday == "April Fool's Day"))
		if(spam_flag == 0)
			spam_flag = 1
			playsound(loc, 'sound/items/bikehorn.ogg', 50, 1)
			spawn(20)
				spam_flag = 0
	return

/obj/item/weapon/paper/attack_ai(var/mob/living/silicon/ai/user as mob)
	var/dist
	if(istype(user) && user.camera) //is AI
		dist = get_dist(src, user.camera)
	else //cyborg or AI not seeing through a camera
		dist = get_dist(src, user)
	if(dist < 2)
		usr << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[info][stamps]</BODY></HTML>", "window=[name]")
		onclose(usr, "[name]")
	else
		usr << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[stars(info)][stamps]</BODY></HTML>", "window=[name]")
		onclose(usr, "[name]")
	return

/obj/item/weapon/paper/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(user.zone_sel.selecting == "eyes")
		user.visible_message("<span class='notice'>You show the paper to [M]. </span>", \
			"<span class='notice'>[user] holds up a paper and shows it to [M]. </span>")
		M.examinate(src)

	else if(user.zone_sel.selecting == "mouth") // lipstick wiping
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H == user)
				user << "<span class='notice'>You wipe off the lipstick with [src].</span>"
				H.lip_style = null
				H.update_body()
			else
				user.visible_message("<span class='warning'>[user] begins to wipe [H]'s lipstick off with \the [src].</span>", \
								 	 "<span class='notice'>You begin to wipe off [H]'s lipstick.</span>")
				if(do_after(user, 10) && do_after(H, 10, 5, 0))	//user needs to keep their active hand, H does not.
					user.visible_message("<span class='notice'>[user] wipes [H]'s lipstick off with \the [src].</span>", \
										 "<span class='notice'>You wipe off [H]'s lipstick.</span>")
					H.lip_style = null
					H.update_body()

/obj/item/weapon/paper/proc/addtofield(var/id, var/text, var/links = 0)
	var/locid = 0
	var/laststart = 1
	var/textindex = 1
	while(1) // I know this can cause infinite loops and fuck up the whole server, but the if(istart==0) should be safe as fuck
		var/istart = 0
		if(links)
			istart = findtext(info_links, "<span class=\"paper_field\">", laststart)
		else
			istart = findtext(info, "<span class=\"paper_field\">", laststart)

		if(istart==0)
			return // No field found with matching id

		laststart = istart+1
		locid++
		if(locid == id)
			var/iend = 1
			if(links)
				iend = findtext(info_links, "</span>", istart)
			else
				iend = findtext(info, "</span>", istart)

			//textindex = istart+26
			textindex = iend
			break

	if(links)
		var/before = copytext(info_links, 1, textindex)
		var/after = copytext(info_links, textindex)
		info_links = before + text + after
	else
		var/before = copytext(info, 1, textindex)
		var/after = copytext(info, textindex)
		info = before + text + after
		updateinfolinks()

/obj/item/weapon/paper/proc/updateinfolinks()
	info_links = info
	var/i = 0
	for(i=1,i<=fields,i++)
		addtofield(i, "<font face=\"[deffont]\"><A href='?src=\ref[src];write=[i]'>write</A></font>", 1)
	info_links = info_links + "<font face=\"[deffont]\"><A href='?src=\ref[src];write=end'>write</A></font>"


/obj/item/weapon/paper/proc/clearpaper()
	info = null
	stamps = null
	stamped = list()
	signatures = list()
	overlays.Cut()
	updateinfolinks()
	update_icon()

/obj/item/weapon/paper/proc/get_signature(var/obj/item/weapon/pen/P, mob/user as mob)
	var/signature

	if(P && istype(P, /obj/item/weapon/pen))
		signature = P.get_signature(user)
	else
		signature = (user && user.real_name) ? user.real_name : "Anonymous"

	signatures += signature

	return signature

/obj/item/weapon/paper/proc/parsepencode(var/t, var/obj/item/weapon/pen/P, mob/user as mob, var/iscrayon = 0)
//	t = copytext(sanitize(t),1,MAX_MESSAGE_LEN)

	t = replacetext(t, "\[center\]", "<center>")
	t = replacetext(t, "\[/center\]", "</center>")
	t = replacetext(t, "\[br\]", "<BR>")
	t = replacetext(t, "\[b\]", "<B>")
	t = replacetext(t, "\[/b\]", "</B>")
	t = replacetext(t, "\[i\]", "<I>")
	t = replacetext(t, "\[/i\]", "</I>")
	t = replacetext(t, "\[u\]", "<U>")
	t = replacetext(t, "\[/u\]", "</U>")
	t = replacetext(t, "\[large\]", "<font size=\"4\">")
	t = replacetext(t, "\[/large\]", "</font>")
	t = replacetext(t, "\[sign\]", "<font face=\"[signfont]\"><i>[get_signature(P, user)]</i></font>")
	t = replacetext(t, "\[field\]", "<span class=\"paper_field\"></span>")

	t = replacetext(t, "\[h1\]", "<H1>")
	t = replacetext(t, "\[/h1\]", "</H1>")
	t = replacetext(t, "\[h2\]", "<H2>")
	t = replacetext(t, "\[/h2\]", "</H2>")
	t = replacetext(t, "\[h3\]", "<H3>")
	t = replacetext(t, "\[/h3\]", "</H3>")

	if(!iscrayon)
		t = replacetext(t, "\[*\]", "<li>")
		t = replacetext(t, "\[hr\]", "<HR>")
		t = replacetext(t, "\[small\]", "<font size = \"1\">")
		t = replacetext(t, "\[/small\]", "</font>")
		t = replacetext(t, "\[list\]", "<ul>")
		t = replacetext(t, "\[/list\]", "</ul>")
		t = replacetext(t, "\[table\]", "<table border=1 cellspacing=0 cellpadding=3 style='border: 1px solid black;'>")
		t = replacetext(t, "\[/table\]", "</td></tr></table>")
		t = replacetext(t, "\[grid\]", "<table>")
		t = replacetext(t, "\[/grid\]", "</td></tr></table>")
		t = replacetext(t, "\[row\]", "</td><tr>")
		t = replacetext(t, "\[cell\]", "<td>")
		t = replacetext(t, "\[time]", "<font face=\"[signfont]\"><i>[worldtime2text()]</i></font>")	// Adds ability to add a timestamp for added document security.
		t = replacetext(t, "\[date]", "<font face=\"[signfont]\"><i>[print_date( universe.date )]</i></font>")	// Adds ability to add a timestamp for added document security.
		t = replacetext(t, "\[logo\]", "<img src = logo-nt.png>")
		t = replacetext(t, "\[apollo\]", "<img src = logo-apollo.png>")
		t = replacetext(t, "\[antilogo\]", "<img src = logo-anti.png>")	// Adds alternative anti-NT logo.
		t = replacetext(t, "\[barcode\]", "<img src = barcode.png>")

		t = "<font face=\"[deffont]\" color=[P ? P.colour : "black"]>[t]</font>"
	else // If it is a crayon, and he still tries to use these, make them empty!
		t = replacetext(t, "\[*\]", "")
		t = replacetext(t, "\[hr\]", "")
		t = replacetext(t, "\[small\]", "")
		t = replacetext(t, "\[/small\]", "")
		t = replacetext(t, "\[list\]", "")
		t = replacetext(t, "\[/list\]", "")
		t = replacetext(t, "\[table\]", "")
		t = replacetext(t, "\[/table\]", "")
		t = replacetext(t, "\[row\]", "")
		t = replacetext(t, "\[cell\]", "")
		t = replacetext(t, "\[logo\]", "")
		t = replacetext(t, "\[apollo\]", "")
		t = replacetext(t, "\[antilogo\]", "")	// Adds alternative anti-NT logo.

		t = "<font face=\"[crayonfont]\" color=[P ? P.colour : "black"]><b>[t]</b></font>"

//	t = replacetext(t, "#", "") // Junk converted to nothing!

//Count the fields
	var/laststart = 1
	while(1)
		var/i = findtext(t, "<span class=\"paper_field\">", laststart)
		if(i==0)
			break
		laststart = i+1
		fields++

	return t


/obj/item/weapon/paper/proc/openhelp(mob/user as mob)
	user << browse({"<HTML><HEAD><TITLE>Pen Help</TITLE></HEAD>
	<BODY>
		<b><center>Crayon&Pen commands</center></b><br>
		<br>
		\[br\] : Creates a linebreak.<br>
		\[center\] - \[/center\] : Centers the text.<br>
		\[h1\] - \[/h1\] : Makes the text a first level heading<br>
		\[h2\] - \[/h2\] : Makes the text a second level heading<br>
		\[h3\] - \[/h3\] : Makes the text a third level heading<br>
		\[b\] - \[/b\] : Makes the text <b>bold</b>.<br>
		\[i\] - \[/i\] : Makes the text <i>italic</i>.<br>
		\[u\] - \[/u\] : Makes the text <u>underlined</u>.<br>
		\[large\] - \[/large\] : Increases the <font size = \"4\">size</font> of the text.<br>
		\[sign\] : Inserts a signature of your name in a foolproof way.<br>
		\[field\] : Inserts an invisible field which lets you start type from there. Useful for forms.<br>
		<br>
		<b><center>Pen exclusive commands</center></b><br>
		\[small\] - \[/small\] : Decreases the <font size = \"1\">size</font> of the text.<br>
		\[list\] - \[/list\] : A list.<br>
		\[*\] : A dot used for lists.<br>
		\[hr\] : Adds a horizontal rule.
	</BODY></HTML>"}, "window=paper_help")

/obj/item/weapon/paper/proc/burnpaper(obj/item/weapon/flame/P, mob/user)
	var/class = "<span class='warning'>"

	if(P.lit && !user.restrained())
		if(istype(P, /obj/item/weapon/flame/lighter/zippo))
			class = "<span class='rose'>"

		user.visible_message("[class][user] holds \the [P] up to \the [src], it looks like \he's trying to burn it!", \
		"[class]You hold \the [P] up to \the [src], burning it slowly.")

		spawn(20)
			if(get_dist(src, user) < 2 && user.get_active_hand() == P && P.lit)
				user.visible_message("[class][user] burns right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.", \
				"[class]You burn right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.")

				if(user.get_inactive_hand() == src)
					user.drop_from_inventory(src)

				new /obj/effect/decal/cleanable/ash(src.loc)
				qdel(src)

			else
				user << "<span class='alert'>You must hold \the [P] steady to burn \the [src].</span>"


/obj/item/weapon/paper/Topic(href, href_list)
	..()
	if(!usr || (usr.stat || usr.restrained()))
		return

	if(href_list["write"])
		var/id = href_list["write"]
		var/t = sanitize(input("Enter what you want to write:", "Write", null, null) as message, MAX_PAPER_MESSAGE_LEN, extra = 0)
		var/textlimit = MAX_PAPER_MESSAGE_LEN - length(info)
		if(textlimit <= 0)
			usr << "<span class='info'>You're trying to find a free place on paper, but can't!</span>"
			return

		if(!t)
			return

		var/obj/item/i = usr.get_active_hand() // Check to see if he still got that darn pen, also check if he's using a crayon or pen.
		var/iscrayon = 0
		if(!istype(i, /obj/item/weapon/pen))
			if(!istype(i, /obj/item/toy/crayon))
				return
			iscrayon = 1


		// if paper is not in usr, then it must be near them, or in a clipboard or folder, which must be in or near usr
		if(src.loc != usr && !src.Adjacent(usr) && !((istype(src.loc, /obj/item/weapon/clipboard) || istype(src.loc, /obj/item/weapon/folder)) && (src.loc.loc == usr || src.loc.Adjacent(usr)) ) )
			return
/*
		t = checkhtml(t)

		// check for exploits
		for(var/bad in paper_blacklist)
			if(findtext(t,bad))
				usr << "<span class='notice'>You think to yourself, \"Hm.. this is only paper...\"</span>"
				log_admin("PAPER: [usr] ([usr.ckey]) tried to use forbidden word in [src]: [bad].")
				message_admins("PAPER: [usr] ([usr.ckey]) tried to use forbidden word in [src]: [bad].")
				return
*/
		var last_fields_value = fields
		//t = html_encode(t)

		t = replacetext(t, "\n", "<BR>")
		t = parsepencode(t, i, usr, iscrayon) // Encode everything from pencode to html


		if(fields > 50)//large amount of fields creates a heavy load on the server, see updateinfolinks() and addtofield()
			usr << "<span class='warning'>Too many fields. Sorry, you can't do this.</span>"
			fields = last_fields_value
			return

		if(id!="end")
			addtofield(text2num(id), t) // He wants to edit a field, let him.
		else
			info += t // Oh, he wants to edit to the end of the file, let him.
			updateinfolinks()

		usr << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[info_links][stamps]</BODY></HTML>", "window=[name]") // Update the window

		update_icon()

/obj/item/weapon/paper/proc/WriteWindow( var/user )
	user << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY>[info_links][stamps]</BODY></HTML>", "window=[name]")

/obj/item/weapon/paper/attackby(obj/item/weapon/P as obj, mob/user as mob)
	..()
	var/clown = 0
	if(user.mind && (user.mind.assigned_role == "Clown"))
		clown = 1

	if(istype(P, /obj/item/weapon/tape_roll))
		var/obj/item/weapon/tape_roll/tape = P
		tape.stick(src, user)
		return

	if(istype(P, /obj/item/weapon/paper) || istype(P, /obj/item/weapon/photo))
		if (istype(P, /obj/item/weapon/paper/carbon))
			var/obj/item/weapon/paper/carbon/C = P
			if (!C.iscopy && !C.copied)
				user << "<span class='notice'>Take off the carbon copy first.</span>"
				add_fingerprint(user)
				return
		var/obj/item/weapon/paper_bundle/B = new(src.loc)
		if (name != "paper")
			B.name = name
		else if (P.name != "paper" && P.name != "photo")
			B.name = P.name
		user.drop_from_inventory(P)
		if (istype(user, /mob/living/carbon/human))
			var/mob/living/carbon/human/h_user = user
			if (h_user.r_hand == src)
				h_user.drop_from_inventory(src)
				h_user.put_in_r_hand(B)
			else if (h_user.l_hand == src)
				h_user.drop_from_inventory(src)
				h_user.put_in_l_hand(B)
			else if (h_user.l_store == src)
				h_user.drop_from_inventory(src)
				B.loc = h_user
				B.layer = 20
				h_user.l_store = B
				h_user.update_inv_pockets()
			else if (h_user.r_store == src)
				h_user.drop_from_inventory(src)
				B.loc = h_user
				B.layer = 20
				h_user.r_store = B
				h_user.update_inv_pockets()
			else if (h_user.head == src)
				h_user.u_equip(src)
				h_user.put_in_hands(B)
			else if (!istype(src.loc, /turf))
				src.loc = get_turf(h_user)
				if(h_user.client)	h_user.client.screen -= src
				h_user.put_in_hands(B)
		user << "<span class='notice'>You clip the [P.name] to [(src.name == "paper") ? "the paper" : src.name].</span>"
		src.loc = B
		P.loc = B
		B.amount++
		B.update_icon()

	else if(istype(P, /obj/item/weapon/pen) || istype(P, /obj/item/toy/crayon))
		if ( istype(P, /obj/item/weapon/pen/robopen) && P:mode == 2 )
			P:RenamePaper(user,src)
		else
			WriteWindow( user )
		//openhelp(user)
		return

	else if(istype(P, /obj/item/weapon/stamp))
		if((!in_range(src, usr) && loc != user && !( istype(loc, /obj/item/weapon/clipboard) ) && loc.loc != user && user.get_active_hand() != P))
			return

		stamps += (stamps=="" ? "<HR>" : "<BR>") + "<i>This paper has been stamped with the [P.name].</i>"

		var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
		var/{x; y;}
		if(istype(P, /obj/item/weapon/stamp/captain) || istype(P, /obj/item/weapon/stamp/centcomm))
			x = rand(-2, 0)
			y = rand(-1, 2)
		else
			x = rand(-2, 2)
			y = rand(-3, 2)
		offset_x += x
		offset_y += y
		stampoverlay.pixel_x = x
		stampoverlay.pixel_y = y

		if(istype(P, /obj/item/weapon/stamp/clown))
			if(!clown)
				user << "<span class='notice'>You are totally unable to use the stamp. HONK!</span>"
				return

		if(!ico)
			ico = new
		ico += "paper_[P.icon_state]"
		stampoverlay.icon_state = "paper_[P.icon_state]"

		if(!stamped)
			stamped = new
		stamped += P.type
		overlays += stampoverlay

		user << "<span class='notice'>You stamp the paper with your rubber stamp.</span>"

	else if(istype(P, /obj/item/weapon/flame))
		burnpaper(P, user)

	add_fingerprint(user)
	return

/*
 * Premade paper
 */
/obj/item/weapon/paper/Court
	name = "Judgement"
	info = "For crimes against the station, the offender is sentenced to:<BR>\n<BR>\n"

/obj/item/weapon/paper/Toxin
	name = "Chemical Information"
	info = "Known Onboard Toxins:<BR>\n\tGrade A Semi-Liquid Phoron:<BR>\n\t\tHighly poisonous. You cannot sustain concentrations above 15 units.<BR>\n\t\tA gas mask fails to filter phoron after 50 units.<BR>\n\t\tWill attempt to diffuse like a gas.<BR>\n\t\tFiltered by scrubbers.<BR>\n\t\tThere is a bottled version which is very different<BR>\n\t\t\tfrom the version found in canisters!<BR>\n<BR>\n\t\tWARNING: Highly Flammable. Keep away from heat sources<BR>\n\t\texcept in a enclosed fire area!<BR>\n\t\tWARNING: It is a crime to use this without authorization.<BR>\nKnown Onboard Anti-Toxin:<BR>\n\tAnti-Toxin Type 01P: Works against Grade A Phoron.<BR>\n\t\tBest if injected directly into bloodstream.<BR>\n\t\tA full injection is in every regular Med-Kit.<BR>\n\t\tSpecial toxin Kits hold around 7.<BR>\n<BR>\nKnown Onboard Chemicals (other):<BR>\n\tRejuvenation T#001:<BR>\n\t\tEven 1 unit injected directly into the bloodstream<BR>\n\t\t\twill cure paralysis and sleep phoron.<BR>\n\t\tIf administered to a dying patient it will prevent<BR>\n\t\t\tfurther damage for about units*3 seconds.<BR>\n\t\t\tit will not cure them or allow them to be cured.<BR>\n\t\tIt can be administeredd to a non-dying patient<BR>\n\t\t\tbut the chemicals disappear just as fast.<BR>\n\tSoporific T#054:<BR>\n\t\t5 units wilkl induce precisely 1 minute of sleep.<BR>\n\t\t\tThe effect are cumulative.<BR>\n\t\tWARNING: It is a crime to use this without authorization"

/obj/item/weapon/paper/courtroom
	name = "A Crash Course in Legal SOP on SS13"
	info = "<B>Roles:</B><BR>\nThe Detective is basically the investigator and prosecutor.<BR>\nThe Staff Assistant can perform these functions with written authority from the Detective.<BR>\nThe Captain/HoP/Warden is ct as the judicial authority.<BR>\nThe Security Officers are responsible for executing warrants, security during trial, and prisoner transport.<BR>\n<BR>\n<B>Investigative Phase:</B><BR>\nAfter the crime has been committed the Detective's job is to gather evidence and try to ascertain not only who did it but what happened. He must take special care to catalogue everything and don't leave anything out. Write out all the evidence on paper. Make sure you take an appropriate number of fingerprints. IF he must ask someone questions he has permission to confront them. If the person refuses he can ask a judicial authority to write a subpoena for questioning. If again he fails to respond then that person is to be jailed as insubordinate and obstructing justice. Said person will be released after he cooperates.<BR>\n<BR>\nONCE the FT has a clear idea as to who the criminal is he is to write an arrest warrant on the piece of paper. IT MUST LIST THE CHARGES. The FT is to then go to the judicial authority and explain a small version of his case. If the case is moderately acceptable the authority should sign it. Security must then execute said warrant.<BR>\n<BR>\n<B>Pre-Pre-Trial Phase:</B><BR>\nNow a legal representative must be presented to the defendant if said defendant requests one. That person and the defendant are then to be given time to meet (in the jail IS ACCEPTABLE). The defendant and his lawyer are then to be given a copy of all the evidence that will be presented at trial (rewriting it all on paper is fine). THIS IS CALLED THE DISCOVERY PACK. With a few exceptions, THIS IS THE ONLY EVIDENCE BOTH SIDES MAY USE AT TRIAL. IF the prosecution will be seeking the death penalty it MUST be stated at this time. ALSO if the defense will be seeking not guilty by mental defect it must state this at this time to allow ample time for examination.<BR>\nNow at this time each side is to compile a list of witnesses. By default, the defendant is on both lists regardless of anything else. Also the defense and prosecution can compile more evidence beforehand BUT in order for it to be used the evidence MUST also be given to the other side.\nThe defense has time to compile motions against some evidence here.<BR>\n<B>Possible Motions:</B><BR>\n1. <U>Invalidate Evidence-</U> Something with the evidence is wrong and the evidence is to be thrown out. This includes irrelevance or corrupt security.<BR>\n2. <U>Free Movement-</U> Basically the defendant is to be kept uncuffed before and during the trial.<BR>\n3. <U>Subpoena Witness-</U> If the defense presents god reasons for needing a witness but said person fails to cooperate then a subpoena is issued.<BR>\n4. <U>Drop the Charges-</U> Not enough evidence is there for a trial so the charges are to be dropped. The FT CAN RETRY but the judicial authority must carefully reexamine the new evidence.<BR>\n5. <U>Declare Incompetent-</U> Basically the defendant is insane. Once this is granted a medical official is to examine the patient. If he is indeed insane he is to be placed under care of the medical staff until he is deemed competent to stand trial.<BR>\n<BR>\nALL SIDES MOVE TO A COURTROOM<BR>\n<B>Pre-Trial Hearings:</B><BR>\nA judicial authority and the 2 sides are to meet in the trial room. NO ONE ELSE BESIDES A SECURITY DETAIL IS TO BE PRESENT. The defense submits a plea. If the plea is guilty then proceed directly to sentencing phase. Now the sides each present their motions to the judicial authority. He rules on them. Each side can debate each motion. Then the judicial authority gets a list of crew members. He first gets a chance to look at them all and pick out acceptable and available jurors. Those jurors are then called over. Each side can ask a few questions and dismiss jurors they find too biased. HOWEVER before dismissal the judicial authority MUST agree to the reasoning.<BR>\n<BR>\n<B>The Trial:</B><BR>\nThe trial has three phases.<BR>\n1. <B>Opening Arguments</B>- Each side can give a short speech. They may not present ANY evidence.<BR>\n2. <B>Witness Calling/Evidence Presentation</B>- The prosecution goes first and is able to call the witnesses on his approved list in any order. He can recall them if necessary. During the questioning the lawyer may use the evidence in the questions to help prove a point. After every witness the other side has a chance to cross-examine. After both sides are done questioning a witness the prosecution can present another or recall one (even the EXACT same one again!). After prosecution is done the defense can call witnesses. After the initial cases are presented both sides are free to call witnesses on either list.<BR>\nFINALLY once both sides are done calling witnesses we move onto the next phase.<BR>\n3. <B>Closing Arguments</B>- Same as opening.<BR>\nThe jury then deliberates IN PRIVATE. THEY MUST ALL AGREE on a verdict. REMEMBER: They mix between some charges being guilty and others not guilty (IE if you supposedly killed someone with a gun and you unfortunately picked up a gun without authorization then you CAN be found not guilty of murder BUT guilty of possession of illegal weaponry.). Once they have agreed they present their verdict. If unable to reach a verdict and feel they will never they call a deadlocked jury and we restart at Pre-Trial phase with an entirely new set of jurors.<BR>\n<BR>\n<B>Sentencing Phase:</B><BR>\nIf the death penalty was sought (you MUST have gone through a trial for death penalty) then skip to the second part. <BR>\nI. Each side can present more evidence/witnesses in any order. There is NO ban on emotional aspects or anything. The prosecution is to submit a suggested penalty. After all the sides are done then the judicial authority is to give a sentence.<BR>\nII. The jury stays and does the same thing as I. Their sole job is to determine if the death penalty is applicable. If NOT then the judge selects a sentence.<BR>\n<BR>\nTADA you're done. Security then executes the sentence and adds the applicable convictions to the person's record.<BR>\n"

/obj/item/weapon/paper/hydroponics
	name = "Greetings from Billy Bob"
	info = "<B>Hey fellow botanist!</B><BR>\n<BR>\nI didn't trust the station folk so I left<BR>\na couple of weeks ago. But here's some<BR>\ninstructions on how to operate things here.<BR>\nYou can grow plants and each iteration they become<BR>\nstronger, more potent and have better yield, if you<BR>\nknow which ones to pick. Use your botanist's analyzer<BR>\nfor that. You can turn harvested plants into seeds<BR>\nat the seed extractor, and replant them for better stuff!<BR>\nSometimes if the weed level gets high in the tray<BR>\nmutations into different mushroom or weed species have<BR>\nbeen witnessed. On the rare occassion even weeds mutate!<BR>\n<BR>\nEither way, have fun!<BR>\n<BR>\nBest regards,<BR>\nBilly Bob Johnson.<BR>\n<BR>\nPS.<BR>\nHere's a few tips:<BR>\nIn nettles, potency = damage<BR>\nIn amanitas, potency = deadliness + side effect<BR>\nIn Liberty caps, potency = drug power + effect<BR>\nIn chilis, potency = heat<BR>\n<B>Nutrients keep mushrooms alive!</B><BR>\n<B>Water keeps weeds such as nettles alive!</B><BR>\n<B>All other plants need both.</B>"

/obj/item/weapon/paper/djstation
	name = "DJ Listening Outpost"
	info = "<B>Welcome new owner!</B><BR><BR>You have purchased the latest in listening equipment. The telecommunication setup we created is the best in listening to common and private radio fequencies. Here is a step by step guide to start listening in on those saucy radio channels:<br><ol><li>Equip yourself with a multi-tool</li><li>Use the multitool on each machine, that is the broadcaster, receiver and the relay.</li><li>Turn all the machines on, it has already been configured for you to listen on.</li></ol> Simple as that. Now to listen to the private channels, you'll have to configure the intercoms, located on the front desk. Here is a list of frequencies for you to listen on.<br><ul><li>145.7 - Common Channel</li><li>144.7 - Private AI Channel</li><li>135.9 - Security Channel</li><li>135.7 - Engineering Channel</li><li>135.5 - Medical Channel</li><li>135.3 - Command Channel</li><li>135.1 - Science Channel</li><li>134.9 - Mining Channel</li><li>134.7 - Cargo Channel</li>"

/obj/item/weapon/paper/flag
	icon_state = "flag_neutral"
	item_state = "paper"
	anchored = 1.0

/obj/item/weapon/paper/jobs
	name = "Job Information"
	info = "Information on all formal jobs that can be assigned on Apollo Station can be found on this document.<BR>\nThe data will be in the following form.<BR>\nGenerally lower ranking positions come first in this list.<BR>\n<BR>\n<B>Job Name</B>   general access>lab access-engine access-systems access (atmosphere control)<BR>\n\tJob Description<BR>\nJob Duties (in no particular order)<BR>\nTips (where applicable)<BR>\n<BR>\n<B>Research Assistant</B> 1>1-0-0<BR>\n\tThis is probably the lowest level position. Anyone who enters the space station after the initial job\nassignment will automatically receive this position. Access with this is restricted. Head of Personnel should\nappropriate the correct level of assistance.<BR>\n1. Assist the researchers.<BR>\n2. Clean up the labs.<BR>\n3. Prepare materials.<BR>\n<BR>\n<B>Staff Assistant</B> 2>0-0-0<BR>\n\tThis position assists the security officer in his duties. The staff assisstants should primarily br\npatrolling the ship waiting until they are needed to maintain ship safety.\n(Addendum: Updated/Elevated Security Protocols admit issuing of low level weapons to security personnel)<BR>\n1. Patrol ship/Guard key areas<BR>\n2. Assist security officer<BR>\n3. Perform other security duties.<BR>\n<BR>\n<B>Technical Assistant</B> 1>0-0-1<BR>\n\tThis is yet another low level position. The technical assistant helps the engineer and the statian\ntechnician with the upkeep and maintenance of the station. This job is very important because it usually\ngets to be a heavy workload on station technician and these helpers will alleviate that.<BR>\n1. Assist Station technician and Engineers.<BR>\n2. Perform general maintenance of station.<BR>\n3. Prepare materials.<BR>\n<BR>\n<B>Medical Assistant</B> 1>1-0-0<BR>\n\tThis is the fourth position yet it is slightly less common. This position doesn't have much power\noutside of the med bay. Consider this position like a nurse who helps to upkeep medical records and the\nmaterials (filling syringes and checking vitals)<BR>\n1. Assist the medical personnel.<BR>\n2. Update medical files.<BR>\n3. Prepare materials for medical operations.<BR>\n<BR>\n<B>Research Technician</B> 2>3-0-0<BR>\n\tThis job is primarily a step up from research assistant. These people generally do not get their own lab\nbut are more hands on in the experimentation process. At this level they are permitted to work as consultants to\nthe others formally.<BR>\n1. Inform superiors of research.<BR>\n2. Perform research alongside of official researchers.<BR>\n<BR>\n<B>Detective</B> 3>2-0-0<BR>\n\tThis job is in most cases slightly boring at best. Their sole duty is to\nperform investigations of crine scenes and analysis of the crime scene. This\nalleviates SOME of the burden from the security officer. This person's duty\nis to draw conclusions as to what happened and testify in court. Said person\nalso should stroe the evidence ly.<BR>\n1. Perform crime-scene investigations/draw conclusions.<BR>\n2. Store and catalogue evidence properly.<BR>\n3. Testify to superiors/inquieries on findings.<BR>\n<BR>\n<B>Station Technician</B> 2>0-2-3<BR>\n\tPeople assigned to this position must work to make sure all the systems aboard Apollo Station are operable.\nThey should primarily work in the computer lab and repairing faulty equipment. They should work with the\natmospheric technician.<BR>\n1. Maintain SS13 systems.<BR>\n2. Repair equipment.<BR>\n<BR>\n<B>Atmospheric Technician</B> 3>0-0-4<BR>\n\tThese people should primarily work in the atmospheric control center and lab. They have the very important\njob of maintaining the delicate atmosphere on SS13.<BR>\n1. Maintain atmosphere on SS13<BR>\n2. Research atmospheres on the space station. (safely please!)<BR>\n<BR>\n<B>Engineer</B> 2>1-3-0<BR>\n\tPeople working as this should generally have detailed knowledge as to how the propulsion systems on SS13\nwork. They are one of the few classes that have unrestricted access to the engine area.<BR>\n1. Upkeep the engine.<BR>\n2. Prevent fires in the engine.<BR>\n3. Maintain a safe orbit.<BR>\n<BR>\n<B>Medical Researcher</B> 2>5-0-0<BR>\n\tThis position may need a little clarification. Their duty is to make sure that all experiments are safe and\nto conduct experiments that may help to improve the station. They will be generally idle until a new laboratory\nis constructed.<BR>\n1. Make sure the station is kept safe.<BR>\n2. Research medical properties of materials studied of Apollo Station.<BR>\n<BR>\n<B>Scientist</B> 2>5-0-0<BR>\n\tThese people study the properties, particularly the toxic properties, of materials handled on SS13.\nTechnically they can also be called Phoron Technicians as phoron is the material they routinly handle.<BR>\n1. Research phoron<BR>\n2. Make sure all phoron is properly handled.<BR>\n<BR>\n<B>Medical Doctor (Officer)</B> 2>0-0-0<BR>\n\tPeople working this job should primarily stay in the medical area. They should make sure everyone goes to\nthe medical bay for treatment and examination. Also they should make sure that medical supplies are kept in\norder.<BR>\n1. Heal wounded people.<BR>\n2. Perform examinations of all personnel.<BR>\n3. Moniter usage of medical equipment.<BR>\n<BR>\n<B>Security Officer</B> 3>0-0-0<BR>\n\tThese people should attempt to keep the peace inside the station and make sure the station is kept safe. One\nside duty is to assist in repairing the station. They also work like general maintenance personnel. They are not\ngiven a weapon and must use their own resources.<BR>\n(Addendum: Updated/Elevated Security Protocols admit issuing of weapons to security personnel)<BR>\n1. Maintain order.<BR>\n2. Assist others.<BR>\n3. Repair structural problems.<BR>\n<BR>\n<B>Head of Security</B> 4>5-2-2<BR>\n\tPeople assigned as Head of Security should issue orders to the security staff. They should\nalso carefully moderate the usage of all security equipment. All security matters should be reported to this person.<BR>\n1. Oversee security.<BR>\n2. Assign patrol duties.<BR>\n3. Protect the station and staff.<BR>\n<BR>\n<B>Head of Personnel</B> 4>4-2-2<BR>\n\tPeople assigned as head of personnel will find themselves moderating all actions done by personnel. \nAlso they have the ability to assign jobs and access levels.<BR>\n1. Assign duties.<BR>\n2. Moderate personnel.<BR>\n3. Moderate research. <BR>\n<BR>\n<B>Captain</B> 5>5-5-5 (unrestricted station wide access)<BR>\n\tThis is the highest position youi can aquire on Apollo Station. They are allowed anywhere inside the\nspace station and therefore should protect their ID card. They also have the ability to assign positions\nand access levels. They should not abuse their power.<BR>\n1. Assign all positions on SS13<BR>\n2. Inspect the station for any problems.<BR>\n3. Perform administrative duties.<BR>\n"

/obj/item/weapon/paper/photograph
	name = "photo"
	icon_state = "photo"
	var/photo_id = 0.0
	item_state = "paper"

/obj/item/weapon/paper/sop
	name = "paper- 'Standard Operating Procedure'"
	info = "Alert Levels:<BR>\nBlue- Emergency<BR>\n\t1. Caused by fire<BR>\n\t2. Caused by manual interaction<BR>\n\tAction:<BR>\n\t\tClose all fire doors. These can only be opened by reseting the alarm<BR>\nRed- Ejection/Self Destruct<BR>\n\t1. Caused by module operating computer.<BR>\n\tAction:<BR>\n\t\tAfter the specified time the module will eject completely.<BR>\n<BR>\nEngine Maintenance Instructions:<BR>\n\tShut off ignition systems:<BR>\n\tActivate internal power<BR>\n\tActivate orbital balance matrix<BR>\n\tRemove volatile liquids from area<BR>\n\tWear a fire suit<BR>\n<BR>\n\tAfter<BR>\n\t\tDecontaminate<BR>\n\t\tVisit medical examiner<BR>\n<BR>\nToxin Laboratory Procedure:<BR>\n\tWear a gas mask regardless<BR>\n\tGet an oxygen tank.<BR>\n\tActivate internal atmosphere<BR>\n<BR>\n\tAfter<BR>\n\t\tDecontaminate<BR>\n\t\tVisit medical examiner<BR>\n<BR>\nDisaster Procedure:<BR>\n\tFire:<BR>\n\t\tActivate sector fire alarm.<BR>\n\t\tMove to a safe area.<BR>\n\t\tGet a fire suit<BR>\n\t\tAfter:<BR>\n\t\t\tAssess Damage<BR>\n\t\t\tRepair damages<BR>\n\t\t\tIf needed, Evacuate<BR>\n\tMeteor Shower:<BR>\n\t\tActivate fire alarm<BR>\n\t\tMove to the back of ship<BR>\n\t\tAfter<BR>\n\t\t\tRepair damage<BR>\n\t\t\tIf needed, Evacuate<BR>\n\tAccidental Reentry:<BR>\n\t\tActivate fire alarms in front of ship.<BR>\n\t\tMove volatile matter to a fire proof area!<BR>\n\t\tGet a fire suit.<BR>\n\t\tStay secure until an emergency ship arrives.<BR>\n<BR>\n\t\tIf ship does not arrive-<BR>\n\t\t\tEvacuate to a nearby safe area!"

/obj/item/weapon/paper/hos
	name = "Armory Inventory"
	info = "<center><Large><b>NSS Apollo</b></large><br> <small>Armoury Inventory</small></center> <hr> <hr> <br> <b>Weaponry</b><br> <field> Energy Gun(s)<br> <field> Laser Gun(s)<br> <field> Ion Rifle(s)<br> <field> Combat Shotgun(s) <hr> <b>Armour</b><br> <field> Bulletproof Vest(s)<br> <field> Abalative Vest(s)<br> <field> Biohazard Suit(s)<br> <field> Bomb Suit(s) <hr> <b>Auxiliary Equipment</b><br> <field> Gasmask(s)<br> <field> box(es) of Flashbangs<br> <field> box(es) of Handcuffs<br> <field> box(es) of R.O.B.U.S.T. Cartridges <hr> <b>Riot Equipment</b><br> <field> Stun Baton(s)<br> <field> Riot Suit(s)<br> <field> Riot Shield(s) <hr> <b>Tactical Equipment</b><br> <field> Tactical Armour(s)<br> <field> Tactical Helmet(s)<br> <field> Tactical Jumpsuit(s)<br> <field> Green Balaclava(s)<br> <field> Tactical HUD(s)<br> <field> Combat Belt(s)<br> <field> Black Glove(s)<br> <field> Jackboot(s) <hr> <b>Implants</b><br> <field> Tracking Implant Box(es)<br> <field> Chemical Implant Box(es) <hr> <b>Defense Systems</b><br> <field> Deployable Barrier(s)<br> <field> Portable Flasher(s) <hr> <b>Other</b><br> <field> Holobadge Box(es) <hr> <b><center>Warden's's Signature:</b> <field></center> <hr>"

/obj/item/weapon/paper/wiz
	name = "List of Available Spells"
	info = "<p><b>LIST OF SPELLS AVAILABLE</b></p><p>Magic Missile:<br>This spell fires several, slow moving, magic projectiles at nearby targets. If they hit a target, it is paralyzed and takes minor damage.</p><p>Fireball:<br>This spell fires a fireball at a target and does not require wizard garb. Be careful not to fire it at people that are standing next to you.</p><p>Disintegrate:</br>This spell instantly kills somebody adjacent to you with the vilest of magick. It has a long cooldown.</p><p>Disable Technology:<br>This spell disables all weapons, cameras and most other technology in range.</p><p>Smoke:<br>This spell spawns a cloud of choking smoke at your location and does not require wizard garb.</p><p>Blind:<br>This spell temporarly blinds a single person and does not require wizard garb.<p>Forcewall:<br>This spell creates an unbreakable wall that lasts for 30 seconds and does not require wizard garb.</p><p>Blink:<br>This spell randomly teleports you a short distance. Useful for evasion or getting into areas if you have patience.</p><p>Teleport:<br>This spell teleports you to a type of area of your selection. Very useful if you are in danger, but has a decent cooldown, and is unpredictable.</p><p>Mutate:<br>This spell causes you to turn into a hulk, and gain telekinesis for a short while.</p><p>Ethereal Jaunt:<br>This spell creates your ethereal form, temporarily making you invisible and able to pass through walls.</p><p>Knock:<br>This spell opens nearby doors and does not require wizard garb.</p>"

/obj/item/weapon/paper/cmo
	name = "CMO's Outgoing Notes"
	info = "<i><center>To the incoming CMO of Apollo:</center><br><br>I wish you and your crew well. Do take note:<br><br><br>The Medical Emergency Red Phone system has proven itself well. Take care to keep the phones in their designated places as they have been optimised for broadcast. The two handheld green radios (I have left one in this office, and one near the Emergency Entrance) are free to be used. The system has proven effective at alerting Medbay of important details, especially during power outages.<br><br>I think I may have left the toilet cubicle doors shut. It might be a good idea to open them so the staff and patients know they are not engaged.<br><br>The new syringe gun has been stored in secondary storage. I tend to prefer it stored in my office, but 'guidelines' are 'guidelines'.<br><br>Also in secondary storage is the grenade equipment crate. I've just realised I've left it open - you may wish to shut it.<br><br>There were a few problems with their installation, but the Medbay Quarantine shutters should now be working again  - they lock down the Emergency and Main entrances to prevent travel in and out. Pray you shan't have to use them.<br><br>The new version of the Medical Diagnostics Manual arrived. I distributed them to the shelf in the staff break room, and one on the table in the corner of this room.<br><br>The exam/triage room has the walking canes in it. I'm not sure why we'd need them - but there you have it.<br><br>Emergency Cryo bags are beside the emergency entrance, along with a kit.<br><br>Spare paper cups for the reception are on the left side of the reception desk.<br><br>I've fed Runtime. She should be fine.<br><br><br><center>That should be all. Good luck!</center>"

/obj/item/weapon/paper/shotgun_permit
	name = "Bartender Shotgun Permit"
	info = {"
	<font face="Verdana" color=black>
		<h2>Weapon Permit</h2>
		<HR>
		The following item(s) are considered dangerous. NanoTrasen can not be held responsible for injury sustained during the use of the item(s). The receiver must use the following item(s) only for their intended purpose. The receiver must not share these items with any other person(s) without direct approval of NanoTrasen command staff. The reciever claims all responsibility for damages caused as a result of the items loaned.
		<BR><BR>
		<h3>Items(s) Loaned:</h3>
		<ul>
			<li>Double-Barrel Shotgun</li>
			<li>One (1) Box of Seven (7) Beanbag Shells</li>
		</ul>
		<BR>
		<b>Name of Receiver:</b> NSS Apollo Bartender
		<BR><BR>
		Note: The items recieved may not be taken outside of the Bar or Bar Backroom. The reciever of the recieved items may openly display the recieved items, but this privilege may be revoked by any command staff. The Captain or the Head of Security may revoke this permit at their discretion.
		<BR><HR>
		<b>
			Issued By:
		</b>
		<font face="Times New Roman">
			<i>Jack South</i>
		</font>
		, NanoTrasen Representative
	</font>"}

/obj/item/weapon/paper/crumpled
	name = "paper scrap"
	icon_state = "scrap"

/obj/item/weapon/paper/crumpled/update_icon()
	return

/obj/item/weapon/paper/crumpled/bloody
	icon_state = "scrap_bloodied"
