#include "gsl_matrix.h"
//#include <stdlib.h>

gsl_matrix *gsl_matrix_alloc (int size1, int size2)
{
  gsl_matrix * new;
  new = (gsl_matrix*) malloc (sizeof (gsl_matrix));
  new->size1 = size1;
  new->size2 = size2;
  new->data = (float *) malloc (sizeof (float) * size1 * size2);
  return new;
}
float gsl_matrix_get (gsl_matrix* x, int size1, int size2)
{
  return x->data[x->size2 * size1 + size2];
}
void gsl_matrix_set (gsl_matrix* x, int size1, int size2, float val)
{
  x->data[x->size2 * size1 + size2] = val ;
}
float* gsl_matrix_ptr (gsl_matrix* x, int size1, int size2)
{
  return &(x->data[x->size2 * size1 + size2]);
}

void multiply_mat (gsl_matrix *x, gsl_matrix* y, gsl_matrix *res)
{
  int i,j,k;
  float val;
  for (i = 0; i < res->size1; i++) {
    for (j = 0; j < res->size2; j++){
      val = 0;
      for (k = 0; k < x->size2; k++){
	val += gsl_matrix_get(x, i, k) * gsl_matrix_get(y, k, j);
      }
      gsl_matrix_set (res, i, j, val);
    }
  }
}
