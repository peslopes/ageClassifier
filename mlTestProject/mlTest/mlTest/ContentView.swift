//
//  ContentView.swift
//  mlTest
//
//  Created by Pedro Lopes on 18/04/20.
//  Copyright © 2020 Pedro Lopes. All rights reserved.
//

import SwiftUI
import CoreML

struct ContentView: View {
    
    @State private var showImagePicker : Bool = false
    @State private var image : UIImage? = nil
    
    var body: some View {
        NavigationView{
            
            VStack {
                
                self.detectImage(image: image)
                Image(uiImage: image ?? UIImage()).resizable()
                
                Button("Open Camera"){
                    self.showImagePicker = true
                }.padding()
                .foregroundColor(Color.white)
                .background(Color.purple)
                .cornerRadius(10)
            }.sheet(isPresented: self.$showImagePicker){
                PhotoCaptureView(showImagePicker: self.$showImagePicker, image: self.$image)
            }
            
            .navigationBarTitle(Text("Camera"))
        }
    }
    
    func detectImage(image: UIImage?) -> Text {

        let model = elderReconizer_1()
        guard let image = image else {
            return Text("")
        }
        guard let buffer = self.buffer(from: image) else {
            return Text("")
        }
        guard let prediction = try? model.prediction(image: buffer) else {
            return Text("")
        }
        return Text(prediction.classLabel)

    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
}

struct ImagePicker : UIViewControllerRepresentable {
    
    @Binding var isShown    : Bool
    @Binding var image      : UIImage?
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> ImagePickerCordinator {
        return ImagePickerCordinator(isShown: $isShown, image: $image)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
}

class ImagePickerCordinator : NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    @Binding var isShown    : Bool
    @Binding var image      : UIImage?
    
    init(isShown : Binding<Bool>, image: Binding<UIImage?>) {
        _isShown = isShown
        _image   = image
    }
    
    //Selected Image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        isShown = false
    }
    
    //Image selection got cancel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShown = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
