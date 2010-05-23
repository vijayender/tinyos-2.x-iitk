import tos

class Radio_packet(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('control', 'int', 2)],
                            packet)

class coordinate_packet_f(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('x', 'float', 4),
                             ('y', 'float', 4)],
                            packet)

class pcPacket(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('counter','int',4),
                             ('toa', 'int',1),
                             ('rssi1','int',1),
                             ('rssi2','int',1),
                             ('lqi1','int',1),
                             ('lqi2','int',1),
                             ('retr1','int',1),
                             ('retr2','int',1),
                             ('v1','int',2),
                             ('v2','int',2)],
                            packet)
