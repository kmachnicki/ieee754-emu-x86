# Makefile na potrzeby projektu
CC=gcc
CFLAGS=-m32 -lc -O0 -g
OBJS=emulacja.o dodawanie.o odejmowanie.o mnozenie.o normalizacja.o zaokraglenie.o wyjatki.o

all: emulacja

emulacja: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o emulacja

$(OBJS): %.o: %.S
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f *.o emulacja

.PHONY: all clean

