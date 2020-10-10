/*
 * ~Link State Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
interface LinkState{
	command void start();
	command void printRoutingTable();
	command void LSAHandle(pack *package);
}