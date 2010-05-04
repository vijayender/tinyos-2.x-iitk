CC=gcc -g

all: test_iterative_majorize

test_iterative_majorize: mds.c  iterative_majorize.c gsl_matrix.c test_iterative_majorize.c
	$(CC) -lgsl $^ -o $@

