# Project 3 Mid Review Design Doc

- [ ] Make TCP struct
- [ ] 3-Way Handshake
- [ ] Stop and Wait
- [ ] Closing Connection
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
- payload [UINT16_T*]

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

### 3-WAY HANDSHAKE PseudoCode

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

## IMPLEMENT STOP-AND-WAIT

***SENDER*** Sends Packet, starts Timer

***RECIVER*** If Packet is recieved, send ACK

***SENDER*** If ACK is recieved stop timer and send next Packet start new timer OR if Timer times out resend Packet

***RECIVER*** If duplicate packet is recieved due to a dropped ACK, resend ACK but drop the duplicate packet

### STOP-AND-WAIT PseudoCode

```python
  lastPacketRecieved = 0
  # sequence and ack numbers from handshake
  sequenceNumber = RecievedSyn.SequenceNum
  
  Sender(RecievedSyn, data):
      if (ReceivedAck):
        sequenceNumber = sequenceNumber + 1
        stopTimer()
        return

      tcpPacket = CreateTCPPacket(RecievedSyn.sourcePort, RecievedSyn.destPort, sequenceNumber, RecievedSyn.acknumber, RecievedSyn.hrdln, DATA, 1, RecievedSyn.checksum, payload = data)
      sendPacket(tcpPacket)
      startTimer(timeout)

      if (timer.finish):
        sendPacket(tcpPacket)
        startTimer(timeout)


  Receiver.Handler():
    if (recivedPacket.sequenceNumber == lastPacketRecieved):
      dropPacket
    else:
      lastPacketRecieved = recievedPacket.sequenceNumber

    tcpPacket = CreateTCPPacket(sourcePort, destPort, recievedPacket.sequenceNumber, recievedPacket.sequenceNumber + 1, hdrlen, ACK, 1, checksum, NULL)

```

## IMPLEMENT ClOSE-CONNECTION

***CLIENT*** Sends FIN sequnceNum = x

***SERVER*** Sends FIN sequnceNum = y, ACKnum = x + 1

***CLIENT*** If all FINs are succesful,

### Notes

- No bidirectional
- will need server, client, and clientClose python commands for mid review
- after 3 way handshake the client will save the connection
- can have as many connections as we want, but cannot have 2 or more on the same source port
- client decides the source port
- we need to split code based on state handling and make a more defined structure
- state machine is a glorified switch statement
- follow socket based methodology, where we use the socket interface and the socket commands
- tcp module only knows if you are receiving or sending and handles accordingly
- build a reset flow to showcase logical errors known while running
