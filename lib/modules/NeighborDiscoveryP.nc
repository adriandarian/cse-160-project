/*
 * ~NEIGHBOR DISCOVERY MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;

    // Interfaces to be used:
    uses interface SimpleSend; // For sending messages to potential neighbors
    uses interface Hashmap<uint16_t>;   // For keeping track of neighbors
    uses interface List<pack> as listOfNeighbors;
}

implementation {
    
    command error_t NeighborDiscovery.start() {      // print debug indicating that import was successful for now
        pack package;
        uint8_t payload = 123;
        dbg(GENERAL_CHANNEL,"neighbor discovery works\n");
        makePack(&package, TOS_NODE_ID,0,1,PROTOCOL_PING,0,&payload,PACKET_MAX_PAYLOAD_SIZE);
        call SimpleSend.send(package, AM_BROADCAST_ADDR);
    }

    command error_t NeighborDiscovery.print() {

    }

    command error_t NeighborDiscovery.getNeighbors() {}
}