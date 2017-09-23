import Foundation
import WebRTC

class PluginRTCPeerConnectionConfig {
	fileprivate var iceServers: [RTCIceServer] = []

	init(pcConfig: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConfig#init()")

		let iceServers = pcConfig?.object(forKey: "iceServers") as? [NSDictionary]

		if iceServers == nil {
			return
		}

		for iceServer: NSDictionary in iceServers! {
			let url = iceServer.object(forKey: "url") as? String
			let username = iceServer.object(forKey: "username") as? String ?? ""
			let password = iceServer.object(forKey: "credential") as? String ?? ""

			if (url != nil) {
				NSLog("PluginRTCPeerConnectionConfig#init() | adding ICE server [url:'%@', username:'%@', password:'******']",
					String(url!), String(username))

				self.iceServers.append(RTCIceServer.init(
                    urlStrings: [url!],
					username: username,
					credential: password
				))
			}
		}
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConfig#deinit()")
	}


	func getIceServers() -> [RTCIceServer] {
		NSLog("PluginRTCPeerConnectionConfig#getIceServers()")

		return self.iceServers
	}
}
