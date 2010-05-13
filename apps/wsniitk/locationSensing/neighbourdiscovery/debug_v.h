#ifndef DEBUG_V_H
#define DEBUG_V_H

/* #define debug_type(t) typedef nx_struct debug_ ## t ## _f {	\ */
/*     nx_uint8_t type;					\ */
/*     nx_ ## t d;						\ */
/*   } debug_ ## t ## _t */

/* debug_type (uint8_t); */
/* debug_type (uint16_t); */
/* debug_type (uint32_t); */
/* debug_type (double); */

/* typedef nx_struct coordinate_f { */
/*   nx_uint8_t type; */
/*   nx_double x; */
/*   nx_double y; */
/* } coordinate_f_t; */
#define val_uint8_t 1
#define val_uint16_t 2
#define val_uint32_t 3
#define val_double 4
#define val_coordinate 5


#define push_val(t) void push_ ## t (t i)\
  {\
    push_g(&i, sizeof(t));			\
  }

#endif
