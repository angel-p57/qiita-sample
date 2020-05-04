default: appok.exe appng.exe
appok.exe: appok.o specific.o libcommon.a
	gcc -o appok.exe appok.o specific.o -L. -lcommon
appng.exe: appng.o specific.o libcommon.a
	gcc -o appng.exe appng.o specific.o -L. -lcommon

appok.o: appok.c
	gcc -c -o appok.o appok.c
appng.o: appng.c
	gcc -c -o appng.o appng.c
specific.o: specific.c
	gcc -c -o specific.o specific.c
libcommon.a: common1.o common2.o
	ar r libcommon.a common1.o common2.o
common1.o: common1.c
	gcc -c -o common1.o common1.c
common2.o: common2.c
	gcc -c -o common2.o common2.c
clean:
	rm -f *.o *.a *.exe
