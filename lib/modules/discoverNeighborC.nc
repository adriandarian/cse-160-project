/*
~DISCOVER NEIGHBOR MODULE CONFIG~
Busher Bridi, Adrian Darian 
UC MERCED, Prof. Serpa CSE_160 2020
*/



configuration discoverNeighborC {
    provides interface discoverNeighbor;
}

implementation{
    components discoverNeighborP;
    discoverNeighbor = discoverNeighborP;
}