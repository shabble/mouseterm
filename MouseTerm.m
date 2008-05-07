#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>

#import "JRSwizzle.h"

// Dummy implementations to fix 64-bit linking
@implementation TTView
- (Position) displayPositionForPoint: (NSPoint) point {}
@end

@implementation TTTabController
@end

NSMutableDictionary* MouseTerm_ivars = nil;

@interface MouseTerm: NSObject
@end

@implementation MouseTerm

// FIXME: Revert swizzled methods when a swizzle fails
+ (void) load
{
    Class cl1 = NSClassFromString(@"TTTabController");
    if (!cl1)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTTabController");
        return;
    }
    if (!class_getInstanceMethod(cl1, @selector(shellDidReceiveData:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTTabController "
               "shellDidReceiveData:]");
        return;
    }

    Class cl2 = NSClassFromString(@"TTView");
    if (!cl2)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTView");
        return;
    }
    if (!class_getInstanceMethod(cl2, @selector(initWithFrame:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView "
               "initWithFrame:]");
        return;
    }
    if (!class_getInstanceMethod(cl2, @selector(dealloc)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView dealloc]");
        return;
    }
    if (!class_getInstanceMethod(cl2, @selector(scrollWheel:)))
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Method for [TTView scrollWheel:]");
        return;
    }

    // Initialize instance vars before any swizzling so nothing bad happens
    // if some methods are swizzled but not others.
    MouseTerm_ivars = [[NSMutableDictionary alloc] init];

    if (![cl2 jr_swizzleMethod: @selector(initWithFrame:)
              withMethod: @selector(MouseTerm_initWithFrame:)
              error: nil])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle [TTView "
               "initWithFrame:]");
        return;
    }

    if (![cl2 jr_swizzleMethod: @selector(dealloc)
              withMethod: @selector(MouseTerm_dealloc)
              error: nil])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle [TTView dealloc]");
        return;
    }

    if (![cl2 jr_swizzleMethod: @selector(scrollWheel:)
              withMethod: @selector(MouseTerm_scrollWheel:)
              error: nil])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle [TTView scrollWheel:]");
        return;
    }

    if (![cl1 jr_swizzleMethod: @selector(shellDidReceiveData:)
              withMethod: @selector(MouseTerm_shellDidReceiveData:)
              error: nill])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to swizzle "
               "[TTTabController shellDidReceiveData:]");
        return;
    }
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
