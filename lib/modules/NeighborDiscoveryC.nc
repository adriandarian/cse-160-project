/*
 * ~Neighbor Discovery Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
 
configuration NeighborDiscoveryC {
    provides interface NeighborDiscovery;
}

implementation{
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    /*
     * #######################################
     *              Modules
     * #######################################
     */

    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.SimpleSend->SimpleSendC;

    components RandomC as Random;
    NeighborDiscoveryP.Random->Random;

    components new TimerMilliC() as updateNeighborTable;
    NeighborDiscoveryP.updateNeighborTable->updateNeighborTable;
    
    components new TimerMilliC() as updateTimer;
    NeighborDiscoveryP.updateTimer->updateTimer;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new HashmapC(uint16_t, 100);
    NeighborDiscoveryP.Hashmap->HashmapC;
}