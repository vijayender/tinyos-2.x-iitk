#include "nd.h"
#include "im/gsl_matrix.h"
#ifdef TOSSIM
#define RF230ActiveMessageC ActiveMessageC
#endif
configuration ndAppC
{
}
implementation
{
  components MainC, ndC as App, LedsC, RandomC;
  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;
  App.Random -> RandomC;

  components ActiveMessageC;
#ifndef TOSSIM
  components RF230ActiveMessageC;
#endif
  App.AMControl -> ActiveMessageC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;
  App.PacketRSSI -> RF230ActiveMessageC.PacketRSSI;

  components new AMSenderC (AM_ND_MSG) as neighbour_discover_send;
  components new AMReceiverC (AM_ND_MSG) as neighbour_discover_receive;
  App.neighbour_discover_receive -> neighbour_discover_receive;
  App.neighbour_discover_send -> neighbour_discover_send;

  components new AMReceiverC (AM_CONTROL_MSG) as controller_receive;
  components new AMSenderC (AM_CONTROL_MSG) as controller_send;
  App.controller_receive -> controller_receive;
  App.controller_send -> controller_send;

  components new AMSenderC (AM_NDATA_MSG) as neighbour_data_send;
  App.neighbour_data_send -> neighbour_data_send;

  components new AMSenderC (AM_COORD_MSG) as coordinate_send;
  App.coordinate_send -> coordinate_send;
  
  components new VarArrayC (neighbour_data_t, 8);
  App.neighbours -> VarArrayC;

  components new TimerMilliC() as backoff;
  components new TimerMilliC() as discover_complete;
  App.backoff -> backoff;
  App.discover_complete -> discover_complete;

  components iterative_majorizeC as im;
  App.im -> im;
}