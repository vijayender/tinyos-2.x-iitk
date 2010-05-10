#include "RssiTest.h"

configuration LightDecoderAppC
{
}

implementation
{
  components MainC, LightDecoderC as App, LedsC;
  components new TimerMilliC() as light_Timer;
  components new AMSenderC(AM_RADIO_MSG);
  components ActiveMessageC;
  components  RF230ActiveMessageC;

  App -> MainC.Boot;
  App.Timer -> light_Timer;
  App.Leds -> LedsC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.PacketAcknowledgements -> RF230ActiveMessageC;
}