/*
 * ~Neighbor Discovery Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface NeighborDiscovery{
    command error_t start();
    command error_t print();
    command uint32_t* getNeighbors();
    command uint16_t size();
    command void pingHandle(pack* package);
}
