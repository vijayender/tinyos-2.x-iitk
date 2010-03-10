#include "Accel.h"
/**
 * AccelAppC is a basic application that reads
 * from mts300 sensor
 * 
 * @author kvijayender@gmail.com
 **/

configuration AccelAppC
{
}
implementation
{
  components MainC, AccelC as App, LedsC,LocalTimeMilliC;
  App -> MainC.Boot;
  App.Leds -> LedsC;
  App.Time -> LocalTimeMilliC;

  components new PoolC(message_t,2);
  App.Pool -> PoolC;

  components new AMSenderC(AM_ACCEL_RADIO);
  components ActiveMessageC;

  App.Packet -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;

  components new AccelXStreamC(), new AccelYStreamC();
  App.X -> AccelXStreamC;
  App.Y -> AccelYStreamC;
}

