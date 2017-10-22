
//Used \n[\s]*origin_tech[\s]*=[\s]*"[\S]+" to delete all origin techs.
//Used \n[\s]*req_tech[\s]*=[\s]*list\(["\w\d\s=]*\)\n to delete all req_techs.

//Techweb datums are meant to store unlocked research, being able to be stored on research consoles, servers, and disks. They are NOT global.
/datum/techweb
	var/list/datum/techweb_node/researched_nodes = list()		//Already unlocked and all designs are now available. Assoc list, id = datum
	var/list/datum/techweb_node/visible_nodes = list()			//Visible nodes, doesn't mean it can be researched. Assoc list, id = datum
	var/list/datum/techweb_node/available_nodes = list()		//Nodes that can immediately be researched, all reqs met. assoc list, id = datum
	var/list/datum/design/researched_designs = list()			//Designs that are available for use. Assoc list, id = datum
	var/list/datum/techweb_node/boosted_nodes = list()			//Already boosted nodes that can't be boosted again. node datum = path of boost object.
	var/list/datum/techweb_node/hidden_nodes = list()			//Hidden nodes. id = datum. Used for unhiding nodes when requirements are met by removing the entry of the node.
	var/list/deconstructed_items = list()						//items already deconstructed for a generic point boost
	var/research_points = 0										//Available research points.
	var/list/obj/machinery/computer/rdconsole/consoles_accessing = list()
	var/id = "generic"
	var/list/research_logs = list()								//IC logs.
	var/max_bomb_value = 0

/datum/techweb/New()
	for(var/i in SSresearch.techweb_nodes_starting)
		var/datum/techweb_node/DN = SSresearch.techweb_nodes_starting[i]
		research_node(DN)
	hidden_nodes = SSresearch.techweb_nodes_hidden
	return ..()

/datum/techweb/admin
	research_points = INFINITY	//KEKKLES.
	id = "ADMIN"

/datum/techweb/admin/New()	//All unlocked.
	. = ..()
	for(var/i in SSresearch.techweb_nodes)
		var/datum/techweb_node/TN = SSresearch.techweb_nodes[i]
		research_node(TN, TRUE)
	hidden_nodes = list()

/datum/techweb/science	//Global science techweb for RND consoles.
	id = "SCIENCE"

/datum/techweb/Destroy()
	researched_nodes = null
	researched_designs = null
	available_nodes = null
	visible_nodes = null
	return ..()

/datum/techweb/proc/recalculate_nodes(recalculate_designs = FALSE)
	var/list/datum/techweb_node/processing = list()
	for(var/i in researched_nodes)
		processing[i] = researched_nodes[i]
	for(var/i in visible_nodes)
		processing[i] = visible_nodes[i]
	for(var/i in available_nodes)
		processing[i] = available_nodes[i]
	for(var/i in processing)
		update_node_status(processing[i])
	if(recalculate_designs)					//Wipes custom added designs like from design disks or anything like that!
		researched_designs = list()
	for(var/i in processing)
		var/datum/techweb_node/TN = processing[i]
		if(researched_nodes[TN.id])
			for(var/I in TN.designs)
				researched_designs[I] = TN.designs[I]

/datum/techweb/proc/copy_research_to(datum/techweb/reciever, unlock_hidden = TRUE)				//Adds any missing research to theirs.
	for(var/i in researched_nodes)
		reciever.researched_nodes[i] = researched_nodes[i]
	for(var/i in researched_designs)
		reciever.researched_designs[i] = researched_designs[i]
	if(unlock_hidden)
		for(var/i in reciever.hidden_nodes)
			if(!hidden_nodes[i])
				reciever.hidden_nodes -= i		//We can see it so let them see it too.
	reciever.recalculate_nodes()

/datum/techweb/proc/copy()
	var/datum/techweb/returned = new()
	returned.researched_nodes = researched_nodes.Copy()
	returned.visible_nodes = visible_nodes.Copy()
	returned.available_nodes = available_nodes.Copy()
	returned.researched_designs = researched_designs.Copy()
	returned.hidden_nodes = hidden_nodes.Copy()
	return returned

/datum/techweb/proc/get_visible_nodes()			//The way this is set up is shit but whatever.
	return visible_nodes - hidden_nodes

/datum/techweb/proc/get_available_nodes()
	return available_nodes - hidden_nodes

/datum/techweb/proc/get_researched_nodes()
	return researched_nodes - hidden_nodes

/datum/techweb/proc/add_design_by_id(id)
	return add_design(get_techweb_design_by_id(id))

/datum/techweb/proc/add_design(datum/design/design)
	if(!istype(design))
		return FALSE
	researched_designs[design.id] = design
	return TRUE

/datum/techweb/proc/remove_design_by_id(id)
	return remove_design(get_techweb_design_by_id(id))

/datum/techweb/proc/remove_design(datum/design/design)
	if(!istype(design))
		return FALSE
	researched_designs[design.id] = design
	return TRUE

/datum/techweb/proc/research_node_id(id, force, auto_update_points)
	return research_node(get_techweb_node_by_id(id), force, auto_update_points)

