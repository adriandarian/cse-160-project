
#ifndef LINKSTATE_H
#define LINKSTATE_H

enum{
	MAX_LINKSTATE = 25
};

typedef nx_struct linkstate{
	nx_uint16_t neighbor;
	nx_uint8_t cost;
	nx_uint8_t src;
}linkstate;

#endif
