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
    uses interface Receive as Receiver;
    uses interface SimpleSend as Sender;
}

implementation {
    uint16_t sequenceNumber = 0;

    command error_t Flooding.send(pack package, uint16_t destination) { 
        package.seq = sequenceNumber++;
        call Sender.send(package, destination);
    }

    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(pack)) {
            pack* floodMsg = (pack*) payload;

            if (floodMsg->TTL == 0) {
                return msg;
            } else if(TOS_NODE_ID == floodMsg->dest) {
                dbg(FLOODING_CHANNEL, "This is the Destination from: %d to %d\n", floodMsg->src, floodMsg->dest);
            }

            return msg;
        }
    }
}