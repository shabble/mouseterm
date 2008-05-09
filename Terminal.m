#import <Cocoa/Cocoa.h>
#import <math.h>
#import <alloca.h>

#import "MouseTerm.h"
#import "Mouse.h"

#define IVAR(obj, name) \
    [[MouseTerm_ivars objectForKey: [NSValue valueWithPointer: obj]] \
                      objectForKey: name]
#define SET_IVAR(obj, name, value) \
    [[MouseTerm_ivars objectForKey: [NSValue valueWithPointer: obj]] \
                      setObject: value forKey: name]

@implementation TTTabController (MouseTermTTTabController)

// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    // FIXME: What if the data's split up over method calls?
    NSUInteger length = [data length];
    const char* chars = [data bytes];
    const char* pos;

    // Handle mouse reporting toggle
    if ((pos = strnstr(chars, TOGGLE_MOUSE, length)))
    {
        // Is there enough data in the buffer for the next two characters?
        if (length >= (NSUInteger) (&pos[TOGGLE_MOUSE_LEN] - chars) + 2)
        {
            char mode = pos[TOGGLE_MOUSE_LEN];
            char flag = pos[TOGGLE_MOUSE_LEN + 1];
            MouseMode mouseMode = NO_MODE;

            switch (mode)
            {
            case '0':
                mouseMode = NORMAL_MODE;
                break;
            case '1':
                mouseMode = HILITE_MODE;
                break;
            case '2':
                mouseMode = BUTTON_MODE;
                break;
            case '3': 
                mouseMode = ALL_MODE;
                break;
            }

            if (mouseMode != NO_MODE)
            {
                switch (flag)
                {
                case TOGGLE_ON:
                    SET_IVAR([self view], @"mouseMode",
                             [NSNumber numberWithInt: mouseMode]);
                    break;
                case TOGGLE_OFF:
                    SET_IVAR([self view], @"mouseMode",
                             [NSNumber numberWithInt: NO_MODE]);
                    break;
                }
            }
        }
    }
    // Handle application cursor keys mode toggle
    //
    // Note: This information does exist on the TTVT100Emulator object
    // already, but it's in private member data, and there's no method
    // that returns any data from it. That means we have to look for it
    // ourselves.
    else if ((pos = strnstr(chars, TOGGLE_CURSOR_KEYS, length)))
    {
        // Is there enough data in the buffer for the next character?
        if (length >= (NSUInteger) (&pos[TOGGLE_CURSOR_KEYS_LEN] - chars) + 1)
        {
            char flag = pos[TOGGLE_CURSOR_KEYS_LEN];
            switch (flag)
            {
            case TOGGLE_ON:
                SET_IVAR([self view], @"appCursorMode",
                         [NSNumber numberWithBool: YES]);
                break;
            case TOGGLE_OFF:
                SET_IVAR([self view], @"appCursorMode",
                         [NSNumber numberWithBool: NO]);
                break;
            }
        }
    }

    [self MouseTerm_shellDidReceiveData: data];
}

@end

@implementation TTView (MouseTermTTView)

// FIXME: These need to be implemented!
#if 0
- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    return [self MouseTerm_mouseDown: event];
}

- (void) MouseTerm_mouseUp: (NSEvent*) event
{
    return [self MouseTerm_mouseUp: event];
}

- (void) MouseTerm_mouseDragged: (NSEvent*) event
{
    return [self MouseTerm_mouseDragged: event];
}

- (void) MouseTerm_mouseEntered: (NSEvent*) event
{
    return [self MouseTerm_mouseEntered: event];
}

- (void) MouseTerm_otherMouseDown: (NSEvent*) event
{
    return [self MouseTerm_otherMouseDown: event];
}

- (void) MouseTerm_otherMouseUp: (NSEvent*) event
{
    return [self MouseTerm_otherMouseUp: event];
}

- (void) MouseTerm_otherMouseDragged: (NSEvent*) event
{
    return [self MouseTerm_otherMouseDragged: event];
}
#endif

// Intercepts all scroll wheel movements (one wheel "tick" at a time)
- (void) MouseTerm_scrollWheel: (NSEvent*) event
{
    // Don't handle any scrolling if alt/option is pressed
    // FIXME: Ignore event if scrollbar isn't at the bottom of the view
    if ([event modifierFlags] & NSAlternateKeyMask)
        goto ignored;

    switch ([(NSNumber*) IVAR(self, @"mouseMode") intValue])
    {
        case NO_MODE:
        {
            if ((BOOL) [[self logicalScreen] isAlternateScreenActive] &&
                [IVAR(self, @"appCursorMode") boolValue])
            {
                // Calculate how many lines to scroll by (takes acceleration
                // into account)
                NSData* data;
                double lines = [event deltaY];

                if (copysignf(1.0, lines) == -1.0)
                {
                    lines = labs(lines);
                    data = [NSData dataWithBytes: DOWN_ARROW_APP
                                   length: ARROW_LEN];
                }
                else
                {
                    data = [NSData dataWithBytes: UP_ARROW_APP
                                   length: ARROW_LEN];
                }

                lines = round(lines) + 1.0;
                NSObject* shell = [[self controller] shell];
                long i;
                for (i = 0; i < lines; ++i)
                    [shell writeData: data];

                goto handled;
            }
            else
                goto ignored;
        }
        // FIXME: Unhandled at the moment
        case HILITE_MODE:
            goto ignored;
        case NORMAL_MODE:
        case BUTTON_MODE:
        case ALL_MODE:
        {
            int button = [event deltaY] > 0 ? MOUSE_WHEEL_UP : MOUSE_WHEEL_DOWN;
            NSPoint viewloc = [self convertPoint: [event locationInWindow]
                                    fromView: nil];
            Position pos = [self displayPositionForPoint: viewloc];
            [(NSObject*) [[self controller] shell] writeData: mousePress(
                                button, [event modifierFlags],
                                pos.x, pos.y)];
            goto handled;
        }
    }

handled:
    return;
ignored:
    [self MouseTerm_scrollWheel: event];
}

// Initializes instance variables
- (TTView*) MouseTerm_initWithFrame: (NSRect) frame
{
    [MouseTerm_ivars setObject: [NSMutableDictionary dictionary]
                     forKey: [NSValue valueWithPointer: self]];
    SET_IVAR(self, @"mouseMode", [NSNumber numberWithInt: NO_MODE]);
    SET_IVAR(self, @"appCursorMode", [NSNumber numberWithBool: NO]);
    return [self MouseTerm_initWithFrame: frame];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
