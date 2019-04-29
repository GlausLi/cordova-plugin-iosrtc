import Foundation
import AVFoundation
import WebRTC

class PluginGetUserMedia : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var rtcPeerConnectionFactory: RTCPeerConnectionFactory
    
    var externalVideoBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    
    var assetWriterInput: AVAssetWriterInput?
    var assetWriter: AVAssetWriter?
    var frameNumber: Int64 = 0
    
    var isRecording: Bool = false
    var rtcVideoSource: RTCAVFoundationVideoSource?

    init(rtcPeerConnectionFactory: RTCPeerConnectionFactory) {
        NSLog("PluginGetUserMedia#init()")
        
        self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
        self.rtcVideoSource = nil
    }
    
    
    deinit {
        NSLog("PluginGetUserMedia#deinit()")
    }
    
    
    func call(
        _ constraints: NSDictionary,
        callback: (_ data: NSDictionary) -> Void,
        errback: (_ error: String) -> Void,
        eventListenerForNewStream: (_ pluginMediaStream: PluginMediaStream) -> Void
        ) {
        NSLog("PluginGetUserMedia#call()")
        
        let    audioRequested = constraints.object(forKey: "audio") as? Bool ?? false
        let    videoRequested = constraints.object(forKey: "video") as? Bool ?? false
        let    videoDeviceId = constraints.object(forKey: "videoDeviceId") as? String
        let    videoMinWidth = constraints.object(forKey: "videoMinWidth") as? Int ?? 0
        let    videoMaxWidth = constraints.object(forKey: "videoMaxWidth") as? Int ?? 0
        let    videoMinHeight = constraints.object(forKey: "videoMinHeight") as? Int ?? 0
        let    videoMaxHeight = constraints.object(forKey: "videoMaxHeight") as? Int ?? 0
        let    videoMinFrameRate = constraints.object(forKey: "videoMinFrameRate") as? Float ?? 0.0
        let    videoMaxFrameRate = constraints.object(forKey: "videoMaxFrameRate") as? Float ?? 0.0
        
        var rtcMediaStream: RTCMediaStream
        var pluginMediaStream: PluginMediaStream?
        var rtcAudioTrack: RTCAudioTrack?
        var rtcVideoTrack: RTCVideoTrack?
        var rtcVideoCapturer: RTCVideoCapturer?
        var rtcVideoSource: RTCAVFoundationVideoSource?
        var videoDevice: AVCaptureDevice?
        var mandatoryConstraints: [String: String] = [:]
        var constraints: RTCMediaConstraints
        
        if videoRequested == true {
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case AVAuthorizationStatus.notDetermined:
                NSLog("PluginGetUserMedia#call() | video authorization: not determined")
            case AVAuthorizationStatus.authorized:
                NSLog("PluginGetUserMedia#call() | video authorization: authorized")
            case AVAuthorizationStatus.denied:
                NSLog("PluginGetUserMedia#call() | video authorization: denied")
                errback("video denied")
                return
            case AVAuthorizationStatus.restricted:
                NSLog("PluginGetUserMedia#call() | video authorization: restricted")
                errback("video restricted")
                return
            }
        }
        
        if audioRequested == true {
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
            case AVAuthorizationStatus.notDetermined:
                NSLog("PluginGetUserMedia#call() | audio authorization: not determined")
            case AVAuthorizationStatus.authorized:
                NSLog("PluginGetUserMedia#call() | audio authorization: authorized")
            case AVAuthorizationStatus.denied:
                NSLog("PluginGetUserMedia#call() | audio authorization: denied")
                errback("audio denied")
                return
            case AVAuthorizationStatus.restricted:
                NSLog("PluginGetUserMedia#call() | audio authorization: restricted")
                errback("audio restricted")
                return
            }
        }
        
        rtcMediaStream = self.rtcPeerConnectionFactory.mediaStream(withStreamId: UUID().uuidString)
        
        if videoRequested == true {
            // No specific video device requested.
            if videoDeviceId == nil {
                NSLog("PluginGetUserMedia#call() | video requested (device not specified)")
                
                for device: AVCaptureDevice in (AVCaptureDevice.devices(for: AVMediaType.video) as! Array<AVCaptureDevice>) {
                    if device.position == AVCaptureDevice.Position.front {
                        videoDevice = device
                        break
                    }
                }
            }
                
                // Video device specified.
            else {
                NSLog("PluginGetUserMedia#call() | video requested (specified device id: '%@')", String(videoDeviceId!))
                
                for device: AVCaptureDevice in (AVCaptureDevice.devices(for: AVMediaType.video) as! Array<AVCaptureDevice>) {
                    if device.uniqueID == videoDeviceId {
                        videoDevice = device
                        break
                    }
                }
            }
            
            if videoDevice == nil {
                NSLog("PluginGetUserMedia#call() | video requested but no suitable device found")
                
                errback("no suitable camera device found")
                return
            }
            
            NSLog("PluginGetUserMedia#call() | chosen video device: %@", String(describing: videoDevice!))
            
//            rtcVideoCapturer = RTCVideoCapturer()
            // rtcVideoCapturer = RTCVideoCapturer(deviceName: videoDevice!.localizedName)
            
            if videoMinWidth > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [minWidth:%@]", String(videoMinWidth))
                // mandatoryConstraints.append(RTCPair(key: "minWidth", value: String(videoMinWidth)))
                mandatoryConstraints[kRTCMediaConstraintsMinWidth] = String(videoMinWidth)
            }
            if videoMaxWidth > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [maxWidth:%@]", String(videoMaxWidth))
                // mandatoryConstraints.append(RTCPair(key: "maxWidth", value: String(videoMaxWidth)))
                mandatoryConstraints[kRTCMediaConstraintsMaxWidth] = String(videoMaxWidth)
            }
            if videoMinHeight > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [minHeight:%@]", String(videoMinHeight))
                // mandatoryConstraints.append(RTCPair(key: "minHeight", value: String(videoMinHeight)))
                mandatoryConstraints[kRTCMediaConstraintsMinHeight] = String(videoMinHeight)
            }
            if videoMaxHeight > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [maxHeight:%@]", String(videoMaxHeight))
                // mandatoryConstraints.append(RTCPair(key: "maxHeight", value: String(videoMaxHeight)))
                mandatoryConstraints[kRTCMediaConstraintsMaxHeight] = String(videoMaxHeight)
            }
            if videoMinFrameRate > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [videoMinFrameRate:%@]", String(videoMinFrameRate))
                // mandatoryConstraints.append(RTCPair(key: "minFrameRate", value: String(videoMinFrameRate)))
                mandatoryConstraints[kRTCMediaConstraintsMinFrameRate] = String(videoMinFrameRate)
            }
            if videoMaxFrameRate > 0 {
                NSLog("PluginGetUserMedia#call() | adding media constraint [videoMaxFrameRate:%@]", String(videoMaxFrameRate))
                // mandatoryConstraints.append(RTCPair(key: "maxFrameRate", value: String(videoMaxFrameRate)))
                mandatoryConstraints[kRTCMediaConstraintsMaxFrameRate] = String(videoMaxFrameRate)
            }
            
            constraints = RTCMediaConstraints(
                mandatoryConstraints: mandatoryConstraints,
                optionalConstraints: [:]
            )
            
            if(rtcVideoSource == nil){
                rtcVideoSource = self.rtcPeerConnectionFactory.avFoundationVideoSource(with: constraints)
            }
            
            if(videoDevice != nil) {
                if (videoDevice!.position == AVCaptureDevice.Position.front) {
                    rtcVideoSource?.useBackCamera = true
                } else {
                    rtcVideoSource?.useBackCamera = false
                }
            }
            
            
            for output in (rtcVideoSource?.captureSession.outputs)! {
                if let videoOutput = output as? AVCaptureVideoDataOutput {
                    NSLog("+++ FOUND A VIDEO OUTPUT: \(videoOutput) -> \(videoOutput.sampleBufferDelegate)")
                    
//                    self.externalVideoBufferDelegate = videoOutput.sampleBufferDelegate
//                    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                    self.videoDataOutput = videoOutput
                }
            }
            
            // If videoSource state is "ended" it means that constraints were not satisfied so
            // invoke the given errback.
            if (rtcVideoSource!.state == RTCSourceState.ended) {
                NSLog("PluginGetUserMedia() | rtcVideoSource.state is 'ended', constraints not satisfied")
                
                errback("constraints not satisfied")
                return
            }
            
            rtcVideoTrack = self.rtcPeerConnectionFactory.videoTrack(with: rtcVideoSource!, trackId: UUID().uuidString)
            rtcMediaStream.addVideoTrack(rtcVideoTrack!)
        }
        
        if audioRequested == true {
            NSLog("PluginGetUserMedia#call() | audio requested")
            rtcAudioTrack = self.rtcPeerConnectionFactory.audioTrack(withTrackId: UUID().uuidString)
            rtcMediaStream.addAudioTrack(rtcAudioTrack!)
        }
        
        pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)
        pluginMediaStream!.run()
        
        // Let the plugin store it in its dictionary.
        eventListenerForNewStream(pluginMediaStream!)
        
        callback([
            "stream": pluginMediaStream!.getJSON()
            ])
    }
    
    func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if (self.isRecording) {
            if(assetWriterInput?.isReadyForMoreMediaData)! {
                assetWriterInput?.append(sampleBuffer)
            }
        }
        
        self.externalVideoBufferDelegate?.captureOutput!(output, didDrop: sampleBuffer, from: connection)
    }
    
    func startRecording(_ streamId: String) {
        if((self.externalVideoBufferDelegate) == nil) {
            self.externalVideoBufferDelegate = self.videoDataOutput?.sampleBufferDelegate
            self.videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        }
        
        let outputURL = NSURL(fileURLWithPath:NSHomeDirectory(), isDirectory: true).appendingPathComponent(NSString(format: "Library/NoCloud/%@%@", streamId, ".mp4") as String)
        
        let outputSettings: [String : AnyObject] = [
            AVVideoWidthKey : 480 as AnyObject,
            AVVideoHeightKey: 640 as AnyObject,
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject
        ]
        
        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterInput?.transform = CGAffineTransform( rotationAngle: CGFloat(( 90 * M_PI ) / 180))
        self.isRecording = true
        
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL!, fileType: AVFileType.mp4)
            assetWriter!.add(assetWriterInput!)
            assetWriterInput!.expectsMediaDataInRealTime = true
            
            assetWriter!.startWriting()
            assetWriter!.startSession(atSourceTime: CMTime.zero)
        }
        catch {
            print("[VideoManager]: Error persisting stream!")
        }
    }
    
    func stopRecording() {
        self.isRecording = false
        DispatchQueue.main.async(execute: { () -> Void in
            self.assetWriter!.finishWriting { () -> Void in
                self.assetWriter = nil
                self.assetWriterInput = nil
            }
        })
    }
    
    func terminate() {
        do {
            self.videoDataOutput?.setSampleBufferDelegate(nil, queue: DispatchQueue.main)
        }
        catch {
            print("[VideoManager]: Error killing stream!")
        }
    }
}

