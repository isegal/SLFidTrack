//
//  FiducialMarker.cpp
//  SimpleVideoFilter
//
//  Created by Iv on 10/10/15.
//  Copyright © 2015 Red Queen Coder, LLC. All rights reserved.
//

#include "FiducialMarker.hpp"

void FiducialMarker::updatePose(const FidMatrix& pose)
{
    mPose = pose;
    mLastSeen = clock::now();
    mDirtyFlag = true;
}

bool FiducialMarker::readPose(FidMatrix& inPose)
{
    if(!mDirtyFlag)
        return false;
    inPose = mPose;
    mDirtyFlag = false;
    return true;
}


