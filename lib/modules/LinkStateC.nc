/*
 * ~Link State Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
configuration LinkStateC{
    provides interface LinkState;
}

implementation{
    components LinkStateP;
    LinkState = LinkStateP;

    /*
     * #######################################
     *              Modules
     * #######################################
     */

    components new SimpleSendC(AM_PACK);
    LinkStateP.LinkStateSender->SimpleSendC;

    components FloodingC;
    LinkStateP.Flooding->FloodingC;

    components NeighborDiscoveryC;
    LinkStateP.NeighborDiscovery->NeighborDiscoveryC;

    components new TimerMilliC() as LinkStateTimerC;
    LinkStateP.LinkStateTimer->LinkStateTimerC;

    components new TimerMilliC() as RoutingTableTimerC;
    LinkStateP.RoutingTableTimer->RoutingTableTimerC;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new ListC(LSA, 64) as LinkTableC;
    LinkStateP.LinkTable->LinkTableC;

    components new ListC(LS, 64) as TemporaryListC;
    LinkStateP.TemporaryList->TemporaryListC;

    components new ListC(LS, 64) as TentativeListC;
    LinkStateP.TentativeList->TentativeListC;

    components new ListC(LS, 64) as ConfirmedListC;
    LinkStateP.ConfirmedList->ConfirmedListC;

    components new ListC(pack, 64) as RecievedList;
    LinkStateP.RecievedList->RecievedList;

    components new HashmapC(uint16_t, 100) as RoutingTableC;
    LinkStateP.RoutingTable->RoutingTableC;
}