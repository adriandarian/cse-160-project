/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive as Receiver;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface NeighborDiscovery;
   uses interface Flooding;
   uses interface List<uint16_t> as NeighborList;
   uses interface Hashmap<uint16_t> as RoutingTable;
}

implementation{
   pack sendPackage;
   uint16_t ttl = MAX_TTL, dest = AM_BROADCAST_ADDR;

   event void Boot.booted() {
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         dbg(GENERAL_CHANNEL, "Radio On\n");
         call NeighborDiscovery.start();
      } else {
         // Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err) {
      // DEBUG: any error messages
      dbg(GENERAL_CHANNEL, "An Error occurred: %d\n", err);
   }

   event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len) {
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      
      if (len == sizeof(pack)) {
         pack* message = (pack*) payload;
         // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", message->payload);

         // Output the full package being passed through
         // logPack(message);

         if (message->protocol == PROTOCOL_PING) {
            call Flooding.pingHandle(message);
            call Flooding.printFloodList();
         }

         return msg;
      }

      dbg(GENERAL_CHANNEL, "Unknown Packet Type %u\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {
      dbg(GENERAL_CHANNEL, "PING SENT TO %u\n", destination);

      makePack(&sendPackage, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(uint16_t destination) {
      if (call RoutingTable.contains(destination)) {
         dbg(NEIGHBOR_CHANNEL, "neighbors: %d\n", destination);
      } else {
         dbg(NEIGHBOR_CHANNEL, "unknown destination location at: %d\n", destination);
      }
   }

   event void CommandHandler.printRouteTable() {}

   event void CommandHandler.printLinkState() {}

   event void CommandHandler.printDistanceVector() {}

   event void CommandHandler.setTestServer() {}

   event void CommandHandler.setTestClient() {}

   event void CommandHandler.setAppServer() {}

   event void CommandHandler.setAppClient() {}
}
