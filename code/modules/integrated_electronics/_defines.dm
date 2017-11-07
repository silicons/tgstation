#define IC_INPUT "input"
#define IC_OUTPUT "output"
#define IC_ACTIVATOR "activator"

// Pin functionality.
#define DATA_CHANNEL "data channel"
#define PULSE_CHANNEL "pulse channel"

// Methods of obtaining a circuit.
#define IC_SPAWN_DEFAULT			1 // If the circuit comes in the default circuit box and able to be printed in the IC printer.
#define IC_SPAWN_RESEARCH 			2 // If the circuit design will be available in the IC printer after upgrading it.

// Displayed along with the pin name to show what type of pin it is.
#define IC_FORMAT_ANY			"\<ANY\>"
#define IC_FORMAT_STRING		"\<TEXT\>"
#define IC_FORMAT_CHAR			"\<CHAR\>"
#define IC_FORMAT_COLOR			"\<COLOR\>"
#define IC_FORMAT_NUMBER		"\<NUM\>"
#define IC_FORMAT_DIR			"\<DIR\>"
#define IC_FORMAT_BOOLEAN		"\<BOOL\>"
#define IC_FORMAT_REF			"\<REF\>"
#define IC_FORMAT_LIST			"\<LIST\>"

#define IC_FORMAT_PULSE			"\<PULSE\>"

// Used inside input/output list to tell the constructor what pin to make.
#define IC_PINTYPE_ANY				/datum/integrated_io
#define IC_PINTYPE_STRING			/datum/integrated_io/string
#define IC_PINTYPE_CHAR				/datum/integrated_io/char
#define IC_PINTYPE_COLOR			/datum/integrated_io/color
#define IC_PINTYPE_NUMBER			/datum/integrated_io/number
#define IC_PINTYPE_DIR				/datum/integrated_io/dir
#define IC_PINTYPE_BOOLEAN			/datum/integrated_io/boolean
#define IC_PINTYPE_REF				/datum/integrated_io/ref
#define IC_PINTYPE_LIST				/datum/integrated_io/list

#define IC_PINTYPE_PULSE_IN			/datum/integrated_io/activate
#define IC_PINTYPE_PULSE_OUT		/datum/integrated_io/activate/out

// Data limits.
#define IC_MAX_LIST_LENGTH			200
//some colors
#define COLOR_WHITE   			"#FFFFFF"
#define COLOR_SILVER  			"#C0C0C0"
#define COLOR_GRAY    			"#808080"
#define COLOR_BLACK   			"#000000"
#define COLOR_RED     			"#FF0000"
#define COLOR_MAROON 			"#800000"
#define COLOR_YELLOW  			"#FFFF00"
#define COLOR_OLIVE  			"#808000"
#define COLOR_LIME   			"#00FF00"
#define COLOR_GREEN   			"#008000"
#define COLOR_CYAN    			"#00FFFF"
#define COLOR_TEAL    			"#008080"
#define COLOR_BLUE    			"#0000FF"
#define COLOR_NAVY    			"#000080"
#define COLOR_PINK    			"#FF00FF"
#define COLOR_PURPLE  			"#800080"
#define COLOR_ORANGE  			"#FF9900"
#define COLOR_LUMINOL 			"#66FFFF"
#define COLOR_BEIGE 			"#CEB689"
#define COLOR_BLUE_GRAY 		"#6A97B0"
#define COLOR_BROWN 			"#B19664"
#define COLOR_DARK_BROWN 		"#917448"
#define COLOR_DARK_ORANGE 		"#B95A00"
#define COLOR_GREEN_GRAY 		"#8DAF6A"
#define COLOR_RED_GRAY 			"#AA5F61"
#define COLOR_PALE_BLUE_GRAY	"#8BBBD5"
#define COLOR_PALE_GREEN_GRAY 	"#AED18B"
#define COLOR_PALE_RED_GRAY		"#CC9090"
#define COLOR_PALE_PURPLE_GRAY	"#BDA2BA"
#define COLOR_PURPLE_GRAY 		"#A2819E"
#define COLOR_RED_LIGHT         "#FF3333"
#define COLOR_DEEP_SKY_BLUE     "#00e1ff"
GLOBAL_LIST_EMPTY(all_integrated_circuits)

/proc/iscrowbar(O)
	if(istype(O, /obj/item/crowbar))
		return 1
	return 0



/proc/initialize_integrated_circuits_list()
	for(var/thing in typesof(/obj/item/integrated_circuit))
		GLOB.all_integrated_circuits += new thing()

/proc/between(var/low, var/middle, var/high)
	return max(min(middle, high), low)

/obj/item/integrated_circuit
	name = "integrated circuit"
	desc = "It's a tiny chip!  This one doesn't seem to do much, however."
	icon = 'icons/obj/electronic_assemblies.dmi'
	icon_state = "template"
	w_class = WEIGHT_CLASS_TINY
	var/obj/item/device/electronic_assembly/assembly = null // Reference to the assembly holding this circuit, if any.
	var/extended_desc = null
	var/list/inputs = list()
	var/list/inputs_default = list()			// Assoc list which will fill a pin with data upon creation.  e.g. "2" = 0 will set input pin 2 to equal 0 instead of null.
	var/list/outputs = list()
	var/list/outputs_default = list()		// Ditto, for output.
	var/list/activators = list()
	var/next_use = 0 //Uses world.time
	var/complexity = 1 				//This acts as a limitation on building machines, more resource-intensive components cost more 'space'.
	var/size = null					//This acts as a limitation on building machines, bigger components cost more 'space'. -1 for size 0
	var/cooldown_per_use = 9 // Circuits are limited in how many times they can be work()'d by this variable.
	var/power_draw_per_use = 0 		// How much power is drawn when work()'d.
	var/power_draw_idle = 0			// How much power is drawn when doing nothing.
	var/spawn_flags = null			// Used for world initializing, see the #defines above.
	var/category_text = "NO CATEGORY THIS IS A BUG"	// To show up on circuit printer, and perhaps other places.
	var/removable = TRUE 			// Determines if a circuit is removable from the assembly.
	var/displayed_name = ""
	var/allow_multitool = 1			// Allows additional multitool functionality
									// Used as a global var, (Do not set manually in children).
proc/get_random_colour(var/simple, var/lower=0, var/upper=255)
	var/colour
	if(simple)
		colour = pick(list("FF0000","FF7F00","FFFF00","00FF00","0000FF","4B0082","8F00FF"))
	else
		for(var/i=1;i<=3;i++)
			var/temp_col = "[num2hex(rand(lower,upper))]"
			if(length(temp_col )<2)
				temp_col  = "0[temp_col]"
			colour += temp_col
	return colour

