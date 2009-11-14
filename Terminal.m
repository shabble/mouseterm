#import <Cocoa/Cocoa.h>
#import <math.h>

#import "MouseTerm.h"
#import "Mouse.h"
#import "EscapeParser.h"

// Returns a control code for a mouse movement (from iTerm)
inline NSData* mousePress(MouseButton button, unsigned int modflag,
                          unsigned int x, unsigned int y)
{
    char buf[MOUSE_RESPONSE_LEN + 1];
    char cb;

    switch (button)
    {
    case MOUSE_WHEEL_DOWN:
        cb = 65;
        break;
    case MOUSE_WHEEL_UP:
        cb = 64;
        break;
    default:
        cb = button % 3;
    }
    cb += 32;

    if (modflag & NSShiftKeyMask)
        cb |= 4;
    if (modflag & NSAlternateKeyMask) // Alt/option
        cb |= 8;
    if (modflag & NSControlKeyMask)
        cb |= 16;

    snprintf(buf, sizeof(buf), MOUSE_RESPONSE, cb, 32 + x + 1,
             32 + y + 1);
    return [NSData dataWithBytes: buf length: MOUSE_RESPONSE_LEN];
}

inline NSValue* init_ivars(id obj)
{
    NSValue* value = [NSValue valueWithPointer: obj];
    if ([MouseTerm_ivars objectForKey: value] == nil)
    {
        [MouseTerm_ivars setObject: [NSMutableDictionary dictionary]
                         forKey: value];
    }
    return value;
}

inline id get_ivar(id obj, NSString* name)
{
    NSValue* ptr = init_ivars(obj);
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey: name];
}

inline void set_ivar(id obj, NSString* name, id value)
{
    NSValue* ptr = init_ivars(obj);
    [[MouseTerm_ivars objectForKey: ptr] setObject: value forKey: name];
}

@implementation TTTabController (MouseTermTTTabController)

- (id)   MouseTerm_getIvar:(NSString*)name {
    return get_ivar([self view], name);
}

- (void) MouseTerm_setIvar:(NSString*)name toValue:(id)value {
    set_ivar([self view], name, value);
}
// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    // FIXME: What if the data's split up over method calls?
    NSUInteger length = [data length];
    const char* chars = [data bytes];
    //const char* pos;

    NSLog(@"[MouseTerm] got Data: %@", data);

    EP_execute(chars, length, NO, self);

    NSLog(@"[MouseTerm] appCursor: %@", [self MouseTerm_getIvar:@"appCursorMode"]);
    NSLog(@"[MouseTerm] title: %@", [self customTitle]);
    NSLog(@"[MouseTerm] mouseMode: %@", [self MouseTerm_getIvar:@"mouseMode"]);

    
    // // } else if ((pos = strnstr(chars, ALTERNATE_SCREEN, length))) {
    // //     if (length >= (NSUInteger) (&pos[ALTERNATE_SCREEN_LEN] - chars) + 1) {
    // //         NSUInteger flag = pos[ALTERNATE_SCREEN_LEN]==TOGGLE_ON?1:0;
    // //         NSLog(@"[MouseTerm] got Alternate screen escape toggle: %d", flag);
    // //         if (!(BOOL) [(NSNumber*)
    // //                        get_ivar(self, @"enableAlternateScreen") boolValue]) {
    // //             set_ivar([self view], @"altScreenActive",
    // //                      [NSNumber numberWithInt: flag]);
    // //             NSLog(@"[MouseTerm] Alternate screen disabled; call intercepted.");
    // //             return;
    // //         }
    // //     }
    // // Handle application cursor keys mode toggle
    // //
    // // Note: This information does exist on the TTVT100Emulator object
    // // already, but it's in private member data, and there's no method
    // // that returns any data from it. That means we have to look for it
    // // ourselves.

    [self MouseTerm_shellDidReceiveData: data];
}

@end

@implementation TTView (MouseTermTTView)

// FIXME: These need to be implemented!
#if 0
- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] mouseDown");
    return [self MouseTerm_mouseDown: event];
}

- (void) MouseTerm_mouseDragged: (NSEvent*) event
{
    NSLog(@"[MouseTerm] mouseDragged");
    return [self MouseTerm_mouseDragged: event];
}

- (void) MouseTerm_mouseUp: (NSEvent*) event
{
    NSLog(@"[MouseTerm] mouseUp");
    return [self MouseTerm_mouseUp: event];
}

