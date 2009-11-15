CFLAGS=-g -O -Wall #-Wno-protocol -Wno-undeclared-selector
LDFLAGS=-bundle -framework Cocoa -licucore
PARSER=EscapeParser
OBJECTS:=JRSwizzle.o \
	MouseTerm.o \
	Terminal.o \
	$(PARSER).o \
	MouseTermEscapeParserState.o \
	RegexKitLite.o

NAME=MouseTerm

BUNDLE=$(NAME).bundle
TARGET=$(BUNDLE)/Contents/MacOS/$(NAME)
DMGFILES=$(BUNDLE) README.txt LICENSE.txt
INFO=$(BUNDLE)/Contents/Info.plist

CC:=gcc-4.2
RL:=ragel
OSXVER:=10.5

ARCHES=$(foreach arch,$(ARCH_LIST),-arch $(arch))

.PHONY: build install clean build_native dmg uninstall
.PRECIOUS: $(PARSER).m

build_native: | $(TARGET) $(INFO)

build: ARCH_LIST=i386 ppc
build: |  $(TARGET) $(INFO)

%.m: %.rl
	$(RL) -C -o $@ $<

%.o: %.m
	$(CC) -mmacosx-version-min=$(OSXVER) -c $(ARCHES) $(CFLAGS) $< -o $@

$(TARGET): $(OBJECTS)
	mkdir -p $(NAME).bundle/Contents/MacOS
	$(CC) -mmacosx-version-min=$(OSXVER) $(ARCHES) \
		$(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $(TARGET)

$(INFO):
	mkdir -p $(BUNDLE)/Contents
	cp Info.plist $(BUNDLE)/Contents

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
	-rm EscapeParser.m
	-rm ./*.o
	-rm -rf $(BUNDLE)
	-rm -f $(NAME).dmg

install: build_native
	mkdir -p $(HOME)/Library/Application\ Support/SIMBL/Plugins
	-rm -r $(HOME)/Library/Application\ Support/SIMBL/Plugins/$(BUNDLE)
	cp -R $(BUNDLE) $(HOME)/Library/Application\ Support/SIMBL/Plugins

uninstall:
	-rm -r $(HOME)/Library/Application\ Support/SIMBL/Plugins/$(BUNDLE)
