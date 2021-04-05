.PHONY: build install
.PHONY: uninstall clean

MKDIR:=mkdir
MKDIRFLAGS:=-p

CP:=cp
CPFLAGS:=

CHMOD:=chmod
CHMODFLAGS:=
CHMODEXECUTABLE:=u+x

RM:=rm
RMFLAGS:=-rf

SRC:=src
BIN:=bin
BINEXT:=

TARGET:=tarmux
TARGETEXT:=.sh

PREFIX?=/data/data/com.termux/files/usr
INSTALL:=$(PREFIX)/bin

build:
	$(MKDIR) $(MKDIRFLAGS) $(BIN)
	$(CP) $(CPFLAGS) $(SRC)/$(TARGET)$(TARGETEXT) $(BIN)/$(TARGET)$(BINEXT)
	$(CHMOD) $(CHMODFLAGS) $(CHMODEXECUTABLE) $(BIN)/$(TARGET)$(BINEXT)

install:
	$(CP) $(CPFLAGS) $(BIN)/$(TARGET)$(BINEXT) $(INSTALL)

uninstall:
	$(RM) $(RMFLAGS) $(INSTALL)/$(TARGET)$(BINEXT)

clean:
	$(RM) $(RMFLAGS) $(BIN)
