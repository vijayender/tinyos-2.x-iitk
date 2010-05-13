#include "im/gsl_matrix.h"

interface iterative_majorize {
  command void alloc (uint8_t size1, uint8_t size2);
  command void initialize();
  command gsl_matrix* get_d ();
  command gsl_matrix* get_p ();
  command void iterate ();
  command float test ();
  command void print_details ();
  command void free ();
}