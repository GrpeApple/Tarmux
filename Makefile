.PHONY: build install
.PHONY: uninstall clean

MKDIR:=mkdir
MKDIRFLAGS:=-p

CP:=cp
CPFLAGS:=

SHEBANG:=termux-fix-shebang
SHEBANGFLAGS:=

INSTALL:=install
INSTALLFLAGS:=--mode=700

RM:=rm
RMFLAGS:=-rf

SRC:=src
BIN:=bin
BINEXT:=

TARGET:=tarmux
TARGETEXT:=.sh

PREFIX?=/data/data/com.termux/files/usr
LOCATION:=$(PREFIX)/bin

build:
	$(MKDIR) $(MKDIRFLAGS) $(BIN)
	$(CP) $(CPFLAGS) $(SRC)/$(TARGET)$(TARGETEXT) $(BIN)/$(TARGET)$(BINEXT)
	$(SHEBANG) $(SHEBANGFLAGS) $(BIN)/$(TARGET)$(BINEXT)

install:
	$(INSTALL) $(INSTALLFLAGS) $(BIN)/$(TARGET)$(BINEXT) $(LOCATION)

uninstall:
	$(RM) $(RMFLAGS) $(LOCATION)/$(TARGET)$(BINEXT)

clean:
	$(RM) $(RMFLAGS) $(BIN)
