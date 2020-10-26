# Project 3 Mid Review Design Doc

- [ ] Make TCP struct
- [ ] 3-Way Handshake
- [ ] Stop and Wait
- [ ] Implement sockets...
- [ ] Test Server and test Client commands
- [ ] Test Server Handler
- [ ] Test Client Handler

## MAKE TCP STRUCT

***TCP PACKET***
**PROPERTIES**

- Source Port [UINT16_T]
- Destination Port [UINT16_T]
- Sequence Number [UINT32_T]
- Acknowledgment Number [UINT32_T]
- HdrLen [UINT16_T] [maybe not]
- Flags [tcpFlag]
- Advertised Window [UINT16_T]
- Checksum [UINT16_T]
- Data [UINT16_T*]

***TCP FLAG***

- DATA = 0
- ACK = 1
- SYN = 2
- SYNACK = 3
- FIN = 4
- FINACK = 5

## IMPLEMENT 3-WAY HANDSHAKE

***CLIENT*** Sends SYN
***SERVER*** Sends SYN_ACK
***CLIENT*** Sends ACK
*PseudoCode*

```python
  avaliablePorts # List of ports that are not currently used
  timeout # How long to wait till trying handshake step again
  currentConnections # Destinations we already have a TCP connection with
  bool connectionEstablished = False

  Client(destination, DestPort, data):
    bool isSynAckRecieved = False # we are assuming only one client and one server at the moment!!!!!

    if ((destination, DestPort) not in currentConnections):
      SrcPort = avaliableSocket.pop()
      # Begin 3-Way Handshake
      SequenceNum = Random(0, 1000)
      CheckSum = computeCheckSum(data)

      # ... something needs to go here

      # Establish SYN from Client to Server
      if (isSynAckReceived == False):
        tcpPacket = createTCPPacket(SrcPort, DestPort, SequenceNum, AckNum = 0, HeaderLength, SYN, AcknowledgementWindow = 1, CheckSum, payload)
        sendPacket(tcpPacket)
        startTimer(timeout)

      while (RecievedSynAck == False): # RecievedSynAck is the actual packet
        if (Timer.finish):
          sendPacket(tcpPacket)
          startTimer(timeout)

      # Establish the ACK from Client to Server
      tcpPacket = CreateTCPPacket(RecievedSynAck.SrcPort, RecievedSynAck.DestPort, RecievedSynAck.SequenceNum, RecievedSynAck.AckNum, RecievedSynAck.headerLength, ACK, RecievedSynAck.AcknowledgementWindow, RecievedSynAck.CheckSum, RecievedSynAck.payload)
      sendPacket(tcpPacket)

      print("Client: Connection Established")

  Server.onReceive():
    while (ReceivedAck == False):
      if (RecievedSyn):
        SequenceNum = Random(0, 1000)
        CheckSum = computeCheckSum(RecievedSyn.CheckSum)

        # Establish SYN-ACK from Server to Client
        tcpPacket = CreateTCPPacket(RecievedSyn.SrcPort, RecievedSyn.DestPort, RecievedSyn.SequenceNum, RecievedSyn.SeqNum + 1, RecievedSyn.headerLength, SYNACK, RecievedSyn.AcknowledgementWindow, CheckSum, RecievedSyn.payload)
        sendPacket(tcpPacket)
        startTimer(timeout)

      if (Timer.Finish):
        sendPacket(tcpPacket)
        startTimer(timeout)

    print("Server: Connection Established")
```
