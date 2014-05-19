# Makefile na potrzeby projektu
CC=gcc
CFLAGS=-m32 -lc -O0
OBJS=emulacja.o

all: emulacja

emulacja: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o emulacja

$(OBJS): %.o: %.S
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f *.o emulacja

.PHONY: all clean

