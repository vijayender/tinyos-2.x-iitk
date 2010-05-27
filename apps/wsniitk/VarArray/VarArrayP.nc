#define MAX_STRIDES 8 //Lets say max storage capacity is 256 = 8**

generic module VarArrayP (typedef varArray_t, uint8_t size) {
  provides {
    interface Init;
    interface VarArray<varArray_t>;
  }
}

implementation {
  uint8_t index;
  uint8_t stride_index;
  uint8_t iterator;
  uint8_t stride_iterator;
  varArray_t *stride [MAX_STRIDES];
  varArray_t varArray[size];
  bool spaceLeft = TRUE;

  command error_t Init.init () {
    index = 0;
    stride_index = 0;
    iterator = 0;
    stride_iterator = 0;
    stride[0] = &varArray[0];
    return SUCCESS;
  }
  
  command bool VarArray.empty () {
    return index == 0;
  }

  command uint8_t VarArray.size () {
    dbg("ndC","Lol %d\n", size * stride_index + index);
    return size * stride_index + index;
  }
    
  command varArray_t* VarArray.get () {
    varArray_t* rval;
    if (index < size) {
      rval = &stride[stride_index][index];// &varArray[index];
      index++;
      return rval;
    } else if (spaceLeft && (stride_index < MAX_STRIDES-1)) {
      index = 0;
      stride_index++;
      stride[stride_index] = (varArray_t *) malloc (size * sizeof(varArray_t));
      dbg("tVA","Got new space %p\n", stride[stride_index]);
      if(!stride[stride_index]){
	dbg("tVA","No space leftover\n");
	spaceLeft = FALSE;
	return NULL;
      }
      rval = &stride[stride_index][index];// &varArray[index];
      index++;
      return rval;
    }
    return NULL;
  }

  command error_t VarArray.set_pos (uint8_t pos){
    if (pos <=  size * stride_index + index){
      iterator = pos;
      return SUCCESS;
    }else{
      return FAIL;
    }
  }

  command uint8_t VarArray.get_pos (){
    return iterator;
  }
  
  command varArray_t * VarArray.next_item () {
    if (iterator < size * stride_index + index){
      varArray_t* rval = &stride[iterator / size][iterator % size];//&varArray[iterator];
      iterator++;
      return rval;
    }else
      return NULL;
  }

  command void VarArray.reset () {
    index = 0;
    for (; stride_index > 0; stride_index--) {
      free(stride[stride_index]);
      dbg("tVA", "Freed %d stride\n", stride_index);
      stride[stride_index] = NULL;
    }
    stride_index = 0;
  }
}
