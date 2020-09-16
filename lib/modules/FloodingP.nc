/*
 * ~Flooding MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module FloodingP {
    provides interface Flooding;

    // Interfaces to be used:
    uses interface SimpleSend; // For sending messages to potential neighbors
}

implementation {
    command error_t Flooding.start() { // print debug indicating that import was successful for now
        dbg(GENERAL_CHANNEL,"Flooding works\n");
    }
}