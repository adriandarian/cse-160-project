/*
 * ~NEIGHBOR DISCOVERY MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h" // For making our own discoverNeighbor protocol

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;

    // Interfaces to be used:
    uses interface SimpleSend; // For sending messages to potential neighbors
    uses interface Hashmap<uint16_t>;   // For keeping track of neighbors
    uses interface List<pack> as listOfNeighbors;
}

implementation {
    
    command error_t NeighborDiscovery.start() {      // print debug indicating that import was successful for now
        pack package;
        uint8_t payload = 84;
        dbg(GENERAL_CHANNEL,"Sending Neighbor ping\n");
        makePack(&package, TOS_NODE_ID,0,1,PROTOCOL_PING,0,&payload,PACKET_MAX_PAYLOAD_SIZE);
        call SimpleSend.send(package, AM_BROADCAST_ADDR);
        
    }
    /** 
    This command wont work effectivly because we are making a new pack
    everytime we get ping. Re-write this to use the the same package as the reply
    this will also allow us to control the TTL of the nieghbor pings in circulation
    command void NeighborDiscovery.pingHandle(pack *package){
        //when ping from neighbor recived:
        if(package->protocol == PROTOCOL_PING && package->TTL > 0){
            pack reply;
            uint8_t payload = 82;
            makePack(&reply,TOS_NODE_ID,0,1,PROTOCOL_PINGREPLY,0,&payload,PACKET_MAX_PAYLOAD_SIZE);
            //send the reply:
            call SimpleSend.send(reply,AM_BROADCAST_ADDR);
            dbg(GENERAL_CHANNEL,"reply sent\n");
        }
        if(package->protocol == PROTOCOL_PINGREPLY){
            dbg(GENERAL_CHANNEL,"Neighbor discovered\n");
            //dbg(GENERAL_CHANNEL,"Neighbor %d discoverd\n",package->src);
            call Hashmap.insert(package->src,package->src);
        }
        else{
            dbg(GENERAL_CHANNEL,"REEEEEEE\n");
            
        }
    }
    **/
    command void NeighborDiscovery.pingHandle(pack * package){
        if(package->protocol == PROTOCOL_PING && package-> TTL >0){
            //Use the same package in the reply, so decrease the TTL by 1 and set the source to this TOS_NODE_ID
            //Also change the protocol to a ping reply so when the neighboring nodes recive it they dont forward it
            package->protocol == PROTOCOL_PINGREPLY;
            package->TTL--; //is this causing problems? Try explicitly redefinition:
            package->src = TOS_NODE_ID;
            //broadcast the modified package:
            call SimpleSend.send(*package,AM_BROADCAST_ADDR);
            dbg(GENERAL_CHANNEL,"Sent reply\n");
        }
        //Check if neighbors replied by checking protocol:
        else if(package->protocol = PROTOCOL_PINGREPLY){
            dbg(GENERAL_CHANNEL,"Neighbor discovred %d\n",package->src);
            call Hashmap.insert(package->src,package->src);
        }
    }
    command error_t NeighborDiscovery.print() {
        uint8_t i;
        uint8_t val;
        uint8_t tableSize = call Hashmap.size();
        uint32_t *keyPtr = call Hashmap.getKeys();
        for(i = 0; i < tableSize; i++){
            val = *keyPtr;
            dbg(GENERAL_CHANNEL, "My neighbors: %d ",val);

        }
        dbg(GENERAL_CHANNEL,"\n");
        
    }

    command error_t NeighborDiscovery.getNeighbors() {}
}