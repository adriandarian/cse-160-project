/*
 * ~Flooding Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
 
configuration FloodingC {
    provides interface Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP;

    /*
     * #######################################
     *              Modules
     * #######################################
     */

    components new SimpleSendC(AM_PACK);
    FloodingP.Sender->SimpleSendC;

    components LinkStateC;
    FloodingP.LinkState->LinkStateC;

    components NeighborDiscoveryC;
    FloodingP.NeighborDiscovery->NeighborDiscoveryC;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */    
    
    components new ListC(pack, 64) as FloodingListC;
    FloodingP.FloodingList->FloodingListC;

    components new ListC(LS, 64) as LinkStateProtocolListC;
    FloodingP.LinkStateProtocolList->LinkStateProtocolListC;

    components new HashmapC(uint16_t, 30) as RoutingTableC;
    FloodingP.RoutingTable->RoutingTableC;
}