#import <Cocoa/Cocoa.h>

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

    if ((pos = strnstr(chars, TOGGLE_MOUSE, length)))
    {
        // Is there enough data in the buffer for the next two characters?
        if ([data length] >= (NSUInteger) (&pos[TOGGLE_MOUSE_LEN] - chars) + 2)
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
                if (flag == 'h')
                    SET_IVAR([self view], @"mouseMode",
                             [NSNumber numberWithInt: mouseMode]);
                else if (flag == 'l')
                    SET_IVAR([self view], @"mouseMode",
                             [NSNumber numberWithInt: NO_MODE]);
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
    NSPoint windowloc = [event locationInWindow];
    NSPoint viewloc = [self convertPoint: windowloc fromView: nil];
    NSRect visible = [[self enclosingScrollView] documentVisibleRect];
    NSUInteger modflags = [event modifierFlags];

    // FIXME: Is comparing viewloc.y and visible.origin.y necessary?
    if (viewloc.y <= visible.origin.y || modflags & NSAlternateKeyMask)
        goto ignored;

    NSObject* logicalScreen = [self logicalScreen];

    switch ([(NSNumber*) IVAR(self, @"mouseMode") intValue])
    {
        case NO_MODE:
        {
            // FIXME: This screws up screen. Should probably take a closer
            // look at http://bugzilla.gnome.org/show_bug.cgi?id=424184
            //
            // Maybe it should only be used in application keypad mode?
#if 0
            if ((BOOL) [logicalScreen isAlternateScreenActive])
            {
                // FIXME: Need some way to account for scrolling acceleration
                const char* data;
                if (is application mode ...)
                    data = [event deltaY] > 0 ? UP_ARROW_APP UP_ARROW_APP :
                           DOWN_ARROW_APP DOWN_ARROW_APP;
                else
                    data = [event deltaY] > 0 ? UP_ARROW UP_ARROW :
                           DOWN_ARROW DOWN_ARROW;
                NSData* data = [NSData dataWithBytes: data
                                       length: ARROW_LEN * 2];
                [(NSObject*) [[self controller] shell] writeData: data];
                goto handled;
            }
            else
                goto ignored;
#endif
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
    return [self MouseTerm_initWithFrame: frame];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
