// Author: UCM ANDES Lab
// $Author: abeltran2 $
// $LastChangedBy: abeltran2 $

#ifndef PACKET_H
#define PACKET_H

#include "protocol.h"
#include "channels.h"
#include "tcp.h"

enum{
	PACKET_HEADER_LENGTH = 8,
	PACKET_MAX_PAYLOAD_SIZE = 28 - PACKET_HEADER_LENGTH,
	MAX_TTL = 15,
};

typedef nx_struct pack{
	nx_uint16_t dest;
	nx_uint16_t src;
	nx_uint16_t seq;		// Sequence Number
	nx_uint8_t TTL;			// Time to Live
	nx_uint8_t protocol;
	nx_uint32_t payload[PACKET_MAX_PAYLOAD_SIZE];
}pack;

/*
 * logPack
 * 	Sends packet information to the general channel.
 * @param:
 * 		pack *input = pack to be printed.
 */
void logPack(pack *input) {
	dbg(LOG_CHANNEL, "Package [Src: %hhu, Dest: %hhu, Seq: %hhu, TTL: %hhu, Protocol: %hhu, Payload: %s]\n", input->src, input->dest, input->seq, input->TTL, input->protocol, input->payload);
}

void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint32_t* payload, uint8_t length) {
	Package->src = src;
	Package->dest = dest;
	Package->TTL = TTL;
	Package->seq = seq;
	Package->protocol = protocol;

	memcpy(Package->payload, payload, length);
}

void makePackTCP(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint32_t* payload, uint8_t length) {
	uint8_t i;

	Package->src = src;
	Package->dest = dest;
	Package->TTL = TTL;
	Package->seq = seq;
	Package->protocol = protocol;

	// zero tcp payload
	// for (i = 0; i < MAX_PAYLOAD_SIZE; i++) {
	// 	Package->payload[i] = 0;
	// }

	// for (i = 0; i < MAX_PAYLOAD_SIZE; i++) {
	// 	Package->payload[i] = payload[i];
	// }

	memcpy(Package->payload, payload, length);
}

enum{
	AM_PACK = 6,
};

#endif
