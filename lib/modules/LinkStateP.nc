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
    uses interface List<LSA> as LinkTable;
    uses interface List<pack> as RecievedList;
    uses interface List<LS> as TemporaryList;
    uses interface List<LS> as TentativeList;
    uses interface List<LS> as ConfirmedList;
    uses interface Hashmap<uint16_t> as RoutingTable;
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
        call LinkStateTimer.startPeriodic(30000);

        call RoutingTableTimer.startOneShot(180000);

        return;
    }

    // On LSA recieved
    command void LinkState.LSHandler(pack *package) {
        uint16_t i;
        LSA *incomingLSA = (uint8_t *)package->payload;
        bool notInLinkTable = TRUE;
        LSA temporaryLSA;
        

        // Check for duplicates and ignore them
        for (i = 0; i < call LinkTable.size(); i++) {
            temporaryLSA = call LinkTable.get(i);

            if (temporaryLSA.source == package->src) {
                notInLinkTable = FALSE;
                break;
            }
        }

        if (notInLinkTable) {
            makeLSA(&linkStateAdvertisement, package->src, incomingLSA->linkStateSize, incomingLSA->linkStates);
            call LinkTable.pushback(linkStateAdvertisement);
        }

        return;
    }

    command void LinkState.printRoutingTable() {
        // dbg(ROUTING_CHANNEL, "\n");
        // dbg(ROUTING_CHANNEL, "------------------------Confirmed List of node %d Start------------------------\n", TOS_NODE_ID);
        // printConfirmedList();
        // dbg(ROUTING_CHANNEL, "------------------------Confirmed List of node %d End--------------------------\n\n", TOS_NODE_ID);
            
        // printTentativeList();

        int i = 0;

        for (i = 1; i <= call RoutingTable.size(); i++) {
            dbg(GENERAL_CHANNEL, "Dest: %d \t firstHop: %d\n", i, call RoutingTable.get(i));
        }

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
        LSATuple LSATList[neighborListSize];
        
        for (i = 0; i < neighborListSize; i++) {
            makeLSATuple(&LSAT, neighbors[i], 1);
            LSATList[i] = LSAT;
        }

        // Initialize Link Table
        makeLSA(&linkStateAdvertisement, TOS_NODE_ID, neighborListSize, LSATList);
        call LinkTable.pushback(linkStateAdvertisement);

        // payload stores the address of linkStateAdvertisement which is type LSA.
        // if we want to print the contents of LSA we first have to dreference payload wich gives us LSA and then print the contents of LSA
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKED_STATE, 0, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
        
        call LinkStateSender.send(sendPackage, AM_BROADCAST_ADDR);

        return;
    }

    event void RoutingTableTimer.fired() {
        uint16_t i, j;
        LSA currentLSA;

        dbg(ROUTING_CHANNEL, "Src: %d with size %d [\n", TOS_NODE_ID, call LinkTable.size());
        for (i = 0; i < call LinkTable.size(); i++) {
            currentLSA = call LinkTable.get(i);

            for (j = 0; j < currentLSA.linkStateSize; j++) {
                if (currentLSA.linkStates[j].neighborAddress != 0) {
                    dbg(ROUTING_CHANNEL, "S: %d (N: %d, C: %d)\n", currentLSA.source, currentLSA.linkStates[j].neighborAddress, currentLSA.linkStates[j].cost);
                }
            }
        }
        dbg(ROUTING_CHANNEL, "]\n");

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
        uint16_t size = call ConfirmedList.size();
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
    // Source Reference - https://www.thecrazyprogrammer.com/2014/03/dijkstra-algorithm-for-finding-shortest-path-of-a-graph.html
    void findShortestPath() {
        uint16_t nodesize[20];
        uint16_t size = call LinkTable.size();
        uint16_t maximumNode = 20;
        uint16_t i;
        uint16_t j;
        uint16_t nextHop;
        uint16_t costMatrix[maximumNode][maximumNode];
        uint16_t distanceList[maximumNode];
        uint16_t predicateList[maximumNode];
        uint16_t visitedList[maximumNode];
        uint16_t nodeCount;
        uint16_t minimumDistance;
        uint16_t nextNode;
        uint16_t startNode = TOS_NODE_ID;
        bool adjacencyMatrix[maximumNode][maximumNode];
        LS linkstate;

        for (i = 0; i < maximumNode; i++) {
            for (j = 0; j < maximumNode; j++) {
                adjacencyMatrix[i][j] = FALSE;
            }
        }

        for (i = 0; i < size; i++) {
            linkstate = call LinkTable.get(i);
            adjacencyMatrix[linkstate.nextHop][linkstate.destination] = TRUE;
        }

        // predicateList[] stores the predecessor of each node
        // count gives the number of nodes seen so far
        // create the cost matrix
        for (i = 0; i < size; i++) {
            for (j = 0; j < maximumNode; j++) {
                if (adjacencyMatrix[i][j] == 0) {
                    costMatrix[i][j] = 9999;
                } else {
                    costMatrix[i][j] = adjacencyMatrix[i][j];
                }
            }
        }

        // initialize predicateList[], distanceList[] and visitedlist[]
        for (i = 0; i < maximumNode; i++) {
            distanceList[i] = costMatrix[startNode][i];
            predicateList[i] = startNode;
            visitedList[i] = 0;
        }

        distanceList[startNode] = 0;
        visitedList[startNode] = 1;
        nodeCount = 1;

        while (nodeCount < maximumNode - 1) {
            minimumDistance = 9999;

            for (i = 0; i < maximumNode; i++) {
                // nextNode gives the node at minimum distance
                if (distanceList[i] <= minimumDistance && !visitedList[i]) {
                    minimumDistance = distanceList[i];
                    nextNode = i;
                }
            }

            visitedList[nextNode] = i;

            for (i = 0; i < maximumNode; i++) {
                if (!visitedList[i]) {
                    if (minimumDistance + costMatrix[nextNode][i] < distanceList[i]) {
                        distanceList[i] = minimumDistance + costMatrix[nextNode][i];
                        predicateList[i] = nextNode;
                    }
                }
            }

            nodeCount++;
        }

        for (i = 0; i < maximumNode; i++) {
            nextHop = TOS_NODE_ID;

            if (distanceList[i] != 9999) {
                if (i != startNode) {
                    j = 1;

                    do {
                        if (j != startNode) {
                            nextHop = j;
                        }

                        j = predicateList[j];
                    } while (j != startNode);
                } else {
                    nextHop = startNode;
                }

                if (nextHop != 0) {
                    call RoutingTable.insert(i, nextHop);
                }
            }
        }
    }
}