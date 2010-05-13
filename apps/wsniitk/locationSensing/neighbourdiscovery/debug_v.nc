interface debug_v {
  command error_t debug_flush();
  command void send_uint8_t(uint8_t i);
  command void send_uint16_t(uint16_t i);
  command void send_uint32_t(uint32_t i);
  command void send_double(double i);
  command void send_coordinate_f(double x, double y);
  event void flushDone ();
  command void* getData ();
}