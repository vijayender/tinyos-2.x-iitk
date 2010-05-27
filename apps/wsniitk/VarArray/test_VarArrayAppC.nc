
configuration test_VarArrayAppC {}
implementation
{
  components MainC, test_VarArrayC as App;
  App.Boot -> MainC.Boot;

  components new VarArrayC (uint8_t, 8) as Arr;
  App.Arr -> Arr;

  components new StateC() as SM; /* State Machine */
  App.SM -> SM;

}