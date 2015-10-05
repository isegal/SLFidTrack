//
//  NetworkingWrapper.hpp
//
//  Created by IvgeniSegal on 10/4/15.
//  Copyright © 2015 Ivgeni Segal. All rights reserved.
//

#ifndef NetworkingWrapper_hpp
#define NetworkingWrapper_hpp

#include "MessageIdentifiers.h"
#include "RakPeerInterface.h"
#include <chrono>

inline unsigned char GetPacketIdentifier(const RakNet::Packet *p)
{
    if (p==0)
        return 255;
    
    if ((unsigned char)p->data[0] == ID_TIMESTAMP)
    {
        RakAssert(p->length > sizeof(RakNet::MessageID) + sizeof(RakNet::Time));
        return (unsigned char) p->data[sizeof(RakNet::MessageID) + sizeof(RakNet::Time)];
    }
    else
        return (unsigned char) p->data[0];
}

class NetworkingWrapper {
    NetworkingWrapper(NetworkingWrapper&) =delete;
    NetworkingWrapper& operator=(NetworkingWrapper&) =delete;
    
public:
    NetworkingWrapper() =default;
    void setup();
    void update();
    void shutdown();
    
private:
    void initPeer();
    void processPacket(const RakNet::Packet *packet);
    void onUnconnectedPong(const RakNet::Packet *packet);
    void onConnectionAccepted(const RakNet::Packet *packet);
    
    void periodicDiscoveryPing();
    
private:
    RakNet::RakPeerInterface *mClient = nullptr;
    int mServerPort = 8204;
    
    bool bDiscovering = false;
    using clock = std::chrono::high_resolution_clock;
    using milliseconds = std::chrono::milliseconds;
    clock::time_point mLastPingSent = clock::time_point::min();
    clock::duration mPingInterval = milliseconds(1000);
};

#endif /* NetworkingWrapper_hpp */