- (void) MouseTerm_rightMouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseDown");
    return [self MouseTerm_rightMouseDown: event];
}

- (void) MouseTerm_rightMouseDragged: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseDragged");
    return [self MouseTerm_rightMouseDragged: event];
}

- (void) MouseTerm_rightMouseUp: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseUp");
    return [self MouseTerm_rightMouseUp: event];
}

- (void) MouseTerm_otherMouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseDown");
    return [self MouseTerm_otherMouseDown: event];
}

- (void) MouseTerm_otherMouseDragged: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseDragged");
    return [self MouseTerm_otherMouseDragged: event];
}

- (void) MouseTerm_otherMouseUp: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseUp");
    return [self MouseTerm_otherMouseUp: event];
}
#endif

// Intercepts all scroll wheel movements (one wheel "tick" at a time)
- (void) MouseTerm_scrollWheel: (NSEvent*) event
{
    // Don't handle any scrolling if alt/option is pressed
    if ([event modifierFlags] & NSAlternateKeyMask)
        goto ignored;

    // Don't handle scrolling if the scroller isn't at the bottom
    unsigned int scrollback =
        (unsigned int) [[self logicalScreen] lineCount] -
        (unsigned int) [self rowCount];

    if (scrollback > 0 &&
        [[(TTTabController*) [self controller] scroller] floatValue] < 1.0)
    {
        goto ignored;
    }

    switch ([(NSNumber*) get_ivar(self, @"mouseMode") intValue])
    {
        case NO_MODE:
        {
            BOOL maybeAppScroll = NO;
            if ((BOOL) [(NSNumber*) 
                           get_ivar(self, @"enableAlternateScreen") boolValue]) {
                if ((BOOL) [(TTLogicalScreen*) [self logicalScreen]
                                               isAlternateScreenActive]) {
                    maybeAppScroll = YES;
                }
            } else {
                if ((BOOL) [(NSNumber*) 
                               get_ivar(self,
                                        @"altScreenActive") boolValue]) {

                
                   maybeAppScroll = YES; 
                }
            }
            NSLog(@"[MouseTerm] MaybeScroll %d", maybeAppScroll);                

            if(maybeAppScroll &&
               [(NSNumber*) get_ivar(self, @"appCursorMode") boolValue])
            {
                NSLog(@"[MouseTerm] AppCursor Scroll called");

                // Calculate how many lines to scroll by (takes acceleration
                // into account)
                NSData* data;
                // deltaY returns CGFloat, which can be float or double
                // depending on the architecture. Upcasting floats to doubles
                // seems like an easier compromise than detecting what the
                // type really is.
                double delta = [event deltaY];

                // Trackpads seem to return a lot of 0.0 events, which
                // shouldn't trigger scrolling anyway.
                if (delta == 0.0)
                    goto handled;
                else if (delta < 0.0)
                {
                    delta = fabs(delta);
                    data = [NSData dataWithBytes: DOWN_ARROW_APP
                                   length: ARROW_LEN];
                }
                else
                {
                    data = [NSData dataWithBytes: UP_ARROW_APP
                                   length: ARROW_LEN];
                }

                TTShell* shell = [[self controller] shell];
                long i;
                long lines = lround(delta) + 1;
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
            MouseButton button;
            double delta = [event deltaY];
            if (delta == 0.0)
                goto handled;
            else if (delta < 0.0)
            {
                delta = fabs(delta);
                button = MOUSE_WHEEL_DOWN;
            }
            else
                button = MOUSE_WHEEL_UP;

            NSPoint viewloc = [self convertPoint: [event locationInWindow]
                                    fromView: nil];
            Position pos = [self displayPositionForPoint: viewloc];
            // The above method returns the position *including* scrollback,
            // so we have to compensate for that.
            pos.y -= scrollback;
            NSData* data = mousePress(button, [event modifierFlags], pos.x,
                                      pos.y);

            TTShell* shell = [[self controller] shell];
            long i;
            long lines = lround(delta) + 1;
            for (i = 0; i < lines; ++i)
                [shell writeData: data];

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
    set_ivar(self, @"mouseMode", [NSNumber numberWithInt: NO_MODE]);
    set_ivar(self, @"appCursorMode", [NSNumber numberWithBool: NO]);

    set_ivar(self, @"enableAlternateScreen", [NSNumber numberWithBool: YES]);
    set_ivar(self, @"altScreenActive", [NSNumber numberWithBool: NO]);

    return [self MouseTerm_initWithFrame: frame];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
