//
//  EyeTracker.swift
//  ARWhiteboard
//
//  Created by shriram siva on 10/03/25.
//

import ARKit

class EyeTracker {
    func getGazeDirection(from faceAnchor: ARFaceAnchor) -> SCNVector3 {
        let gazePoint = faceAnchor.lookAtPoint
        return SCNVector3(Float(gazePoint.x), Float(gazePoint.y), Float(gazePoint.z))
    }
}
