// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import AVFoundation

public protocol VideoExtractorDelegate: AnyObject {
    func getVideoAndExtractFrames(_ processor: VideoExtractor, didFinishExtractingAllFrames allFrames: [String]?)
    func getVideoAndExtractFrames(_ processor: VideoExtractor, didFailWithError error: Error)
}

public class VideoExtractor: NSObject {
    public var delegate: VideoExtractorDelegate?
    
    public override init() {
        super.init()
    }
    
    public func getVideoAndReturnAllTheFrames(videoURL: String) {
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: videoURL) {
                if let allFrames = self.extractFramesFromVideo(at: url) {
                    DispatchQueue.main.async {
                        self.delegate?.getVideoAndExtractFrames(self, didFinishExtractingAllFrames: allFrames)
                    }
                } else {
                    let error = NSError(domain: "VideoExtractor", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al extraer los frames del video."])
                    DispatchQueue.main.async {
                        self.delegate?.getVideoAndExtractFrames(self, didFailWithError: error)
                    }
                }
            } else {
                let error = NSError(domain: "VideoExtractor", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL del video inválida."])
                DispatchQueue.main.async {
                    self.delegate?.getVideoAndExtractFrames(self, didFailWithError: error)
                }
            }
        }
    }
    
    private func extractFramesFromVideo(at videoURL: URL) -> [String]? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var frameURLs = [String]()
        
        do {
            let duration = asset.duration
            let durationInSeconds = CMTimeGetSeconds(duration)
            let desiredFPS: Double = 1.0
            let totalFrames = Int(durationInSeconds * desiredFPS)
            
            for i in 0..<totalFrames {
                let time = CMTime(seconds: Double(i) / desiredFPS, preferredTimescale: 600)
                
                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    let uiImage = UIImage(cgImage: cgImage)
                    let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent("StitchingSDK/frame\(i).jpg")
                    if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
                        try imageData.write(to: imageURL)
                        frameURLs.append(imageURL.absoluteString)
                    }
                }
            }
        } catch {
            print("Error al extraer los frames: \(error.localizedDescription)")
            return nil
        }
        
        return frameURLs
    }
}

