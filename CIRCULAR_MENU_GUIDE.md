# Circular Navigation Menu for Godot 4

A fully-featured circular/radial navigation menu system inspired by modern web interfaces, built for Godot 4.

## Features

✅ **Circular Pie Menu** - Beautiful radial menu with segments
✅ **Smooth Rotation** - Animated transitions with easing
✅ **Multiple Input Methods**:
   - Mouse hover detection
   - Keyboard navigation (Q to toggle, Arrow keys, Enter)
   - Touch support (drag to rotate on mobile)
✅ **Visual Feedback** - Hover states, active states, smooth animations
✅ **Sound Effects** - Rotation and open sounds (configure your own)
✅ **First-Time Hint** - Shows tooltip for new users
✅ **Customizable** - Easy to modify colors, items, and actions
✅ **Backdrop Blur** - Darkens background when menu is open
✅ **Counter-Rotation** - Icons stay upright while wheel rotates

## Controls

### Keyboard
- **Q** - Toggle menu open/close
- **Arrow Left/Right** - Rotate menu (when open)
- **Enter** - Select highlighted item (when open)
- **Escape** - Close menu / Toggle pause

### Mouse
- **Click toggle button** (top-left) - Open/close menu
- **Click center button** - Close menu
- **Click backdrop** - Close menu
- **Hover over icons** - Highlight segments
- **Click icons** - Rotate and select

### Touch (Mobile)
- **Tap toggle button** - Open menu
- **Drag on wheel** - Rotate menu
- **Release** - Snaps to nearest item
- **Tap icon** - Select item

## Files Created

1. **CircularMenu.gd** - Main menu logic and functionality
2. **CircularMenu.tscn** - Menu scene with UI nodes
3. **MenuConfig.gd** - Configuration for menu items and themes

## Customization

### Change Menu Items

Edit the `MENU_ITEMS` array in [CircularMenu.gd](scenes/CircularMenu.gd):

```gdscript
const MENU_ITEMS = [
    {"label": "Resume", "icon": "▶", "action": "resume"},
    {"label": "Restart", "icon": "↻", "action": "restart"},
    {"label": "Settings", "icon": "⚙", "action": "settings"},
    {"label": "Quit", "icon": "✖", "action": "quit"}
]
```

### Change Colors

Modify the color constants in [CircularMenu.gd](scenes/CircularMenu.gd):

```gdscript
const PRIMARY_COLOR = Color(0.78, 0.13, 0.44)  # Pink/Magenta
const SECONDARY_COLOR = Color(0.10, 0.01, 0.04)  # Dark
const WHITE_COLOR = Color(0.93, 0.93, 0.93)  # Off-white
const DARK_BG = Color(0.08, 0.08, 0.10, 0.9)  # Dark background
```

Or use predefined themes from [MenuConfig.gd](scenes/MenuConfig.gd):
- `THEME_PINK` (default)
- `THEME_BLUE`
- `THEME_GREEN`

### Add Menu Actions

In the `execute_menu_action()` function in [CircularMenu.gd](scenes/CircularMenu.gd):

```gdscript
func execute_menu_action(index: int):
    var action = MENU_ITEMS[index].action
    
    match action:
        "resume":
            close_menu()
            get_tree().paused = false
        "restart":
            get_tree().reload_current_scene()
        "settings":
            # Your settings code here
            pass
        "your_custom_action":
            # Your custom code here
            pass
```

### Add Sound Effects

To add sound effects, place your audio files in the project and load them:

```gdscript
func setup_sounds():
    rotate_sound = AudioStreamPlayer.new()
    open_sound = AudioStreamPlayer.new()
    add_child(rotate_sound)
    add_child(open_sound)
    
    # Load your sound files
    rotate_sound.stream = load("res://sounds/rotate.mp3")
    open_sound.stream = load("res://sounds/open.mp3")
    
    rotate_sound.volume_db = -10
    open_sound.volume_db = -12
```

### Adjust Menu Size

Change these constants in [CircularMenu.gd](scenes/CircularMenu.gd):

```gdscript
const INNER_RADIUS = 65.0   # Inner circle radius
const OUTER_RADIUS = 195.0  # Outer circle radius
const ICON_RADIUS = 130.0   # Where icons are positioned
```

### Animation Timing

Adjust animation durations:

```gdscript
const ANIMATION_DURATION = 0.4  # Open/close speed
const ROTATION_DURATION = 0.5   # Rotation speed
```

## Integration

The menu is already integrated into your main scene. It will:
- Open with **Q** key
- Work with game pause system
- Show first-time hint to new players
- Auto-save hint preference

## Advanced Customization

### Different Menu Items for Different Contexts

You can create multiple menu configurations:

```gdscript
# In-game pause menu
var PAUSE_MENU = [
    {"label": "Resume", "icon": "▶", "action": "resume"},
    {"label": "Settings", "icon": "⚙", "action": "settings"},
    {"label": "Quit", "icon": "✖", "action": "quit"}
]

# Main menu
var MAIN_MENU = [
    {"label": "Play", "icon": "▶", "action": "play"},
    {"label": "Options", "icon": "⚙", "action": "options"},
    {"label": "Credits", "icon": "★", "action": "credits"},
    {"label": "Exit", "icon": "✖", "action": "exit"}
]
```

### Custom Icons

You can use:
- **Unicode characters**: ▶ ↻ ⚙ ✖ 🏠 ⭐ 📊
- **Emoji**: 🏠 ⚙️ 🎮 📝 ❌
- **Custom textures**: Load texture icons instead of text

### Mobile Optimization

For mobile games, the menu automatically:
- Reduces sizes (set in `INNER_RADIUS`, etc.)
- Enables touch drag rotation
- Snaps to nearest segment on release
- Disables transitions while dragging for smooth feel

## Tips

1. **Test keyboard controls** - Press Q to toggle anytime
2. **Adjust colors** to match your game's theme
3. **Add more items** - Works with any number (4-8 recommended)
4. **Sound effects** - Add audio files for better feedback
5. **Backdrop** - Can be customized with blur effects
6. **Icons** - Use Unicode, emoji, or load custom textures

## Troubleshooting

### Menu doesn't appear
- Check that CircularMenu.tscn is added to your scene
- Verify the menu layer is set high enough (layer = 100)

### Icons not rotating correctly
- The rotation is intentionally counter-rotated to keep icons upright
- Check the `update_icon_counter_rotation()` function

### Touch not working
- Ensure you're testing on a touch device or mobile export
- The menu automatically detects mobile vs desktop

### Sound not playing
- Load actual sound files in `setup_sounds()`
- Check volume_db settings aren't too low

## Performance

The menu is optimized for performance:
- Generates segments once on ready
- Uses tweens for smooth animations
- Minimal draw calls with polygon rendering
- Event-based updates (no _process polling)

Enjoy your circular navigation menu! 🎯
