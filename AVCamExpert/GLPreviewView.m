//
//  GLPreviewView.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2016 Matchpix. All rights reserved.
//

#import "GLPreviewView.h"
#import "RippleModel.h"
#include <OpenGLES/ES2/glext.h>
// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];
GLint uniformsBGRA[1];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};
@interface GLPreviewView ()
{
    size_t count;
    
    GLuint _programYUV;
    GLuint _programBGRA;
    
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    size_t _textureWidth;
    size_t _textureHeight;
    unsigned int _meshFactor;
    
    RippleModel *_ripple;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    
    NSString *_sessionPreset;
    
    CVOpenGLESTextureCacheRef _videoTextureCache;
}
@end
@implementation GLPreviewView
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        _screenWidth = self.frame.size.width;
        _screenHeight = self.frame.size.height;
        _ripple = [[RippleModel alloc] initWithScreenWidth:self.frame.size.width
                                              screenHeight:self.frame.size.height
                                                meshFactor:4
                                               touchRadius:5
                                              textureWidth:_screenWidth
                                             textureHeight:_screenHeight];
        _simulation = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        _screenWidth = self.frame.size.width;
        _screenHeight = self.frame.size.height;
        _ripple = [[RippleModel alloc] initWithScreenWidth:self.frame.size.width
                                              screenHeight:self.frame.size.height
                                                meshFactor:4
                                               touchRadius:5
                                              textureWidth:_screenWidth
                                             textureHeight:_screenHeight];
        _simulation = YES;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context{
    self = [super initWithFrame:(CGRect)frame context:(EAGLContext *)context];
    if (self){
        _screenWidth = self.frame.size.width;
        _screenHeight = self.frame.size.height;
    }
    return self;
}
- (void)setupGLWithContext:(EAGLContext*)context
{
    self.context = context;
    self.enableSetNeedsDisplay = NO;
    [EAGLContext setCurrentContext:context];
    
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
    _meshFactor = 8;
    self.delegate = self;
    [self loadShaders];
    if (_isYUV){
        glUseProgram(_programYUV);
        
        glUniform1i(uniforms[UNIFORM_Y], 0);
        glUniform1i(uniforms[UNIFORM_UV], 1);
    }else{
        
        glUseProgram(_programBGRA);
        
        glUniform1i(uniformsBGRA[0], 0);
    }
    _screenHeight = self.frame.size.height;
    _screenWidth = self.frame.size.width;
    [self setupBuffers];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_positionVBO);
    glDeleteBuffers(1, &_texcoordVBO);
    glDeleteBuffers(1, &_indexVBO);
    
    if (_programYUV) {
        glDeleteProgram(_programYUV);
        _programYUV = 0;
    }
    if (_programBGRA) {
        glDeleteProgram(_programBGRA);
        _programBGRA = 0;
    }
}

- (void)cleanUpTextures
{
    if (_lumaTexture)
    {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture)
    {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)update
{
    _screenHeight = self.frame.size.height;
    _screenWidth = self.frame.size.width;
    if (_ripple)
    {
        if (_simulation){
            [_ripple runSimulation];
        }
        // no need to rebind GL_ARRAY_BUFFER to _texcoordVBO since it should be still be bound from setupBuffers
        glBufferData(GL_ARRAY_BUFFER, [_ripple getVertexSize], [_ripple getTexCoords], GL_DYNAMIC_DRAW);
        GLenum error;
        error = glGetError();
        if (error != GL_NO_ERROR){
            NSLog(@"Glerror %i",error);
        }
        
    }
    if (!self.hidden)
        [self display];
    
    
}

#pragma mark - GLKView delegate methods
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_ripple)
    {
        glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)[_ripple getIndexCount], GL_UNSIGNED_SHORT, 0);
    }
}

#pragma mark - Touch handling methods

- (void)myTouch:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInView:touch.view];
        [_ripple initiateRippleAtLocation:location];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self myTouch:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self myTouch:touches withEvent:event];
}

