CFLAGS=-bundle -framework Cocoa -O2 -Wall -Wno-protocol -Wno-undeclared-selector

OBJECTS=JRSwizzle.m MouseTerm.m Terminal.m
NAME=MouseTerm
TARGET=$(NAME).bundle/Contents/MacOS/$(NAME)
DMGFILES=$(NAME).bundle README.txt LICENSE.txt
CC = gcc-4.2

.PHONY: build install clean

build: clean
	mkdir -p $(NAME).bundle/Contents/MacOS
	$(CC) $(CFLAGS) -arch i386 -mmacosx-version-min=10.5 $(OBJECTS) -o $(TARGET)
	cp Info.plist $(NAME).bundle/Contents
buildnative:
	mkdir -p $(NAME).bundle/Contents/MacOS
	$(CC) $(CFLAGS) $(OBJECTS) -o $(TARGET)
	cp Info.plist $(NAME).bundle/Contents
builddmg:
	rm -rf $(NAME) $(NAME).dmg
	mkdir $(NAME)
	osacompile -o $(NAME)/Install.app Install.scpt
	osacompile -o $(NAME)/Uninstall.app Uninstall.scpt
	cp -R $(DMGFILES) $(NAME)
	hdiutil create -fs HFS+ -imagekey zlib-level=9 -srcfolder $(NAME) -volname $(NAME) $(NAME).dmg
	rm -rf $(NAME)
clean:
	rm -rf $(NAME).bundle
	rm -f $(NAME).dmg
install: build
	mkdir -p $(HOME)/Library/Application\ Support/SIMBL/Plugins
	cp -R $(NAME).bundle $(HOME)/Library/Application\ Support/SIMBL/Plugins
