/*
 * ~Link State Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/linkstate.h"

module LinkStateP{
    provides interface LinkState;

    uses interface SimpleSend as LinkStateSender;
    uses interface Flooding;
    uses interface NeighborDiscovery;

    uses interface Timer<TMilli> as LinkStateTimer;

    uses interface List<LS> as TemporaryList;
    uses interface List<LS> as TentativeList;
    uses interface List<LS> as ConfirmedList;
}

implementation{
    LS linkState;
    LSA linkStateAdvertisement;
    pack sendPackage;
    uint8_t payload;
/*
 * TODO: 
 *  Create LSA with neighbors 
 *  Make flooding command to send LSA to network
 *  Fix LSA handle
 *  Dijkstra
 *  Routing Table
 *
 *  IP Module (Forwarding)
 *  Document code
*/
    command void LinkState.start() {
        uint32_t *keys;
        uint8_t i = 0;

        // Create initial LinkState i.e. (D, 0, D)
        makeLS(&linkState, TOS_NODE_ID, 0, TOS_NODE_ID);
        call ConfirmedList.pushback(linkState);

        // Flood Link-State-Advertisment:
        // Start oneshot timer:
        if (call LinkStateTimer.isRunning() == FALSE) {
            // A random element of delay is included to prevent congestion.
            call LinkStateTimer.startOneShot(30000);
        }
        
        keys = call NeighborDiscovery.getNeighbors();
        
        for (i; i < call NeighborDiscovery.size(); i++) {
            dbg(NEIGHBOR_CHANNEL, "Node %d's neighbors %d\n", TOS_NODE_ID, keys[i]);
        }

        payload = &linkStateAdvertisement;
        makePack(&sendPackage, TOS_NODE_ID, 0, 1, PROTOCOL_LINKED_STATE, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call Flooding.pingHandle(&sendPackage);

    }

    // Add new link state to the confirmed list
    void updateConfirmedList(LS linkstate) {
        call ConfirmedList.pushback(linkstate);
    }

    // update our tentative list of link states
    void updateTentativeList(LS *linkstate) {
        uint8_t i = 0;

        // check if the tentative list if empty
        if (call TentativeList.isEmpty()) {
            // push new link state to end of tentative list
            call TentativeList.pushback(*linkstate);
        } else {
            for (i; i < call TentativeList.size(); i++) {
                // generate a temporary link state
                LS temp = call TentativeList.get(i);
                
                /*
                 * if the link state's destination is equal to the link state we want to update, 
                 * then update the cost and nextHop values 
                 */
                if (temp.destination == linkstate->destination) {
                    if (linkstate->cost < temp.cost) {
                        temp.cost = linkstate->cost;
                        temp.nextHop = linkstate->nextHop;
                    }
                }
            }
        }
    }

    // remove a link state from the tentative list
    void removeFromTentativeList(LS *linkstate) {
        uint8_t i = 0;

        // check if the tentative list and temporary list are empty
        if (!call TentativeList.isEmpty() && !call TemporaryList.isEmpty()) {
            for (i; i < call TentativeList.size(); i++) {
                LS temp = call TentativeList.get(i);

                // only remove the 
                if (temp.destination != linkstate->destination) {
                    call TemporaryList.pushback(temp);
                }

                call TentativeList.popfront();
            }
        }

        call TentativeList.popfront();

        if (!call TentativeList.isEmpty() && !call TemporaryList.isEmpty()) {
            for (i; i < call TemporaryList.size(); i++) {
                call TentativeList.pushback(call TemporaryList.get(i));
            }
        } else {
            dbg(ROUTING_CHANNEL, "Failed to remove linkstate with destination %d from TentativeList\n", linkstate->destination);
        }
    }

    command void LinkState.LSHandler(pack *package) {
        uint8_t dest;
        uint8_t src;
        uint8_t cost;

        if (package->protocol == PROTOCOL_LINKED_STATE && package->TTL > 0) {
            dest = *package->payload;
            src = package->src;
            cost = package->seq + 1;
            makeLS(&linkState, dest, cost, src);
            updateTentativeList(&linkState);
        }
    }

    command void LinkState.printRoutingTable() {
        uint8_t i = 0;

        for (i; i < call ConfirmedList.size(); i++) {
            dbg(ROUTING_CHANNEL, "%d\n", call ConfirmedList.get(i));
        }
    }

    // Dijkstra's Implementation
    void findShortestPath() {
        
    }

    event void LinkStateTimer.fired() {

    }
}