#pragma mark - OpenGL ES 2 shader compilation
- (GLuint) loadProgramWithVertexPath:(NSString*)vertShaderPathname fragmentPath:(NSString*)fragShaderPathname{
    
    GLuint vertShader, fragShader;
    GLuint program = glCreateProgram();
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        glDeleteProgram(program);
        return 0;
    }
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        glDeleteProgram(program);
        return 0;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:program]) {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        
    }
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    return program;
}

- (BOOL)loadShaders
{
    NSString *vertShaderPathname, *fragYUVShaderPathname, *fragBGRAShaderPathname;
    
    
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    fragYUVShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderYUV" ofType:@"fsh"];
    fragBGRAShaderPathname = [[NSBundle mainBundle] pathForResource:@"ShaderBGRA" ofType:@"fsh"];
    // Program for YUV type buffer
    _programYUV = [self loadProgramWithVertexPath:vertShaderPathname fragmentPath:fragYUVShaderPathname];
    // Program for BGRA type buffer
    _programBGRA = [self loadProgramWithVertexPath:vertShaderPathname fragmentPath:fragBGRAShaderPathname];
    // Get uniform locations.
    uniforms[UNIFORM_Y] = glGetUniformLocation(_programYUV, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(_programYUV, "SamplerUV");
    uniformsBGRA[0] = glGetUniformLocation(_programBGRA, "Sampler");
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
- (void)setupBuffers
{
    glGenBuffers(1, &_indexVBO);
    GLenum error;
    error = glGetError();
    if (error != GL_NO_ERROR){
        NSLog(@"Glerror %i",error);
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, [_ripple getIndexSize], [_ripple getIndices], GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, [_ripple getVertexSize], [_ripple getVertices], GL_STATIC_DRAW);
    error = glGetError();
    if (error != GL_NO_ERROR){
        NSLog(@"Glerror %i",error);
    }
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
    error = glGetError();
    if (error != GL_NO_ERROR){
        NSLog(@"Glerror %i",error);
    }
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, [_ripple getVertexSize], [_ripple getTexCoords], GL_DYNAMIC_DRAW);
    error = glGetError();
    if (error != GL_NO_ERROR){
        NSLog(@"Glerror %i",error);
    }
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}


#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVReturn err;
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const FourCharCode subType = CMFormatDescriptionGetMediaSubType(formatDescription);
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    if (subType == '420f'){
        _isYUV = YES;
    }else{
        _isYUV = NO;
    }
    if (_isYUV){
        glUseProgram(_programYUV);
        
        glUniform1i(uniforms[UNIFORM_Y], 0);
        glUniform1i(uniforms[UNIFORM_UV], 1);
    }else{
        
        glUseProgram(_programBGRA);
        
        glUniform1i(uniformsBGRA[0], 0);
    }
    if (!_videoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
    
    if (_ripple == nil ||
        width != _textureWidth ||
        height != _textureHeight||
        self.frame.size.width != _screenWidth ||
        self.frame.size.height != _screenHeight)
    {
        _textureWidth = width;
        _textureHeight = height;
        _screenWidth = self.frame.size.width;
        _screenHeight = self.frame.size.height;
        
        _ripple = [[RippleModel alloc] initWithScreenWidth:_screenWidth
                                              screenHeight:_screenHeight
                                                meshFactor:_meshFactor
                                               touchRadius:5
                                              textureWidth:_textureWidth
                                             textureHeight:_textureHeight];
        
        [self setupBuffers];
    }
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
    // optimally from CVImageBufferRef.
    
    if (_isYUV){
        // Y-plane
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE,
                                                           (GLsizei)_textureWidth,
                                                           (GLsizei)_textureHeight,
                                                           GL_LUMINANCE,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_LUMINANCE_ALPHA,
                                                           (GLsizei)_textureWidth/2,
                                                           (GLsizei)_textureHeight/2,
                                                           GL_LUMINANCE_ALPHA,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }else{
        // BGRA binding
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           (GLsizei)_textureWidth,
                                                           (GLsizei)_textureHeight,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    }
}

@end
