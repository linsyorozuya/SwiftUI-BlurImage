//
//  AppState.swift
//  BlurPIc
//
//  Created by linhui on 2020/5/19.
//  Copyright © 2020 linhui. All rights reserved.
//
import SwiftUI
import Combine
import CoreImage

class Store: ObservableObject {
    @Published var appState = AppState()
    var disposeBag = [AnyCancellable]()
    
    init() {
        // 订阅状态变化
        self.appState.filter.isFilterChange.sink { () in
            self.dispatch(action: .addCIGaussianBlurAndCIColorControls)
        }.store(in: &disposeBag)
    }
    
    static func reduce(state: AppState, action: AppAction) -> (AppState, AppCommand?) {
        
        var appState = state
        var appCommand: AppCommand?

        switch action {
            
        // 变更图片
        case .updateDispalyImage(let image):
            appState.displayimage = image
            
        // 添加效果
        case .addCIGaussianBlurAndCIColorControls:
            appCommand = AddFilterCommand()
                    
        }
        
        return (appState, appCommand)
    }
    
    func dispatch(action: AppAction) {
        #if DEBUG
        print("AppAction:\(action)")
        #endif
        
        let result = Store.reduce(state: appState, action: action)
        appState = result.0
        if let command = result.1 {
            #if DEBUG
            print("AppCommand:\(command)")
            #endif
            command.execute(in: self)
        }
        
    }
}

struct AppState {

    var originImage = NSImage(imageLiteralResourceName: "IMG_0567")
    var displayimage = NSImage(imageLiteralResourceName: "IMG_0567")
    var filter = ImageFilter()
    
    // 效果集
    class ImageFilter {
        @Published var blurValue:CGFloat = 10
        @Published var saturationValue:CGFloat = 1
        
        var isFilterChange: AnyPublisher<Void, Never>{
            return Publishers.CombineLatest($blurValue, $saturationValue).map({ (_,_) -> Void in
                })
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
    }
}

// 操作接口
enum AppAction {
    case updateDispalyImage(image: NSImage)
    case addCIGaussianBlurAndCIColorControls
}

// 副作用
protocol AppCommand {
    func execute(in store: Store)
}

// 添加效果
struct AddFilterCommand: AppCommand {
    
    let queue = DispatchQueue(label: "com.zhengwenxiang")
    var context: CIContext = CIContext(options: nil)

    func execute(in store: Store) {
        self.queue.async {
            let imageData = store.appState.originImage.tiffRepresentation!
            let inputImage = CIImage(data: imageData)
            // ----- 使用高斯模糊滤镜
            let blur = CIFilter(name: "CIGaussianBlur")!
            blur.setValue(inputImage, forKey:kCIInputImageKey)
            blur.setValue(store.appState.filter.blurValue, forKey: kCIInputRadiusKey)
            guard let blurImage = blur.outputImage else {return}
            
            // ----- 亮度
            let lighten = CIFilter(name: "CIColorControls")!
            lighten.setValue(blurImage, forKey:kCIInputImageKey)
            lighten.setValue(store.appState.filter.saturationValue, forKey: "inputSaturation")
            guard let lightenImage = lighten.outputImage else {return}
            
            // ----- 图片大小
            let rect = CGRect(origin: CGPoint.zero, size:store.appState.originImage.getRealSize() )
            
            // ----- 生成图片数据
            if let cgImage = self.context.createCGImage(lightenImage, from: rect){
                let nsImage = NSImage.init(cgImage: cgImage, size: rect.size)
                DispatchQueue.main.async {
                    store.dispatch(action: .updateDispalyImage(image: nsImage))
                }
            }
        }
    }
}
