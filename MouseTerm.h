#import <Cocoa/Cocoa.h>

// Classes from Terminal.app being overridden

typedef struct
{
    unsigned int y;
    unsigned int x;
} Position;

@interface TTView: NSScrollView
- (Position) displayPositionForPoint: (NSPoint) point;
@end

@interface TTTabController: NSObject
@end

// Custom instance variables
extern NSMutableDictionary* MouseTerm_ivars = nil;
