/*
 * ~Link State Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/linkstate.h"

module LinkStateP{
    provides interface LinkState;

    uses interface SimpleSend as LinkStateSender;
    uses interface List<linkstate> as TentativeList;
    uses interface List<linkstate> as ConfirmedList;
}

implementation{
    command void LinkState.start() {

    }

    command void LinkState.printRoutingTable() {

    }
}