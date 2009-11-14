CFLAGS=-bundle -framework Cocoa -O2 -Wall -Wno-protocol -Wno-undeclared-selector

PARSER=EscapeParser
OBJECTS=JRSwizzle.m MouseTerm.m Terminal.m $(PARSER).m
NAME=MouseTerm
TARGET=$(NAME).bundle/Contents/MacOS/$(NAME)
DMGFILES=$(NAME).bundle README.txt LICENSE.txt
CC = gcc-4.2
RL = ragel
OSXVER=10.5

.PHONY: build install clean copy-plist build-native dmg

%.m: %.rl
	$(RL) -C -o $@ $<

copy-plist:
	mkdir -p $(NAME).bundle/Contents/MacOS
	cp Info.plist $(NAME).bundle/Contents

build: copy-plist $(PARSER)
	$(CC) $(CFLAGS) -arch i386 -mmacosx-version-min$(OSXVER) $(OBJECTS) -o $(TARGET)
	cp Info.plist $(NAME).bundle/Contents

build-native: copy-plist $(PARSER)
	mkdir -p $(NAME).bundle/Contents/MacOS
	$(CC) $(CFLAGS) $(OBJECTS) -o $(TARGET)
	cp Info.plist $(NAME).bundle/Contents

dmg:
	rm -rf $(NAME) $(NAME).dmg
	mkdir $(NAME)
	osacompile -o $(NAME)/Install.app Install.scpt
	osacompile -o $(NAME)/Uninstall.app Uninstall.scpt
	cp -R $(DMGFILES) $(NAME)
	hdiutil create -fs HFS+ -imagekey zlib-level=9 \
		-srcfolder $(NAME) -volname $(NAME) $(NAME).dmg
	rm -rf $(NAME)
clean:
	rm EscapeParser.m
	rm -rf $(NAME).bundle
	rm -f $(NAME).dmg

install: buildnative
	mkdir -p $(HOME)/Library/Application\ Support/SIMBL/Plugins
	cp -R $(NAME).bundle $(HOME)/Library/Application\ Support/SIMBL/Plugins
