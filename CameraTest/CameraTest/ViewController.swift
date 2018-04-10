//
//  ViewController.swift
//  CameraTest
//
//  Created by Emmanuel Olivo on 10/04/18.
//  Copyright © 2018 Con Dos Emes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var photoModeButton: UIButton!
    @IBOutlet weak var videoModeButton: UIButton!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    
    // MARK: Variables
    
    let cameraController = CameraController()
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool { return true }

    
    // MARK: Actions
    
    // MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureButton()
        configureCameraController()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Function to set button as a circle
    func setupCaptureButton() {
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
    }
    

    // Configure the preview
    func configureCameraController() {
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
            
            try? self.cameraController.displayPreview(on: self.captureView)
        }
    }
    


}

