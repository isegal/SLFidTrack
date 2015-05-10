//
//  ARImageTarget.h
//  SimpleVideoFilter
//
//  Created by Iv Segal on 3/21/15.
//  Copyright (c) 2015 Red Queen Coder, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GPUImage/GPUImage.h>

#include <ARToolKitPlus/TrackerSingleMarker.h>

@interface ARImageTarget : GPUImageFilter
{

    GLfloat* markerVerts;
    GLfloat* markerTexCoords;
    GLint numMarkerPoints;
    
}

- (void)addMarkerPointX: (GLfloat) xcoord y: (GLfloat) ycoord;
- (void) resetMarkerPoints;

@property ARToolKitPlus::TrackerSingleMarker *tracker;

@end
