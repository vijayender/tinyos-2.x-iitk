interface VarArray<t> {
  command bool empty ();
  command uint8_t size ();
  command uint8_t maxSize ();
  command void reset ();
  //  command error_t put (t* val);
  command t* get ();

  /* Default position is set to first element */
  command error_t set_pos (uint8_t pos);
  
  /* returns null if last item */
  command t* next_item ();
}