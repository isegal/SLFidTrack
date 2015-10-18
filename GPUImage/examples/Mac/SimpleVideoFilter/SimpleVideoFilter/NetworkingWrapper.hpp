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
#include "FiducialMarker.hpp"

#include <chrono>
#include <array>

enum SLMessageIds {
    ID_SERVER_TEXTMSG = ID_USER_PACKET_ENUM,
    ID_PLAYER_INPUT_STATE,
    ID_PLAYER_ACTION1,
    ID_PLAYER_ACTION2,
    ID_PLAYER_RAY_ACTION1,
    ID_PLAYER_RAY_ACTION2,
    ID_PLAYER_RAY_ACTION3,
    ID_MARKER_POSE,
    ID_MARKER_VISIBILITIES
};

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

using Mat16 = std::array<float, 16>;

class NetworkingWrapper {
    NetworkingWrapper(NetworkingWrapper&) =delete;
    NetworkingWrapper& operator=(NetworkingWrapper&) =delete;
    
public:
    NetworkingWrapper() =default;
    void setup();
    void update();
    void shutdown();
    
    void updatePose(int markerId, const FidMatrix& poseMatrix);
    
private:
    void initPeer();
    void processPacket(RakNet::Packet *packet);
    void onUnconnectedPong(const RakNet::Packet *packet);
    void onConnectionAccepted(const RakNet::Packet *packet);
    void onDisconnection();
    void onFailedToConnect();
    
    void sendStateUpdate();
    void sendMarkerPose(RakNet::BitStream& bsOut, FiducialMarker& marker, int id);
    void sendMarkerVisibilities(RakNet::BitStream& bsOut, int visMask);
    
    void periodicDiscoveryPing();
    
    void closeClient();
    
private:
    RakNet::RakPeerInterface *mClient = nullptr;
    static constexpr int serverPort = 8204;
    static constexpr int numMarkers = 16;
    std::array<FiducialMarker, numMarkers> mMarkers;
    
    bool bDiscovering = false;
    bool bConnected = false;
    using clock = std::chrono::high_resolution_clock;
    using milliseconds = std::chrono::milliseconds;
    clock::time_point mLastSent = clock::time_point::min();
    const clock::duration mPingInterval = milliseconds(1000);
    
    const clock::duration mSendInterval = milliseconds(100);
    
    
};

#endif /* NetworkingWrapper_hpp */
