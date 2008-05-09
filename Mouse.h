// Possible mouse modes
typedef enum
{
    NO_MODE = -1,
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

// Returns a control code for a mouse movement (from iTerm)
inline NSData* mousePress(MouseButton button, unsigned int modflag,
                          unsigned int x, unsigned int y)
{
    char buf[MOUSE_RESPONSE_LEN + 1];
    char cb;

    cb = button % 3;

    // FIXME: This can't be right...
    if (button == MOUSE_WHEEL_DOWN)
        cb += 64;
    else if (button == MOUSE_WHEEL_UP)
        cb += 62;

    if (modflag & NSControlKeyMask)
        cb += 16;
    if (modflag & NSShiftKeyMask)
        cb += 4;
    if (modflag & NSAlternateKeyMask) // Alt/option
        cb += 8;

    snprintf(buf, sizeof(buf), MOUSE_RESPONSE, 32 + cb, 32 + x + 1,
             32 + y + 1);
    return [NSData dataWithBytes: buf length: MOUSE_RESPONSE_LEN];
}
