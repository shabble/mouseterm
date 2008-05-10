#import <Cocoa/Cocoa.h>

// Classes from Terminal.app being overridden

typedef struct
{
    unsigned int y;
    unsigned int x;
} Position;

@interface TTView: NSView
- (Position) displayPositionForPoint: (NSPoint) point;
@end

@interface TTTabController: NSObject
@end

@interface TTShell: NSObject
@end

@interface TTLogicalScreen: NSObject
@end

// Custom instance variables
extern NSMutableDictionary* MouseTerm_ivars;
