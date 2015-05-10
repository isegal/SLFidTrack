//
//  ARImageTarget.m
//  SimpleVideoFilter
//
//  Created by Iv Segal on 3/21/15.
//  Copyright (c) 2015 Red Queen Coder, LLC. All rights reserved.
//

#import "ARImageTarget.h"

@implementation ARImageTarget

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImagePlainFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = textureColor = texture2D(inputImageTexture, textureCoordinate);;
 }
 );
#else
NSString *const kGPUImagePlainFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );
#endif

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePlainFragmentShaderString]))
    {
        return nil;
    }
    
    markerVerts = (GLfloat*) malloc(4096);
    markerTexCoords = (GLfloat*) malloc(4096);
    numMarkerPoints = 0;
    
    return self;
}

float texCoords[12] = {

    0.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,

    
    0.0f, 1.0f,
    1.0f, 0.0f,
    1.0f, 1.0f,

};

- (void)addMarkerPointX: (GLfloat) xcoord y: (GLfloat) ycoord
{
    markerVerts[numMarkerPoints*2] = (xcoord / (0.5 * inputTextureSize.width)) - 1.0;
    markerVerts[numMarkerPoints*2 + 1] = (ycoord / (0.5 * inputTextureSize.height)) - 1.0;
    
    markerTexCoords[numMarkerPoints*2] = texCoords[(numMarkerPoints*2) % 12];
    markerTexCoords[numMarkerPoints*2 + 1] = texCoords[(numMarkerPoints*2+1) % 12];;
    
    ++numMarkerPoints;
}

- (void) resetMarkerPoints
{
    numMarkerPoints = 0;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    if(numMarkerPoints < 6) numMarkerPoints = 6;
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    {
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, markerVerts);
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, markerTexCoords);
        glDrawArrays(GL_TRIANGLES, 0, numMarkerPoints);
    }
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)dealloc
{

}




@end
