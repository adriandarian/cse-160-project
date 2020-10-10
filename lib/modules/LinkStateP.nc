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

    uses interface List<LSA> as TemporaryList;
    uses interface List<LSA> as TentativeList;
    uses interface List<LSA> as ConfirmedList;
}

implementation{
    LSA LS;

    command void LinkState.start() {
        makeLSA(&LS, TOS_NODE_ID, 0, TOS_NODE_ID);
        call ConfirmedList.pushback(LS);
    }

    void updateConfirmedList(LSA linkstate) {
        call ConfirmedList.pushback(linkstate);
    }

    void updateTentativeList(LSA *linkstate) {
        uint8_t i = 0;

        if (!call TentativeList.isEmpty()) {
            for (i; i < call TentativeList.size(); i++) {
                LSA temp = call TentativeList.get(i);
                
                if (temp.destination == linkstate->destination) {
                    if (linkstate->cost < temp.cost) {
                        temp.cost = linkstate->cost;
                        temp.nextHop = linkstate->nextHop;
                    }
                }
            }
        }
    }

    void removeFromTentativeList(LSA *linkstate) {
        uint8_t i = 0;

        if (!call TentativeList.isEmpty() && !call TemporaryList.isEmpty()) {
            for (i; i < call TentativeList.size(); i++) {
                LSA temp = call TentativeList.get(i);

                if (temp.destination != linkstate->destination) {
                    call TemporaryList.pushback(temp);
                }
            }
        }

        call TentativeList.popfront();

        if (!call TentativeList.isEmpty() && !call TemporaryList.isEmpty()) {
            for (i; i < call TemporaryList.size(); i++) {
                call TentativeList.pushback(call TemporaryList.get(i));
            }
        } else {
            dbg(ROUTING_CHANNEL, "Failed to remove linkstate with destination %d from TentativeList\n");
        }
    }

    command void LinkState.LSAHandle(pack *package) {
        uint8_t dest;
        uint8_t src;
        uint8_t cost;

        if (package->protocol == PROTOCOL_LINKED_STATE && package->TTL > 0) {
            dest = package->payload;
            src = package->src;
            cost = package->seq + 1;
            makeLSA(&LS, dest, cost, src);
            updateTentativeList(&LS);
        }
    }

    command void LinkState.printRoutingTable() {
        uint8_t i = 0;

        for (i; i < call ConfirmedList.size(); i++) {
            dbg(ROUTING_CHANNEL, "%d\n", call ConfirmedList.get(i));
        }
    }

    void findShortestPath() {
        
    }
}