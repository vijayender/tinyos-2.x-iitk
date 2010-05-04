#include "nd.h"
#include "im/gsl_matrix.h"

module ndC{
  uses {
    interface Leds;
    interface Boot;
    interface AMPacket;

    interface Timer<TMilli> as backoff;
    interface Timer<TMilli> as discover_complete;
    interface Random;

    interface VarArray<neighbour_data_t> as neighbours;

    interface Receive as neighbour_discover_receive;
    interface AMSend as neighbour_discover_send;

    interface AMSend as neighbour_data_send;
    interface AMSend as coordiante_send;

    interface Receive as controller_receive;
    interface AMSend as controller_send;

    interface SplitControl as AMControl;
    interface Packet;
    interface PacketField<uint8_t> as PacketRSSI;

    interface iterative_majorize as im;
  }
}

implementation {
  bool busy = FALSE;
  neighbour_data_t* temp_n;
  message_t packet;
  int16_t wait;
  uint8_t group_leader = 0xff;
  uint16_t pdb_addr = AM_BROADCAST_ADDR;
  uint8_t iters = 0;  
  void send_cmd (uint16_t addr, uint8_t cmd);
  void sig_error (void);

  task void test_im(void);
  task void im_iterate ();
  task void start_discover ();
  task void send_pdb ();
  
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
    /* uint8_t * a; */
    /* uint8_t i; */
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
	/* TESTING MALLOC -- IT WORKS! */
	/* a = (uint8_t *) malloc (10*sizeof(uint8_t)); */
	/* printf("%p\n",a); */
	/* printfflush(); */
	/* for (i = 0 ; i < 10; i++) */
	/*   a[i] = i; */
	/* for (i = 0 ; i < 10; i++){ */
	/*   printf("%d",i); */
	/*   printfflush(); */
	/* } */
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
	break;
      case TEST_IM:
	printf("working\n");
	printfflush();
       	post test_im();
	break;
      default:
	sig_error ();
      }
    }
    return bufPtr;
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
    neighbour_discover_msg_t *rcm;
    if (neighbour_discovery_state == noleader){
      //Set leader to self.
      call Leds.led2On();
      group_leader = TOS_NODE_ID;
      neighbour_discovery_state = found_leader;
    }
    rcm = (neighbour_discover_msg_t*) call Packet.getPayload (&packet, sizeof (neighbour_discover_msg_t));
    if (rcm  != NULL){
      rcm->leader = group_leader;
      call neighbour_discover_send.send (AM_BROADCAST_ADDR, &packet, sizeof (neighbour_discover_msg_t));
    }
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
    neighbour_data_t* pkt;
    temp_n = call neighbours.next_item ();
    if (temp_n){
      pkt = (neighbour_data_t*) call Packet.getPayload (&packet, sizeof (neighbour_data_t));
      memcpy (pkt, temp_n, sizeof (neighbour_data_t));
      call neighbour_data_send.send (pdb_addr, &packet, sizeof (neighbour_data_t));
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
    command_msg_t* rcm;
    rcm = (command_msg_t*) call Packet.getPayload (&packet, sizeof (command_msg_t));
    if (rcm  != NULL){
      rcm->cmd = cmd;
      call controller_send.send (addr,&packet, sizeof (command_msg_t));
    }     
  }
  event void controller_send.sendDone(message_t* bufPtr, error_t error)
  {
  }

  task void test_im(void)
  {
    gsl_matrix *p,*d;
    float val[][2] = {{1,2},{3,4},{5,6}}, psum, diff;
    int i,j,k;

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
    post im_iterate();
  }

  task void im_iterate ()
  {
    float a;
    iters++;
    call im.iterate ();
    a = call im.test();
    call Leds.led0Toggle();
    printf("iters: %d %1.3f\n",iters, (double)a);
    printfflush();
    if (a > 0.001)
      post im_iterate();
  }

  send_element (gsl_matrix *d) {
    
  }
}
