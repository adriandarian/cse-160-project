/*
~DISCOVER NEIGHBOR MODULE~
Busher Bridi, Adrian Darian 
UC MERCED, Prof. Serpa CSE_160 2020
*/

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h" //
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module discoverNeighborP {
    provides interface discoverNeighbor;

    //Interfaces to be used:
    uses interface SimpleSend; //For sending messages to potential neighbors
    uses interface Hashmap<uint16_t>;   //For keeping track of neighbors
}

implementation {

    command error_t discoverNeighbor.start(){      // print debug indicating that import was successful for now
        dbg(GENERAL_CHANNEL,"neighbor discovery works\n");
    }
}
