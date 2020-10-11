/*
 * ~Flooding Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/linkstate.h"

module FloodingP {
    provides interface Flooding;

    uses interface SimpleSend as Sender;
    uses interface List<pack> as FloodingList;
}

implementation {
    uint16_t broadcastDest = 666;
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

        return SUCCESS;
    }

    command void Flooding.pingHandle(pack* message) {
        if (message->protocol == PROTOCOL_PING) {
            // Have we seen the node before
            if (message->TTL <= 0 || searchForPackage(message)) {
                // Drop the packet if we've seen it or if it's TTL has run out: i.e. do nothing
                dbg(FLOODING_CHANNEL, "Package in node %d already inside of cache, proceeding to drop\n", TOS_NODE_ID);
                return;
            } else if (message->dest == TOS_NODE_ID) {
                dbg(GENERAL_CHANNEL, "This is the Destination from: %d to %d with %d\n", message->src, message->dest, message->seq);

                // Found its destination, does nothing if so
                if (message->protocol == PROTOCOL_PING) {
                    // dbg(FLOODING_CHANNEL, "Sending a Ping Reply from: %d to %d with seq %d\n", message->dest, message->src, message->seq);

                    // Add to cache
                    pushToFloodingList(message);

                    // TODO: PINGREPLY DOES NOT WORK, BUT LUCKILY WE DID NOT NEED IT
                    // makePack(&sendPackage, message->dest, message->src, message->TTL - 1, PROTOCOL_PINGREPLY, message->seq, (uint8_t *)message->payload, sizeof(message->payload));
                    // call Sender.send(sendPackage, AM_BROADCAST_ADDR);
                    
                    return;
                } 
                // else if (message->protocol == PROTOCOL_PINGREPLY) {
                //     dbg(FLOODING_CHANNEL, "Received a Ping Reply from node %d\n", message->src);
                // }

                return;
            } else {
                dbg(FLOODING_CHANNEL, "Flooding at node %d\n", TOS_NODE_ID);

                // Re-validate list of seen nodes 
                pushToFloodingList(message);

                // Send off package to next node in network
                makePack(&sendPackage, message->src, message->dest, message->TTL - 1, message->protocol, message->seq, (uint8_t *)message->payload, sizeof(message->payload));
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }
        } 

        return;
    }


    command void Flooding.LSAHandle(pack* message) {
        LSA *payload = message->payload;
        LSATuple LinkStates = payload->linkStates[0];
        logPack(message);
        dbg(ROUTING_CHANNEL, "Payload:[Neighbor: %d, cost: %d]\n", LinkStates.neighborAddress, LinkStates.cost);
        /*
        * 1) Get flooding package
        * 2) Access tuple list
        * 3) For every tuple in the list
        * 4) set next hop to TOS_NODE_ID
        * 5) Forward the packet
        */
        if (message->protocol == PROTOCOL_LINKED_STATE) {
            // Have we seen the node before
            if (message->TTL <= 0 || searchForPackage(message)) {
                // Drop the packet if we've seen it or if it's TTL has run out: i.e. do nothing
                dbg(FLOODING_CHANNEL, "Package in node %d already inside of cache, proceeding to drop\n", TOS_NODE_ID);
                return;
            } else {
                dbg(FLOODING_CHANNEL, "Flooding at node %d\n", TOS_NODE_ID);

                // Re-validate list of seen nodes 
                pushToFloodingList(message);
                
                // Send off package to next node in network
                makePack(&sendPackage, message->src, broadcastDest, message->TTL - 1, message->protocol, message->seq, (uint8_t *)message->payload, sizeof(message->payload));
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }
        } 

    }
}



/*
*       example.topo
*             1
*           /  \
*          3 __ 2
*         / \  \  \        
*        6__ 4 __ 5
*            /      \   
*       9 __ 8  ___  7 
*/