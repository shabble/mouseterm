#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>

#import "JRSwizzle.h"

// Classes we're overriding

typedef struct
{
    unsigned int y;
    unsigned int x;
} Position;

@interface TTView: NSScrollView
- (Position) displayPositionForPoint: (NSPoint) point;
@end

@implementation TTView
- (Position) displayPositionForPoint: (NSPoint) point {}
@end

@interface TTTabController: NSObject
@end

@implementation TTTabController
@end

// For custom instance variables
static NSMutableDictionary* MouseTerm_ivars = nil;

#define IVAR(obj, name) \
    [[MouseTerm_ivars objectForKey: [NSValue valueWithPointer: obj]] \
                      objectForKey: name]
#define SET_IVAR(obj, name, value) \
    [[MouseTerm_ivars objectForKey: [NSValue valueWithPointer: obj]] \
                      setObject: value forKey: name]

// Possible mouse modes
typedef enum
{
    NO_MODE = -1,
    NORMAL_MODE,
    HILITE_MODE,
    BUTTON_MODE,
    ALL_MODE
} MouseMode;

// Returns a control code for a mouse movement (from iTerm)
NSData* mousePress(int button, unsigned int modflag, int x, int y)
{
    static char buf[7];
    char cb;

    cb = button % 3;
    if (button > 3)
        cb += 64;
    if (modflag & NSControlKeyMask)
        cb += 16;
    if (modflag & NSShiftKeyMask)
        cb += 4;
    if (modflag & NSAlternateKeyMask)
        cb += 8;

    snprintf(buf, sizeof(buf), "\033[M%c%c%c", 32 + cb, 32 + x + 1,
             32 + y + 1);
    return [NSData dataWithBytes: buf length: sizeof(buf) - 1];
}

@implementation TTTabController (MouseTermTTTabController)

// We intercept all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    // FIXME: What if the data's split up over method calls?
    char* pos;
    if (pos = strnstr([data bytes], "\e[?100", [data length]))
    {
        // FIXME: Possible pointer arithmetic issues? Generates warnings...

        // Is there enough data in the buffer for the next two characters?
        if ([data length] >= (pos + sizeof("\e]?100") - 1 -
                              (const char*) [data bytes]) + 2)
        {
            char mode = pos[6];
            char flag = pos[7];
            MouseMode mouseMode = NO_MODE;

            if (flag == 'h')
            {
                switch (mode)
                {
                case '0':
                    mouseMode = NORMAL_MODE;
                    break;
                case '2':
                    mouseMode = BUTTON_MODE;
                    break;
                case '3': 
                    mouseMode = ALL_MODE;
                    break;
                }
                
                if (mouseMode != NO_MODE)
                    SET_IVAR([self view], @"mouseMode",
                             [NSNumber numberWithInt: mouseMode]);
            }
            // FIXME: Should it turn off reporting for any mode?
            else if (flag == 'l')
                SET_IVAR([self view], @"mouseMode",
                         [NSNumber numberWithInt: NO_MODE]);
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

    // FIXME: Is this necessary?
    if (viewloc.y <= visible.origin.y || modflags & NSAlternateKeyMask)
        goto ignored;

    NSObject* logicalScreen = [self logicalScreen];

    switch ([(NSNumber*) IVAR(self, @"mouseMode") intValue])
    {
        case NO_MODE: {
            // FIXME: This screws up screen. Should probably take a closer
            // look at http://bugzilla.gnome.org/show_bug.cgi?id=424184
            if ((BOOL) [logicalScreen isAlternateScreenActive])
            {
                // FIXME: Need some way to account for scrolling acceleration
                NSData* data = [NSData dataWithBytes: ([event deltaY] > 0 ?
                                "\eOA\eOA\eOA" : "\eOB\eOB\eOB") length: 9];
                [(NSObject*) [[self controller] shell] writeData: data];
                return;
            }
            else
                goto ignored;
        }
        case NORMAL_MODE:
        case BUTTON_MODE:
        case ALL_MODE: {
            Position pos = [self displayPositionForPoint: viewloc];

        [(NSObject*) [[self controller] shell] writeData: mousePress(
                ([event deltaY] > 0 ? 5 : 4),
                [event modifierFlags], pos.x, pos.y)];
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

#undef RESPONSE
#undef IVAR
#undef SET_IVAR

@interface MouseTerm: NSObject
@end

@implementation MouseTerm

// FIXME: What happens when only some methods are swizzled?
+ (void) load
{
    Class cls = NSClassFromString(@"TTTabController");
    if (!cls)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTTabController");
        return;
    }
    if (!class_getInstanceMethod(cls, @selector(shellDidReceiveData:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTTabController "
               "shellDidReceiveData:]");
        return;
    }

    NSError* error = nil;

    if (![cls jr_swizzleMethod: @selector(shellDidReceiveData:)
              withMethod: @selector(MouseTerm_shellDidReceiveData:)
              error: &error])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle "
               "[TTTabController shellDidReceiveData:]: %@", error);
        return;
    }

    cls = NSClassFromString(@"TTView");
    if (!cls)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTView");
        return;
    }
    if (!class_getInstanceMethod(cls, @selector(initWithFrame:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView "
               "initWithFrame:]");
        return;
    }
    if (!class_getInstanceMethod(cls, @selector(dealloc)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView dealloc]");
        return;
    }
    if (!class_getInstanceMethod(cls, @selector(scrollWheel:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView scrollWheel:]");
        return;
    }

    error = nil;

    if (![cls jr_swizzleMethod: @selector(initWithFrame:)
              withMethod: @selector(MouseTerm_initWithFrame:)
              error: &error])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle [TTView "
               "initWithFrame:]: %@", error);
        return;
    }

    if (![cls jr_swizzleMethod: @selector(dealloc)
              withMethod: @selector(MouseTerm_dealloc)
              error: &error])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle [TTView dealloc]: %@",
              error);
        return;
    }

    if (![cls jr_swizzleMethod: @selector(scrollWheel:)
              withMethod: @selector(MouseTerm_scrollWheel:)
              error: &error])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle "
               "[TTView scrollWheel:]: %@", error);
        return;
    }

    MouseTerm_ivars = [[NSMutableDictionary alloc] init];
}

// Deletes instance variables dictionary
- (BOOL) unload
{
    if (MouseTerm_ivars)
    {
        [MouseTerm_ivars release];
        MouseTerm_ivars = nil;
    }

    return YES;
}

@end
