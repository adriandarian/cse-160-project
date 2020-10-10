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

    components new SimpleSendC(AM_PACK);
    LinkStateP.LinkStateSender->SimpleSendC;

    components new ListC(linkstate, 64) as TentativeListC;
    LinkStateP.TentativeList->TentativeListC;

    components new ListC(linkstate, 64) as ConfirmedListC;
    LinkStateP.ConfirmedList->ConfirmedListC;
}