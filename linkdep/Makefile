.PHONY: clean build test
default: test

EXES = tdep1-db tdep1-bd tdep2-db tdep2-bd

CFLAGS = -I.
LDFLAGS = -Wl,--no-as-needed -L. -Wl,-rpath=.

%.o: %.c
	gcc -c $(CFLAGS) $<
test-%: %
	@echo "** start $* **"; ./$*; echo "** end $* **"; echo

libtbase.o: CFLAGS+=-fpic
libtdep.o: CFLAGS+=-fpic
libtbase.so: libtbase.o
	gcc -o $@ -shared $<
libtdep1.so: libtdep.o
	gcc -o $@ -shared $<
libtdep2.so: libtdep.o libtbase.so
	gcc -o $@ -shared $< $(LDFLAGS) -ltbase
tdep1-db: tdep.o libtdep1.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltdep1 -ltbase
tdep1-bd: tdep.o libtdep1.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltbase -ltdep1
tdep2-db: tdep.o libtdep2.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltdep2 -ltbase
tdep2-bd: tdep.o libtdep2.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltbase -ltdep2
test-tdep1-bd-WA: tdep1-bd
	@echo "** start $< ( workaround ) **"; env LD_PRELOAD=./libtdep1.so ./$<; echo "** end $< ( workaround ) **"; echo

build: $(EXES)
test: build test-tdep1-db test-tdep1-bd test-tdep1-bd-WA test-tdep2-db test-tdep2-bd
clean:
	rm -f $(EXES) *.so *.o

# dependencies
libtbase.o: tbase.h
libtdep.o: tdep.h tbase.h
tdep.o: tdep.h
