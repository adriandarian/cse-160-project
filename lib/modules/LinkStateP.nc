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

    // Modules
    uses interface Timer<TMilli> as LinkStateTimer;
    uses interface Timer<TMilli> as RoutingTableTimer;
    uses interface SimpleSend as LinkStateSender;
    uses interface Flooding;
    uses interface NeighborDiscovery;

    // Data Structures
    uses interface List<pack> as RecievedList;
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
    *  [] Fix LSA handle
    *  [ ] Dijkstra
    *  [ ] Routing Table
    *  [ ] IP Module (Forwarding)
    *  [ ] Document code
    *  [ ] Test
    */

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */
    
    LS getLowestCost();
    void updateConfirmedList(LS incomingLinkState);
    void updateTentativeList(LS incomingLinkState);
    void removeFromTentativeList(LS linkstate);
    bool searchForPackage(pack package);
    void printLSA(LSA* LSAdvertisement);
    void findShortestPath();
    void printTentativeList();
    void printConfirmedList();

    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command void LinkState.start() {
        // Create initial LinkState i.e. (D, 0, D)
        makeLS(&linkState, TOS_NODE_ID, 0, TOS_NODE_ID);
        call ConfirmedList.pushback(linkState);

        // Flood Link-State-Advertisment:
        // Start oneshot timer:
        call LinkStateTimer.startOneShot(30000);

        call RoutingTableTimer.startOneShot(180000);

        return;
    }

    // On LSA recieved
    command void LinkState.LSHandler(pack *package) {
        /*
        * TODO: 
        *  [X] Check if packet is already recieved. If not store in tentative with +1 to cost (also with the +1 to cost and sequence num)
        */
        LSA *recievedLSA = package->payload;
        uint16_t TTL = package->TTL - 1;
        uint8_t destination;
        uint8_t source;
        uint8_t cost;
        uint16_t linkStateSize = recievedLSA->linkStateSize;
        uint16_t packageSeqNum = package->seq; // packageSeqNum
        uint16_t sequenceNumber;
        uint8_t i;
        LSATuple LSAT;
        LSATuple LSATList[linkStateSize];        
        
        call RecievedList.pushback(*package);

        if (package->protocol == PROTOCOL_LINKED_STATE && package->TTL > 0 && searchForPackage(*package)) {
            /*
            * 1) Get the package
            * 2) set a var equal to the payload
            * 3) Store the payload tuples in our tentative list
            */
            // Check if package is already recieved
            sequenceNumber = recievedLSA->sequence;
            
            for (i = 0; i < linkStateSize; i++) {
                destination = recievedLSA->linkStates[i].neighborAddress;
                cost = recievedLSA->linkStates[i].cost + 1;
                source = package->src;
                
                if (destination != TOS_NODE_ID) {
                    // Insert into TentativeList:
                    makeLS(&linkState, destination, cost, source);  

                    updateTentativeList(linkState);

                    // Prepare tuples for forwarding:
                    makeLSATuple(&LSAT, destination, cost);
                    LSATList[i] = LSAT;
                } else {
                    LSATList[i] = recievedLSA->linkStates[i];
                }
            }

            // updateConfirmedList(getLowestCost());
            // removeFromTentativeList(getLowestCost());
            
            sequenceNumber++;
            
            makeLSA(&linkStateAdvertisement, TOS_NODE_ID, sequenceNumber, LSATList, linkStateSize);
            
            makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, TTL, PROTOCOL_LINKED_STATE, packageSeqNum, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
            
            call LinkStateSender.send(sendPackage, AM_BROADCAST_ADDR);
            packageSeqNum++;
            // call Flooding.LSAHandle(&sendPackage);
        }

        return;
    }

    command void LinkState.printRoutingTable() {
        dbg(ROUTING_CHANNEL, "\n");
        dbg(ROUTING_CHANNEL, "------------------------Confirmed List of node %d Start------------------------\n", TOS_NODE_ID);
        printConfirmedList();
        dbg(ROUTING_CHANNEL, "------------------------Confirmed List of node %d End--------------------------\n\n", TOS_NODE_ID);
            
        printTentativeList();

        return;
    }

    /*
     * #######################################
     *              Events
     * #######################################
     */
    
    event void LinkStateTimer.fired() {
        uint8_t i;
        uint32_t *neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t neighborListSize = call NeighborDiscovery.size();
        LSATuple LSAT;
        LS tempLS;
        LSATuple LSATList[neighborListSize + 1];
        
        for (i = 0; i < neighborListSize; i++) {
            makeLSATuple(&LSAT, neighbors[i], 1);
            makeLS(&tempLS, LSAT.neighborAddress, LSAT.cost, LSAT.neighborAddress);
            updateTentativeList(tempLS);
            updateConfirmedList(tempLS);
            LSATList[i] = LSAT;
        }

        makeLSA(&linkStateAdvertisement, TOS_NODE_ID, 0, LSATList, neighborListSize);

        // payload stores the address of linkStateAdvertisement which is type LSA.
        // if we want to print the contents of LSA we first have to dreference payload wich gives us LSA and then print the contents of LSA
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKED_STATE, 0, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
        
        call Flooding.LSAHandle(&sendPackage);

        return;
    }

    event void RoutingTableTimer.fired() {
        uint16_t i;

        for (i = 0; i < call TentativeList.size(); i++) {
            updateConfirmedList(call TentativeList.get(i));
        }

        call TentativeList.empty();

        call LinkState.printRoutingTable();
        return;
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    void printTentativeList() {
        uint8_t i;
        LS temp;
        uint16_t size;
        
        if (!call TentativeList.isEmpty()) {
            size = call TentativeList.size();

            for (i = 0; i < size; i++) {
                temp = call TentativeList.get(i);
                
                if (temp.destination > 0) {
                    dbg(ROUTING_CHANNEL, "Tenative List State[%d] at src %d: [destination: %d, cost: %d, nextHop: %d], size: %d\n", i, TOS_NODE_ID, temp.destination, temp.cost, temp.nextHop, size);
                }
            }
        }

        return;
    }

    void printConfirmedList() {
        uint8_t i;
        LS temp;
        uint16_t size;
        
        if (!call ConfirmedList.isEmpty()) {
            size = call ConfirmedList.size();

            for (i = 0; i < size; i++) {
                temp = call ConfirmedList.get(i);
                dbg(ROUTING_CHANNEL, "Confirmed List State[%d]: [destination: %d, cost: %d, nextHop: %d], size: %d\n", i, temp.destination, temp.cost, temp.nextHop, size);
            }
        }

        return;
    }

    // Add new link state to the confirmed list
    void updateConfirmedList(LS incomingLinkState) {
        uint16_t size = call TentativeList.size();
        uint8_t i;
        LS currentLinkState;
        uint8_t shouldPush = 1;

        // check if the tentative list if empty
        if (incomingLinkState.destination < 30) {
            for (i = 0; i < size; i++) {
                // generate a temporary link state
                currentLinkState = call ConfirmedList.get(i);

                /*
                * if the link state's destination is equal to the link state we want to update, 
                * then update the cost and nextHop values 
                */
                if (currentLinkState.destination == incomingLinkState.destination) {
                    if (incomingLinkState.cost < currentLinkState.cost) {
                        currentLinkState.cost = incomingLinkState.cost;
                        currentLinkState.nextHop = incomingLinkState.nextHop;
                    }

                    shouldPush = 0;
                }
            }

            if (shouldPush == 1) {
                call ConfirmedList.pushback(incomingLinkState);
            }
        }

        return;
    }

    // update our tentative list of link states
    void updateTentativeList(LS incomingLinkState) {
        uint16_t size = call TentativeList.size();
        uint8_t i;
        LS currentLinkState;
        uint8_t shouldPush = 1;

        // check if the tentative list if empty
        if (call TentativeList.isEmpty()) {
            // push new link state to end of tentative list
            call TentativeList.pushback(incomingLinkState);
        } else if (incomingLinkState.destination < 30) {
            for (i = 0; i < size; i++) {
                // generate a temporary link state
                currentLinkState = call TentativeList.get(i);

                /*
                * if the link state's destination is equal to the link state we want to update, 
                * then update the cost and nextHop values 
                */
                if (currentLinkState.destination == incomingLinkState.destination) {
                    if (incomingLinkState.cost < currentLinkState.cost) {
                        currentLinkState.cost = incomingLinkState.cost;
                        currentLinkState.nextHop = incomingLinkState.nextHop;
                    }

                    shouldPush = 0;
                }
            }

            if (shouldPush == 1) {
                call TentativeList.pushback(incomingLinkState);
            }
        }

        return;
    }

    LS getLowestCost() {
        LS lowestCostTuple, temporaryLinkState;
        uint8_t i = 0;
        uint16_t size;

        if (!call TentativeList.isEmpty()) {
            size = call TentativeList.size();

            do {
                temporaryLinkState = call TentativeList.get(i);

                if (i == 0) {
                    lowestCostTuple = temporaryLinkState;
                } else if (lowestCostTuple.cost > temporaryLinkState.cost) {
                    lowestCostTuple = temporaryLinkState;
                }

                i++;
            } while (i < size);
        } else {
            lowestCostTuple = call ConfirmedList.get(call ConfirmedList.size() - 1);
        }

        return lowestCostTuple;
    }

    // remove a link state from the tentative list
    void removeFromTentativeList(LS linkstate) {
        uint8_t i;

        // check if the tentative list and temporary list are empty
        if (!call TentativeList.isEmpty()) {
            for (i = 0; i < call TentativeList.size(); i++) {
                LS temp = call TentativeList.get(i);

                // only remove the 
                if (temp.destination != linkstate.destination) {
                    call TemporaryList.pushback(temp);
                }

                call TentativeList.popfront();
            }
        }

        if (!call TemporaryList.isEmpty()) {
            for (i = 0; i < call TemporaryList.size(); i++) {
                call TentativeList.pushback(call TemporaryList.get(i));
                call TemporaryList.popfront();
            }
        }

        return;
    }

    bool searchForPackage(pack package) {
        uint16_t i = 0, RecievedListSize = call RecievedList.size();
        while (i < RecievedListSize) {
          pack temporaryPackage = call RecievedList.get(i);

          if (temporaryPackage.src == package.src && temporaryPackage.seq == package.seq && temporaryPackage.protocol == package.protocol) {
            return TRUE;
          }

          i++;
        }

        return FALSE;
    };

    void printLSA(LSA* LSAdvertisement) {
        uint8_t i;
        uint16_t size = LSAdvertisement->linkStateSize;
        LSATuple temp;

        for (i = 0; i < size; i++) {
            temp = LSAdvertisement->linkStates[i];
            dbg(ROUTING_CHANNEL, "LSA[%d]: [neighborAddress: %d, cost: %d], size %d\n", i, temp.neighborAddress, temp.cost, size);
        }

        return;
    }
    
    // Dijkstra's Implementation
    void findShortestPath() {
        
    }
}