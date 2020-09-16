/*
 * ~Flooding MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h"

module FloodingP {
    provides interface Flooding;

    // Interfaces to be used:
    uses interface SimpleSend as Sender;
}

implementation {
    uint16_t sequenceNumber = 0;

    command error_t Flooding.send(pack package, uint16_t destination) { 
        package.seq = sequenceNumber++;
        call Sender.send(package, AM_BROADCAST_ADDR);
    }
}