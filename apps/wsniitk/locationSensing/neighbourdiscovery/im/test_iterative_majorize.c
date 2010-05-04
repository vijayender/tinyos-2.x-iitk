#include "mds.h"
#include "iterative_majorize.h"
#include <gsl/gsl_rng.h>

int main(int argc, char *argv[]){
  int verbose_mode = 0;
  {
    int c;
    
    while ((c = getopt(argc, argv, "hv")) != -1)
      switch (c)
	{
	case 'h':
	  fprintf(stderr, "usage: test_mds_simplex [-v] [-h]\n");
	  exit(EXIT_SUCCESS);
	case 'v':
	  verbose_mode = 1;
	  break;
	default:
	  fprintf(stderr, "test_mds_simplex error: unknown option %c\n", c);
	  exit(EXIT_FAILURE);
	}
  }

  gsl_matrix *p, *d;
  float psum, diff, loss;
  int i,j,k;
  float val[][2] = {{1,2},{3,4},{5,6}};
  gsl_rng * number_generator = gsl_rng_alloc(gsl_rng_rand);
  
  p = gsl_matrix_alloc(3,2);//new_float_matrix_2d(3, 2);
  d = gsl_matrix_alloc(3,3);//new_float_matrix_2d(3, 3);

  for (i = 0; i < 3; i++)
    for (j = 0; j < 2; j++){
      gsl_matrix_set(p, i, j, val[i][j]);
    }

  for (i = 0; i < 3; i++)
    for (j = 0; j < 3; j++){
      for (k = 0, psum = 0; k < 2; k++){
	diff = gsl_matrix_get(p,i,k) - gsl_matrix_get(p,j,k);
	psum += SQR(diff);// + gsl_rng_uniform(number_generator) * 1 ;// Adding some noise
      }
      gsl_matrix_set(d,i,j,sqrt(psum));	/* d contains squared distances */
    }

  /*
   * Adding noise to the input `p' matrix.
   * This is easier to understand how close we are to the final answer
   * rather than adding noise to `d' matrix.
   * Random input:
   */
  for (i = 0; i < 3; i++)
    for (j = 0; j < 2; j++)
      gsl_matrix_set(p, i, j, gsl_rng_uniform(number_generator) * 5);
  print_matrix_2d(p,"p intially");
  print_matrix_2d(d,"d");

  i = iterative_majorize_solve(p, d, 500, .001, verbose_mode, &loss);

  print_matrix_2d(p,"result:");
  printf( " final loss %f after %d iterations \n", loss, i);
  exit(EXIT_SUCCESS);
  return 0;
}
