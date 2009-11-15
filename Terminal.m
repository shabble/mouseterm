#import <Cocoa/Cocoa.h>
#import <math.h>

#import "MouseTerm.h"
#import "Mouse.h"
#import "EscapeParser.h"
#import "RegexKitLite.h"

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
    NSLog(@"Set_ivar: setting %@ to %@", name, value);
    [[MouseTerm_ivars objectForKey: ptr] setObject: value forKey: name];
}

@implementation TTTabController (MouseTermTTTabController)

- (id)MouseTerm_tabTitle {
    id tty = [self scriptTTY];
    id mtself = (MouseTermTTTabController*)self;
//    return @"Hello";
    NSString* title = [mtself MouseTerm_customTitle];
    NSLog(@"[MouseTerm] %@ tabTitle called: [%@]", tty, title);
    if ([title compare:@""] != 0) {
        NSString* debug = [mtself MouseTerm_getIvar:@"mouseDebug"];
        if ([debug compare:@""] != 0) {
            NSString* dbgTitle
                = [NSString stringWithFormat:@"%@ %@", 
                            debug, title];
            [dbgTitle retain];
            NSLog(@"[MouseTerm] %@ Title: Custom: %@", tty, dbgTitle);
            return dbgTitle;
        }
        NSLog(@"[MouseTerm] %@ Title: Custom: %@", tty, title);
        return title;
    } else {
        NSLog(@"[MouseTerm] tT is nil, here's what we have: %@",
              [MouseTerm_ivars objectForKey: [NSValue valueWithPointer: self]]);
    }
    id def = [self MouseTerm_tabTitle]; // Call parent
    NSLog(@"[MouseTerm] %@ Title: default: %@", tty, def);
    return def;
}
- (void)MouseTerm_updateMouseTitle {
    id mtself = (MouseTermTTTabController*) self;
    char blah[4] = { 'k', 0, 0, 0};
    BOOL appKeys = (BOOL) [mtself MouseTerm_getAppCursorMode];
    //NSLog(@"[MouseTerm] Appkeys is now: %d in %@", appKeys, mobj);
    
    if (appKeys) {
        blah[0] = 'K';
    }
    blah[1] = ((int)[mtself MouseTerm_getMouseMode])+'0';
    blah[2] = 'a';
    if ([[[self view] logicalScreen] isAlternateScreenActive]) {
        blah[2] = 'A';
    }

    NSString* title
        = [NSString stringWithFormat:@"%s", blah];
    [title retain];
    set_ivar(self, @"mouseDebug", title);
    [self setScriptCustomTitle:[mtself MouseTerm_customTitle]];
}

- (NSString*)MouseTerm_customTitle {
    return [((MouseTermTTTabController*)self) MouseTerm_getIvar:@"customTabTitle"];
}

- (void)MouseTerm_setCustomTitle:(id)fp8 {
    //id mtself = (MouseTermTTTabController*)self;
    NSString *str;
    
    if (fp8 != nil) {
        str = [[NSString alloc] initWithString:fp8];
        NSLog(@"[MouseTerm] setCustomTitle: %@, %@", str, [self scriptTTY]);
        set_ivar(self, @"customTabTitle", str);
        
        // I have *no* idea why this is necessary, but it appears to do
        // something that setCustomTitle doesn't.  We don't actually use the
        // value since it's stored locally in an ivar, but something it does
        // triggers the title update.
        
        [self setScriptCustomTitle:str];
    }

}

- (id)   MouseTerm_getIvar:(NSString*)name {
    return get_ivar(self, name);
}

- (void) MouseTerm_setIvar:(NSString*)name toValue:(id)value {
    set_ivar(self, name, value);
}

- (BOOL) MouseTerm_getAppCursorMode {
    BOOL acm=((BOOL)
            [(NSNumber*) 
                get_ivar(self, @"appCursorMode") boolValue]);
    //NSLog(@"[MouseTerm] MT_gACM: %d", bob);
    return acm;
}

- (void) MouseTerm_setAppCursorMode: (BOOL)isEnabled {
    //NSLog(@"[MouseTerm] MT_sACM: %d", isEnabled);
    set_ivar(self, @"appCursorMode", [NSNumber numberWithBool: isEnabled]);
}

- (MouseMode) MouseTerm_getMouseMode {
    return ((MouseMode) [(NSNumber*) 
                            get_ivar(self, @"mouseMode") intValue]);
}

- (void) MouseTerm_setMouseMode: (MouseMode)setting {
    set_ivar(self, @"mouseMode", [NSNumber numberWithInt: setting]);
}

- (void) MouseTerm_writeToShell:(NSString*)data {
    TTShell* shell = [self shell];
    NSData* dataFromString = [data dataUsingEncoding:NSMacOSRomanStringEncoding];
    [shell writeData:dataFromString];
}

- (MouseTermEscapeParserState*) MouseTerm_getParserState {
    return ((MouseTermEscapeParserState*) 
            get_ivar(self, @"parserState"));
}

// - (void) MouseTerm_setMouseMode: (MouseMode)setting {
//     set_ivar([self view], @"mouseMode", [NSNumber numberWithInt: setting]);
// }

