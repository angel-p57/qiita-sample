.PHONY: clean build test
default: test

EXES = exe1-db exe1-bd exe2-db exe2-bd

CFLAGS = -I.
LDFLAGS = -Wl,--no-as-needed -L. -Wl,-rpath=.

%.o: %.c
	gcc -c $(CFLAGS) $<
test%: exe%
	@echo "** start $< **"; ./$<; echo "** end $< **"; echo

libtbase.o: CFLAGS+=-fpic
libtdep.o: CFLAGS+=-fpic
libtbase.so: libtbase.o
	gcc -o $@ -shared $<
libtdep1.so: libtdep.o
	gcc -o $@ -shared $<
libtdep2.so: libtdep.o libtbase.so
	gcc -o $@ -shared $< $(LDFLAGS) -ltbase
exe1-db: main.o libtdep1.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltdep1 -ltbase
exe1-bd: main.o libtdep1.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltbase -ltdep1
exe2-db: main.o libtdep2.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltdep2 -ltbase
exe2-bd: main.o libtdep2.so libtbase.so
	gcc -o $@ $< $(LDFLAGS) -ltbase -ltdep2
test1-bd-WA: exe1-bd
	@echo "** start $< ( workaround ) **"; env LD_PRELOAD=./libtdep1.so ./$<; echo "** end $< ( workaround ) **"; echo

build: $(EXES)
test: build test1-db test1-bd test1-bd-WA test2-db test2-bd
clean:
	rm -f $(EXES) *.so *.o

# dependencies
libtbase.o: tbase.h
libtdep.o: tdep.h tbase.h
main.o: tdep.h
