#ifndef GSL_MATRIX_H
#define GSL_MATRIX_H
#ifndef SQR
#define SQR(x) (x)*(x)
#endif
typedef struct gsl_matrix {
  int size1;
  int size2;
  float *data;
} gsl_matrix;

gsl_matrix *gsl_matrix_alloc (int size1, int size2);
float gsl_matrix_get (gsl_matrix* x, int size1, int size2);
float * gsl_matrix_ptr (gsl_matrix* x, int size1, int size2);
void gsl_matrix_set (gsl_matrix* x, int size1, int size2, float val);
void multiply_mat (gsl_matrix *x, gsl_matrix* y, gsl_matrix *res);

#endif
