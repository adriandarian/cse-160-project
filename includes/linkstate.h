#ifndef LINKSTATE_H
#define LINKSTATE_H

enum{
	MAX_LINK_STATE = 20
};

typedef nx_struct LS{
	nx_uint16_t destination;
	nx_uint16_t cost;
	nx_uint16_t nextHop;
}LS;

typedef nx_struct LSATuple{
	nx_uint16_t neighborAddress;
	nx_uint16_t cost;
}LSATuple;

typedef nx_struct LSA{
	nx_uint16_t source;
	nx_uint16_t sequence;
	LSATuple linkStates[MAX_LINK_STATE];
}LSA;

void makeLS(LS *linkState, uint16_t destination, uint16_t cost, uint16_t nextHop) {
	linkState->destination = destination;
	linkState->cost = cost;
	linkState->nextHop = nextHop;
}

void makeLSATuple(LSATuple *linkStateAdvertisementTuple, uint16_t neighborAddress, uint16_t cost) {
	// dbg(ROUTING_CHANNEL, "Neighbor Address: %d, cost: %d\n", neighborAddress, cost);
	linkStateAdvertisementTuple->neighborAddress = neighborAddress;
	linkStateAdvertisementTuple->cost = cost;
}

void makeLSA(LSA *linkStateAdvertisement, uint16_t source, uint16_t sequence, LSATuple* linkStates) {
	dbg(ROUTING_CHANNEL, "source: %d, sequence: %d, link states: %d\n", source, sequence, linkStates[0].neighborAddress);
	linkStateAdvertisement->source = source;
	linkStateAdvertisement->sequence = sequence;
	// memcpy(linkStateAdvertisement->linkStates, &linkStates, MAX_LINK_STATE); //retake 31 my guy lmao
	memcpy(linkStateAdvertisement->linkStates, linkStates, MAX_LINK_STATE);
}

#endif
