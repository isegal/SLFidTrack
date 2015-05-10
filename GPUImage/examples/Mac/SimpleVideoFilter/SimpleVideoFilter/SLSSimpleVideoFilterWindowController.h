#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

#import "ARImageTarget.h"

#include "apriltag.h"
#include "common/image_u8.h"
#include "common/homography.h"
#include "tag36h11.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@interface SLSSimpleVideoFilterWindowController : NSWindowController
{
    GPUImageAVCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageCrosshairGenerator* crosshairs;
    GPUImageAlphaBlendFilter *blendFilter;
    ARImageTarget* arTargetOverlay;
    
    GLfloat points[1024];
    
    GLfloat poses[16][16];
    
    int pidx;
    
    float focalLength;
    
    GPUImageMovieWriter *movieWriter;
    
    
    //
    // Socket comm
    //
    
    int sockfd;
    struct sockaddr_in servaddr;
    

    //
    // AprilTags
    //
    apriltag_family_t *tf;
    apriltag_detector_t *td;
    image_u8_t *im; // to be used as an adapter
}
@property (weak) IBOutlet NSSlider *sldFocalLength;

@property (weak) IBOutlet NSButton *ctrlEnableThresh;

@property (weak) IBOutlet GPUImageView *videoView;



@end
