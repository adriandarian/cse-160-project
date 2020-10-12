/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}

implementation {
    components MainC;
    components Node;

    Node->MainC.Boot;

    /*
     * #######################################
     *              Modules
     * #######################################
     */

    components new AMReceiverC(AM_PACK) as GeneralReceive;
    Node.Receive->GeneralReceive;

    components ActiveMessageC;
    Node.AMControl->ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender->SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler->CommandHandlerC;

    // Flooding
    components FloodingC;
    Node.Flooding->FloodingC;

    // Neighbor Discovery
    components NeighborDiscoveryC;
    Node.NeighborDiscovery->NeighborDiscoveryC;

    // Link State
    components LinkStateC;
    Node.LinkState->LinkStateC;
}
