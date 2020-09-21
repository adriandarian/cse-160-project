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

    command void Flooding.printFloodList() {
        uint16_t i = 0;
        if (!call FloodingList.isEmpty()) {
            while (i < call FloodingList.size()) {
                pack FloodingListElement = (pack) call FloodingList.get(i);
                logPack(&FloodingListElement);
                dbg(LOG_CHANNEL, "\n");
                i++;
            }
        }
    }

    command error_t Flooding.send(pack package, uint16_t destination) { 
        package.src = TOS_NODE_ID;
        package.protocol = PROTOCOL_PING;
        package.seq = sequenceNumber++;
        package.TTL = MAX_TTL;
        call Sender.send(package, AM_BROADCAST_ADDR);
    }

    command void Flooding.pingHandle(pack *package) {
        // Have we seen the node before
        if (package->TTL == 0 || searchForPackage(package)) {
            // Drop the packet if we've seen it or if it's TTL has run out: i.e. do nothing
            dbg(FLOODING_CHANNEL, "Packet Exists in the List so dropping packet with seq %d from %d\n", package->seq, TOS_NODE_ID);
        } else if (package->dest == TOS_NODE_ID) {
            dbg(GENERAL_CHANNEL, "This is the Destination from: %d to %d\n", package->src, package->dest);

            // Found its destination, does nothing if so
            if (package->protocol == PROTOCOL_PING) {
            //     dbg(FLOODING_CHANNEL, "Sending a Ping Reply from: %d to %d with seq %d\n", package->dest, package->src, package->seq);

                // Add to cache
                pushToFloodingList(package);

            //     makePack(&sendPackage, package->dest, package->src, package->TTL - 1, PROTOCOL_PINGREPLY, package->seq, (uint8_t *)package->payload, sizeof(package->payload));
            //     call Sender.send(sendPackage, AM_BROADCAST_ADDR);
                
                return;
            } 
            // else if (package->protocol == PROTOCOL_PINGREPLY) {
            //     dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", package->src);
            // }
        } else {
            // Re-validate list of seen nodes 
            pushToFloodingList(package);
            dbg(FLOODING_CHANNEL, "Flooding at node %d\n", TOS_NODE_ID);
            makePack(&sendPackage, package->src, package->dest, package->TTL - 1, package->protocol, package->seq, (uint8_t *)package->payload, sizeof(package->payload));
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }

        return;
    }
}



/*
*             1
*           /  \
*          3 __ 2
*         / \  \  \        
*        6__ 4 __ 5
*            /      \   
*       9 __ 8  ___7 
*/