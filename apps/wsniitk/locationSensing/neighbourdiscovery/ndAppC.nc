#include "nd.h"
#include "im/gsl_matrix.h"

#ifdef TOSSIM
void printfflush();

void printfflush(){}
#endif

configuration ndAppC {}
implementation
{
  components MainC, ndC as App, LedsC, RandomC;
  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;
  App.Random -> RandomC;

  components ActiveMessageC;
#ifndef TOSSIM
  components RF230ActiveMessageC;
  App.PacketRSSI -> RF230ActiveMessageC.PacketRSSI;
#else
  components TossimActiveMessageC;
  App.PacketRSSI -> TossimActiveMessageC.TossimPacket;
#endif
  App.AMControl -> ActiveMessageC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;

  components new AMSenderC (AM_ND_MSG) as neighbour_discover_send;
  components new AMReceiverC (AM_ND_MSG) as neighbour_discover_receive;
  App.neighbour_discover_receive -> neighbour_discover_receive;
  App.neighbour_discover_send -> neighbour_discover_send;

  components new AMReceiverC (AM_CONTROL_MSG) as controller_receive;
  components new AMSenderC (AM_CONTROL_MSG) as controller_send;
  App.controller_receive -> controller_receive;
  App.controller_send -> controller_send;

  components new AMSenderC (AM_NDATA_MSG) as neighbour_data_send;
  components new AMReceiverC (AM_NDATA_MSG) as neighbour_data_receive;
  App.neighbour_data_send -> neighbour_data_send;
  App.neighbour_data_receive -> neighbour_data_receive;

  //  components new AMSenderC (AM_COORD_MSG) as coordinate_send;
  //  App.coordinate_send -> coordinate_send;
  
  components new VarArrayC (neighbour_data_t, 8);
  App.neighbours -> VarArrayC;

  components new TimerMilliC() as backoff;
  components new TimerMilliC() as discover_complete;
  App.backoff -> backoff;
  App.discover_complete -> discover_complete;

  components iterative_majorizeC as im;
  App.im -> im;

  components new StateC() as syndicateState;
  App.syndicateState -> syndicateState;
  
  /* DEBUG */
  components new AMReceiverC (AM_DBG_MSG) as debug_receiver;
  components new AMSenderC (AM_DBG_MSG) as debug_sender;
  components new TimerMilliC() as timer2;
  components debugC as debugger;
  debugger.timer -> timer2;
  App.debugger -> debugger;
  debugger.Packet -> ActiveMessageC;
  debugger.sender -> debug_sender;
  debugger.receiver -> debug_receiver;
  debugger.Leds -> LedsC;
  MainC.SoftwareInit -> debugger;
}