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
    
    public func getVideoAndReturnAllTheFrames(videoURL: String, selectTimeValue: Int) {
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: videoURL) {
                if let allFrames = self.extractFramesFromVideo(at: url, selectTimeValue: selectTimeValue) {
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
    
    private func extractFramesFromVideo(at videoURL: URL, selectTimeValue: Int) -> [String]? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var frameURLs = [String]()
        
        do {
            let duration = asset.duration
            let durationInSeconds = CMTimeGetSeconds(duration)
            
            var desiredFrames: Int
            
            if durationInSeconds < 5 {
                desiredFrames = Int(durationInSeconds) * 5 // 5 frames por segundo
            } else if durationInSeconds >= 5 && durationInSeconds < 10 {
                desiredFrames = 12 // Alrededor de 12 fotogramas
            } else if durationInSeconds >= 10 && durationInSeconds < 15 {
                desiredFrames = 15 // Alrededor de 15 fotogramas
            } else if durationInSeconds >= 15 && durationInSeconds < 20 {
                desiredFrames = 20 // Alrededor de 20 fotogramas
            } else if durationInSeconds >= 20 && durationInSeconds <= 35 {
                desiredFrames = Int(durationInSeconds) // Un fotograma por segundo
            } else {
                desiredFrames = 35 // Hasta un máximo de 35 fotogramas
            }
            
            // Limitar la cantidad máxima de fotogramas a 35
            if desiredFrames > 35 {
                desiredFrames = 35
            }
            
            for i in 0..<desiredFrames {
                let time = CMTime(seconds: durationInSeconds * Double(i) / Double(desiredFrames), preferredTimescale: 600)
                
                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    let uiImage = UIImage(cgImage: cgImage)
                    let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent("StitchingSDK/frame\(i).jpg")
                    if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
                        try imageData.write(to: imageURL)
                        frameURLs.append(imageURL.absoluteString)
                    }
                }
            }
            //            let duration = asset.duration
            //            let durationInSeconds = CMTimeGetSeconds(duration)
            //
            //            let desiredFPS: Double = 1.0
            //
            //            let totalFrames = Int(durationInSeconds * desiredFPS)
            //
            //            var framesTaken = 0 // Track the number of frames taken
            //
            //            var desiredFrames: Int
            //
            //            if durationInSeconds < 5 {
            //                desiredFrames = Int(durationInSeconds) * 5 // 5 frames por segundo
            //            } else if durationInSeconds >= 5 && durationInSeconds < 10 {
            //                desiredFrames = 12 // Alrededor de 12 fotogramas
            //            } else if durationInSeconds >= 10 && durationInSeconds < 15 {
            //                desiredFrames = 15 // Alrededor de 15 fotogramas
            //            } else if durationInSeconds >= 15 && durationInSeconds < 20 {
            //                desiredFrames = 20 // Alrededor de 20 fotogramas
            //            } else if durationInSeconds >= 20 && durationInSeconds < 25 {
            //                desiredFrames = 25 // Alrededor de 25 fotogramas
            //            } else if durationInSeconds >= 25 && durationInSeconds <= 35 {
            //                desiredFrames = Int(durationInSeconds) // Un fotograma por segundo
            //            } else {
            //                desiredFrames = 35 // Hasta un máximo de 35 fotogramas
            //            }
            //
            //            if desiredFrames > 35 {
            //                desiredFrames = 35 // Limitar la cantidad máxima de fotogramas a 35
            //            }
            //
            //            for i in 0..<desiredFrames {
            //                let time = CMTime(seconds: Double(i) / Double(desiredFrames), preferredTimescale: 600)
            //
            //                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
            //                    let uiImage = UIImage(cgImage: cgImage)
            //                    let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent("StitchingSDK/frame\(i).jpg")
            //                    if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
            //                        try imageData.write(to: imageURL)
            //                        frameURLs.append(imageURL.absoluteString)
            //                    }
            //                }
            //            }
        } catch {
            print("Error al extraer los frames: \(error.localizedDescription)")
            return nil
        }
        
        return frameURLs
    }
}

