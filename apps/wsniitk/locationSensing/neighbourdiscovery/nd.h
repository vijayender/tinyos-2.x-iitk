#ifndef ND_H
#define ND_H
#define RF230_RSSI_ENERGY
#define TIMEOUT 1000
typedef nx_struct command_msg {
  nx_uint16_t cmd;
} command_msg_t;

typedef nx_struct neighbour_discover_msg {
  //nx_uint16_t leader;
  nx_int16_t x;
  nx_int16_t y;
  nx_uint8_t updated;
} neighbour_discover_msg_t;

typedef nx_struct neighbour_data {
  nx_uint16_t node_id;
  nx_uint8_t estimated_distance;
  nx_uint8_t computed_distance;
} neighbour_data_t;

#define MAXRETRIES 50

enum {
  AM_CONTROL_MSG = 3,
  AM_ND_MSG = 4,
  AM_NDATA_MSG = 5,
  AM_RADIO_MSG = 6,
  AM_COORD_MSG = 7,
  AM_DBG_MSG = 8,
};

enum {
  HELLO,
  START_DISCOVERY,
  DISCOVERY_DONE,
  GET_PDB,
  GET_PDB_DONE,
  TEST_IM,
  TEST_DEBUG,
  TEST_SYNDICATE,
  TEST_IM2,
};


#define _SEND_ALLOC(p, t)			\
  t* p;
#define _SEND_INI(p, t, packet)				\
  p = (t*) call Packet.getPayload (packet, sizeof (t));	\
  if (p  != NULL){

#define _SEND_SEND(carrier, addr, packet, t)				\
  call carrier.send (addr, packet, sizeof (t));				\
  }


#endif
