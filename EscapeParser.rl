#import <Cocoa/Cocoa.h>
#import <math.h>
#import "EscapeParser.h"
#import "MouseTerm.h"
#import "Mouse.h"


%%{
	machine EscapeSeqParser;

    action got_toggle {
        NSLog(@"[MouseTerm] Parsed Toggle");
    }

    action got_title {
        NSLog(@"[MouseTerm] Parsed Title: %@", [stateObj pendingTitleString]);
//        [mobj MouseTerm_updateMouseTitle];
        [mobj MouseTerm_setCustomTitle:[stateObj pendingTitleString]];
        [stateObj clearPendingTitleString];
    }

    action handle_flag {
        if (fc == 'h') {
            [stateObj setStateToggle:YES];
        } else {
            [stateObj setStateToggle:NO];
        }

        NSLog(@"[MouseTerm] Parsed ToggleFlag: %d", [stateObj stateToggle]);
    }

    action handle_title_string {
        [stateObj appendPendingTitleString:fc];
    }

    action handle_appkeys {
        NSLog(@"[MouseTerm] Parsed Appkeys %d for %@", [stateObj stateToggle], mobj);
        [mobj MouseTerm_setAppCursorMode: [stateObj stateToggle]];
        //      [mobj MouseTerm_updateMouseTitle];
    }

    action handle_mouse_digit {
        [stateObj setPendingMouseMode:(fc - 48)];
    }

    action handle_mouse {
        int mouseMode = [stateObj pendingMouseMode];
        NSLog(@"[MouseTerm] Parsed MouseMode %d", mouseMode);
        MouseMode newMouseMode = NO_MODE;
        switch(mouseMode) {
        case 0:
            newMouseMode = NORMAL_MODE;
            break;
        case 1:
            newMouseMode = HILITE_MODE;
            break;
        case 2:
            newMouseMode = BUTTON_MODE;
            break;
        case 3:
            newMouseMode = ALL_MODE;
            break;
        default:
            newMouseMode = NO_MODE;
            break;
        }

        if (newMouseMode != NO_MODE) {
            if ([stateObj stateToggle]) {
                [mobj MouseTerm_setMouseMode:newMouseMode];
            } else {
                [mobj MouseTerm_setMouseMode:NO_MODE];
            }
        }
//        [mobj MouseTerm_updateMouseTitle];
    }

    action got_debug {
        NSLog(@"[MouseTerm] Got debug");
        [mobj MouseTerm_writeToShell:@"Hello"];
    }

    esc = 0x1b;
    csi = esc . "[";
    flag = ("h" | "l") @handle_flag;
    osc = esc . ']';
    appkeys = "1";
    mouse = "100" . ([0123]) @handle_mouse_digit;
    mode_toggle = csi . "?" . (appkeys . flag @handle_flag @handle_appkeys 
                               | mouse . flag @handle_flag @handle_mouse );

    debug = (csi . "1i");
    bel = 0x07;
    st  = 0x9c;
    title = osc . "2;" . (print*) $handle_title_string . (bel | st);

    
main := ((any - csi | any - osc)* . ( mode_toggle # @got_toggle 
                                      | title @got_title
                                      | debug @got_debug))*;

}%%

%% write data;


int EP_execute( const char *data, int len, 
                BOOL isEof, id obj,
                MouseTermEscapeParserState *stateObj) 
{
	const char *p = data;
	const char *pe = data + len;
	const char *eof = isEof ? pe : 0;

    int cs = [stateObj state];
    MouseTermTTTabController *mobj = (MouseTermTTTabController*)obj;
    NSThread* ct = [NSThread currentThread];

    if (eof) NSLog(@"[MouseTerm] %@ EOF", [mobj scriptTTY]);
    //NSLog(@"%@ [MouseTerm] %@ EP Exec",ct, [mobj scriptTTY]);

    %%write init nocs;
    %%write exec;
    
    //NSLog(@"%@ [MouseTerm] %@ EP Exec done: s%d",ct,  [mobj scriptTTY],cs);
    [stateObj setState:cs];

	if ( cs == EscapeSeqParser_error )
		return -1;
	if ( cs >= EscapeSeqParser_first_final )
		return 1;
	return 0;
}

