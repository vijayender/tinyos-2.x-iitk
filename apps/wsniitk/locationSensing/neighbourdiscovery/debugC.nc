#include "debug_v.h"


module debugC
{
  uses {
    interface AMSend as sender;
    interface Receive as receiver;
    interface Packet;
    interface Leds;
    interface Timer<TMilli> as  timer;
  }
  provides {
    interface debug_v;
    interface Init;
  }
}

implementation
{
  message_t packet0, packet1;
  void *start, *end, *data;
  uint8_t inUse = 0;
  void push_uint8_t (uint8_t i);
  void push_uint16_t (uint16_t i);
  void push_uint32_t (uint32_t i);
  void push_double (double i);
  void push_coordinate_f (double x, double y);
  void push_g (void* val, uint8_t size);
  bool hasSpace (uint8_t i);

  push_val (uint8_t)
  push_val (uint16_t)
  push_val (uint32_t)
  push_val (double)

  void push_coordinate_f (double x, double y)
  {
    push_g(&x, sizeof(double));
    push_g(&y, sizeof(double));
  }

  bool hasSpace (uint8_t i)
  {
    return (end >= start + i);
  }
  
  void push_g (void* val, uint8_t size)
  {
    //If packet has space then append to packet
    if(!hasSpace(size)){
      //Else send packet, clear packet and append packet
      /* printf("f"); */
      /* printfflush(); */
      call debug_v.debug_flush ();
    }

    /* printf("%d|",start); */
    /* printfflush(); */
    memcpy (start, val, size);
    start += size;
  }
 
  command error_t Init.init()
  {
    uint8_t i;
    if (inUse == 0)
      start = call Packet.getPayload (&packet0, TOSH_DATA_LENGTH);
    else
      start = call Packet.getPayload (&packet1, TOSH_DATA_LENGTH);
    end = (void *) ( (uint8_t *)start + TOSH_DATA_LENGTH);
    for (i = 0; i < TOSH_DATA_LENGTH; i++)
      *((uint8_t*)start + i) = 0;
    // end > start (only then work)
    return SUCCESS;
  }
 
  command error_t debug_v.debug_flush()
  {
    /* Send all messages stored till now */
    if (inUse == 0){
      inUse = 1;
      call sender.send (AM_BROADCAST_ADDR, &packet0, TOSH_DATA_LENGTH);
    } else {
      inUse = 0;
      call sender.send (AM_BROADCAST_ADDR, &packet1, TOSH_DATA_LENGTH);
    }
    call Init.init();
    return SUCCESS;
  }

  command void debug_v.send_uint8_t(uint8_t i)
  {
    //push_uint8_t (inUse);
    push_uint8_t (val_uint8_t);
    push_uint8_t (i);
    /* printf("%d:",i); */
    /* printfflush(); */
  }
  command void debug_v.send_uint16_t(uint16_t i)
  {
    push_uint8_t (val_uint16_t);
    push_uint16_t (i);
  }
  command void debug_v.send_uint32_t(uint32_t i)
  {
    push_uint8_t (val_uint32_t);
    push_uint32_t (i);
  }
  command void debug_v.send_double(double i)
  {
    push_uint8_t (val_double);
    push_double (i);
  }
  command void debug_v.send_coordinate_f(double x, double y)
  {
    push_uint8_t (val_coordinate);
    push_coordinate_f (x, y);
  }
  
  event void sender.sendDone (message_t* bufPtr, error_t error)
  {
    //Acknowledgements?
    call Leds.led0Toggle ();
    call timer.startOneShot (10);
  }

  event void timer.fired ()
  {
    signal debug_v.flushDone ();
  }

  command void* debug_v.getData ()
  {
    void * data2;
    data2 = data;
    data = NULL;
    return data2;
  }
  
  event message_t* receiver.receive(message_t* bufPtr, void* payload, uint8_t len){
    //TODO: check if busy
    data = (uint8_t *)payload;
    /* switch (*data){ */
    /* case val_uint8_t: */
    /*   break; */
    /* case val_uint16_t: */
    /*   break; */
    /* case val_uint32_t: */
    /*   break; */
    /* case val_double: */
    /*   break; */
    /* case val_coordinate_f: */
    /*   break; */
    /* default: */
    /* } */
    return bufPtr;
  }
}