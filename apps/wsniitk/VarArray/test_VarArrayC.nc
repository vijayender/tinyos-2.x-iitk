#define TESTBASE 2
#define TESTSIZE 10

module test_VarArrayC{
  uses {
    interface Boot;
    interface VarArray<uint8_t> as Arr;
    interface State as SM;
  }
}

implementation {
  enum {
    S_IDLE,
    S_INITIALIZE,
    S_ADD_DATA,
    S_PRINT_DATA,
    S_FREE,
    S_END,
  };
  
  task void run_test ();
  
  event void Boot.booted() 
  {
    dbg("tVA", "Booted \n");
    post run_test ();
  }

  task void run_test () {
    int i;
    switch (call SM.getState()) {
    case S_IDLE:
      call SM.forceState(S_INITIALIZE);
    case S_INITIALIZE:
      dbg ("tVA", "Initial size of Arr %d\n", call Arr.size());
      call SM.forceState(S_ADD_DATA);
      post run_test();
      break;
    case S_ADD_DATA:
      for (i = 0; i < TESTSIZE; i++) {
	*(call Arr.get ()) = TESTBASE + i;
	dbg ("tVA", "Added entry val: %d\n", TESTBASE + i);
      }
      dbg("tVA","Size after adding data: %d\n", call Arr.size());
      call SM.forceState(S_PRINT_DATA);
      post run_test();
      break;
    case S_PRINT_DATA:
      call Arr.set_pos(0);
      for (i = 0; i < TESTSIZE; i++) {
	dbg ("tVA", "Received val: %d\n", *(call Arr.next_item()));
      }
      call SM.forceState(S_FREE);
      post run_test();
      break;
    case S_FREE:
      /* Nothing as of now */
      dbg("tVA", "Freeing...\n");
      call Arr.reset();
      call SM.forceState(S_END);
      post run_test();
      break;
    case S_END:
      dbg("tVA", "Test finished \n");
      dbg("tVA", "sending for another test\n");
      call SM.forceState(S_IDLE);
      post run_test();
      break;
    }
  }
}