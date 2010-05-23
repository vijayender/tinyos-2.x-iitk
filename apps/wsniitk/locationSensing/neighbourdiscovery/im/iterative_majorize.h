#ifndef ITERATIVE_MAJORIZE_H
#define ITERATIVE_MAJORIZE_H

#include "gsl_matrix.h"

typedef struct iterative_majorizer_t {
  gsl_matrix * x; // Initial point
  gsl_matrix * d; // Distance matrix
  gsl_matrix * x_temp; // A temporary buffer for multiplication
  gsl_matrix * BZ; // A temporary matrix to store the value of B
  gsl_matrix * DZ; // To store the distances of matrix Z
  // BZ & DZ can be merged to a single matrix
  float loss;
  float loss_temp;
  float epsilon;
  float lt;
} iterative_majorizer_t; // All these values should be allocated upon initialization

iterative_majorizer_t * iterative_majorizer_alloc ();
void iterative_majorizer_initialize (iterative_majorizer_t *s, gsl_matrix *x, gsl_matrix *d);
void iterative_majorizer_free (iterative_majorizer_t *s);
void iterative_majorizer_iterate (iterative_majorizer_t *s);
int iterative_majorize_solve(gsl_matrix* _p, gsl_matrix*  _d, int _iters, float energy_limit, int verbose_mode, float *final_loss);
#endif
