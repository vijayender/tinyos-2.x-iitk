#include "nd.h"
#include "im/gsl_matrix.h"

module ndC{
  uses {
    interface Leds;
    interface Boot;
    interface AMPacket;
    interface State as syndicateState;

    interface Timer<TMilli> as backoff;
    interface Timer<TMilli> as discover_complete;
    interface Random;

    interface VarArray<neighbour_data_t> as neighbours;

    interface Receive as neighbour_discover_receive;
    interface AMSend as neighbour_discover_send;

    interface AMSend as neighbour_data_send;
    interface Receive as neighbour_data_receive;
    //    interface AMSend as coordinate_send;

    interface Receive as controller_receive;
    interface AMSend as controller_send;

    interface SplitControl as AMControl;
    interface Packet;
    interface PacketField<uint8_t> as PacketRSSI;

    interface iterative_majorize as im;
    interface debug_v as debugger;
  }
}

implementation {
  gsl_matrix *p,*d;
  bool busy = FALSE;
  neighbour_data_t* temp_n;
  message_t packet;
  int16_t wait;
  uint8_t group_leader = 0xff;
  uint16_t pdb_addr = AM_BROADCAST_ADDR;
  uint8_t iters = 0;  
  void send_cmd (uint16_t addr, uint8_t cmd);
  void sig_error (void);
  void im_initialize();
  uint8_t computeDistance(uint8_t);
  uint8_t indexOf(uint8_t nodeid);
  bool im_running = FALSE, results = FALSE;
  int i,j,k;

  task void test_im(void);
  task void im_iterate ();
  task void start_discover ();
  task void send_pdb ();
  task void test_syndicate();
  task void test_im2(void);

  enum {
    S_IDLE,
    S_COLLECT,
    S_DISPATCH,
    S_DONE
  };
  
  enum {noleader, found_leader, finished} neighbour_discovery_state = noleader;

  /* BOOT */
  event void Boot.booted ()
  {
    call AMControl.start ();
  }    
  event void AMControl.startDone (error_t err)
  {
    if (err == SUCCESS){
      call Leds.led0Toggle ();
    } else 
      call AMControl.start ();
  }  
  event void AMControl.stopDone (error_t err)
  {
  }

  /* COMMAND_PROCESS */
  event message_t* controller_receive.receive (message_t* bufPtr, void* payload, uint8_t len)
  {
    if (busy)
      return bufPtr;
    if (len != sizeof (command_msg_t)){
      return bufPtr;
    }else{
      command_msg_t* rcm = (command_msg_t*) payload;
      switch (rcm->cmd) {
      case HELLO:
	printf("working\n");
	printfflush();
	send_cmd (call AMPacket.source (bufPtr), HELLO);
	break;
      case START_DISCOVERY:
	post start_discover ();
	break;
      case DISCOVERY_DONE:
	call Leds.led1On ();
	break;
      case GET_PDB:
	call neighbours.set_pos (0);
	pdb_addr = call AMPacket.source (bufPtr);
	post send_pdb ();
	break;
      case GET_PDB_DONE:
	if (call syndicateState.getState() == S_COLLECT) {
	  post test_syndicate();
	}
	break;
      case TEST_IM:
	printf("working\n");
	printfflush();
       	post test_im();
	break;
      case TEST_DEBUG:
	call debugger.send_uint8_t (1);
	call debugger.send_uint32_t (-1);
	call debugger.send_double (0.1);
	call debugger.send_coordinate_f (1.23,0.001);
	call debugger.debug_flush ();
	break;
      case TEST_SYNDICATE:
	post test_syndicate();
	break;
      case TEST_IM2:
	printf("working\n");
	printfflush();
       	post test_im2();
	break;
      default:
	sig_error ();
      }
    }
    return bufPtr;
  }
  
  task void test_syndicate()
  {
    static int curr_pos=0;
    switch (call syndicateState.getState()) {
    case S_IDLE:
      call syndicateState.forceState(S_COLLECT);
      curr_pos = 0;
      im_initialize();
    case S_COLLECT:
      //foreach node in neighbour list issue GET_PDB
      call neighbours.set_pos(curr_pos);
      temp_n = call neighbours.next_item();
      curr_pos = call neighbours.get_pos();
      if (temp_n) {
	send_cmd(temp_n->node_id, GET_PDB);
      } else {
	call syndicateState.forceState(S_DISPATCH);
	post test_syndicate();
      }
      i = 0;
    case S_DISPATCH:
      for (j = 0; j < i; j++){
	call debugger.send_uint8_t(gsl_matrix_get(d, i, j));
      }
      call debugger.send_uint8_t(255);
      call debugger.debug_flush();
      if (++i < d->size1)
	call syndicateState.forceState(S_DONE);
    case S_DONE:
      call Leds.led0On();
    default:
      sig_error();
    }
  }

  void im_initialize() {
    call im.alloc(call neighbours.size(), 2);
    p = call im.get_p();
    d = call im.get_d();
  }
  
  event message_t* neighbour_data_receive.receive(message_t* bufPtr, void* payload, uint8_t len)
  {
    neighbour_data_t* rcm;        
    if (len != sizeof (neighbour_data_t)){
      return bufPtr;
    } else {
      //Make an entry in neighbours
      uint8_t pos1 = indexOf(call AMPacket.source(bufPtr));
      uint8_t pos2 = indexOf(rcm->node_id);
      if ((pos2 != -1) && (pos1 != -1)) {
	if (pos1 < pos2)	/* Fill only lower triangle */
	  gsl_matrix_set(d, pos1, pos2, computeDistance(rcm->p_db));
	else
	  gsl_matrix_set(d, pos2, pos1, computeDistance(rcm->p_db));
      }
    }
    return bufPtr;
  }

  uint8_t indexOf(uint8_t nodeid)
  {
    call neighbours.set_pos(0);
    while ((temp_n = call neighbours.next_item())) {
      if ((temp_n->node_id = nodeid))
	return call neighbours.get_pos();
    }
    return -1;
  }
  
  void sig_error (void)
  {
    call Leds.led2On ();
  }

  /* DISCOVERY STUFF */
  task void start_discover ()
  {
    call neighbours.reset ();
    neighbour_discovery_state = noleader;
    wait = call Random.rand16 () & 0x00ff;	/* Maximum of 16ms */

    call backoff.startOneShot (wait);
  }
  
  event void backoff.fired ()
  {
    _SEND_ALLOC(rcm, neighbour_discover_msg_t)
    if (neighbour_discovery_state == noleader){
      //Set leader to self.
      call Leds.led2On();
      group_leader = TOS_NODE_ID;
      neighbour_discovery_state = found_leader;
    }
    _SEND_INI(rcm, neighbour_discover_msg_t, &packet)
    rcm->leader = group_leader;
    _SEND_SEND(neighbour_discover_send, AM_BROADCAST_ADDR, &packet, neighbour_discover_msg_t)
  }

  event void neighbour_discover_send.sendDone (message_t* bufPtr, error_t error)
  {
    neighbour_discovery_state = finished;
    call Leds.led0Toggle ();
    call discover_complete.startOneShot (TIMEOUT);
  }

  event void discover_complete.fired ()
  {
    if (TOS_NODE_ID == group_leader)
      send_cmd (AM_BROADCAST_ADDR, DISCOVERY_DONE);
  }
  
  event message_t* neighbour_discover_receive.receive (message_t* bufPtr, void* payload, uint8_t len)
  {
    neighbour_discover_msg_t* rcm;        
    if (len != sizeof (neighbour_discover_msg_t)){
      return bufPtr;
    } else {
      call backoff.stop ();
      call discover_complete.stop ();
      rcm = (neighbour_discover_msg_t*) payload;
      if (neighbour_discovery_state == noleader){
	neighbour_discovery_state = found_leader;
	group_leader = rcm->leader;
      }
      /* REGISTER THE INCOMING NODE (will require a variable size array) */
      temp_n = call neighbours.get ();
      temp_n->node_id = call AMPacket.source (bufPtr);
      temp_n->p_db = call PacketRSSI.get (bufPtr);

      if (neighbour_discovery_state == found_leader){
	wait = call Random.rand16 () & 0x00ff;	/* Maximum of 16ms */
	call backoff.startOneShot (wait);
      }
      if (neighbour_discovery_state == finished)
	call discover_complete.startOneShot (TIMEOUT);
    }
    return bufPtr;
  }

  task void send_pdb ()
  {
    _SEND_ALLOC(pkt, neighbour_data_t);
    temp_n = call neighbours.next_item ();
    if (temp_n){
      _SEND_INI(pkt, neighbour_data_t, &packet)
      memcpy (pkt, temp_n, sizeof (neighbour_data_t));
      _SEND_SEND( neighbour_data_send, pdb_addr, &packet, neighbour_data_t)
    } else {
      send_cmd (pdb_addr, GET_PDB_DONE);		
    }
  }

  event void neighbour_data_send.sendDone (message_t* bufPtr, error_t error)
  {
    post send_pdb ();
  }

  void send_cmd (uint16_t addr, uint8_t cmd)
  {
    /* Add acknowledgements when sending to a single mote */
    _SEND_ALLOC(rcm, command_msg_t);
    _SEND_INI(rcm, command_msg_t, &packet);
    rcm->cmd = cmd;
    _SEND_SEND(controller_send, addr, &packet, command_msg_t);
  }

  event void controller_send.sendDone(message_t* bufPtr, error_t error)
  {
  }

  task void test_im(void)
  {
    float val[][2] = {{1,2},{3,4},{5,6}}, psum, diff;

    printf("working %d %d\n", sizeof(float), sizeof(double));
    printfflush();
    
    call im.alloc(3,2);
    p = call im.get_p();
    d = call im.get_d();
    
    for (i = 0; i < 3; i++)
      for (j = 0; j < 2; j++){
	gsl_matrix_set(p, i, j, val[i][j]);
      }

    for (i = 0; i < 3; i++)
      for (j = 0; j < 3; j++){
	for (k = 0, psum = 0; k < 2; k++){
	  diff = gsl_matrix_get(p,i,k) - gsl_matrix_get(p,j,k);
	  psum += SQR(diff);
	}
	gsl_matrix_set(d,i,j,sqrt(psum));
      }


    for (i = 0; i < 3; i++)
      for (j = 0; j < 2; j++)
	gsl_matrix_set(p, i, j, ((float)(call Random.rand16()%100))/100 * 5);

    
    call im.initialize();
    call Leds.led1Toggle();
    im_running = TRUE;
    post im_iterate();
  }


  task void test_im2 (void) {  
    for (i = 0; i < call neighbours.size(); i++)
      for (j = 0; j < 2; j++)
	gsl_matrix_set(p, i, j, ((float)(call Random.rand16()%100))/100 * 5);

    // Convert d from p_db to distance.
    // Use a distance table
    call im.initialize();
    call Leds.led1Toggle();
    im_running = TRUE;
    post im_iterate();
  }

  task void im_iterate ()
  {
    float a;
    iters++;
    call im.iterate ();
    a = call im.test();
    call Leds.led0Toggle();
    //    printf("iters: %d\n",iters);
    call debugger.send_uint8_t(iters);
    call debugger.send_double((double)a);
    call debugger.debug_flush();
  }

  uint8_t computeDistance (uint8_t dis)
  {
    return dis;
  }
  
  event void debugger.flushDone ()
  {
    float a;
    if (im_running) {
      a = call im.test();
      if (a > 0.001) {
	post im_iterate();
	i = 0;
      } else {
	if (i < p->size1) {
	  call debugger.send_coordinate_f (gsl_matrix_get(p,i,0), gsl_matrix_get(p,i,1));
	  call debugger.debug_flush ();
	  i++;
	} else {
	  call im.free();
	}
      }
    }
  }
}
