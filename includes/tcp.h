#ifndef TCP_H
#define TCP_H

enum{
    max_payload_size = 4,
    ATTEMPT_CONNECTION_TIME = 20000,
    CLIENT_WRITE_TIMER = 20000,
};

typedef nx_struct TCPPack{
    nx_uint16_t source_port;
    nx_uint16_t destination_port;
    nx_uint32_t sequence_num;
    nx_uint32_t acknowledgement_num;
    nx_uint16_t flag;
    nx_uint16_t advertisement_window;
    nx_uint32_t checksum;
    nx_uint16_t payload[max_payload_size];
}TCPPack;

enum{
    DATA = 0,
    ACK = 1,
    SYN = 2,
    SYNACK = 3,
    FIN = 4,
    FINACK = 5,
};

// void makeTCPPacket(TCPPack* TCP, nx_uint16_t source_port, nx_uint16_t destination_port, nx_uint32_t sequence_num, nx_uint32_t acknowledgement_num, nx_uint16_t flag, nx_uint16_t advertisement_window, nx_uint32_t checksum, nx_uint16_t payload[max_payload_size]) {
//     TCP->source_port = source_port;
//     TCP->destination_port = destination_port;
//     TCP->sequence_num = sequence_num;
//     TCP->acknowledgement_num = acknowledgement_num;
//     TCP->flag = flag;
//     TCP->advertisement_window = advertisement_window;
//     TCP->checksum = checksum;
//     TCP->payload = payload;
// }

#endif