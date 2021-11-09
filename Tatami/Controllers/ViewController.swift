//
//  ViewController.swift
//  Tatami
//
//  Created by Layne Johnson on 9/25/21.
//

import UIKit
import SceneKit
import ARKit

// TODO: AddARCoachingOverlayView

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var diceArray = [SCNNode]()
    
    // MARK: - IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show plane detection feature points.
        //        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate.
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information.
        sceneView.showsStatistics = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Verify device support.
        if ARConfiguration.isSupported {
            
            print("Success! ARKit is supported on this device.")
            
            // Create a session configuration.
            let configuration = ARWorldTrackingConfiguration()
            
            // Enable horizontal plane detection.
            configuration.planeDetection = .horizontal
            
            // Run the view's session.
            sceneView.session.run(configuration)
            
        } else {
            
            print("Sorry :( This experience is not supported on this device.")
            
            // Configure alert.
            let alert = UIAlertController(title: "Sorry! 😕", message: " Tatami AR is not supported on this device.", preferredStyle: .alert)
            
            // Configure alert action.
            let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
            
            // Add action to alert.
            alert.addAction(action)
            
            // Present alert to user.
            present(alert, animated: true, completion: nil)
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session.
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    // MARK: - ARSession
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            // 2D touch coordinate.
            let touchLocation = touch.location(in: sceneView)
            
            // Convert 2D location to position in 3D space.
            guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .any) else {
                return
            }
            
            let results = sceneView.session.raycast(query)
            
            if let hitResult = results.first {
                
                // Create a new scene.
                let diceScene = SCNScene(named: "art.scnassets/Dice Model/diceCollada.scn")!
                
                // Create node.
                if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
                    
                    // Set node position in 3D space.
                    diceNode.position = SCNVector3(
                        x: hitResult.worldTransform.columns.3.x,
                        y: hitResult.worldTransform.columns.3.y + diceNode.boundingSphere.radius * 3,
                        z: hitResult.worldTransform.columns.3.z
                    )
                    
                    // Add dice nodes to dice array.
                    diceArray.append(diceNode)
                    
                    // Add node to scene.
                    sceneView.scene.rootNode.addChildNode(diceNode)
                    
                    // Automatically adjust lighting in scene.
                    sceneView.automaticallyUpdatesLighting = true
                    
                    roll(dice: diceNode)
                }
            }
        }
    }
    
    // MARK: - Dice Functions
    
    func rollAll() {
        for dice in diceArray {
            roll(dice: dice)
        }
    }
    
    func roll(dice: SCNNode) {
        
        // Animate dice.
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        dice.runAction(SCNAction.rotateBy(
                        x: CGFloat(randomX),
                        y: 0,
                        z: CGFloat(randomZ),
                        duration: 0.5)
        )
        
        // TODO: Add haptic feedback on dice roll. Create haptic engine.
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        rollAll()
    }
    
    func removeAllDice() {
        for dice in diceArray {
            dice.removeFromParentNode()
        }
    }
    
    // MARK: - SCNSceneRenderer Plane Detection
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This code is triggered when a horizontal plane is detected.
        
        if anchor is ARPlaneAnchor {
            
            let planeAnchor = anchor as! ARPlaneAnchor
            
            // Convert the dimensions of anchor into scene plane.
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            
            // Create plane node.
            let planeNode = SCNNode()
            
            // Position node.
            planeNode.position = SCNVector3(planeAnchor.center.y, 0, planeAnchor.center.z)
            
            // Transform plane node.
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            
            // TODO: Replace material with 3D tatami model.
            
            // Create material object.
            let gridMaterial = SCNMaterial()
            
            // Tatami mat images.
            let tatamiMat = UIImage(named: "art.scnassets/Materials/tatami_mat.jpg")
            let tatamiImagePlaceholder = UIImage(named: "art.scnassets/Materials/tatami_border.jpeg")
            
            // Define material contents.
            if tatamiMat != nil {
                gridMaterial.diffuse.contents = tatamiMat
            } else {
                gridMaterial.diffuse.contents = tatamiImagePlaceholder
            }
            
            // Add materials to plane.
            plane.materials = [gridMaterial]
            
            // Set node geometry
            planeNode.geometry = plane
            
            // Add node to scene
            node.addChildNode(planeNode)
            
        } else {
            return
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func replay(_ sender: UIBarButtonItem) {
        removeAllDice()
    }
    
    @IBAction func rollAgainPressed(_ sender: UIBarButtonItem) {
        
        rollAll()
    }
}

