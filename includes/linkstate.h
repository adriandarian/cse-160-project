
#ifndef LINKSTATE_H
#define LINKSTATE_H

enum{
	MAX_LINKSTATE = 25
};

typedef nx_struct LSA{
	nx_uint16_t destination;
	nx_uint16_t cost;
	nx_uint16_t nextHop;
}LSA;

void makeLSA(LSA *LS, uint16_t destination, uint16_t cost, uint16_t nextHop){
	LS->destination = destination;
	LS->cost = cost;
	LS->nextHop = nextHop;
}

#endif
