//
//  NetworkingWrapper.cpp
//
//  Created by IvgeniSegal on 10/4/15.
//  Copyright © 2015 Ivgeni Segal. All rights reserved.
//

#include "NetworkingWrapper.hpp"

#include <iostream>

void NetworkingWrapper::setup()
{

}

void NetworkingWrapper::initPeer()
{
    mClient = RakNet::RakPeerInterface::GetInstance();
    auto desc = RakNet::SocketDescriptor();
    mClient->Startup(1, &desc, 1);
    
    bDiscovering = true;
    periodicDiscoveryPing();
}

void NetworkingWrapper::update()
{
    if(!mClient) {
        initPeer();
        return;
    }
    
    if(bDiscovering) {
        periodicDiscoveryPing();
    }
    
    auto packet = mClient->Receive();
    if(!packet)
        return;
    
    processPacket(packet);
    mClient->DeallocatePacket(packet);
}

void NetworkingWrapper::periodicDiscoveryPing()
{
    if(clock::now() <= mLastPingSent + mPingInterval) {
        return;
    }
    mClient->Ping("255.255.255.255", mServerPort, false);
    mLastPingSent = clock::now();
    
}

void NetworkingWrapper::processPacket(const RakNet::Packet *packet)
{
    auto messageId = GetPacketIdentifier(packet);
    
    switch(messageId) {
        case ID_UNCONNECTED_PONG:
        {
            onUnconnectedPong(packet);
            break;
        }
        case ID_CONNECTION_REQUEST_ACCEPTED:
        {
            onConnectionAccepted(packet);
            break;
        }
            
    }
}

void NetworkingWrapper::onConnectionAccepted(const RakNet::Packet *packet)
{
    std::cout << "Connected\n";
}

void NetworkingWrapper::onUnconnectedPong(const RakNet::Packet *packet)
{
    if(!bDiscovering) {
        return;
    }
    
    char hostAddr[1024];
    
    packet->systemAddress.ToString(false, hostAddr);
    
    mClient->Connect(hostAddr, packet->systemAddress.GetPort(), 0, 0);
    bDiscovering = false;
}

void NetworkingWrapper::shutdown()
{
    if(mClient) {
        RakNet::RakPeerInterface::DestroyInstance(mClient);
    }
}
