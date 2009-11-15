OPT_LEVEL=2
CFLAGS=-O$(OPT_LEVEL) -Wall #-Wno-protocol -Wno-undeclared-selector

ifdef DEBUG
	CFLAGS +=-g -DDEBUG
endif

LDFLAGS=-bundle -framework Cocoa -licucore # for regex support.
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
ARCH_LIST= # leave this empty to select default arch (as build_native does)
ARCHES=$(foreach arch,$(ARCH_LIST),-arch $(arch))

.PHONY: build install clean build_native dmg uninstall
.PRECIOUS: $(PARSER).m

# default, and what you should probably use, or install.
build_native: | $(TARGET) $(INFO)

build: ARCH_LIST=i386 ppc # add additional architectures here to build them all.
build: |  $(TARGET) $(INFO)

# generic targets for building bits.
%.m: %.rl
	$(RL) -C -o $@ $<

%.o: %.m
	$(CC) -c -mmacosx-version-min=$(OSXVER) $(ARCHES) $(CFLAGS) $< -o $@

$(TARGET): $(OBJECTS)
	mkdir -p $(NAME).bundle/Contents/MacOS
	$(CC) -mmacosx-version-min=$(OSXVER) $(ARCHES) \
		$(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $(TARGET)

$(INFO):
	mkdir -p $(BUNDLE)/Contents
	cp Info.plist $(BUNDLE)/Contents

dmg: # UNTESTED
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
