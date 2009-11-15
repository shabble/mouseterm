#import <Cocoa/Cocoa.h>
#import <math.h>

#import "MouseTerm.h"
#import "Mouse.h"
#import "EscapeParser.h"


@implementation MouseTermEscapeParserState

- (int) state {
    //NSLog(@"[MouseTerm] state called value: %d", m_state);
    return m_state;
}
- (void) setState:(int)to {
    m_state = to;
}
- (BOOL) stateToggle {
    return m_toggle;
}
- (void) setStateToggle:(BOOL)state {
    m_toggle = state;
}

- (int) pendingMouseMode {
    return pending_mouse_mode;
}
- (void) setPendingMouseMode:(int)to {
    pending_mouse_mode = to;
}
- (NSMutableString*)pendingTitleString {
    return pending_TitleStr; 
}

- (void)clearPendingTitleString {
    [pending_TitleStr setString:@""];
}

- (void)setPendingTitleString:(NSString*)string {
    [pending_TitleStr setString:string];
}
- (void)appendPendingTitleString:(char)chr {
    [pending_TitleStr appendFormat:@"%c", chr];
}

- (id) init {
    if ((self = [super init])) {
        m_state = 0;
        pending_mouse_mode = -1;
        pending_TitleStr = [[NSMutableString stringWithCapacity:10] retain];
        //NSLog(@"[MouseTerm] Initialised Parser State, %@", pending_TitleStr);
    }

    return self;
}
- (void) dealloc {
    [pending_TitleStr release];
//    [super dealloc];
}
@end;
