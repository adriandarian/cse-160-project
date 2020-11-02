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
    uses interface Timer<TMilli> as UpdateTimer;
    uses interface Timer<TMilli> as RoutingTableTimer;
    uses interface SimpleSend as LinkStateSender;
    uses interface Flooding;
    uses interface NeighborDiscovery;
    uses interface Random;

    // Data Structures
    uses interface List<LSA> as LinkTable;
    uses interface List<pack> as RecievedList;
    uses interface List<uint32_t> as NeighborList;
    uses interface Hashmap<uint16_t> as DistanceList;
    uses interface Hashmap<uint16_t> as RoutingTable;
}

implementation{
    LS linkState;
    LSA linkStateAdvertisement;
    pack sendPackage;
    uint8_t payload;
    uint16_t sequenceNum = 0;
    bool neighborsHaveChanged = FALSE;

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
    
    bool searchForPackage(pack package);
    void printLSA(LSA* LSAdvertisement);
    void findShortestPath();
    void printLinkTable();
    void printNeighbors(uint32_t* neighbors, uint16_t size);

    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command void LinkState.start() {
        // Flood Link-State-Advertisment:
        // Start oneshot timer:
        call LinkStateTimer.startOneShot(20000 + (uint16_t)((call Random.rand16()) % 10 * 10000));

        return;
    }

    // On LSA recieved
    command void LinkState.LSHandler(pack *package) {
        uint16_t i;
        LSA *incomingLSA = (uint8_t *)package->payload;
        uint16_t notInLinkTable = 1;
        LSA temporaryLSA;
        

        // Check for duplicates and ignore them
        for (i = 0; i < call LinkTable.size(); i++) {
            temporaryLSA = call LinkTable.get(i);

            if (temporaryLSA.source == package->src) {
                notInLinkTable = 0;
                break;
            }
        }

        if (notInLinkTable) {
            makeLSA(&linkStateAdvertisement, package->src, incomingLSA->linkStateSize, incomingLSA->linkStates);
            call LinkTable.pushback(linkStateAdvertisement);
            
        }

        return;
    }

    command bool LinkState.checkIfInRoutingTable(uint16_t destination) {
        return call RoutingTable.contains(destination);
    }

    command uint16_t LinkState.getFromRoutingTable(uint16_t destination) {
        return call RoutingTable.get(destination);
    }

    command void LinkState.printRoutingTable() {
        uint16_t i, j;
        // uint32_t *keyPtr = call RoutingTable.getKeys();
        // if(call RoutingTable.isEmpty() == FALSE){
        //     for(i = 0; i < call RoutingTable.size(); i++){
        //         call RoutingTable.remove(i);
        //     }
        // }
        dbg(ROUTING_CHANNEL, "Source Node: %d\n", TOS_NODE_ID);
        printf("{\ndestination: nextHop,  cost\n");
        for (i = 0; i < call RoutingTable.size()+1 ; i++) {
                // printf("Path = %d", i);
                
                // j = i;
                // do {
                //     j = call RoutingTable.get(j);
                //     printf("<-%d", j);
                // } while (j != destination);
                // printf("\n");
                if (i != 0) {
                    printf("\t%d: \t%d, \t%d\n", i, call RoutingTable.get(i), call DistanceList.get(i));
                }
        }
        printf("}\n");

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
            call NeighborList.pushback(neighbors[i]);
        }

        // printNeighbors(neighbors, neighborListSize);
        
        for (i = 0; i < neighborListSize; i++) {
            makeLSATuple(&LSAT, neighbors[i], 1);
            LSATList[i] = LSAT;
        }

        // Initialize Link Table
        makeLSA(&linkStateAdvertisement, TOS_NODE_ID, neighborListSize, LSATList);
        call LinkTable.pushback(linkStateAdvertisement);

        // payload stores the address of linkStateAdvertisement which is type LSA.
        // if we want to print the contents of LSA we first have to dreference payload wich gives us LSA and then print the contents of LSA
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKED_STATE, sequenceNum++, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
        
        call LinkStateSender.send(sendPackage, AM_BROADCAST_ADDR);
        call UpdateTimer.startPeriodic(100000);
        

        return;
    }

    event void UpdateTimer.fired() {
        uint8_t i;
        uint32_t *neighbors = call NeighborDiscovery.getNeighbors();
        uint16_t neighborListSize = call NeighborDiscovery.size();
        LSATuple LSAT;
        LSATuple LSATList[neighborListSize];
        // printNeighbors(neighbors, neighborListSize);
        for (i = 0; i < neighborListSize; i++) {
            // printf("%d UPDATE NEGHBORS: %d\n", TOS_NODE_ID,neighbors[i]);
            makeLSATuple(&LSAT, neighbors[i], 1);
            LSATList[i] = LSAT;
        }

        // payload stores the address of linkStateAdvertisement which is type LSA.
        // if we want to print the contents of LSA we first have to dreference payload wich gives us LSA and then print the contents of LSA
        makeLSA(&linkStateAdvertisement, TOS_NODE_ID, neighborListSize, LSATList);
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKED_STATE, sequenceNum++, &linkStateAdvertisement, PACKET_MAX_PAYLOAD_SIZE);
        // printLSA(&linkStateAdvertisement);
        call LinkStateSender.send(sendPackage, AM_BROADCAST_ADDR);
        call RoutingTableTimer.startOneShot(500);
        return;
    }

    event void RoutingTableTimer.fired() {
        uint16_t i;
        uint32_t *keyPtr = call RoutingTable.getKeys();
        
        // printLinkTable();
        if(call RoutingTable.isEmpty() == FALSE){
            for(i = 0; i < call RoutingTable.size(); i++){
                
                call RoutingTable.remove(i);
            }
        }
        findShortestPath();
        // call LinkState.printRoutingTable();
        call LinkTable.empty();

        return;
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    void printNeighbors(uint32_t* neighbors, uint16_t size) {
        uint16_t i;

        printf("Neighbors of %d are [", TOS_NODE_ID);
        for (i = 0; i < size; i++) {
            printf("%d", neighbors[i]);
            if (i != size - 1) printf(", ");
        }
        printf("]\n");

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

    void printLinkTable() {
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
    
    // Dijkstra's Implementation
    // Source Reference - https://www.thecrazyprogrammer.com/2014/03/dijkstra-algorithm-for-finding-shortest-path-of-a-graph.html
    void findShortestPath() {
        uint16_t size = call LinkTable.size();
        uint16_t maximumNode = call LinkTable.size() + 2;
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
        uint16_t adjacencyMatrix[maximumNode][maximumNode];
        LSA linkstate;

        for (i = 0; i < maximumNode; i++) {
            for (j = 0; j < maximumNode; j++) {
                adjacencyMatrix[i][j] = 0;
            }
        }

        for (i = 0; i < size; i++) {
            linkstate = call LinkTable.get(i); // linktable stores LSA trying to insert into LS linkstate
            for (j = 0; j < linkstate.linkStateSize; j++) {
                
                adjacencyMatrix[linkstate.source][linkstate.linkStates[j].neighborAddress] = linkstate.linkStates[j].cost;
            }
        }
        
        // dbg(ROUTING_CHANNEL, "Generated Adjacency Matrix\n");
        // printf("   [");
        // for (i = 0; i < maximumNode; i++) {
        //     printf("%d", i);

        //     if (i != maximumNode - 1) {
        //         printf(", ");
        //     }
        // }
        // printf("]\n");

        // for (i = 0; i < maximumNode; i++) {
        //     if (i >= 10) {
        //         printf("%d [", i);
        //     } else {
        //         printf("%d  [", i);
        //     }
        //     for (j = 0; j < maximumNode; j++) {
        //         if (adjacencyMatrix[i][j] != 1) {
        //             printf(" ");
        //         } else {
        //             printf("%d", adjacencyMatrix[i][j]);
        //         }
                
        //         if (j != maximumNode - 1) {
        //             printf(", ");
        //         }
        //     }
        //     printf("]\n");
        // }

        // predicateList[] stores the predecessor of each node
        // count gives the number of nodes seen so far
        // create the cost matrix
        for (i = 0; i < maximumNode; i++) {
            for (j = 0; j < maximumNode; j++) {
                if (adjacencyMatrix[i][j] == 0) {
                    costMatrix[i][j] = 11111;
                } else {
                    costMatrix[i][j] = adjacencyMatrix[i][j];
                }
            }
        }

        // dbg(ROUTING_CHANNEL, "Initial Cost Matrix\n");
        // for (i = 0; i < maximumNode; i++) {
        //     printf("[");
        //     for (j = 0; j < maximumNode; j++) {
        //         if (costMatrix[i][j] != 11111) {
        //             printf("  %d  ", costMatrix[i][j]);
        //         } else {
        //             printf("%d", costMatrix[i][j]);
        //         }

        //         if (j != maximumNode - 1) {
        //             printf(", ");
        //         }
        //     }
        //     printf("]\n");
        // }

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
            minimumDistance = 11111;

            for (i = 0; i < maximumNode; i++) {
                // nextNode gives the node at minimum distance
                if (distanceList[i] < minimumDistance && !visitedList[i]) {
                    minimumDistance = distanceList[i];
                    nextNode = i;
                }
            }

            visitedList[nextNode] = 1;

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

        // TODO Fix the below
        // dbg(ROUTING_CHANNEL, "Source Node: %d\n", TOS_NODE_ID);
        for (i = 0; i < maximumNode; i++) {
            nextHop = TOS_NODE_ID;
            if (distanceList[i] != 11111) {
                // printf("Distance to node %d has cost of %d\n", i, distanceList[i]);
                // printf("Path = %d", i);
                if (i != startNode) {
                    j = i;
                    do {
                        if (j != startNode) {
                            nextHop = j;
                        }

                        j = predicateList[j];
                        // printf("<-%d", j);
                    } while (j != startNode);
                    // printf("\n");
                } else {
                    nextHop = startNode;
                    // j = i;
                    // do {
                    //     j = predicateList[j];
                    //     printf("<-%d", j);
                    // } while (j != startNode);
                    // printf("\n");
                }

                // if (nextHop != 0) {
                    call RoutingTable.insert(i, nextHop);
                    call DistanceList.insert(i, distanceList[i]);
                // }
            }
        }
        
        return;
    }
}