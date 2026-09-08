import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct NativeCameraPicker: UIViewControllerRepresentable {
    let onCapture:(UIImage)->Void
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator()->Coordinator{Coordinator(self)}
    func makeUIViewController(context:Context)->UIImagePickerController{let picker=UIImagePickerController();picker.sourceType = .camera;picker.cameraCaptureMode = .photo;picker.delegate=context.coordinator;return picker}
    func updateUIViewController(_ controller:UIImagePickerController,context:Context){}
    final class Coordinator:NSObject,UINavigationControllerDelegate,UIImagePickerControllerDelegate{let parent:NativeCameraPicker;init(_ p:NativeCameraPicker){parent=p};func imagePickerControllerDidCancel(_ picker:UIImagePickerController){parent.dismiss()};func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey:Any]){if let image=info[.originalImage] as? UIImage{parent.onCapture(image)};parent.dismiss()}}
}

@MainActor enum CameraAuthorization {
    static func request() async -> Result<Void,PhotoGenerationFailure> {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else{return .failure(.cameraUnavailable)}
        switch AVCaptureDevice.authorizationStatus(for:.video){case .authorized:return .success(());case .notDetermined:return await AVCaptureDevice.requestAccess(for:.video) ? .success(()):.failure(.cameraDenied);case .denied,.restricted:return .failure(.cameraDenied);@unknown default:return .failure(.cameraUnavailable)}
    }
}

struct SquareCropView: View {
    let image:UIImage; let confirm:(UIImage)->Void
    @Environment(\.dismiss) private var dismiss
    @State private var resetToken=0
    var body:some View{NavigationStack{VStack(spacing:18){SquareZoomSurface(image:image,resetToken:resetToken){cropped in confirm(cropped);dismiss()}.aspectRatio(1,contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:24));Text("Pinch to zoom and drag to place your subject inside the square.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center);HStack{Button("Reset"){resetToken += 1}.buttonStyle(.bordered);Button("Use This Crop"){NotificationCenter.default.post(name:.captureSquareCrop,object:nil)}.buttonStyle(.borderedProminent).tint(Color.artInk)}}.padding().background(Color.artPaper).navigationTitle("Position Photo").navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.topBarLeading){Button("Cancel"){dismiss()}}}}}
}
extension Notification.Name { static let captureSquareCrop=Notification.Name("captureSquareCrop") }
struct SquareZoomSurface:UIViewRepresentable {
    let image:UIImage;let resetToken:Int;let onCrop:(UIImage)->Void
    func makeCoordinator()->Coordinator{Coordinator(onCrop)}
    func makeUIView(context:Context)->UIScrollView{let s=UIScrollView();s.delegate=context.coordinator;s.minimumZoomScale=1;s.maximumZoomScale=5;s.bouncesZoom=true;s.clipsToBounds=true;s.backgroundColor = .black;let iv=context.coordinator.imageView;iv.image=image;iv.contentMode = .scaleAspectFill;s.addSubview(iv);context.coordinator.observer=NotificationCenter.default.addObserver(forName:.captureSquareCrop,object:nil,queue:.main){[weak s] _ in if let s{context.coordinator.crop(scroll:s)}};return s}
    func updateUIView(_ s:UIScrollView,context:Context){let side=min(s.bounds.width,s.bounds.height);guard side>0 else{return};let imageSize=image.size,scale=max(side/imageSize.width,side/imageSize.height);let fitted=CGSize(width:imageSize.width*scale,height:imageSize.height*scale);context.coordinator.imageView.frame=CGRect(origin:.zero,size:fitted);s.contentSize=fitted;if context.coordinator.lastReset != resetToken{context.coordinator.lastReset=resetToken;s.zoomScale=1;s.contentOffset=CGPoint(x:max(0,(fitted.width-side)/2),y:max(0,(fitted.height-side)/2))}}
    static func dismantleUIView(_ uiView:UIScrollView,coordinator:Coordinator){if let o=coordinator.observer{NotificationCenter.default.removeObserver(o)}}
    final class Coordinator:NSObject,UIScrollViewDelegate{let imageView=UIImageView();let onCrop:(UIImage)->Void;var observer:NSObjectProtocol?;var lastReset = -1;init(_ crop:@escaping(UIImage)->Void){onCrop=crop};func viewForZooming(in scrollView:UIScrollView)->UIView?{imageView};func crop(scroll:UIScrollView){let renderer=UIGraphicsImageRenderer(size:CGSize(width:1536,height:1536));let result=renderer.image{ctx in let scale=1536/scroll.bounds.width;ctx.cgContext.scaleBy(x:scale,y:scale);scroll.layer.render(in:ctx.cgContext)};onCrop(result)}}
}
