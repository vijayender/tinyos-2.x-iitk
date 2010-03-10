/**
 * Implementation for AccelTest application.
 **/

#include "Timer.h"
#include "Accel.h"

module AccelC @safe()
{
  uses {
    interface Boot;
    interface Leds;
    interface Packet;
    interface AMSend;
    interface SplitControl as AMControl;
    interface ReadStream<uint16_t> as X;
    interface ReadStream<uint16_t> as Y;
    interface Pool<message_t> as Pool;
    interface LocalTime<TMilli>as Time;
  }
}
implementation
{
  msg_t* curr;
  message_t* msg;
  void postBuffer();
  void sendData();

  void postBuffer(){
    if(call Pool.empty()){
      printf("Pool empty!\n");
      printfflush();
      return;
    }
    msg = call Pool.get();
    curr = (msg_t*)call Packet.getPayload(msg,sizeof(msg_t));
    call X.postBuffer((uint16_t*)curr->x,BUFSIZE);
    call X.read(INTERVAL);
    call Y.postBuffer((uint16_t*)curr->y,BUFSIZE);
    call Y.read(INTERVAL);
    /* printf("posted\n"); */
    /* printfflush(); */
  }

  void sendData(){
    static uint8_t i = 0;
    /* printf("sendData %d\n",i); */
    /* printfflush(); */
    i++;
    if(i == 2){
      i = 0;
      postBuffer();
      call AMSend.send(1,msg,sizeof(msg_t));
    }
  }
  
  event void Boot.booted()
  {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if(err == SUCCESS){
      //      printf("Radio started succesfully\n");
      //      printfflush();
      
      //continue
      postBuffer();
    }else{
      call AMControl.start();
    }
  }

  event void X.readDone(error_t err, uint32_t usActualPeriod){
    //    printf("X Read done !\n");
    //    printfflush();
    // Submit a new buffer
    curr->x_tsp = call Time.get();
    // Radio transmit contents of old buffer
    sendData();
  }

  event void X.bufferDone(error_t err, uint16_t* buf, uint16_t count){
    //    printf("bufferDone X\n");
  }

  event void Y.readDone(error_t err, uint32_t usActualPeriod){
    //    printf("Y Read done !\n");
    //    printfflush();
    // Submit a new buffer
    curr->y_tsp = call Time.get();
    // Radio transmit contents of old buffer.
    sendData();
  }

  event void Y.bufferDone(error_t err, uint16_t* buf, uint16_t count){
    //    printf("bufferDone Y\n");
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t err){
    //put back bufPtr back into Pool
    error_t  err1= call Pool.put(bufPtr);
    if(err1 == SUCCESS) call Leds.led0Toggle();
    
  }
  
  event void AMControl.stopDone(error_t err){
  }

}

