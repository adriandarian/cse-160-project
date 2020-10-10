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

    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.SimpleSend->SimpleSendC;

    components new HashmapC(uint16_t,100); //assuming less than 100 neighbors
    NeighborDiscoveryP.Hashmap->HashmapC;

    components new TimerMilliC() as updateNeighborTable;
    NeighborDiscoveryP.updateNeighborTable->updateNeighborTable;

    components RandomC as Random;
    NeighborDiscoveryP.Random->Random;

    components new TimerMilliC() as updateTimer;
    NeighborDiscoveryP.updateTimer->updateTimer;
}