/datum/techweb/proc/research_node(datum/techweb_node/node, force = FALSE, auto_adjust_cost = TRUE)
	if(!istype(node))
		return FALSE
	update_node_status(node)
	if(!force)
		if(!available_nodes[node.id] || (auto_adjust_cost && (research_points < node.get_price(src))))
			return FALSE
	if(auto_adjust_cost)
		research_points -= node.get_price(src)
	researched_nodes[node.id] = node				//Add to our researched list
	for(var/i in node.unlocks)
		visible_nodes[i] = node.unlocks[i]
		update_node_status(node.unlocks[i])
	for(var/i in node.designs)
		researched_designs[i] = node.designs[i]
	update_node_status(node)
	return TRUE

/datum/techweb/proc/unresearch_node_id(id)
	return unresearch_node(get_techweb_node_by_id(id))

/datum/techweb/proc/unresearch_node(datum/techweb_node/node)
	if(!istype(node))
		return FALSE
	researched_nodes -= node.id
	recalculate_nodes(TRUE)				//Fully rebuild the tree.

/datum/techweb/proc/boost_with_path(datum/techweb_node/N, itempath)
	if(!istype(N)||!ispath(itempath))
		return FALSE
	var/boost = N.boost_item_paths[itempath]
	if(!boosted_nodes[N])
		boosted_nodes[N] = boost
	return TRUE

/datum/techweb/proc/update_node_status(datum/techweb_node/node, autoupdate_consoles = TRUE)
	var/researched = FALSE
	var/available = FALSE
	var/visible = FALSE
	if(researched_nodes[node.id])
		researched = TRUE
	var/needed = node.prereq_ids.len
	for(var/i in node.prereq_ids)
		if(researched_nodes[i])
			visible = TRUE
			needed--
	if(!needed)
		available = TRUE
	researched_nodes -= node.id
	available_nodes -= node.id
	visible_nodes -= node.id
	if(hidden_nodes[node.id])	//Hidden.
		return
	if(researched)
		researched_nodes[node.id] = node
		for(var/i in node.designs)
			add_design(node.designs[i])
	else
		if(available)
			available_nodes[node.id] = node
		else
			if(visible)
				visible_nodes[node.id] = node
	if(autoupdate_consoles)
		for(var/v in consoles_accessing)
			var/obj/machinery/computer/rdconsole/V = v
			V.rescan_views()
			V.updateUsrDialog()

//Laggy procs to do specific checks, just in case. Don't use them if you can just use the vars that already store all this!
/datum/techweb/proc/designHasReqs(datum/design/D)
	for(var/i in researched_nodes)
		var/datum/techweb_node/N = researched_nodes[i]
		for(var/I in N.designs)
			if(D == N.designs[I])
				return TRUE
	return FALSE

/datum/techweb/proc/isDesignResearched(datum/design/D)
	return isDesignResearchedID(D.id)

/datum/techweb/proc/isDesignResearchedID(id)
	return researched_designs[id]

/datum/techweb/proc/isNodeResearched(datum/techweb_node/N)
	return isNodeResearchedID(N.id)

/datum/techweb/proc/isNodeResearchedID(id)
	return researched_nodes[id]

/datum/techweb/proc/isNodeVisible(datum/techweb_node/N)
	return isNodeResearchedID(N.id)

/datum/techweb/proc/isNodeVisibleID(id)
	return visible_nodes[id]

/datum/techweb/proc/isNodeAvailable(datum/techweb_node/N)
	return isNodeAvailableID(N.id)

/datum/techweb/proc/isNodeAvailableID(id)
	return available_nodes[id]

/datum/techweb/autolathe/New()
	for(var/D in SSresearch.techweb_designs)
		var/datum/design/d = SSresearch.techweb_designs[D]
		if((d.build_type & AUTOLATHE) && ("initial" in d.category))
			add_design(d)
	return ..()

/datum/techweb/autolathe/add_design(datum/design/D)
	if(!(D.build_type & AUTOLATHE))
		return FALSE
	return ..()

/datum/techweb/limbgrower/New()
	for(var/D in SSresearch.techweb_designs)
		var/datum/design/d = SSresearch.techweb_designs[D]
		if((d.build_type & LIMBGROWER) && ("initial" in d.category))
			add_design(d)
	return ..()

/datum/techweb/limbgrower/add_design(datum/design/D)
	if(!(D.build_type & LIMBGROWER))
		return FALSE
	return TRUE

/datum/techweb/biogenerator/New()
	for(var/D in SSresearch.techweb_designs)
		var/datum/design/d = SSresearch.techweb_designs[D]
		if((d.build_type & BIOGENERATOR) && ("initial" in d.category))
			add_design(d)
	return ..()

/datum/techweb/biogenerator/add_design(datum/design/D)
	if(!(D.build_type & BIOGENERATOR))
		return FALSE
	return ..()

/datum/techweb/smelter/New()
	for(var/D in SSresearch.techweb_designs)
		var/datum/design/d = SSresearch.techweb_designs[D]
		if((d.build_type & SMELTER) && ("initial" in d.category))
			add_design(d)
	return ..()

/datum/techweb/smelter/add_design(datum/design/D)
	if(!(D.build_type & SMELTER))
		return FALSE
	return ..()

/datum/techweb/exofab/New()
	var/static/list/starting_exofab_nodes = list("robotics", "mmi", "cyborg")
	for(var/i in starting_exofab_nodes)
		research_node(get_techweb_node_by_id(i), TRUE, FALSE)
	return ..()
