#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>

#import "JRSwizzle.h"

#import "MouseTerm.h"

 NSMutableDictionary* MouseTerm_ivars = nil;

@interface MouseTerm: NSObject
@end

@implementation MouseTerm

#define EXISTS(cls, sel)                                                 \
    do {                                                                 \
        if (!class_getInstanceMethod(cls, sel))                          \
        {                                                                \
            NSLog(@"[MouseTerm] ERROR: Got nil Method for [%@ %s]", cls, \
                  sel);                                                  \
            return;                                                      \
        }                                                                \
    } while (0)

#define SWIZZLE(cls, sel1, sel2)                                        \
    do {                                                                \
        if (![cls jr_swizzleMethod: sel1 withMethod: sel2 error: nil])  \
        {                                                               \
            NSLog(@"[MouseTerm] ERROR: Failed to swizzle [%@ %s]", cls, \
                  sel1);                                                \
            return;                                                     \
        }                                                               \
    } while (0)

+ (void) load
{
    Class controller = NSClassFromString(@"TTTabController");
    if (!controller)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTTabController");
        return;
    }

    EXISTS(controller, @selector(shellDidReceiveData:));
    EXISTS(controller, @selector(view));
    EXISTS(controller, @selector(scroller));

    EXISTS(controller, @selector(tabTitle));
//    EXISTS(controller, @selector(setCustomTitle));

    Class logicalScreen = NSClassFromString(@"TTLogicalScreen");
    if (!logicalScreen)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTLogicalScreen");
        return;
    }

    EXISTS(logicalScreen, @selector(isAlternateScreenActive));

    Class shell = NSClassFromString(@"TTShell");
    if (!shell)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTShell");
        return;
    }

    EXISTS(shell, @selector(writeData:));

    Class view = NSClassFromString(@"TTView");
    if (!view)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTView");
        return;
    }

    EXISTS(view, @selector(initWithFrame:));
    EXISTS(view, @selector(dealloc));
    EXISTS(view, @selector(scrollWheel:));
    EXISTS(view, @selector(rowCount));
    EXISTS(view, @selector(controller));
    EXISTS(view, @selector(logicalScreen));

    // Initialize instance vars before any swizzling so nothing bad happens
    // if some methods are swizzled but not others.
    MouseTerm_ivars = [[NSMutableDictionary alloc] init];

    SWIZZLE(view, @selector(initWithFrame:),
            @selector(MouseTerm_initWithFrame:));
    SWIZZLE(view, @selector(dealloc), @selector(MouseTerm_dealloc));
    SWIZZLE(view, @selector(scrollWheel:), @selector(MouseTerm_scrollWheel:));

    SWIZZLE(view, @selector(mouseDown:), @selector(MouseTerm_mouseDown:));

    SWIZZLE(view, @selector(rightMouseDown:),
            @selector(MouseTerm_rightMouseDown:));

#if 0
    SWIZZLE(view, @selector(mouseDragged:),
            @selector(MouseTerm_mouseDragged:));
    SWIZZLE(view, @selector(mouseUp:), @selector(MouseTerm_mouseUp:));
    SWIZZLE(view, @selector(rightMouseDragged:),
            @selector(MouseTerm_rightMouseDragged:));
    SWIZZLE(view, @selector(rightMouseUp:),
            @selector(MouseTerm_rightMouseUp:));
    SWIZZLE(view, @selector(otherMouseDown:),
            @selector(MouseTerm_otherMouseDown:));
    SWIZZLE(view, @selector(otherMouseDragged:),
            @selector(MouseTerm_otherMouseDragged:));
    SWIZZLE(view, @selector(otherMouseUp:),
            @selector(MouseTerm_otherMouseUp:));
#endif
    SWIZZLE(controller, @selector(shellDidReceiveData:),
            @selector(MouseTerm_shellDidReceiveData:));
    // SWIZZLE(controller, @selector(setCustomTitle:),
    //         @selector(MouseTerm_setCustomTitle:));

    SWIZZLE(controller, @selector(tabTitle),
            @selector(MouseTerm_tabTitle));


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
