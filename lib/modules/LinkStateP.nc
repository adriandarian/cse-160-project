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
    *  [x] Create LSA with neighbors 
    *  [x] Make flooding command to send LSA to network
    *  [ ] Fix LSA handle
    *  [ ] Dijkstra
    *  [ ] Routing Table
    *
    *  [ ] IP Module (Forwarding)
    *  [ ] Document code
    *  [ ] Test
    */
    command void LinkState.start() {
        // Create initial LinkState i.e. (D, 0, D)
        makeLS(&linkState, TOS_NODE_ID, 0, TOS_NODE_ID);
        call ConfirmedList.pushback(linkState);

        // Flood Link-State-Advertisment:
        // Start oneshot timer:
        call LinkStateTimer.startOneShot(30000);
    }

    // Add new link state to the confirmed list
    void updateConfirmedList(LS linkstate) {
        call ConfirmedList.pushback(linkstate);
    }

    // update our tentative list of link states
    void updateTentativeList(LS *linkstate) {
        uint8_t i;

        // check if the tentative list if empty
        if (call TentativeList.isEmpty()) {
            // push new link state to end of tentative list
            call TentativeList.pushback(*linkstate);
        } else {
            for (i = 0; i < call TentativeList.size(); i++) {
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
        uint8_t i;

        // check if the tentative list and temporary list are empty
        if (!call TentativeList.isEmpty() && !call TemporaryList.isEmpty()) {
            for (i = 0; i < call TentativeList.size(); i++) {
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
            for (i = 0; i < call TemporaryList.size(); i++) {
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
            /*
             * 1) Get the package
             * 2) set a var equal to the payload
             * 3) Store the payload tuples in our tentative list
             */
            dest = *package->payload;
            src = package->src;
            cost = package->seq + 1;
            makeLS(&linkState, dest, cost, src);
            updateTentativeList(&linkState);
        }
    }

    command void LinkState.printRoutingTable() {
        uint8_t i;

        for (i = 0; i < call ConfirmedList.size(); i++) {
            dbg(ROUTING_CHANNEL, "%d\n", call ConfirmedList.get(i));
        }
    }

    // Dijkstra's Implementation
    void findShortestPath() {
        
    }

    event void LinkStateTimer.fired() {
        uint8_t i;
        LSA *temp;
        uint32_t *neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t neighborListSize = call NeighborDiscovery.size();
        LSATuple LSAT;
        LSATuple LSATList[neighborListSize];
        
        for (i = 0; i < neighborListSize; i++) {
            makeLSATuple(&LSAT, neighbors[i], 1);

            //*(LSATList + i) = LSAT; // LSAList[i] = LSAT
            LSATList[i] = LSAT;
        }
        
        makeLSA(&linkStateAdvertisement, TOS_NODE_ID, 0, LSATList);
        //payload stores the address of linkStateAdvertisement which is type LSA.
        // if we want to print the contents of LSA we first have to dreference payload wich gives us LSA and then print the contents of LSA
        makePack(&sendPackage, TOS_NODE_ID, 0, 1, PROTOCOL_LINKED_STATE, 0, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
        call Flooding.LSAHandle(&sendPackage);
    }
}