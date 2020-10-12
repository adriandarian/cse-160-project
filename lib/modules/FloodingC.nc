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

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */    
    
    components new ListC(pack, 64) as FloodingListC;
    FloodingP.FloodingList->FloodingListC;
}