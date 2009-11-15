#import "MouseTerm.h"

int EP_init(void);
int EP_execute(const char *data, int len, BOOL isEof, id obj, 
    MouseTermEscapeParserState *state);

