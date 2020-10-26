/*
 * ~Neighbor Discovery Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;

    uses interface SimpleSend; // For sending messages to potential neighbors
    uses interface Hashmap<uint16_t>; // For keeping track of neighbors
    uses interface Timer<TMilli> as updateNeighborTable;
    uses interface Timer<TMilli> as updateTimer;
    uses interface Random;
}

implementation {
    
    /*
     * #######################################
     *              Commands
     * #######################################
     */

    // print debug indicating that import was successful for now
    command error_t NeighborDiscovery.start() {
        pack package;
        uint8_t payload = 84;
        dbg(NEIGHBOR_CHANNEL, "Sending Neighbor ping\n");
        makePack(&package, TOS_NODE_ID, 0, 1, PROTOCOL_NEIGHBOR_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call SimpleSend.send(package, AM_BROADCAST_ADDR);

        // UNCOMMENT THIS FOR DYNMAIC NEIGHBOR TABLE
        call updateNeighborTable.startPeriodic(20000); //update evey 30 seconds 
    }

    command void NeighborDiscovery.pingHandle(pack * package) {
        if (package->protocol == PROTOCOL_NEIGHBOR_PING && package->TTL > 0) {
            // Use the same package in the reply, so decrease the TTL by 1 and set the source to this TOS_NODE_ID
            // Also change the protocol to a ping reply so when the neighboring nodes recive it they dont forward it
            uint16_t dest = package->src;
            package->protocol = PROTOCOL_NEIGHBOR_PING_REPLY;
            package->TTL -= 1;
            package->src = TOS_NODE_ID;

            // broadcast the modified package:
            call SimpleSend.send(*package, dest);
            dbg(NEIGHBOR_CHANNEL,"Sent reply\n");
        }

        // Check if neighbors replied by checking protocol:
        else if (package->protocol == PROTOCOL_NEIGHBOR_PING_REPLY) {
            dbg(NEIGHBOR_CHANNEL, "Neighbor discovered %d\n", package->src);
            call Hashmap.insert(package->src, 2);
        }
    }

    command error_t NeighborDiscovery.print() {
        uint16_t j;
        uint16_t tableSizeP;
        uint32_t *keyPtrP;
        uint16_t i;
        uint32_t *keyPtr = call Hashmap.getKeys();
        uint16_t tableSize = call Hashmap.size();
        pack package;
        uint16_t payload = 84;

        dbg(NEIGHBOR_CHANNEL, "Updating neighbor table\n");
        makePack(&package, TOS_NODE_ID, 0, 1, PROTOCOL_NEIGHBOR_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        // wait some time:
        // call updateTimer.startOneShot((call Random.rand16() % 500) + 300);

        for (i = 0; i < tableSize; i++) {
            call Hashmap.insert(keyPtr[i], call Hashmap.get(keyPtr[i]) - 1);
        }

        for (i = 0; i < tableSize; i++) {
            if (call Hashmap.get(keyPtr[i]) <= 0) {
                call Hashmap.remove(keyPtr[i]);
                dbg(NEIGHBOR_CHANNEL, "Removed %d from neighbor table\n", keyPtr[i]);
            }
        }

        call SimpleSend.send(package, AM_BROADCAST_ADDR);
        if (!call Hashmap.isEmpty()) {
            tableSizeP = call Hashmap.size();
            keyPtrP = call Hashmap.getKeys();

            for (j = 0; j < tableSizeP; j++) {
                dbg(GENERAL_CHANNEL, "Neighbors: %d\n", keyPtrP[j]); 
            }

            dbg(NEIGHBOR_CHANNEL, "\n");
            
            return SUCCESS;
        }

        return FAIL;
    }

    command uint16_t NeighborDiscovery.size() {
        return call Hashmap.size();
    }

    command uint32_t* NeighborDiscovery.getNeighbors() {
        
        return call Hashmap.getKeys();
    }

    /*
     * #######################################
     *              Events
     * #######################################
     */

    // Need to implement timer so that neighbor table is updated
    event void updateNeighborTable.fired() {
        uint16_t i;
        uint32_t *keyPtr = call Hashmap.getKeys();
        uint16_t tableSize = call Hashmap.size();
        pack package;
        uint16_t payload = 84;

        dbg(NEIGHBOR_CHANNEL, "Updating neighbor table\n");
        makePack(&package, TOS_NODE_ID, 0, 1, PROTOCOL_NEIGHBOR_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        // wait some time:
        // call updateTimer.startOneShot((call Random.rand16() % 500) + 300);

        for (i = 0; i < tableSize; i++) {
            call Hashmap.insert(keyPtr[i], call Hashmap.get(keyPtr[i]) - 1);
        }

        for (i = 0; i < tableSize; i++) {
            if (call Hashmap.get(keyPtr[i]) <= 0) {
                call Hashmap.remove(keyPtr[i]);
                dbg(NEIGHBOR_CHANNEL, "Removed %d from neighbor table\n", keyPtr[i]);
            }
        }

        call SimpleSend.send(package, AM_BROADCAST_ADDR);
    }

    event void updateTimer.fired() {}
}