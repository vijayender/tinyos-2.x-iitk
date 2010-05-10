#include "RssiTest.h"

module LightDecoderC
{
  uses {
    interface Timer<TMilli> as Timer;
    interface Leds;
    interface Boot;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Packet;
    interface PacketAcknowledgements;
  }
}
implementation
{

  message_t packet;
  uint8_t photoValue=0;
  uint8_t pos=0;

  event void Boot.booted()
  {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err)
  {
    int moteId = 3;
    command_msg_t* rcm;
    if(err == SUCCESS){
      rcm = (command_msg_t*) call Packet.getPayload(&packet,sizeof(command_msg_t));
      if(rcm  != NULL){
	rcm->control = 1;
	call PacketAcknowledgements.requestAck(&packet);
	call AMSend.send(moteId,&packet,sizeof(command_msg_t));
      }
    }else
      call AMControl.start();
  }

  event void AMControl.stopDone(error_t err)
  {
  }
  
  event void Timer.fired(){
    call PacketAcknowledgements.requestAck(&packet);
    call AMSend.send(3,&packet,sizeof(command_msg_t));
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    call Leds.led1Toggle();
    if(call PacketAcknowledgements.wasAcked(bufPtr)){
      call Leds.led0On();
    }else{
      call Timer.startOneShot(10);
    }
  }

}
