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
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface discoverNeighbor;
}

implementation{
   pack sendPackage;

   // Prototypes
   //Moved this to packet.h so it can be called for other modules
   //void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted() {
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         dbg(GENERAL_CHANNEL, "Radio On\n");
         call discoverNeighbor.start();
      } else {
         // Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err) {
      dbg(GENERAL_CHANNEL, "An Error occurred: %s\n", err);
   }

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
      dbg(GENERAL_CHANNEL, "Packet Received\n");

      // Check the package size before execution
      dbg(GENERAL_CHANNEL, "len: %d, pack: %d\n", len, sizeof(pack));

      // Log the msg
      dbg(GENERAL_CHANNEL, "Package Message: %s\n", msg);
      
      if (len == sizeof(pack)) {
         pack* myMsg = (pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);

         // Output the full package being passed through
         logPack(myMsg);

         return msg;
      }

      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {
      dbg(GENERAL_CHANNEL, "PING SENT TO %d\n", destination);
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}


}
