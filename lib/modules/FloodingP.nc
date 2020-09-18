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

    
    void validateFloodingList(pack *package){
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
        package.seq = sequenceNumber++;
        package.TTL -= 1;
        call Sender.send(package, AM_BROADCAST_ADDR);
    }

    command void Flooding.pingHandle(pack *package) {
        if(package->dest == TOS_NODE_ID) {
            dbg(FLOODING_CHANNEL, "This is the Destination from: %d to %d\n", package->src, package->dest);
            dbg(FLOODING_CHANNEL, "Package Payload: %s\n", package->payload);

            if (package->protocol == PROTOCOL_PING && package->TTL > 0) {
                dbg(FLOODING_CHANNEL, "Going to ping from: %d to %d with seq %d\n", package->dest, package->src, package->seq);

                call Sender.send(*package, AM_BROADCAST_ADDR);

                validateFloodingList(package);
            } else if (package->protocol == PROTOCOL_PINGREPLY) {
                dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", package->src);
            }
        }
    }
}