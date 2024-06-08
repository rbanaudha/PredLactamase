OBJECTS = pseb.o fasta.o error.o parameters.o pcprop.o pseaac.o tools.o biofiles.o
CC = g++ -s -O3
LD = ld

pseb: $(OBJECTS)
	$(CC) -o pseb $(OBJECTS) -lm -static
pseb.o: pseb.cpp pseb.h
	$(CC) -c pseb.cpp -o pseb.o
fasta.o: fasta.cpp fasta.h
	$(CC) -c fasta.cpp -o fasta.o
error.o: error.cpp error.h
	$(CC) -c error.cpp -o error.o
parameters.o: parameters.cpp parameters.h
	$(CC) -c parameters.cpp -o parameters.o
pcprop.o: pcprop.cpp pcprop.h
	$(CC) -c pcprop.cpp -o pcprop.o
pseaac.o: pseaac.cpp pseaac.h
	$(CC) -c pseaac.cpp -o pseaac.o
tools.o: tools.cpp tools.h
	$(CC) -c tools.cpp -o tools.o
biofiles.o: biofiles.cpp biofiles.h
	$(CC) -c biofiles.cpp -o biofiles.o

.PHONY: clean
clean:
	rm -f pseb $(OBJECTS)

.PHONY: install
install:
	if [ ! -d "../bin" ] ; then \
		mkdir ../bin ; \
	fi
	if [ -e "./pseb" ] && [ -d "../bin" ] ; then \
		cp ./pseb ../bin ; \
		chmod a+x ../bin/pseb ; \
	fi

