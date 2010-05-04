
generic configuration VarArrayC (typedef varArray_t, uint8_t VARARRAY_SIZE) {
  provides interface VarArray<varArray_t>;
} 

implementation {
  components MainC, new VarArrayP (varArray_t, VARARRAY_SIZE);

  MainC.SoftwareInit -> VarArrayP;
  VarArray = VarArrayP;
}
