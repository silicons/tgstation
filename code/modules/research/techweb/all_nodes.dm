
/datum/techweb_node/basic_materials
	id = "basicmaterials"
	starting_node = TRUE
	display_name = "Basic Materials Processing"
	description = "The study into processing and use of basic materials, like glass, and steel."
	design_ids = list("basic_matter_bin")

/datum/techweb_node/advanced_materials
	id = "advancedmaterials"
	display_name = "Advanced Materials Processing"
	description = "The study into processing and use of more advanced materials, like gold and silver."
	prereq_ids = list("basicmaterials")
	design_ids = list("adv_matter_bin")

/datum/techweb_node/industrial_materials
	id = "industrialmaterials"
	display_name = "Industrial Materials Processing"
	description = "The study into processing and use of industrial materials, including uranium, diamond, and titanium."
	prereq_ids = list("advancedmaterials")
	design_ids = list("plasteel", "plastitanium", "alienalloy", "super_matter_bin")

/datum/techweb_node/bluespace_materials
	id = "bluespacematerials"
	display_name = "Bluespace Materials Processing"
	description = "Highly advanced research into processing and use of rare materials with transdimensional bluespace properties."
	prereq_ids = list("industrialmaterials")
	design_ids = list("bluespace_matter_bin")


/*
/datum/techweb_node
	var/id
	var/display_name = "Errored Node"
	var/description = "Why are you seeing this?"
	var/starting_node = FALSE	//Whether it's available without any research.
	var/list/prereq_ids = list()
	var/list/design_ids = list()
	var/list/datum/techweb_node/prerequisites = list()		//Assoc list id = datum
	var/list/datum/techweb_node/unlocks = list()			//CALCULATED FROM OTHER NODE'S PREREQUISITES. Assoc list id = datum.
	var/list/datum/design/designs = list()					//Assoc list id = datum
	var/list/boost_item_paths = list()		//Associative list, path = point_value.
	var/export_price = 0					//Cargo export price.
	var/research_cost = 0					//Point cost to research.
	var/boosted_path						//If science boosted this by deconning something, it puts the path here to make it one-time-only.
*/
