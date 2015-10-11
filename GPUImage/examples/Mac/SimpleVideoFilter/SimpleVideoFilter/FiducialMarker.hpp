//
//  FiducialMarker.hpp
//
//  Created by IvgeniSegal on 10/4/15.
//  Copyright © 2015 Ivgeni Segal. All rights reserved.
//

#ifndef FiducialMarker_hpp
#define FiducialMarker_hpp

#include <array>
#include <chrono>

using FidMatrix = std::array<float, 16>;

class FiducialMarker {
public:
    
    void updatePose(const FidMatrix& pose);
    bool readPose(FidMatrix& inPose);
    bool isVisible() { return((clock::now() - mLastSeen) < mVisibilityLostDelay); }
    
private:
    FidMatrix mPose = {0};
    bool mDirtyFlag = false;
    
    using clock = std::chrono::high_resolution_clock;
    using milliseconds = std::chrono::milliseconds;
    clock::time_point mLastSeen = clock::time_point::min();
    
    const clock::duration mVisibilityLostDelay = milliseconds(600);
};

#endif /* FiducialMarker_hpp */
