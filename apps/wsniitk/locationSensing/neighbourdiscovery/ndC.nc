#include "nd.h"
#include "im/gsl_matrix.h"

#define EXPRS(dis)  ((exp((50.0-dis)/11) - 1)/2)

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
#ifndef TOSSIM
    interface PacketField<uint8_t> as PacketRSSI;
#else
    interface TossimPacket as PacketRSSI;
#endif

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
  bool im_running = FALSE, results = FALSE;
  int i,j,k;
  uint8_t distance_table[] = {0, 0, 0, 1, 1, 1, 1, 1,
			    2, 2, 2, 2, 3, 3, 3, 4,
			    4, 5, 5, 5, 6, 7, 7, 8,
			    9, 10, 12, 18, 26, 32,
			    35, 39, 44, 47};

  void send_cmd (uint16_t addr, uint8_t cmd);
  void sig_error (void);
  void im_initialize();
  double computeDistance(uint8_t);
  uint8_t indexOf(uint8_t nodeid);
  void addToD(uint8_t pos1, uint8_t pos2, uint8_t p_db);

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
    dbg("ndC","Hurray!, its up\n");
  }    
  event void AMControl.startDone (error_t err)
  {
    if (err == SUCCESS){
      dbg("ndC", "AM up!\n");
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
	dbg("ndC", "Hello\n");
	send_cmd (call AMPacket.source (bufPtr), HELLO);
	break;
      case START_DISCOVERY:
	dbg("ndC", "start_discovery\n");
	post start_discover ();
	break;
      case DISCOVERY_DONE:
	//dbg("ndC", "Discovery done\n");
	call Leds.led1On ();
	break;
      case GET_PDB:
	dbg("ndC", "get_pdb\n");
	call neighbours.set_pos (0);
	pdb_addr = call AMPacket.source (bufPtr);
	post send_pdb ();
	break;
      case GET_PDB_DONE:
	dbg("ndC", "get_pdb_done\n");
	if (call syndicateState.getState() == S_COLLECT) {
	  post test_syndicate();
	}
	break;
      case TEST_IM:
	dbg("ndC", "test_im\n");
       	post test_im();
	break;
      case TEST_DEBUG:
	dbg("ndC", "test_debug\n");
	call debugger.send_uint8_t (1);
	call debugger.send_uint32_t (-1);
	call debugger.send_double (0.1);
	call debugger.send_coordinate_f (1.23,0.001);
	call debugger.debug_flush ();
	break;
      case TEST_SYNDICATE:
	dbg("ndC", "test_syndicate\n");
	post test_syndicate();
	break;
      case TEST_IM2:
	dbg("ndC", "test_im2\n");
       	post test_im2();
	break;
      default:
	dbg("ndC", "Err\n");
	sig_error ();
      }
    }
    return bufPtr;
  }
  
  task void test_syndicate()
  {
    static int curr_pos=1;
    switch (call syndicateState.getState()) {
    case S_IDLE:
      call syndicateState.forceState(S_COLLECT);
      curr_pos = 1;		/* Choosing 1 because 0 is self */
      im_initialize();
      call neighbours.set_pos(0);
      temp_n = call neighbours.next_item();
      if (temp_n) {
	addToD(TOS_NODE_ID, temp_n->node_id, temp_n->p_db );
      }
    case S_COLLECT:
      //foreach node in neighbour list issue GET_PDB
      call neighbours.set_pos(curr_pos);
      temp_n = call neighbours.next_item();
      curr_pos = call neighbours.get_pos();
      if (temp_n) {
	send_cmd(temp_n->node_id, GET_PDB);
      } else {
	curr_pos = 0;
	call syndicateState.forceState(S_DISPATCH);
	post test_syndicate();
      }
      break;
    case S_DISPATCH:
#ifndef TOSSIM
      for (j = 0; j < curr_pos; j++){
	call debugger.send_double(gsl_matrix_get(d, curr_pos, j));
      }
      call debugger.send_uint8_t(curr_pos);
      call debugger.debug_flush();
      if (++curr_pos == d->size1)
	call syndicateState.forceState(S_DONE);
#else
      dbg("ndC", "distance estimates\n");
      for (curr_pos = 0; curr_pos < d->size1; curr_pos++) {
	for (j = 0; j < curr_pos; j++)
	  dbg("ndC", "%f, ", gsl_matrix_get(d, curr_pos, j));
	dbg("ndC", "\n");
      }
      call syndicateState.forceState(S_DONE);
      post test_syndicate();
#endif
      break;
    case S_DONE:
      call Leds.led0On();
    default:
      call Leds.led1On();
      sig_error();
    }
  }

  void im_initialize() {
    int ii;
    call im.alloc(call neighbours.size(), 2);
    p = call im.get_p();
    d = call im.get_d();
    for (ii = 0; ii < d->size1; ii++)
      gsl_matrix_set(d, ii, ii, 0);
  }

  void addToD(uint8_t pos1, uint8_t pos2, uint8_t p_db) {
    if ((pos2 != -1) && (pos1 != -1) && (pos1 != pos2)) {
      //if (pos2 < pos1)	/* Fill only lower triangle */
	gsl_matrix_set(d, pos1, pos2, computeDistance(p_db));
	//else
	gsl_matrix_set(d, pos2, pos1, computeDistance(p_db));
    }
  }
  
  event message_t* neighbour_data_receive.receive(message_t* bufPtr, void* payload, uint8_t len)
  {
    neighbour_data_t* rcm;        
    uint8_t pos1, pos2;
    if (len != sizeof (neighbour_data_t)){
      return bufPtr;
    } else {
      rcm = (neighbour_data_t*) payload;
      //Make an entry in neighbours
      pos1 = indexOf(call AMPacket.source(bufPtr));
      pos2 = indexOf(rcm->node_id);
      addToD(pos1, pos2, rcm->p_db);
    }
    return bufPtr;
  }

  uint8_t indexOf(uint8_t nodeid)
  {
#ifdef TOSSIM
    return nodeid;
#endif
    call neighbours.set_pos(0);
    while ((temp_n = call neighbours.next_item())) {
      if ((temp_n->node_id == nodeid))
	return call neighbours.get_pos() - 1;
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
    temp_n = call neighbours.get ();
    temp_n->node_id = TOS_NODE_ID; /* Registering self */
    temp_n->p_db = -1;		   /* With max possible pdb */

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
    dbg("ndC","send  %d\n", group_leader);
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
    dbg("ndC","Discovery complete\n");
    if (TOS_NODE_ID == group_leader)
      send_cmd (AM_BROADCAST_ADDR, DISCOVERY_DONE);
  }
  
  event message_t* neighbour_discover_receive.receive (message_t* bufPtr, void* payload, uint8_t len)
  {
    neighbour_discover_msg_t* rcm; 
    dbg("ndC","rcv!\n");
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
#ifndef TOSSIM      
      temp_n->p_db = call PacketRSSI.get (bufPtr);
#else
      temp_n->p_db = 84 + (84 * (int8_t)(call PacketRSSI.strength(bufPtr))) / 91;
      //temp_n->p_db = -40 - (int8_t)(call PacketRSSI.strength(bufPtr));
#endif
      dbg("ndC", "%d %d %hhi\n", rcm->leader, temp_n->node_id, temp_n->p_db);
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
      if (pdb_addr == 255) {
	dbg("ndC","%d %d\n", temp_n->node_id, temp_n->p_db);
	signal neighbour_data_send.sendDone(&packet, SUCCESS);
      } else {
	_SEND_INI(pkt, neighbour_data_t, &packet)
	  memcpy (pkt, temp_n, sizeof (neighbour_data_t));
	_SEND_SEND( neighbour_data_send, pdb_addr, &packet, neighbour_data_t)
	  }
    } else {
      if (pdb_addr == 255)	
	dbg("ndC","get_pdb_done\n");
      else
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
    for (i = 0; i < call neighbours.size(); i++){
      for (j = 0; j < 2; j++)
	gsl_matrix_set(p, i, j, ((float)(call Random.rand16()%100))/100 * 5);
      dbg("ndC","l %f %f\n",gsl_matrix_get(p,i,0),gsl_matrix_get(p,i,1));
    }

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
    dbg("ndC","loss %g\n",call im.loss());
    call debugger.send_uint8_t(iters);
    call debugger.send_double((double)fabs(a));
    call debugger.debug_flush();
  }

  double computeDistance (uint8_t dis)
  {
    /* dbg("ndC","ComputeDistance %d %f\n", dis, (EXPRS(dis))); */
    uint8_t ind;
    //return dis;
    ind = 40 - dis;
    if ( ind < 0 )
      return 0.1;
    if ( ind > 33 )
      return 50;
    return (distance_table[ind] == 0)?0.01:(double)distance_table[ind];
    //return EXPRS(dis);
  }
  
  event void debugger.flushDone ()
  {
    float a;
    if (call syndicateState.getState() == S_DISPATCH) {
      post test_syndicate();
    } else if (im_running) {
      a = call im.test();
      if (fabs(a) > 1) {
	post im_iterate();
	i = 0;
      } else {
	if (i < p->size1) {
	  call debugger.send_coordinate_f (gsl_matrix_get(p,i,0), gsl_matrix_get(p,i,1));
	  call debugger.debug_flush ();
	  i++;
	} else {
	  dbg("ndC","Final loss %f\n", call im.loss());
	  call im.free();
	dbg("ndC","Done with IM!\n");
	}
      }
    }
  }
}
