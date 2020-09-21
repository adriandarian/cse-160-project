/*
 * ~NEIGHBOR DISCOVERY MODULE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/channels.h" // For printing debug statements
#include "../../includes/packet.h"
#include "../../includes/protocol.h"

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;

    // Interfaces to be used:
    uses interface SimpleSend; // For sending messages to potential neighbors
    uses interface Hashmap<uint16_t>;   // For keeping track of neighbors
    //uses interface List<pack> as listOfNeighbors; NOT NEEDED
    uses interface Timer<TMilli> as updateNeighborTable;
    uses interface Timer<TMilli> as updateTimer;
    uses interface Random;
}

implementation {
    
    command error_t NeighborDiscovery.start() {      // print debug indicating that import was successful for now
        pack package;
        uint8_t payload = 84;
        dbg(NEIGHBOR_CHANNEL,"Sending Neighbor ping\n");
        makePack(&package, TOS_NODE_ID,0,1,PROTOCOL_NEIGHBORPING,0,&payload,PACKET_MAX_PAYLOAD_SIZE);
        call SimpleSend.send(package, AM_BROADCAST_ADDR);
       // call updateNeighborTable.startPeriodic(500); UNCOMMENT THIS FOR DYNMAIC NEIGHBOR TABLE
        
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
            dbg(NEIGHBOR_CHANNEL,"reply sent\n");
        }
        if(package->protocol == PROTOCOL_PINGREPLY){
            dbg(NEIGHBOR_CHANNEL,"Neighbor discovered\n");
            //dbg(NEIGHBOR_CHANNEL,"Neighbor %d discovered\n",package->src);
            call Hashmap.insert(package->src,package->src);
        }
        else{
            dbg(NEIGHBOR_CHANNEL,"ERROR\n");
            
        }
    }
    **/
    command void NeighborDiscovery.pingHandle(pack * package){
        if(package->protocol == PROTOCOL_NEIGHBORPING && package-> TTL >0){
            //Use the same package in the reply, so decrease the TTL by 1 and set the source to this TOS_NODE_ID
            //Also change the protocol to a ping reply so when the neighboring nodes recive it they dont forward it
            uint16_t dest = package->src;
            package->protocol == PROTOCOL_NEIGHBORPINGREPLY;
            package->TTL--; //is this causing problems? Try explicitly redefinition
            package->src = TOS_NODE_ID;
            //broadcast the modified package:
            call SimpleSend.send(*package, dest);
            dbg(NEIGHBOR_CHANNEL,"Sent reply\n");
        }
        //Check if neighbors replied by checking protocol:
        else if(package->protocol == PROTOCOL_NEIGHBORPINGREPLY) {
            dbg(NEIGHBOR_CHANNEL,"Neighbor discovred %d\n",package->src);
            call Hashmap.insert(package->src,1);
        }
    }

    command error_t NeighborDiscovery.print() {
        uint16_t i;
        uint16_t val;
        uint16_t tableSize = call Hashmap.size();
        uint32_t *keyPtr = call Hashmap.getKeys();
        for(i = 0; i < tableSize; i++) {
            //val = *keyPtr;
            dbg(NEIGHBOR_CHANNEL, "My neighbors: %d\n", keyPtr[i]); 

        }

        dbg(NEIGHBOR_CHANNEL,"\n");
        
    }
    
    //Need to implement timer so that neighbor table is updated
    event void updateNeighborTable.fired() {
        uint16_t i;
        uint16_t val;
        uint32_t *keyPtr = call Hashmap.getKeys();
        uint16_t tableSize = call Hashmap.size();
        pack package;
        uint16_t payload = 84;
        dbg(NEIGHBOR_CHANNEL,"Updating neighbor table\n");
        makePack(&package, TOS_NODE_ID,0,1,PROTOCOL_NEIGHBORPING,0,&payload,PACKET_MAX_PAYLOAD_SIZE);
        // wait some time:
        call updateTimer.startOneShot((call Random.rand16() % 500)+300);
        for(i=0; i < tableSize; i++){
            //val  = call NeighborMap.get(keysPtr[i]);
            call Hashmap.insert(keyPtr[i],call Hashmap.get(keyPtr[i])-1);
        }
        for(i=0;i < tableSize; i++){
           if(keyPtr[i] < 0){
               call Hashmap.remove(keyPtr[i]);
                dbg(NEIGHBOR_CHANNEL,"Removed %d from neighbor table\n",keyPtr[i]);
           }
           
        }
        call SimpleSend.send(package, AM_BROADCAST_ADDR);
    }
    event void updateTimer.fired(){

    }

    command uint32_t* NeighborDiscovery.getNeighbors() {
      return call Hashmap.getKeys();
    }
}