#import "SLSSimpleVideoFilterWindowController.h"



#import "ARImageTarget.h"




#include <stdio.h>

#include <unordered_map>
#include "NetworkingWrapper.hpp"

std::unordered_map<int, int> ID_MAP = {
    {160, 0},
    {162, 1},
    {182, 2},
    {158, 3},
    {136, 4},
    {113, 5},
    
    {110, 6},
    {134, 7},
    {138, 8},
    {159, 9},
    {183, 10},
    {185, 11},
    {135, 12},
    {184, 13},
    {112, 14},
    {114, 15},
    
    {186, 0} // test marker

};

@interface SLSSimpleVideoFilterWindowController ()

@end

@implementation SLSSimpleVideoFilterWindowController

- (void)initSocket {

    mNetworkingWrapper = new NetworkingWrapper();
    mNetworkingWrapper->setup();
}

- (void)windowDidLoad {
    focalLength = 1080.0f;
    
    [super windowDidLoad];
    
    [self initAprilTags];
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
    char path[PATH_MAX];
    if (!CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)path, PATH_MAX))
    {
        // error!
    }
    CFRelease(resourcesURL);
    
    chdir(path);
    // std::cout << "Current Path: " << path << std::endl;
    
    // [self initARLibrary];
    
    [self initSocket];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // Instantiate video camera
    videoCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:nil];
    // videoCamera.runBenchmark = YES;
    
    [videoCamera printSupportedPixelFormats];
    
    // Create filter and add it to target
    filter = [[GPUImageLuminanceThresholdFilter alloc] init];
    //[filter forceProcessingAtSize:CGSizeMake(640.0, 480.0)];
    
    
    arTargetOverlay = [[ARImageTarget alloc] init];
    //[arTargetOverlay forceProcessingAtSize:CGSizeMake(640, 480)];

    [videoCamera addTarget:filter];
    

    // Save video to desktop
    NSError *error = nil;
    
    NSURL *pathToDesktop = [[NSFileManager defaultManager] URLForDirectory:NSDesktopDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    NSURL *pathToMovieFile = [pathToDesktop URLByAppendingPathComponent:@"movie.mp4"];
    NSString *filePathString = [pathToMovieFile absoluteString];
    NSString *filePathSubstring = [filePathString substringFromIndex:7];
    unlink([filePathSubstring UTF8String]);
    
    GPUImageRawDataOutput *rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(1280,720) resultsInBGRAFormat:NO];
    
    [rawDataOutput setNewFrameAvailableBlock:^{
        GLubyte *outputBytes = [rawDataOutput rawBytesForImage];
        NSInteger bytesPerRow = [rawDataOutput bytesPerRowInOutput];
        
        
        
        image_u8_t tmp = { .width = 1280, .height = 720, .stride = 1280, .buf = outputBytes };
        zarray_t *detections = apriltag_detector_detect(td, &tmp);
        // printf("detections: %d\n", zarray_size(detections));
        
        [arTargetOverlay resetMarkerPoints];
        
        int dcount = zarray_size(detections);
        pidx = 0;
        for (int i = 0; i < dcount; i++) {
            apriltag_detection_t *det;
            
            zarray_get(detections, i, &det);
            
            auto marker_id_idx = ID_MAP.find(det->id);
            
            if(marker_id_idx == ID_MAP.end())
                continue;
            
            int marker_array_id = marker_id_idx->second;
            

            [arTargetOverlay addMarkerPointX: det->p[0][0] y:det->p[0][1]];
            [arTargetOverlay addMarkerPointX: det->p[1][0] y:det->p[1][1]];
            [arTargetOverlay addMarkerPointX: det->p[2][0] y:det->p[2][1]];

            
            
            [arTargetOverlay addMarkerPointX: det->p[0][0] y:det->p[0][1]];
            [arTargetOverlay addMarkerPointX: det->p[2][0] y:det->p[2][1]];
            [arTargetOverlay addMarkerPointX: det->p[3][0] y:det->p[3][1]];
            
            // [ F  0  A  0 ]     (see glFrustrum)
            // [ 0  G  B  0 ]
            // [ 0  0  C  D ]
            // [ 0  0 -1  0 ]
            // double F, double G, double A, double B, double C, double D)
            // matd_t* m = homography_to_model_view(det->H, 0.836787939, 1.19175363, 0.0, 0.0, -1.0016681, -0.200166807);

            // F 0 0 0
            // 0 G 0 0
            // A B C -1
            // 0 0 D 0

            // matd_t* m = homography_to_model_view(det->H, 0.836787939, 1.19175363, 0.0, 0.0, -1.0016681, -0.500166807);
            
            // [ fx 0  cx 0 ] [ R00  R01  TX ]    [ H00 H01 H02 ]
            // [  0 fy cy 0 ] [ R10  R11  TY ] =  [ H10 H11 H12 ]
            // [  0  0  1 0 ] [ R20  R21  TZ ] =  [ H20 H21 H22 ]
            //                [  0    0    1 ]
            // homography_to_pose(const matd_t *H, double fx, double fy, double cx, double cy);
            
            // http://answers.opencv.org/question/17076/conversion-focal-distance-from-mm-to-pixels/
            
            // focal_pixel = (image_width_in_pixels  0.5) / tan(FOV  0.5 * PI/180)
            //
            //matd_t* m = homography_to_pose(det->H, 250, 187, 0.055, 0.055);
            // *homography_to_pose(const matd_t *H, double fx, double fy, double cx, double cy);
            matd_t* m = homography_to_pose(det->H, 1280, 1280, 0.5*1280, 0.5*1280);
            
            
            //matd_t* m = homography_to_pose(det->H, 1280, 720, 1280/2.0, 720/2.0);
            
            //matd_t* m = homography_to_model_view(det->H, 0.836787939, 1.19175363, 0.0, 0.0, -1.0016681, -0.500166807);
            
            FidMatrix mat;
            
            // printf("-----------\n");
            for(int c = 0; c < 16; ++c) {
                points[c] = m->data[c];
                mat[c] = m->data[c];
                
                // printf("%f.3 ", points[c]);
                
            }
            
            mNetworkingWrapper->updatePose(marker_array_id, mat);
            
            printf("\n");
            matd_destroy(m);
            pidx++;

        }
        
        apriltag_detections_destroy(detections);
        
        mNetworkingWrapper->update();
    }];

    
    // Instantiate movie writer and add targets
    //movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:pathToMovieFile size:CGSizeMake(640.0, 480.0)];
    //movieWriter.encodingLiveVideo = YES;
    
    self.videoView.fillMode = kGPUImageFillModePreserveAspectRatio;
    //[filter addTarget:movieWriter];
    
    
    [filter addTarget:rawDataOutput];
    //[filter addTarget:blendFilter atTextureLocation:0];
    // [crosshairs addTarget:blendFilter atTextureLocation:1];
    
    [videoCamera addTarget:arTargetOverlay];
    [arTargetOverlay addTarget:self.videoView];
    
    // [filter addTarget: [[ARImageTarget alloc] init]];
    
    // Start capturing
    [videoCamera startCameraCapture];
    

}

-(void)initAprilTags
{
    tf = tag36h11_create();
    tf->black_border = 1;
    
    td = apriltag_detector_create();
    apriltag_detector_add_family(td, tf);
    td->quad_decimate = 0; // 1.0;
    td->quad_sigma = 0; // 0.9; // 0.3;
    td->nthreads = 4;
    
    td->debug = 0;
    td->refine_edges = 0;
    td->refine_decode = 0;
    td->refine_pose = 0;
    
    im = (image_u8_t *)calloc(1, sizeof(image_u8_t));
    
}

- (IBAction)enableThreshView:(id)sender {
    if([sender state] == NSOnState) {
        [arTargetOverlay removeTarget:self.videoView];
        [filter addTarget: self.videoView];
    } else if([sender state] == NSOffState) {
        [filter removeTarget: self.videoView];
        [arTargetOverlay addTarget:self.videoView];
    }
}

- (IBAction)sldFocalChanged:(NSSlider *)sender {
    int sliderValue = [sender intValue];
    float scaling = (float) sliderValue / 1000.0f;
    
    ((GPUImageLuminanceThresholdFilter*)filter).threshold = scaling;
    
    // focalLength = 640.0f + 1280.0f * scaling;
    
}



@end
