import Foundation
import WebRTC

class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints?

	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")
        
		if pcConstraints == nil {
            NSLog("NO CONSTRAINTS!")
			// self.constraints = RTCMediaConstraints
			
            self.constraints = RTCMediaConstraints.init(
                mandatoryConstraints: [
                    kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                    kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
                    ], optionalConstraints: nil
            )
            
            return
		}
        
		var	offerToReceiveAudio = pcConstraints?.object(forKey: "offerToReceiveAudio") as? Bool
		var	offerToReceiveVideo = pcConstraints?.object(forKey: "offerToReceiveVideo") as? Bool

		if offerToReceiveAudio == nil && offerToReceiveVideo == nil {
			// self.constraints = RTCMediaConstraints
			// return
		}

		if offerToReceiveAudio == nil {
			offerToReceiveAudio = false
		}

		if offerToReceiveVideo == nil {
			offerToReceiveVideo = false
		}

		NSLog("PluginRTCPeerConnectionConstraints#init() | [offerToReceiveAudio:%@, offerToReceiveVideo:%@]",
			String(offerToReceiveAudio!), String(offerToReceiveVideo!))

		self.constraints = RTCMediaConstraints.init(
			mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: offerToReceiveAudio == true ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse,
                kRTCMediaConstraintsOfferToReceiveVideo: offerToReceiveVideo == true ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
			],
			optionalConstraints: nil
		)
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConstraints#deinit()")
	}


	func getConstraints() -> RTCMediaConstraints {
		NSLog("PluginRTCPeerConnectionConstraints#getConstraints()")

        return self.constraints!
	}
}
