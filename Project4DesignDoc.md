# Project 4 Design Doc

1. Create commands in python file
2. Testsim functions handle type of command and sends to CommandHandlerP.nc
3. make a new command type in the command.h
4. Wire the CommandHandlerP.nc switch cases to the methods in the Node.nc file
5. Node.nc methods call a TCPP app method respectively
6. TCPP.nc methods will determine type of incoming message based on switch case where we check for the first word in message
7. Handler method in TCPP.nc calls given method to process the message and print out response
