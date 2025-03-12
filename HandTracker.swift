import Vision
import SceneKit

class HandTracker {
    var lastDrawnPoint: SCNVector3?

    func detectHandGestures(from pixelBuffer: CVPixelBuffer, in whiteboard: SCNNode) {
        let request = VNDetectHumanHandPoseRequest { request, _ in
            guard let observations = request.results as? [VNHumanHandPoseObservation],
                  let firstHand = observations.first else { return }
            
            do {
                if let indexFinger = try firstHand.recognizedPoints(.all)[.indexTip] {
                    let visionPoint = indexFinger.location
                    let currentPoint = self.convertVisionPointToWhiteboard(visionPoint, whiteboard: whiteboard)

                    if let lastPoint = self.lastDrawnPoint {
                        let lineNode = self.createLineNode(from: lastPoint, to: currentPoint)
                        whiteboard.addChildNode(lineNode)
                    }

                    self.lastDrawnPoint = currentPoint
                }
            } catch {}
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? requestHandler.perform([request])
    }

    func convertVisionPointToWhiteboard(_ point: CGPoint, whiteboard: SCNNode) -> SCNVector3 {
        let whiteboardWidth: Float = 1.0
        let whiteboardHeight: Float = 0.5

        let mappedX = (Float(point.x) - 0.5) * whiteboardWidth
        let mappedY = (0.5 - Float(point.y)) * whiteboardHeight

        return SCNVector3(mappedX, mappedY, 0)
    }

    func createLineNode(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let line = SCNGeometry.createLine(from: start, to: end)
        let node = SCNNode(geometry: line)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red  // Default color
        return node
    }
}

// ✅ MOVE THIS OUTSIDE THE CLASS! ✅
extension SCNGeometry {
    static func createLine(from start: SCNVector3, to end: SCNVector3) -> SCNGeometry {
        let vertices: [SCNVector3] = [start, end]
        let vertexSource = SCNGeometrySource(vertices: vertices)

        let indices: [Int32] = [0, 1]
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: 1, bytesPerIndex: MemoryLayout<Int32>.size)

        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
