#ifndef ACCEL_H
#define ACCEL_H

#define BUFSIZE 20
#define INTERVAL 1000
#define TOSH_DATA_LENGTH 100

typedef nx_struct msg {
  nx_uint32_t x_tsp;
  nx_uint32_t y_tsp;
  nx_uint16_t x[BUFSIZE];
  nx_uint16_t y[BUFSIZE];
} msg_t;

enum {
  AM_ACCEL_RADIO = 6
};

#endif
