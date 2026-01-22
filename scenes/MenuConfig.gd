# MenuConfig.gd - Configuration for menu items and colors
extends Node

# You can customize these menu items for your game
static var MENU_ITEMS_GAME = [
	{"label": "Resume", "icon": "▶", "action": "resume"},
	{"label": "Restart", "icon": "↻", "action": "restart"},
	{"label": "Home", "icon": "🏠", "action": "home"},
	{"label": "Settings", "icon": "⚙", "action": "settings"},
	{"label": "Help", "icon": "?", "action": "help"},
	{"label": "Quit", "icon": "✖", "action": "quit"}
]

# Alternative simple menu
static var MENU_ITEMS_SIMPLE = [
	{"label": "Continue", "icon": "▶", "action": "resume"},
	{"label": "Restart", "icon": "↻", "action": "restart"},
	{"label": "Settings", "icon": "⚙", "action": "settings"},
	{"label": "Exit", "icon": "✖", "action": "quit"}
]

# Color themes
static var THEME_PINK = {
	"primary": Color(0.78, 0.13, 0.44),  # #c72071
	"secondary": Color(0.10, 0.01, 0.04),  # #1a020b
	"white": Color(0.93, 0.93, 0.93),  # #eeeeee
	"dark_bg": Color(0.08, 0.08, 0.10, 0.9)
}

static var THEME_BLUE = {
	"primary": Color(0.2, 0.4, 0.9),
	"secondary": Color(0.05, 0.05, 0.15),
	"white": Color(0.95, 0.95, 0.95),
	"dark_bg": Color(0.1, 0.1, 0.15, 0.9)
}

static var THEME_GREEN = {
	"primary": Color(0.2, 0.8, 0.3),
	"secondary": Color(0.02, 0.1, 0.02),
	"white": Color(0.95, 0.95, 0.95),
	"dark_bg": Color(0.05, 0.15, 0.05, 0.9)
}

# Get menu items based on context
static func get_menu_items(menu_type: String = "game") -> Array:
	match menu_type:
		"game":
			return MENU_ITEMS_GAME
		"simple":
			return MENU_ITEMS_SIMPLE
		_:
			return MENU_ITEMS_GAME

# Get theme colors
static func get_theme(theme_name: String = "pink") -> Dictionary:
	match theme_name:
		"pink":
			return THEME_PINK
		"blue":
			return THEME_BLUE
		"green":
			return THEME_GREEN
		_:
			return THEME_PINK
