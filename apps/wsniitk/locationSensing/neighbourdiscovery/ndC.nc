#include "nd.h"
#include "im/gsl_matrix.h"

#define EXPRS(dis)  ((exp((50.0-dis)/11) - 1)/2)

module ndC{
  uses {
    interface Leds;
    interface Boot;
    interface AMPacket;
    interface State as syndicateState;
    interface State as nd_state; /* Neighbour discovery state */

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
  uint16_t pdb_addr = AM_BROADCAST_ADDR;
  uint8_t iters = 0;  
  bool im_running = FALSE, results = FALSE;
  int i,j,k;
  int16_t x,y;
  float _x,_y;
  float factor;
  uint8_t n;
  uint8_t finished_discovery = 0;
  bool updated = TRUE;
  bool requireUpdate = FALSE;
  
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
  bool computeNewCoordinate(void);
  void initializeArr();

  task void start_discover ();
  task void send_pdb ();

  enum {
    S_IDLE,
    S_COLLECT,
    S_DISPATCH,
    S_DONE
  };

  enum {			/* nd_state */
    N_IDLE,
    N_DISCOVER,
    N_TEST,
    N_DONE,
  };
  

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
	call nd_state.forceState(N_IDLE);
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
	/* if (call syndicateState.getState() == S_COLLECT) { */
	/*   post test_syndicate(); */
	/* } */
	break;
      default:
	dbg("ndC", "Err\n");
	sig_error ();
      }
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

  void initializeArr () {
    requireUpdate = FALSE;
    factor = 0;
      n = 0;
      _x = 0;
      _y = 0;
  }

  /* DISCOVERY STUFF */
  task void start_discover ()
  {
    static int test_count;
    switch (call nd_state.getState()) {
    case N_IDLE:
      initializeArr();
      updated = TRUE;
      test_count = 0;
      x = call Random.rand16()%100 - 50;
      y = call Random.rand16()%100 - 50;
      call nd_state.forceState(N_DISCOVER);
      call neighbours.reset ();
      wait = call Random.rand16 () & 0x00ff;	/* Maximum of 16ms */
      call backoff.startOneShot (wait);
      call discover_complete.startOneShot(TIMEOUT);
      break;
    case N_TEST:
      updated = computeNewCoordinate();
      if(!requireUpdate){
	test_count++;
      }else{
	test_count = 0;
      }
      initializeArr();
      dbg("ndC","CC %f %f\n",(float)x/10,(float)y/10);
      if (test_count == 3) {
	finished_discovery = 1;
	dbg("ndC","DONE %d %f, %f \n",TOS_NODE_ID,(float)x/10,(float)y/10);
	call nd_state.forceState(N_DONE);
      } else {
	wait = call Random.rand16 () & 0x00ff;	/* Maximum of 16ms */
	call backoff.startOneShot (wait);
	call discover_complete.startOneShot(TIMEOUT);
	call nd_state.forceState(N_DISCOVER);
      }
      break;
    case N_DONE:
    }
  }

  bool computeNewCoordinate(void){
    iters++;
    dbg("ndC","Finishing Iter: %d\n", iters);
    factor /= n;

    _x /= n;
    _x += x*(1-factor);

    _y /= n;
    _y += y*(1-factor);

    if ((fabs(_x - x) < 1 ) && (fabs(_y - y) < 1)){
      x = (int16_t)_x;
      y = (int16_t)_y;      
      return FALSE;
    }else{
      x = (int16_t)_x;
      y = (int16_t)_y;
      return TRUE;
    }
  }
  
  event void backoff.fired ()
  {
    _SEND_ALLOC(rcm, neighbour_discover_msg_t);
      //Set leader to self.
    _SEND_INI(rcm, neighbour_discover_msg_t, &packet);
    rcm->x = x;
    rcm->y = y;
    rcm->updated = updated;
    dbg("ndC","send  %d,%d\n", rcm->x, rcm->y);
    _SEND_SEND(neighbour_discover_send, AM_BROADCAST_ADDR, &packet, neighbour_discover_msg_t);
  }

  event void neighbour_discover_send.sendDone (message_t* bufPtr, error_t error)
  { 
  }

  event void discover_complete.fired ()
  {
    call nd_state.forceState(N_TEST);
    post start_discover();
  }
  
  event message_t* neighbour_discover_receive.receive (message_t* bufPtr, void* payload, uint8_t len)
  {
    neighbour_discover_msg_t* rcm;
    int16_t estimated_distance;
    int16_t computed_distance;
    float _factor;
    if (len != sizeof (neighbour_discover_msg_t)){
      return bufPtr;
    } else {
      rcm = (neighbour_discover_msg_t*) payload;

#ifndef TOSSIM      
      estimated_distance = computeDistance(call PacketRSSI.get (bufPtr));
#else
      //temp_n->p_db = 84 + (84 * (int8_t)(call PacketRSSI.strength(bufPtr))) / 91;
      estimated_distance = computeDistance(-40 - (int8_t)(call PacketRSSI.strength(bufPtr)));
#endif
      requireUpdate |= (rcm->updated);
      computed_distance = sqrt(SQR(rcm->x - x) + SQR(rcm->y - y));
      _factor = 1-((float)estimated_distance)*10 / computed_distance;
      _x += _factor * rcm->x;
      _y += _factor * rcm->y;
      factor += _factor;
      n += 1;
      dbg("ndC","dbgV: %d %d %f\n",estimated_distance, computed_distance,_factor);
    }      
    return bufPtr;
  }

  task void send_pdb ()
  {
    _SEND_ALLOC(pkt, neighbour_data_t);
    temp_n = call neighbours.next_item ();
    if (temp_n){
      if (pdb_addr == 255) {
	dbg("ndC","%d %d %d\n", temp_n->node_id, temp_n->computed_distance, temp_n->estimated_distance);
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

  double computeDistance (uint8_t dis)
  {
    /* dbg("ndC","ComputeDistance %d %f\n", dis, (EXPRS(dis))); */
    uint8_t ind;
    return dis;
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
  }
  
  event message_t* neighbour_data_receive.receive (message_t* bufPtr, void* payload, uint8_t len)
  {
    return bufPtr;
  }
}
