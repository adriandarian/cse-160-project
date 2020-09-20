/*
 * ~Flooding CONFIG~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
 
configuration FloodingC {
    provides interface Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP;

    components new SimpleSendC(AM_PACK);
    FloodingP.SimpleSend->SimpleSendC;

    components new HashmapC(uint16_t,100); //assuming less than 1000 messages in circulation at once
    FloodingP.messageCache->HashmapC;

    //components new TimerMilliC() as updateNeighborTable;
    //FloodingP.updateNeighborTable->updateNeighborTable;

    components RandomC as Random;
    FloodingP.Random->Random;

    //components NeighborDiscoveryC;
    //FloodingP.NeighborDiscovery->NeighborDiscoveryC;

}