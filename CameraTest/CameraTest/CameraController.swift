//
//  CameraController.swift
//  CameraTest
//
//  Created by Emmanuel Olivo on 10/04/18.
//  Copyright © 2018 Con Dos Emes. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraController {
    
    // MARK: Variables
    
    // Session
    var captureSession: AVCaptureSession?
    
    // Cameras
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    
    // Camera Position
    var currentCameraPosition: CameraPosition?
    
    // Camera Inputs
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    
    // Session Output
    var photoOutput: AVCapturePhotoOutput?
    
    // Preview
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Flash Mode
    var flashMode = AVCaptureDevice.FlashMode.off
    
    // Possible Errors
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    // Define CameraPosition
    public enum CameraPosition {
        case front
        case rear
    }
    
    
    // MARK: Functions
    
    // Prepare capture session for use
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            
           // Get Cameras of the device and append them to array
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified) as? AVCaptureDevice.DiscoverySession
            
            guard let cameras = (session?.devices.compactMap { $0 }), !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
           
            // Search for camera types
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        
        func configureDeviceInputs() throws {
            
            // Make sure there is a capture session
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            // If it is possible to create rear camera input do the configuration
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                
                self.currentCameraPosition = .rear
                
            }
            
                // If it is not possible, try to create front camera input and configure
            else if let frontCamera = self.frontCamera {
                
                
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                else { throw CameraControllerError.inputsAreInvalid }
                
                self.currentCameraPosition = .front
            }
                
                // If neither camera input can be created throw an error
            else { throw CameraControllerError.noCamerasAvailable }
            
        }
        
        
        func configurePhotoOutput() throws {
            
            // Make sure there is a capture session
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            // Configure photo output with jpeg codec type
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            
            // Add photoOutput to capture session
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            
            // Start capture session
            captureSession.startRunning()
        }
        
        
        // Call all functions for the session
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    
    // Display camera preview on screen
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    // Switch cameras
    func switchCameras() throws {
        
        // Verify current camera position
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        
        captureSession.beginConfiguration()
        
        func switchToFrontCamera() throws {
            
            guard let inputs = captureSession.inputs as? [AVCaptureInput], let rearCameraInput = self.rearCameraInput, inputs.contains(rearCameraInput),
                let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.removeInput(rearCameraInput)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                
                self.currentCameraPosition = .front
            }
                
            else { throw CameraControllerError.invalidOperation }
        }
        
        func switchToRearCamera() throws {
            guard let inputs = captureSession.inputs as? [AVCaptureInput], let frontCameraInput = self.frontCameraInput, inputs.contains(frontCameraInput),
                let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            captureSession.removeInput(frontCameraInput)
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                
                self.currentCameraPosition = .rear
            }
                
            else { throw CameraControllerError.invalidOperation }
        }
        
        //Switch cameras depending on which one is active
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
            
        case .rear:
            try switchToFrontCamera()
        }
        
        // Save capture feature
        captureSession.commitConfiguration()
        
    }
}

