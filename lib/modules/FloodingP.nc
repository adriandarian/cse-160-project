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
    uses interface Receive as Receiver;
    uses interface List<pack> as FloodingList;
}

implementation {
    uint16_t sequenceNumber = 0;
    pack sendPackage;
    
    bool searchForPackage(pack *package) {
        uint16_t i = 0, FloodingListSize = call FloodingList.size();
        while (i < FloodingListSize) {
          pack temporaryPackage = call FloodingList.get(i);

          if (temporaryPackage.src == package->src && temporaryPackage.dest == package->dest && temporaryPackage.seq == package->seq) {
            return TRUE;
          }

          i++;
        }

        return FALSE;
    };

    void pushToFloodingList(pack *package){
        if (call FloodingList.size() == 64) {
            call FloodingList.popfront();
        }

        call FloodingList.pushback(*package);
    }

    void printFloodList() {
        uint16_t i = 0;
        dbg(LOG_CHANNEL, "Flood List Print\n");
        if (!call FloodingList.isEmpty()) {
            dbg(LOG_CHANNEL, "Start Flood List Print\n");

            while (i < call FloodingList.size()) {
                pack FloodingListElement = (pack) call FloodingList.get(i);
                logPack(&FloodingListElement);
                i++;
            }

            dbg(LOG_CHANNEL, "End Flood List Print\n");
        }
    }

    command error_t Flooding.send(pack package, uint16_t destination) { 
        package.src = TOS_NODE_ID;
        package.protocol = PROTOCOL_PING;
        package.seq = sequenceNumber++;
        package.TTL = MAX_TTL;
        call Sender.send(package, AM_BROADCAST_ADDR);
    }

    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len) {
        if (len == sizeof(pack)) {
            pack *message = (pack *)payload;

            // Have we seen the node before
            if (message->TTL == 0 || searchForPackage(message)) {
                // Drop the packet if we've seen it or if it's TTL has run out: i.e. do nothing
                dbg(FLOODING_CHANNEL, "Packet Exists in the List so dropping packet with seq %d from %d\n", message->seq, TOS_NODE_ID);
                return msg;
            } else if (message->dest == TOS_NODE_ID) {
                dbg(GENERAL_CHANNEL, "This is the Destination from: %d to %d\n", message->src, message->dest);

                printFloodList();

                // Found its destination, does nothing if so
                if (message->protocol == PROTOCOL_PING) {
                    dbg(FLOODING_CHANNEL, "Sending a Ping Reply from: %d to %d with seq %d\n", message->dest, message->src, message->seq);

                    // Add to cache
                    pushToFloodingList(message);

                    makePack(&sendPackage, message->dest, message->src, message->TTL - 1, PROTOCOL_PINGREPLY, message->seq, (uint8_t *)message->payload, sizeof(message->payload));
                    call Sender.send(sendPackage, AM_BROADCAST_ADDR);
                    
                    return msg;
                } else if (message->protocol == PROTOCOL_PINGREPLY) {
                    dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", message->src);
                }

                return msg;
            } else {
                // Re-validate list of seen nodes 
                pushToFloodingList(message);
                dbg(FLOODING_CHANNEL, "Flooding at node %d\n", TOS_NODE_ID);
                makePack(&sendPackage, message->src, message->dest, message->TTL - 1, message->protocol, message->seq, (uint8_t *)message->payload, sizeof(message->payload));
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }

            return msg;
        }

        dbg(GENERAL_CHANNEL, "Unknown Packet Type %u\n", len);
        return msg;
    }
}



/*
*             1
*           /  \
*          3 __ 2
*         / \  \  \        
*        6__ 4 __ 5
*            /      \   
*       9 __ 8  ___  7 
*/