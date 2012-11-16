CC=gcc
CFLAGS=-g -O2 -Wall
EXECUTABLE=quote_daemon

all:
	$(CC) $(CFLAGS) quote_daemon.c -o $(EXECUTABLE)

