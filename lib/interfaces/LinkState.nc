/*
 * ~Link State Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface LinkState{
	command void start();
	command void printRoutingTable();
	command void LSHandler(pack *package);
	command bool checkIfInRoutingTable(uint16_t destination);
	command uint16_t getFromRoutingTable(uint16_t destination);
}