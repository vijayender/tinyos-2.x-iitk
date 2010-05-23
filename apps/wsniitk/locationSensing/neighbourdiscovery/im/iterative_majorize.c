#include "iterative_majorize.h"
#include "mds.h"

int iterative_majorize_solve(gsl_matrix* _p, gsl_matrix*  _d, int _iters, float energy_limit, int verbose_mode, float *final_loss)
{
  //Conversion from the given data
  gsl_matrix *p, *d;
  iterative_majorizer_t *s;
  int iters = 0;
  float lower_triangle, limit;

  s = iterative_majorizer_alloc();
  p = _p;
  d = _d;
  iterative_majorizer_initialize(s, p, d);
  lower_triangle = sum_distance_matrix_sqr(d);
  limit = lower_triangle * energy_limit;

  do{
    iters++;
    iterative_majorizer_iterate(s);
    if(verbose_mode) {
      printf("%5d: loss %f, loss_temp %f, limit %f * %f \n", iters, s->loss/lower_triangle, s->loss_temp, energy_limit, lower_triangle);
      printf("\n-----------------------------------\n");
    }
  }while(_iters > iters && s->loss > limit);
  *final_loss = s->loss / lower_triangle;
  return iters;
}

iterative_majorizer_t * iterative_majorizer_alloc ()
{
  return (iterative_majorizer_t *) malloc (sizeof(iterative_majorizer_t));
}

void iterative_majorizer_initialize (iterative_majorizer_t *s, gsl_matrix *x, gsl_matrix *d)
{
  s->d = d;			/* Move initialisation of x & d
				   outside this function, so that s
				   can be freed easily */
  s->x = x;
  // Initialize the other variables
  s->x_temp = gsl_matrix_alloc(x->size1, x->size2); 
  s->BZ = gsl_matrix_alloc(d->size1, d->size2);
  s->DZ = gsl_matrix_alloc(d->size1, d->size2);
  s->loss = loss_function_simple(s->x, s->d, -1);
  s->lt = sum_distance_matrix_sqr(d);
}
void iterative_majorizer_free (iterative_majorizer_t *s)
{
  /* Free only d, as p will be reused.*/
  free(s->DZ);
  free(s->BZ);
  free(s->x_temp);
  free(s->x);
  free(s->d);
  free(s);
}
void iterative_majorizer_iterate (iterative_majorizer_t *s)
{
  int i,j;
  gsl_matrix * x_temp;
  float d_temp,psum;
  // To Find X_new :
  // Find DZ
  compute_distance_matrix_lt(s->DZ, s->x);
  #ifdef DEBUG
  print_matrix_2d(s->x, "from x");
  print_matrix_2d(s->DZ, "DZ");
  #endif
  // Compute B(X) using d1/dz
  for (i = 0; i < s->d->size1; i++){
    for (j = 0,psum = 0; j < s->d->size2; j++){
      if (i == j)// || 
	gsl_matrix_set(s->BZ, i, j, 0);
      else if(i < j){
	gsl_matrix_set(s->BZ, i, j, -gsl_matrix_get(s->d, j, i)/gsl_matrix_get(s->DZ, j, i)/s->d->size1); /* Symmetry */
      } else {
	gsl_matrix_set(s->BZ, i, j, -gsl_matrix_get(s->d, i, j)/gsl_matrix_get(s->DZ, i, j)/s->d->size1);
      }
      psum += gsl_matrix_get(s->BZ,i,j);
    }
    gsl_matrix_set(s->BZ, i, i, -psum);
  }
  //Update the diagonal elements
  #ifdef DEBUG
  print_matrix_2d(s->BZ,"BZ");
  #endif
  // Multiply B(x)*x in DZ and store in x_temp
  /* gsl_blas_dgemm (CblasNoTrans, CblasNoTrans, */
  /* 		  1.0, s->BZ, s->x, */
  /* 		  0.0, s->x_temp); */
  multiply_mat( s->BZ, s->x, s->x_temp);
  #ifdef DEBUG
  print_matrix_2d(s->x_temp, "new x");
  #endif
  s->loss_temp = loss_function_simple_unsquared_d(s->x_temp, s->d, -1);
  // swap pointers x and x_temp
  x_temp = s->x_temp; s->x_temp = s->x; s->x = x_temp;
  d_temp = s->loss_temp; s->loss_temp = s->loss; s->loss = d_temp;
}
