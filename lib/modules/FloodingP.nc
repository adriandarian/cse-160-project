/*
 * ~Flooding MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module FloodingP {
    provides interface Flooding;

    // Interfaces to be used:
    uses interface SimpleSend; // For sending messages to potential neighbors
    uses interface Random;
    //uses interface Timer<TMilli> as discoveryWait;
    //uses interface Timer<TMilli> as updateNeighborTable;
    //uses interface NeighborDiscovery as neighborTable;
    uses interface Hashmap<uint16_t> as messageCache;
}

implementation {
    uint16_t sequenceNumber = 0; // sequence counter
    uint16_t TTL = 100; //Assuming that there will be no more than 100 hops needed to reach dest
    command error_t Flooding.start() { 
       // uint16_t tableSize = call neighborTable.size();
        //call discoveryWait((call Random.rand16() %500)+300); //Ideally this gives ample time for the neighbor discovery protocol to finish its initial run of the network
        //dbg(GENERAL_CHANNEL, "Table size: %d\n",tablesize);
        dbg(GENERAL_CHANNEL, "FLOODING\n");
    }
    /* Shittiest code I ever wrote top contender
    command void Flooding.forwardHandle(pack *package){
        uint16_t i;
        uint16_t val;
        uint16_t cacheSize = call messageCache.size();
        uint32_t *keyPtr = call messageCache.getKeys(); 
        uint16_t isInCache = 0;
        if(package->protocol == PROTOCOL_PING && package->TTL>0){
            dbg(GENERAL_CHANNEL, "BOYS WE GOT A MESSAGE!\n");
            //check for the following conditions: message in cache, or src is the TOS_NODE_ID
             if(package->src == TOS_NODE_ID){
                dbg(FLOODING_CHANNEL, "MESSAGE ALREADY FORWORDED, DROPPING\n");
                dbg(GENERAL_CHANNEL, "MESSAGE ALREADY FORWORDED, DROPPING\n");
            }
            //Check if package is for TOS_NODE_ID:
            else if(package->dest == TOS_NODE_ID){
                dbg(FLOODING_CHANNEL, "PACKAGE RECIEVED\n");
                dbg(GENERAL_CHANNEL, "PACKAGE RECIEVED\n");
            }
            else if(call messageCache.contains(package->src)){
                for(i = 0; i < cacheSize; i++){
                    if(keyPtr[i] == package->seq){
                        //Drop packet, already seen (DO NOTHING):
                        dbg(FLOODING_CHANNEL, "MESSAGE IN CACHE, DROPPING");
                        isInCache = 1;
                        break;
                    }
                }
                if(isInCache == 0){
                dbg(FLOODING_CHANNEL, "FORWARDING PACKAGE\n");
                package->TTL--;
                //send the message:
                call SimpleSend.send(*package, AM_BROADCAST_ADDR);
                //inset message into the cache:
                call messageCache.insert(package->src, package->seq);
                }
            }
            //After those checks, we conclude that the message should be forwarded:
            //First, decrement the TTL by 1, indicating that the message has "hopped"
            else{
                dbg(FLOODING_CHANNEL, "FORWARDING PACKAGE\n");
                package->TTL--;
                //send the message:
                call SimpleSend.send(*package, AM_BROADCAST_ADDR);
                //inset message into the cache:
                call messageCache.insert(package->src, package->seq);
            }
            
        }
    }
    */

    command void Flooding.forwardHandle(pack *package){
        uint16_t i;
        uint16_t val;
        uint16_t cacheSize = call messageCache.size();
        uint32_t *keyPtr = call messageCache.getKeys(); 
        if(package->protocol == PROTOCOL_PING){
            dbg(GENERAL_CHANNEL, "plz\n");
            //Check if message is already in cache:
            if(call messageCache.contains(package->src)){
                for(i = 0; i < cacheSize; i++){
                    if(keyPtr[i] == package->seq){
                        //Drop packet, already seen (DO NOTHING):
                        dbg(FLOODING_CHANNEL, "MESSAGE IN CACHE, DROPPING");
                        dbg(GENERAL_CHANNEL, "MESSAGE IN CACHE, DROPPING");
                        return;
                    }
                }
            }
            //Check if message is expired:
            else if(package->TTL <= 0){
                //Drop package:
                dbg(FLOODING_CHANNEL, "MESSAGE EXPIRED (TTL:%d)\n",package->TTL);
                dbg(GENERAL_CHANNEL, "MESSAGE EXPIRED (TTL:%d)\n",package->TTL);
            }
            //Check if message is for this node:
            else if(package->dest == TOS_NODE_ID){
                dbg(FLOODING_CHANNEL, "MESSAGE RECIEVED\n");
                dbg(GENERAL_CHANNEL, "MESSAGE RECIEVED\n");
            }
            //Finally, the message is forwarded:
            else{
                //First decrement the TTL:
                package->TTL--;
                //Send the message:
                call SimpleSend.send(*package, AM_BROADCAST_ADDR);
                //Update the cache:
                call messageCache.insert(package->src, package->seq);
                dbg(FLOODING_CHANNEL, "FORWARDING MESSAGE\n");
                dbg(GENERAL_CHANNEL, "FORWARDING MESSAGE\n");
            }
        }
    }
    
    //We need to "hijack" the ping so we can tell the forward handler to operate on it:
    //Same arguments as the ping in command handler 
    command void Flooding.pingHandle(uint16_t destination, uint8_t *payload){
        pack pingPack;
        //make package with the inteded destination and with our sequence "id" to represent a unique message:
        //Choosing 
        makePack(&pingPack, TOS_NODE_ID, destination, TTL, PROTOCOL_PING, sequenceNumber, payload, PACKET_MAX_PAYLOAD_SIZE);
        //send it:
        call SimpleSend.send(pingPack, AM_BROADCAST_ADDR);
        //increment sequenceNumber so that next package is "unique" and wont get caught in the cache:
        sequenceNumber++;
    }

}