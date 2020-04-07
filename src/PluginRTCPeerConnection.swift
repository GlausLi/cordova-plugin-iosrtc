import Foundation
import WebRTC

class PluginRTCPeerConnection : NSObject, RTCPeerConnectionDelegate {
    
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory
	var rtcPeerConnection: RTCPeerConnection!
	var pluginRTCPeerConnectionConfig: PluginRTCPeerConnectionConfig
	var pluginRTCPeerConnectionConstraints: PluginRTCPeerConnectionConstraints
	// PluginRTCDataChannel dictionary.
	var pluginRTCDataChannels: [Int : PluginRTCDataChannel] = [:]
	// PluginRTCDTMFSender dictionary.
	var pluginRTCDTMFSenders: [Int : PluginRTCDTMFSender] = [:]
	var eventListener: (_ data: NSDictionary) -> Void
	var eventListenerForAddStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForRemoveStream: (_ id: String) -> Void
	var onCreateDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: Error) -> Void)!
	var onGetStatsCallback: ((_ array: NSArray) -> Void)!

	init(
		rtcPeerConnectionFactory: RTCPeerConnectionFactory,
		pcConfig: NSDictionary?,
		pcConstraints: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForAddStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForRemoveStream: @escaping (_ id: String) -> Void
	) {
		NSLog("PluginRTCPeerConnection#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
		self.pluginRTCPeerConnectionConfig = PluginRTCPeerConnectionConfig(pcConfig: pcConfig)
		self.pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: pcConstraints)
		self.eventListener = eventListener
		self.eventListenerForAddStream = eventListenerForAddStream
		self.eventListenerForRemoveStream = eventListenerForRemoveStream
	}


	deinit {
		NSLog("PluginRTCPeerConnection#deinit()")
		self.pluginRTCDTMFSenders = [:]
	}


	func run() {
		NSLog("PluginRTCPeerConnection#run()")

        let config = RTCConfiguration()
        config.iceServers = self.pluginRTCPeerConnectionConfig.getIceServers()
        config.iceTransportPolicy = RTCIceTransportPolicy.relay
        
		self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnection(
            with: config,
			constraints: self.pluginRTCPeerConnectionConstraints.getConstraints(),
			delegate: self
		)
	}


	func createOffer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createOffer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)
        
        self.rtcPeerConnection.offer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: { (rtcSessionDescription: RTCSessionDescription?, error: Error?) -> Void in
           NSLog("PluginRTCPeerConnection#createOffer() | success callback")
            
            if(rtcSessionDescription != nil) {
                let desc: RTCSessionDescription = rtcSessionDescription!
                let data = [
                    "type": RTCSessionDescription.string(for: desc.type),
                    "sdp": desc.sdp
                    ]
                
                callback(data as NSDictionary)
            }
        })
	}


	func createAnswer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)
        
        self.rtcPeerConnection.answer(for: pluginRTCPeerConnectionConstraints.getConstraints(), completionHandler: { (rtcSessionDescription: RTCSessionDescription?, error: Error?) -> Void in
            if(error == nil) {
                NSLog("PluginRTCPeerConnection#createAnswer() | success callback")
                
                let desc: RTCSessionDescription = rtcSessionDescription!
                let data = [
                    "type": RTCSessionDescription.string(for: desc.type),
                    "sdp": desc.sdp
                    ]
                
                callback(data as NSDictionary)
            } else {
                NSLog("PluginRTCPeerConnection#createAnswer() | failure callback: %@", String(describing: error))
            }
        })
	}


	func setLocalDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
		}
        
		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
        let rtcSessionDescription = RTCSessionDescription(type: RTCSessionDescription.type(for: type), sdp: sdp)
        
        self.rtcPeerConnection.setLocalDescription(rtcSessionDescription, completionHandler: { [unowned self] (error: Error?) -> Void in
            if(error == nil) {
                NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")
                
                let type : RTCSdpType = self.rtcPeerConnection.localDescription!.type
                let data = [
                    "type": RTCSessionDescription.string(for: type),
                    "sdp": self.rtcPeerConnection.localDescription?.sdp
                ]
                
                callback(data as NSDictionary)
            } else {
                NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@", String(describing: error))
            }
        })
	}


	func setRemoteDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: Error) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")
        
		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""

        let rtcSessionDescription = RTCSessionDescription(type: RTCSessionDescription.type(for: type), sdp: sdp)
        
        self.rtcPeerConnection.setRemoteDescription(rtcSessionDescription, completionHandler: { [unowned self] (error: Error?) -> Void in
            if(error == nil) {
                NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback ")
                
                let type : RTCSdpType = self.rtcPeerConnection.remoteDescription!.type
                let data = [
                    "type": RTCSessionDescription.string(for: type),
                    "sdp": self.rtcPeerConnection.remoteDescription?.sdp
                ]
                
                callback(data as NSDictionary)
            } else {
                NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: %@", String(describing: error))
            }
        })
	}


	func addIceCandidate(
		_ candidate: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: () -> Void
	) {
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
		}
       
		let sdpMid = candidate.object(forKey: "sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.object(forKey: "sdpMLineIndex") as? Int ?? 0
		let candidate = candidate.object(forKey: "candidate") as? String ?? ""

        self.rtcPeerConnection.add(RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: Int32(sdpMLineIndex),
            sdpMid: sdpMid
        ))
        
		var data: NSDictionary
		
        if self.rtcPeerConnection.remoteDescription != nil {
            let type : RTCSdpType = self.rtcPeerConnection.remoteDescription!.type
            data = [
                "remoteDescription": [
                    "type": RTCSessionDescription.string(for: type),
                    "sdp": self.rtcPeerConnection.remoteDescription?.sdp
                ]
            ]
        } else {
            data = [
                "remoteDescription": false
            ]
        }

        callback(data)		
	}


	func addStream(_ pluginMediaStream: PluginMediaStream) -> Bool {
		NSLog("PluginRTCPeerConnection#addStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return false
		}

        self.rtcPeerConnection.add(pluginMediaStream.rtcMediaStream)
		return true
	}


	func removeStream(_ pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
	}

    func mute(
        _ constraint: NSDictionary,
        callback: (_ data: NSDictionary) -> Void,
        errback: (_ error: Error) -> Void
        ) {
        NSLog("PluginRTCPeerConnection#mute()")
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        self.rtcPeerConnection.senders.forEach { (sender) in
            if sender.track?.kind == "video"{
                sender.track?.isEnabled = !(constraint.object(forKey: "video") as? Bool ?? false)
            }
            if sender.track?.kind == "audio"{
                sender.track?.isEnabled = !(constraint.object(forKey: "audio") as? Bool ?? false)
            }
        }
        let data: NSDictionary = [
            "result": true
        ]
        callback(data);
    }

    func switchcamera(
        _ pluginMediaStream: PluginMediaStream,
        callback: (_ data: NSDictionary) -> Void,
        errback: (_ error: Error) -> Void
        ) {
        NSLog("PluginRTCPeerConnection#switchcamera()")
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        
        let sender: RTCRtpSender = self.rtcPeerConnection.senders.filter{
            $0.track?.kind == pluginMediaStream.rtcMediaStream.videoTracks[0].kind
            }.first!
        sender.track = pluginMediaStream.rtcMediaStream.videoTracks[0]
        
        let audiosender: RTCRtpSender = self.rtcPeerConnection.senders.filter{
            $0.track?.kind == pluginMediaStream.rtcMediaStream.audioTracks[0].kind
            }.first!
        audiosender.track = pluginMediaStream.rtcMediaStream.audioTracks[0]
        
        let data: NSDictionary = [
            "result": true
        ]
        callback(data);
    }
    
	func createDataChannel(
		_ dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcPeerConnection: rtcPeerConnection,
			label: label,
			options: options,
			eventListener: eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()
	}


	func RTCDataChannel_setListener(
		_ dcId: Int,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: Data) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_setListener()")

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		// Set the eventListener.
		pluginRTCDataChannel!.setListener(eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)
	}


	func createDTMFSender(
		_ dsId: Int,
		track: PluginMediaStreamTrack,
		eventListener: @escaping (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDTMFSender()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDTMFSender = PluginRTCDTMFSender(
			rtcPeerConnection: rtcPeerConnection,
			track: track.rtcMediaStreamTrack,
			eventListener: eventListener
		)

		// Store the pluginRTCDTMFSender into the dictionary.
		self.pluginRTCDTMFSenders[dsId] = pluginRTCDTMFSender

		// Run it.
		pluginRTCDTMFSender.run()
	}

	func getStats(
		_ pluginMediaStreamTrack: PluginMediaStreamTrack?,
		callback: @escaping (_ data: NSArray) -> Void,
		errback: (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#getStats()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.onGetStatsCallback = { (array: NSArray) -> Void in
			callback(array)
		}
        
//        self.rtcPeerConnection.stats(for: pluginMediaStreamTrack?.rtcMediaStreamTrack, statsOutputLevel: RTCStatsOutputLevel.standard)
    }

	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.close()
	}


	func RTCDataChannel_sendString(
		_ dcId: Int,
		data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendString(data, callback: callback)
	}


	func RTCDataChannel_sendBinary(
		_ dcId: Int,
		data: Data,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendBinary()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendBinary(data, callback: callback)
	}


	func RTCDataChannel_close(_ dcId: Int) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.close()

		// Remove the pluginRTCDataChannel from the dictionary.
		self.pluginRTCDataChannels[dcId] = nil
	}


	func RTCDTMFSender_insertDTMF(
		_ dsId: Int,
		tones: String,
		duration: Int,
		interToneGap: Int
	) {
		NSLog("PluginRTCPeerConnection#RTCDTMFSender_insertDTMF()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDTMFSender = self.pluginRTCDTMFSenders[dsId]
		if pluginRTCDTMFSender == nil {
			return
		}

		pluginRTCDTMFSender!.insertDTMF(tones, duration: duration, interToneGap: interToneGap)
	}


	/**
	 * Methods inherited from RTCPeerConnectionDelegate.
	 */

    
    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didChange newState: RTCSignalingState) {
        let state_str = PluginRTCTypes.signalingStates[newState.rawValue] as String?

		NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "signalingstatechange",
			"signalingState": state_str as Any
		])
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		iceGatheringChanged newState: RTCIceGatheringState) {
        let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue] as String?

		NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "icegatheringstatechange",
			"iceGatheringState": state_str
		])

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		// Emit an empty candidate if iceGatheringState is "complete".
		if newState.rawValue == RTCIceGatheringState.complete.rawValue && self.rtcPeerConnection.localDescription != nil {
            let type : RTCSdpType = self.rtcPeerConnection.localDescription!.type
			self.eventListener([
				"type": "icecandidate",
				// NOTE: Cannot set null as value.
				"candidate": false,
				"localDescription": [
					"type": RTCSessionDescription.string(for: type),
					"sdp": self.rtcPeerConnection.localDescription?.sdp
				]
			])
		}
	}

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:%@, sdpMLineIndex:%@, candidate:%@]",
              String(describing: candidate.sdpMid), String(candidate.sdpMLineIndex), String(candidate.sdp))
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        
        let type : RTCSdpType = self.rtcPeerConnection.localDescription!.type
        self.eventListener([
            "type": "icecandidate",
            "candidate": [
                "sdpMid": candidate.sdpMid,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "candidate": candidate.sdp
            ],
            "localDescription": [
                "type": RTCSessionDescription.string(for: type),
                "sdp": self.rtcPeerConnection.localDescription?.sdp
            ]
            ])
    }

	func peerConnection(_ peerConnection: RTCPeerConnection!,
		iceConnectionChanged newState: RTCIceConnectionState) {
        let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue] as String?

		NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))

		self.eventListener([
			"type": "iceconnectionstatechange",
			"iceConnectionState": state_str as Any
		])
	}

	func peerConnection(_ rtcPeerConnection: RTCPeerConnection,
		addedStream rtcMediaStream: RTCMediaStream) {
		NSLog("PluginRTCPeerConnection | onaddstream")

		let pluginMediaStream = PluginMediaStream(rtcMediaStream: rtcMediaStream)

		pluginMediaStream.run()

		// Let the plugin store it in its dictionary.
		self.eventListenerForAddStream(pluginMediaStream)

		// Fire the 'addstream' event so the JS will create a new MediaStream.
		self.eventListener([
			"type": "addstream",
			"stream": pluginMediaStream.getJSON()
		])
	}


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		removedStream rtcMediaStream: RTCMediaStream!) {
		NSLog("PluginRTCPeerConnection | onremovestream")

		// Let the plugin remove it from its dictionary.
		self.eventListenerForRemoveStream(rtcMediaStream.streamId)

		self.eventListener([
			"type": "removestream",
			"streamId": rtcMediaStream.streamId  // NOTE: No "id" property yet.
		])
	}


	func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		self.eventListener([
			"type": "negotiationneeded"
		])
	}


    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didOpen rtcDataChannel: RTCDataChannel) {
		NSLog("PluginRTCPeerConnection | ondatachannel")

		let dcId = PluginUtils.randomInt(10000, max:99999)
		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcDataChannel: rtcDataChannel
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()

		// Fire the 'datachannel' event so the JS will create a new RTCDataChannel.
		self.eventListener([
			"type": "datachannel",
			"channel": [
				"dcId": dcId,
				"label": rtcDataChannel.label,
				"ordered": rtcDataChannel.isOrdered,
				"maxPacketLifeTime": rtcDataChannel.maxRetransmitTime,
				"maxRetransmits": rtcDataChannel.maxRetransmits,
				"protocol": rtcDataChannel.`protocol`,
				"negotiated": rtcDataChannel.isNegotiated,
				"id": rtcDataChannel.streamId,
                "readyState": PluginRTCTypes.dataChannelStates[rtcDataChannel.readyState.rawValue] as String?,
				"bufferedAmount": rtcDataChannel.bufferedAmount
			]
		])
	}


	/**
	 * Methods inherited from RTCSessionDescriptionDelegate.
	 */


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		didCreateSessionDescription rtcSessionDescription: RTCSessionDescription!, error: Error!) {
		if error == nil {
			self.onCreateDescriptionSuccessCallback(rtcSessionDescription)
		} else {
			self.onCreateDescriptionFailureCallback(error)
		}
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didSetSessionDescriptionWithError error: Error!) {
		if error == nil {
			self.onSetDescriptionSuccessCallback()
		} else {
			self.onSetDescriptionFailureCallback(error)
		}
	}

	/**
	* Methods inherited from RTCStatsDelegate
	*/
    
	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didGetStats stats: [Any]!) {
        /*
		var jsStats = [NSDictionary]()

		for stat in stats as NSArray {
			var jsValues = Dictionary<String,String>()

			for pair in (stat as AnyObject).values as! [RTCPair] {
				jsValues[pair.key] = pair.value;
			}

			jsStats.append(["reportId": (stat as! RTCStatsReport).reportId, "type": (stat as! RTCStatsReport).type, "timestamp": (stat as! RTCStatsReport).timestamp, "values": jsValues]);

		}*/

		//self.onGetStatsCallback(jsStats);
	}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue] as String?
        
        NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))
        
        self.eventListener([
            "type": "iceconnectionstatechange",
            "iceConnectionState": state_str as Any
            ])
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        NSLog("peerConnection:didRemove candidates")
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue] as String?
        
        NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))
        
        self.eventListener([
            "type": "icegatheringstatechange",
            "iceGatheringState": state_str as Any
            ])
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        
        // Emit an empty candidate if iceGatheringState is "complete".
        if newState.rawValue == RTCIceGatheringState.complete.rawValue && self.rtcPeerConnection.localDescription != nil {
            self.eventListener([
                "type": "icecandidate",
                // NOTE: Cannot set null as value.
                "candidate": false,
                "localDescription": [
                    "type": RTCSessionDescription.string(for: (self.rtcPeerConnection.localDescription?.type)!),
                    "sdp": self.rtcPeerConnection.localDescription?.sdp
                ]
                ])
        }
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        NSLog("peerConnectionShouldNegotiate")
        
        self.eventListener([
            "type": "negotiationneeded"
            ])
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        NSLog("peerConnection:didAdd stream")
        
        let pluginMediaStream = PluginMediaStream(rtcMediaStream: stream)
        
        pluginMediaStream.run()
        
        // Let the plugin store it in its dictionary.
        self.eventListenerForAddStream(pluginMediaStream)
        
        // Fire the 'addstream' event so the JS will create a new MediaStream.
        self.eventListener([
            "type": "addstream",
            "stream": pluginMediaStream.getJSON()
            ])
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        NSLog("peerConnection:didRemove stream")
        
        // Let the plugin remove it from its dictionary.
        self.eventListenerForRemoveStream(stream.streamId)
        
        self.eventListener([
            "type": "removestream",
            "streamId": stream.streamId  // NOTE: No "id" property yet.
            ])
    }
}
