//
//  ContentView.swift
//  BandwidthSwiftUISample
//
//  Created by user on 27.10.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VideoCallView()
        }
    }
}

struct VideoCallView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VideoView(
                    videoTrack: self.viewModel.remoteVideoTrack,
                    refreshVideoTrack: Binding<Bool>(
                        get: { return self.viewModel.refreshRemoteVideoTrack },
                        set: { p in
                            DispatchQueue.main.async {
                                self.viewModel.refreshRemoteVideoTrack = p
                            }
                        }
                    ),
                    backgroundColor: .secondarySystemBackground
                )
                
                VideoView(
                    videoTrack: self.viewModel.localVideoTrack,
                    refreshVideoTrack: Binding<Bool>(
                        get: { return self.viewModel.refreshLocalVideoTrack },
                        set: { p in
                            DispatchQueue.main.async {
                                self.viewModel.refreshLocalVideoTrack = p

                            }
                        }
                    ),
                    backgroundColor: .tertiarySystemBackground
                )
                .frame(width: geometry.size.width * 0.33, height: geometry.size.height * 0.33)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: viewModel.speaker ? "speaker.3.fill" : "speaker.wave.3")
                    .onTapGesture {
                        self.viewModel.toggleSpeaker()
                    }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                    self.viewModel.join()
                }
            }
        }
    }
}


