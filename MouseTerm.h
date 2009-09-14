#import <Cocoa/Cocoa.h>

// Classes from Terminal.app being overridden

#ifdef __x86_64__
typedef unsigned long long linecount_t;
#else
typedef unsigned int linecount_t;
#endif

typedef struct
{
    linecount_t y;
    linecount_t x;
} Position;

@interface TTShell: NSObject
- (void) writeData: (NSData*) data;
@end

@interface TTLogicalScreen: NSObject
- (BOOL) isAlternateScreenActive;
- (linecount_t) lineCount;
@end

@interface TTPane: NSObject
- (NSScroller*) scroller;
@end

@interface TTTabController
- (TTShell*) shell;
@end

@interface NSObject (MouseTermTTTabController)
- (TTShell*) shell;
@end

@interface NSView (MouseTermTTView)
- (TTLogicalScreen*) logicalScreen;
- (linecount_t) rowCount;
- (TTPane*) pane;
- (TTTabController*) controller;
- (Position) displayPositionForPoint: (NSPoint) point;
@end

// Custom instance variables
extern NSMutableDictionary* MouseTerm_ivars;
