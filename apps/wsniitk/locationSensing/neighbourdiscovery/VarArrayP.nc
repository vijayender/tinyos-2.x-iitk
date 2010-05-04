
generic module VarArrayP (typedef varArray_t, uint8_t size) {
  provides {
    interface Init;
    interface VarArray<varArray_t>;
  }
}
implementation {
  uint8_t free;
  uint8_t index;
  uint8_t iterator;
  varArray_t varArray[size];

  command error_t Init.init () {
    free = size;
    index = 0;
    return SUCCESS;
  }
  
  command bool VarArray.empty () {
    dbg ("VarArrayP", "%s size is %i\n", __FUNCTION__, (int)free);
    return free == 0;
  }

  command uint8_t VarArray.size () {
    dbg ("VarArrayP", "%s size is %i\n", __FUNCTION__, (int)free);
    return free;
  }
    
  command uint8_t VarArray.maxSize () {
    return size;
  }

  command varArray_t* VarArray.get () {
    if (free) {
      varArray_t* rval = &varArray[index];
      free--;
      index++;
      dbg ("VarArrayP", "%s size is %i\n", __FUNCTION__, (int)free);
      return rval;
    }
    return NULL;
  }

  command error_t VarArray.set_pos (uint8_t pos){
    if (pos < size){
      iterator = pos;
      return SUCCESS;
    }else{
      return FAIL;
    }
  }

  command varArray_t * VarArray.next_item () {
    if (iterator < index){
      varArray_t* rval = &varArray[iterator];
      iterator++;
      return rval;
    }else
      return NULL;
  }

  command void VarArray.reset () {
    free = size;
    index = 0;
  }
}
