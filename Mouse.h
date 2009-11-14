#ifndef __MOUSE_H
#define __MOUSE_H
// Possible mouse modes
typedef enum
{
    NO_MODE = 0,
    NORMAL_MODE,
    HILITE_MODE,
    BUTTON_MODE,
    ALL_MODE
} MouseMode;

// Control codes

// Normal control codes
#define UP_ARROW "\033[A"
#define DOWN_ARROW "\033[B"
// Control codes for application keypad mode
#define UP_ARROW_APP "\033OA"
#define DOWN_ARROW_APP "\033OB"
#define ARROW_LEN (sizeof(UP_ARROW) - 1)

// Mode control codes

#define TOGGLE_ON 'h'
#define TOGGLE_OFF 'l'

// Excludes mode and toggle flag
#define TOGGLE_MOUSE "\033[?100"
#define TOGGLE_MOUSE_LEN (sizeof(TOGGLE_MOUSE) - 1)

// Excludes toggle flag
#define TOGGLE_CURSOR_KEYS "\033[?1"
#define TOGGLE_CURSOR_KEYS_LEN (sizeof(TOGGLE_CURSOR_KEYS) - 1)

#define ALTERNATE_SCREEN "\033[?47"
#define ALTERNATE_SCREEN_LEN (sizeof(ALTERNATE_SCREEN) - 1)

#define OSC_TITLE_ESCAPE_START "\033]2;"
#define OSC_TITLE_ESCAPE_START_LEN (sizeof(OSC_TITLE_ESCAPE_START) - 1)

#define OSC_TITLE_ESCAPE_END "\007"


// X11 mouse button values
typedef enum
{
    MOUSE_BUTTON1 = 0,
    MOUSE_BUTTON2,
    MOUSE_BUTTON3,
    MOUSE_RELEASE,
    MOUSE_WHEEL_DOWN,
    MOUSE_WHEEL_UP
} MouseButton;

// X11 mouse reporting responses
#define MOUSE_RESPONSE "\033[M%c%c%c"
#define MOUSE_RESPONSE_LEN 6


#endif
