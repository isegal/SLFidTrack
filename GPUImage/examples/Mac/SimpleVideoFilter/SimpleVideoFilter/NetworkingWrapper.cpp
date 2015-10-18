//
//  NetworkingWrapper.cpp
//
//  Created by IvgeniSegal on 10/4/15.
//  Copyright © 2015 Ivgeni Segal. All rights reserved.
//

#include "NetworkingWrapper.hpp"

#include "BitStream.h"

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
    } else if(bConnected) {
        sendStateUpdate();
    }
    
    if(mClient) {
        auto packet = mClient->Receive();
        if(packet) {
            processPacket(packet);
        }
    }

}

void NetworkingWrapper::updatePose(int markerId, const FidMatrix& poseMatrix)
{
    assert(markerId >= 0 && markerId < numMarkers);
    mMarkers[markerId].updatePose(poseMatrix);
}

void NetworkingWrapper::periodicDiscoveryPing()
{
    if(clock::now() <= mLastSent + mPingInterval) {
        return;
    }
    mClient->Ping("255.255.255.255", serverPort, false);
    mLastSent = clock::now();
    
}

void NetworkingWrapper::processPacket(RakNet::Packet *packet)
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
        case ID_CONNECTION_ATTEMPT_FAILED:
        {
            onFailedToConnect();
            return;
        }
        
        case ID_DISCONNECTION_NOTIFICATION:
        case ID_CONNECTION_LOST:
        {
            mClient->DeallocatePacket(packet);
            onDisconnection();
            return; // no further work necessary
        }
            
    }
    mClient->DeallocatePacket(packet);
}

void NetworkingWrapper::onConnectionAccepted(const RakNet::Packet *packet)
{
    bConnected = true;
}

void NetworkingWrapper::onDisconnection()
{
    closeClient();
}

void NetworkingWrapper::onFailedToConnect()
{
    closeClient();
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

void NetworkingWrapper::sendStateUpdate()
{
    if(clock::now() <= mLastSent + mSendInterval) {
        return;
    }
    
    RakNet::BitStream bsOut;
    bsOut.Write((RakNet::MessageID)(ID_MARKER_POSE));
    
    int idCounter = 0;
    int visibilityMask = 0;
    
    for(auto &marker : mMarkers) {
        if(marker.isVisible()) {
            visibilityMask |= 1 << idCounter;
        }
        ++idCounter;
    }
    sendMarkerVisibilities(bsOut, visibilityMask);
    
    idCounter = 0;
    for(auto &marker : mMarkers) {
        if(visibilityMask & (1 << idCounter)) {
            sendMarkerPose(bsOut, marker, idCounter);
        }
        ++idCounter;
    }
    
    mClient->Send(&bsOut, HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 0, RakNet::UNASSIGNED_SYSTEM_ADDRESS, true);
    
    mLastSent = clock::now();
}

void NetworkingWrapper::sendMarkerVisibilities(RakNet::BitStream& bsOut, int visMask)
{
    constexpr int bitRange = ((int)1 << numMarkers) - 1;
    // RakNet::BitStream bsOut;
    // bsOut.Write((RakNet::MessageID)(ID_MARKER_VISIBILITIES));
    bsOut.WriteBitsFromIntegerRange(visMask, 0, bitRange);
    
    //std::cout << "visMask: " << visMask << "\n";
    
    // std::cout << "MVis: " << visMask << std::endl;
    // mClient->Send(&bsOut, HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 0, RakNet::UNASSIGNED_SYSTEM_ADDRESS, true);
    
}

void NetworkingWrapper::sendMarkerPose(RakNet::BitStream& bsOut, FiducialMarker& marker, int id)
{
    FidMatrix pose;
    /*
     0  1   2   3
     4  5   6   7
     8  9   10  11
     12 13  14  15
     */
    if(marker.readPose(pose)) {
        bsOut.WriteBitsFromIntegerRange(id, 0, numMarkers);
        bsOut.WriteOrthMatrix(pose[0], pose[1], pose[2],
                              pose[4], pose[5], pose[6],
                              pose[8], pose[9], pose[10]);
        bsOut.WriteVector(pose[3], pose[7], pose[11]);
        
        // mClient->Send(&bsOut, HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 0, RakNet::UNASSIGNED_SYSTEM_ADDRESS, true);
        
    }
}

void NetworkingWrapper::closeClient()
{
    if(mClient) {
        RakNet::RakPeerInterface::DestroyInstance(mClient);
        mClient = nullptr;
    }
    bConnected = false;
}

void NetworkingWrapper::shutdown()
{
    closeClient();
}
