#import <Cocoa/Cocoa.h>
#import "Mouse.h"

// Classes from Terminal.app being overridden

typedef struct
{
    unsigned int y;
    unsigned int x;
} Position;

@interface TTView: NSView
- (Position) displayPositionForPoint: (NSPoint) point;
- (id)logicalScreen;
- (id)controller;
- (id)selectedText;
- (void)openURL:(id)fp8;
- (void)clearTextSelection;
- (void)selectTextBetweenDisplayPositions:(Position)fp8 positionTwo:(Position)fp16 rememberPositions:(BOOL)fp24;

@end

@interface TTTabController: NSObject
- (void) setCustomTitle:(id)fp8;
- (id)   customTitle;
- (id)   tabTitle;
- (id)   view;
- (id)   scroller;
- (id)   shell;
- (id)   getWindowController;

@end
@interface TTWindowController : NSWindowController
- (void)updateTitle;
@end

@interface TTTabController (Scripting)
- (id)scriptTTY;
- (void)setScriptCustomTitle:(id)fp8;
@end

@interface TTShell: NSObject
- (void)writeData:(id)fp8;
@end

@interface TTLogicalScreen: NSObject
- (BOOL)isAlternateScreenActive;
- (void)setScriptCustomTitle:(id)fp8;
- (unsigned int)lineCount;
- (unsigned int)rowCount;
- (unsigned int)columnCount;

@end

@interface MouseTermTTTabController : TTTabController 
- (BOOL) MouseTerm_getAppCursorMode;
- (void) MouseTerm_setAppCursorMode:(BOOL)isEnabled;
- (void)MouseTerm_updateMouseTitle;
- (NSString*)MouseTerm_customTitle;

- (MouseMode) MouseTerm_getMouseMode;
- (void) MouseTerm_setMouseMode:(MouseMode)setting;
- (void) MouseTerm_setCustomTitle:(NSString*)title;
- (id) MouseTerm_getIvar:(NSString*)name;
- (void) MouseTerm_setIvar:(NSString*)name toValue:(id)value;

- (void) MouseTerm_writeToShell:(NSString*)data;

@end

@interface MouseTermEscapeParserState : NSObject 
{
    NSMutableString* pending_TitleStr;
    int m_state;
    int pending_mouse_mode;
    BOOL m_toggle;
}
- (id)  init;
- (void) dealloc;
- (int) state;
- (void) setState:(int)to;
- (int) pendingMouseMode;
- (void) setPendingMouseMode:(int)to;
- (NSMutableString*)pendingTitleString;
- (void)clearPendingTitleString;
- (void)setPendingTitleString:(NSString*)string;
- (void)appendPendingTitleString:(char)c;
- (BOOL) stateToggle;
- (void) setStateToggle:(BOOL)state;
@end

// Custom instance variables
extern NSMutableDictionary* MouseTerm_ivars;
