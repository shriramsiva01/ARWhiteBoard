//
//  ViewController.swift
//  ARWhiteboard
//
//  Created by shriram siva on 11/03/25.


import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var whiteboard: SCNNode!
    var eyeTracker = EyeTracker()
    var handTracker = HandTracker()
    
    var isDrawing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            view.addGestureRecognizer(pinchGesture)//pinch gestures
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(resetWhiteboard))
            doubleTapGesture.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTapGesture)
        
        // Set ARSCNView delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.scene = SCNScene()

        // Set up AR Whiteboard
        setupWhiteboard()
        configureARSession()
        addResetButton()
        addUIElements()
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            isDrawing = true
        } else if gesture.state == .ended {
            isDrawing = false
        }
    }
    
    
    @objc func resetWhiteboard() {
        for child in whiteboard.childNodes {
            child.removeFromParentNode()
        }
    }

    
    func convertVisionPointToWhiteboard(_ point: CGPoint, whiteboard: SCNNode) -> SCNVector3 {
        let whiteboardWidth: Float = 1.0
        let whiteboardHeight: Float = 0.5
        
        let mappedX = (Float(point.x) - 0.5) * whiteboardWidth
        let mappedY = (0.5 - Float(point.y)) * whiteboardHeight  // Invert Y-axis
        
        return SCNVector3(mappedX, mappedY, 0)
    }
    
    var selectedColor: UIColor = .red  // Default

    func addColorButtons() {
        let colors: [UIColor] = [.red, .blue, .green, .black]
        let buttonSize: CGFloat = 40
        let spacing: CGFloat = 10

        for (index, color) in colors.enumerated() {
            let button = UIButton(frame: CGRect(x: 20 + CGFloat(index) * (buttonSize + spacing), y: 100, width: buttonSize, height: buttonSize))
            button.backgroundColor = color
            button.layer.cornerRadius = buttonSize / 2
            button.addTarget(self, action: #selector(changeColor(_:)), for: .touchUpInside)
            self.view.addSubview(button)
        }
    }

    @objc func changeColor(_ sender: UIButton) {
        selectedColor = sender.backgroundColor ?? .red
    }

    
    func addUIElements() {
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("🧹 Clear Board", for: .normal)
        clearButton.backgroundColor = UIColor.systemBlue
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 10
        clearButton.frame = CGRect(x: 20, y: 50, width: 150, height: 50)
        
        // Add action
        clearButton.addTarget(self, action: #selector(resetWhiteboard), for: .touchUpInside)
        
        // Add shadow effect for a more modern UI look
        clearButton.layer.shadowColor = UIColor.black.cgColor
        clearButton.layer.shadowOpacity = 0.3
        clearButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        clearButton.layer.shadowRadius = 5
        
        self.view.addSubview(clearButton)
    }
    
    func addResetButton() {
        let resetButton = UIButton(type: .system)
            resetButton.setTitle("Reset", for: .normal)
            resetButton.backgroundColor = UIColor.white
            resetButton.setTitleColor(.black, for: .normal)
            resetButton.layer.cornerRadius = 10
            resetButton.frame = CGRect(x: 20, y: 50, width: 100, height: 40)
            
            // Add action when button is tapped
            resetButton.addTarget(self, action: #selector(resetWhiteboard), for: .touchUpInside)
            
            // Add to the view
            self.view.addSubview(resetButton)
    }
    
    
    func configureARSession() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device")
            return
        }

        let configuration = ARFaceTrackingConfiguration()  // Use front camera
        sceneView.session.run(configuration)
    }

    func setupWhiteboard() {
        let plane = SCNPlane(width: 1.0, height: 0.5)
        plane.firstMaterial?.diffuse.contents = UIColor.white
        whiteboard = SCNNode(geometry: plane)
        whiteboard.position = SCNVector3(0, 0, -0.5)  // Place near user's face
        sceneView.scene.rootNode.addChildNode(whiteboard)
    }

    // Eye Tracking: Move Whiteboard Based on Gaze
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if let faceAnchor = anchors.first as? ARFaceAnchor {
            let gazeDirection = eyeTracker.getGazeDirection(from: faceAnchor)
            whiteboard.position.x = gazeDirection.x
        }
    }

    // Hand Gesture Detection for Drawing
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        handTracker.detectHandGestures(from: frame.capturedImage, in: whiteboard)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}
