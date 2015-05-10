#import "SLSSimpleVideoFilterWindowController.h"



#import "ARImageTarget.h"




#include <stdio.h>

#include <unordered_map>

std::unordered_map<int, int> ID_MAP = {
    {160, 0},
    {162, 1},
    {182, 2},
    {158, 3},
    {136, 4},
    {113, 5}
};

@interface SLSSimpleVideoFilterWindowController ()

@end

@implementation SLSSimpleVideoFilterWindowController

- (void)initSocket {
    sockfd=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);
    
    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    //servaddr.sin_addr.s_addr=inet_addr("127.0.0.1");
    inet_aton("192.168.1.183", &servaddr.sin_addr);
    
    servaddr.sin_port=htons(5123);
}

- (void)sendBufferSocket: (unsigned char*) buffer siz: (size_t) bSize
{
    size_t res = sendto(sockfd,buffer,bSize,0,
           (struct sockaddr *)&servaddr,sizeof(servaddr));
    
}

- (void)windowDidLoad {
    focalLength = 100.0f;
    
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
    filter = [[GPUImageGrayscaleFilter alloc] init];
    //[filter forceProcessingAtSize:CGSizeMake(640.0, 480.0)];
    
    
    arTargetOverlay = [[ARImageTarget alloc] init];
    //[arTargetOverlay forceProcessingAtSize:CGSizeMake(640, 480)];
    
    gfilter = [[GPUImageLowPassFilter alloc] init];
    
    crosshairs = [[GPUImageCrosshairGenerator alloc] init];
    //[crosshairs forceProcessingAtSize:CGSizeMake(640.0, 480.0)];
    [crosshairs setCrosshairWidth: 14.0];
    
    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    //[blendFilter forceProcessingAtSize:CGSizeMake(640.0, 480.0)];
    
    [videoCamera addTarget:filter];
    
    //gfilter.filterStrength = 0.1;
    
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
        
        //if(bytesPerRow == 0) {
        //    return;
        //}
        
        
        
        /*
        int numMarkers = 0;
        ARToolKitPlus::ARMarkerInfo *markerInfo;
        std::vector<int> markerId = tracker->calc(outputBytes, &markerInfo, &numMarkers);
        
        if(numMarkers) {
            printf("POS: %.2f, %.2f\n", markerInfo[0].pos[0], markerInfo[0].pos[1]);
            //for (int i = 0; i < 16; i++)
            //    printf("%.2f  %s", tracker->getModelViewMatrix()[i], (i % 4 == 3) ? "\n  " : "");
        }
        */
        //NSLog(@"Bytes per row: %d", bytesPerRow);
        /*
        for (unsigned int yIndex = 0; yIndex < 3; yIndex++)
        {
            for (unsigned int xIndex = 0; xIndex < 256; xIndex++)
            {
                NSLog(@"Byte at (%d, %d): %d, %d, %d, %d", xIndex, yIndex, outputBytes[yIndex * bytesPerRow + xIndex * 4], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 1], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 2], outputBytes[yIndex * bytesPerRow + xIndex * 4 + 3]);
            }
        }
        */
        
        
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
            
            /*
            printf("detection %3d: id (%2dx%2d)-%-4d, hamming %d, goodness %8.3f, margin %8.3f\n",
                       i, det->family->d*det->family->d, det->family->h, det->id, det->hamming, det->goodness, det->decision_margin);
            */
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
            matd_t* m = homography_to_pose(det->H, focalLength, focalLength, 0.5*focalLength, 0.5*focalLength);
            
            // printf("-----------\n");
            for(int c = 0; c < 16; ++c) {
                points[c] = m->data[c];
                poses[marker_array_id][c] = m->data[c];
                // printf("%f.3 ", points[c]);
                
            }
            printf("\n");
            matd_destroy(m);
            pidx++;

        }
        
        if(pidx) {
            [self sendBufferSocket: (unsigned char*)poses siz: 1024];
        }

        apriltag_detections_destroy(detections);
        
        
    }];

    
    // Instantiate movie writer and add targets
    //movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:pathToMovieFile size:CGSizeMake(640.0, 480.0)];
    //movieWriter.encodingLiveVideo = YES;
    
    self.videoView.fillMode = kGPUImageFillModePreserveAspectRatio;
    //[filter addTarget:movieWriter];
    
    
    [filter addTarget:rawDataOutput];
    //[filter addTarget:blendFilter atTextureLocation:0];
    // [crosshairs addTarget:blendFilter atTextureLocation:1];
    
    [filter addTarget:arTargetOverlay];
    
    [arTargetOverlay addTarget:self.videoView];
    
    // [filter addTarget: [[ARImageTarget alloc] init]];
    
    // Start capturing
    [videoCamera startCameraCapture];
    
    
    /*
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Start recording");
        
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
        
        double delayInSeconds = 10.0;
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            
            [filter removeTarget:movieWriter];
            videoCamera.audioEncodingTarget = nil;
            [movieWriter finishRecording];
            NSLog(@"Movie completed");

        });
    }); */

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

-(void)initARLibrary
{
    const int width = 640, height = 480, bpp = 1;
    
    // create a tracker that does:
    //  - 6x6 sized marker images (required for binary markers)
    //  - samples at a maximum of 6x6
    //  - works with luminance (gray) images
    //  - can load a maximum of 0 non-binary pattern
    //  - can detect a maximum of 8 patterns in one imagege
    tracker = new ARToolKitPlus::TrackerSingleMarker(width, height, 8, 6, 6, 6, 0);
    tracker->setPixelFormat(ARToolKitPlus::PIXEL_FORMAT_RGBA);
    
    // load a camera file.
    if (!tracker->init("no_distortion.cal", 1.0f, 1000.0f)) // load MATLAB file
    {
        printf("ERROR: init() failed\n");
        return;
    }
    
    // tracker->getCamera()->printSettings();
    
    // define size of the marker in OpenGL units
    tracker->setPatternWidth(1.0);
    
    // the marker in the BCH test image has a thin border...
    //tracker->setBorderWidth(0.125);
    tracker->setBorderWidth(0.5);
    
    
    // set a threshold. alternatively we could also activate automatic thresholding
    tracker->setThreshold(150);
    //tracker->activateAutoThreshold(true);
    
    // let's use lookup-table undistortion for high-speed
    // note: LUT only works with images up to 1024x1024
    tracker->setUndistortionMode(ARToolKitPlus::UNDIST_LUT);
    
    // switch to simple ID based markers
    // use the tool in tools/IdPatGen to generate markers
    tracker->setMarkerMode(ARToolKitPlus::MARKER_ID_SIMPLE);
    
}

- (IBAction)sldFocalChanged:(NSSlider *)sender {
    int sliderValue = [sender intValue];
    float scaling = (float) sliderValue / 1000.0f;
    focalLength = 640.0f + 1280.0f * scaling;
}

- (IBAction)sldMinimumChanged:(NSTextField *)sender{
    
}

- (IBAction)sldMaximumChanged:(NSTextField *)sender {
    
}

@end
