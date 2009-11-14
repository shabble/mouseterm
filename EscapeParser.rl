#import <Cocoa/Cocoa.h>
#import <math.h>
#import "EscapeParser.h"
#import "Mouse.h"


%%{
	machine EscapeSeqParser;

    action got_toggle {
        NSLog(@"[MouseTerm] Parsed Toggle");
    }

    action got_title {
        NSLog(@"[MouseTerm] Parsed Title: %@", titleStr);
        [obj setScriptCustomTitle:titleStr];
        NSRange all = NSMakeRange(0, [titleStr length]);
        [titleStr deleteCharactersInRange:all];
        //[titleStr dealloc];
    }

    action handle_flag {
        if (fc == 'h') {
            toggle_flag = YES;
        } else {
            toggle_flag = NO;
        }
        NSLog(@"[MouseTerm] Parsed ToggleFlag: %d", toggle_flag);
    }

    action handle_title_string {
        [titleStr appendFormat:@"%c", fc];
    }

    action handle_appkeys {
        NSLog(@"[MouseTerm] Parsed Appkeys %d", toggle_flag);
        [obj MouseTerm_setIvar:@"appCursorMode"
         toValue: [NSNumber numberWithBool: toggle_flag]];
    }

    action handle_mouse_digit {
        mouseMode = (mouseMode * 10) + (fc - 48);
    }

    action handle_mouse {
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
            if (toggle_flag) {
                [obj MouseTerm_setIvar:@"mouseMode"
                 toValue:[NSNumber numberWithInt: newMouseMode]];
            } else {
                [obj MouseTerm_setIvar:@"mouseMode"
                 toValue:[NSNumber numberWithInt: NO_MODE]];
            }
        }
        mouseMode = 0;
    }

    esc = 0x1b;
    csi = esc . "[";
    flag = ("h" | "l") @handle_flag;
    osc = esc . ']';
    appkeys = "1";
    mouse = "100" . (digit+) $handle_mouse_digit;
    mode_toggle = csi . "?" . (appkeys . flag @handle_flag @handle_appkeys 
                               | mouse . flag @handle_flag @handle_mouse );

    title = osc . "2;" . (print+) $handle_title_string . 0x07;

    
main := ((any - csi | any - osc)* . ( mode_toggle @got_toggle 
                                      | title @got_title))*;

}%%

%% write data;


int EP_execute( const char *data, int len, BOOL isEof, id obj ) {
	const char *p = data;
	const char *pe = data + len;
	const char *eof = isEof ? pe : 0;

    BOOL toggle_flag = NO;
    NSMutableString *titleStr = [NSMutableString stringWithCapacity:10];
    int mouseMode = 0;
    int cs;
    NSLog(@"[MouseTerm] EP Exec");

    %% write init;
	%% write exec;
    
    NSLog(@"[MouseTerm] EP Exec done");

	if ( cs == EscapeSeqParser_error )
		return -1;
	if ( cs >= EscapeSeqParser_first_final )
		return 1;
	return 0;
}