// Swizzled into the TTShell
// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    NSUInteger length = [data length];
    const char* chars = [data bytes];
    //NSLog(@"init: %@", get_ivar(self, @"initialised"));
    if (get_ivar(self, @"initialised") ==NULL) {
        set_ivar(self, @"mouseMode", [NSNumber numberWithInt: NO_MODE]);
        set_ivar(self, @"appCursorMode", [NSNumber numberWithBool: NO]);
        
        set_ivar(self, @"enableAlternateScreen", [NSNumber numberWithBool: YES]);
        set_ivar(self, @"altScreenActive", [NSNumber numberWithBool: NO]);
        
        MouseTermEscapeParserState* esp = [[MouseTermEscapeParserState alloc] init];
        set_ivar(self, @"parserState", esp);
        NSLog(@"[MouseTerm] Initialised State");
        set_ivar(self, @"customTabTitle", @"xxx");
        set_ivar(self, @"mouseDebug", @"");
        set_ivar(self, @"initialised", [NSNumber numberWithBool: YES]);
     
        NSLog(@"Initialised ivar dict");
    }
    NSLog(@"[MouseTerm] got Data: %@", data);
    MouseTermEscapeParserState *state = [self MouseTerm_getParserState];

    EP_execute(chars, length, NO, self, state);
    [self MouseTerm_updateMouseTitle];

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

@interface MT_ThreadedOpen: NSObject
+ (void) openURL:(id)urlId;
@end
@implementation MT_ThreadedOpen
+ (void) openURL:(id)urlId {

    NSURL *url = (NSURL*)urlId;
    NSLog(@"Opening url %@ in thread: %@", url, [NSThread currentThread]);
    [url retain];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [url release];
}

@end
@implementation TTView (MouseTermTTView)

// FIXME: These need to be implemented!

- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    unsigned int rows = (unsigned int) [[self logicalScreen] rowCount];
    unsigned int cols = (unsigned int) [[self logicalScreen] columnCount];//[self performSelector:@selector(columnCount)];
    // NSLog(@"colcount returned %@", bob);
    // unsigned int cols = 100;
//(unsigned int) [self columnCount];

    unsigned int scrollback =
        (unsigned int) [[self logicalScreen] lineCount] - rows;

    NSPoint viewloc = [self convertPoint: [event locationInWindow]
                                fromView: nil];
    Position pos = [self displayPositionForPoint: viewloc];
    pos.y -= scrollback;

    Position pos2;
    pos2.y = pos.y;
    pos2.x = cols -1;
    NSLog(@"[MouseTerm] mouseDown %@ at %d, %d",event, pos.x, pos.y);
    NSLog(@"[MouseTerm] selecting (%d, %d)--(%d, %d)", pos.x, pos.y, pos2.x, pos2.y);
    [self selectTextBetweenDisplayPositions:pos positionTwo:pos2 rememberPositions:YES];
    NSString* selection = [[NSString alloc] initWithString:[self selectedText]];
    NSLog(@"[Mouseterm] Selection: %@", selection);
    [self clearTextSelection];
    NSString *regexString = @"\\b(https?://\\S+?)\\s*$";
    NSString *matchedString = [selection stringByMatching:regexString capture:1L];


    if (matchedString) {
        NSLog(@"Matched: %@", matchedString);
        NSURL *url = [[NSURL URLWithString:matchedString] retain];

        NSLog(@"Url: %@, Thread; %@", url, [NSThread currentThread]);
        // [NSThread detachNewThreadSelector:@selector(openURL:) 
        //                          toTarget:[MT_ThreadedOpen class]
        //                        withObject:url];
        [MT_ThreadedOpen performSelectorInBackground:@selector(openURL:)
                                          withObject:url];
        //[[NSWorkspace sharedWorkspace] openURL:url];
        [url release];
    }
    [selection release];

    return [self MouseTerm_mouseDown: event];
}
- (void) MouseTerm_rightMouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseDown");
    return [self MouseTerm_rightMouseDown: event];
}

#if 0
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
        (unsigned int) [[self logicalScreen] rowCount];

    if (scrollback > 0 &&
        [[(TTTabController*) [self controller] scroller] floatValue] < 1.0)
    {
        goto ignored;
    }

    switch ([(NSNumber*) get_ivar([self controller], @"mouseMode") intValue])
    {
        case NO_MODE:
        {
            BOOL maybeAppScroll = NO;
            if ((BOOL) [(NSNumber*) 
                           get_ivar([self controller], @"enableAlternateScreen") boolValue]) {
                if ((BOOL) [(TTLogicalScreen*) [self logicalScreen]
                                               isAlternateScreenActive]) {
                    maybeAppScroll = YES;
                }
            } else {
                if ((BOOL) [(NSNumber*) 
                               get_ivar([self controller],
                                        @"altScreenActive") boolValue]) {

                
                   maybeAppScroll = YES; 
                }
            }
            NSLog(@"[MouseTerm] MaybeScroll %d", maybeAppScroll);                

            if(maybeAppScroll &&
               [(NSNumber*) get_ivar([self controller], @"appCursorMode") boolValue])
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
    NSLog(@"[MouseTerm] starting up");
    [MouseTerm_ivars setObject: [NSMutableDictionary dictionary]
                     forKey: [NSValue valueWithPointer: self]];


    return [self MouseTerm_initWithFrame: frame];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    // TODO: dealloc our parser state.
    MouseTermEscapeParserState* esp = get_ivar(self, @"parserState");
    [esp dealloc];
//    [esp release];
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
