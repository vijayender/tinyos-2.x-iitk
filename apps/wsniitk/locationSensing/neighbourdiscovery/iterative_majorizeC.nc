#include "im/gsl_matrix.h"
#include "im/mds.h"
#include "im/iterative_majorize.h"

module iterative_majorizeC
{
  provides
  {
    interface iterative_majorize as im;
  }
}
implementation
{
  #include "im/mds.c"
  #include "im/iterative_majorize.c"

  gsl_matrix *p;
  gsl_matrix *d;
  iterative_majorizer_t *s;

  command void im.alloc (uint8_t size1, uint8_t size2)
  {
    s = iterative_majorizer_alloc();
    p = gsl_matrix_alloc(size1, size2);
    d = gsl_matrix_alloc(size1, size1);
  }
  command void im.initialize()
  {
      iterative_majorizer_initialize(s, p, d);
  }
  command void im.free()
  {
    iterative_majorizer_free(s);
  }
  command gsl_matrix* im.get_d ()
  {
    return d;
  }
  command gsl_matrix* im.get_p ()
  {
    return p;
  }
  command void im.iterate ()
  {
    printfflush();
    iterative_majorizer_iterate(s);
    //printf("loss %1.3f, loss_temp %1.3f\n", (double)s->loss, (double)s->loss_temp);
    printfflush();
  }
  command float im.test ()
  {
    return s->loss_temp - s->loss;
  }

  command void im.print_details()
  {
    print_matrix_2d(p,"p");
    print_matrix_2d(d,"d");
  }
  
  gsl_matrix *gsl_matrix_alloc (int size1, int size2) @C() 
  {
    gsl_matrix * new_m;
    new_m = (gsl_matrix*) malloc (sizeof (gsl_matrix));
    new_m->size1 = size1;
    new_m->size2 = size2;
    new_m->data = (float *) malloc (sizeof (float) * size1 * size2);
    return new_m;
  }
  void gsl_matrix_free (gsl_matrix *_p) @C() 
  {
    free(_p->data);
    free(_p);
  }

  float gsl_matrix_get (gsl_matrix* x, int size1, int size2) @C()
  {
    return x->data[x->size2 * size1 + size2];
  }
  void gsl_matrix_set (gsl_matrix* x, int size1, int size2, float val) @C()
  {
    x->data[x->size2 * size1 + size2] = val ;
  }
  float* gsl_matrix_ptr (gsl_matrix* x, int size1, int size2) @C()
  {
    return &(x->data[x->size2 * size1 + size2]);
  }
  
  void multiply_mat (gsl_matrix *x, gsl_matrix* y, gsl_matrix *res) @C()
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
}