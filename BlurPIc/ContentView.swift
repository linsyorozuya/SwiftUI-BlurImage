//
//  ContentView.swift
//  BlurPIc
//
//  Created by linhui on 2020/5/16.
//  Copyright © 2020 linhui. All rights reserved.
//

import SwiftUI
import Combine
import CoreImage

struct ContentView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        
        // 将图片从其他地方拖入 app 时执行的代理
        let dropDelegate = MyDropDelegate(displayImage: $store.appState.displayimage,
                                          originImage: $store.appState.originImage)
        {
            self.store.dispatch(action: .addCIGaussianBlurAndCIColorControls)
        }
        
        return
            ZStack{
                LinearGradient(gradient: .init(colors: [Color("linear1"),Color("linear2")]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all)
                
                VStack{
                    Spacer().frame(height:20)
                    
                    Text("Drag & Drop Image Here")
                        .font(.title)
                        .foregroundColor(Color.gray)
                    
                    // 图片显示
                    Image(nsImage: store.appState.displayimage)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .shadow(radius: 15)
                        .onDrag { () -> NSItemProvider in
//                            let provider = NSItemProvider(item: self.store.appState.displayimage.tiffRepresentation as NSSecureCoding?,typeIdentifier: kUTTypeTIFF as String)
//                            return provider
                            let data = self.store.appState.displayimage.tiffRepresentation
                            let provider = NSItemProvider(item: data as NSSecureCoding?, typeIdentifier: kUTTypeTIFF as String)
                            provider.previewImageHandler = { (handler, _, _) -> Void in
                                handler?(data as NSSecureCoding?, nil)
                            }
                            return provider
                            
                    }
                    
                    .onDrop(of: ["public.file-url"], delegate: dropDelegate)
                    
                    // 高斯模糊
                    HStack{
                        VStack{
                            Text("模糊").font(.body)
                            Text("\(store.appState.filter.blurValue, specifier: "%.2f")").font(.caption)
                        }
                        Slider(value: $store.appState.filter.blurValue
                            ,in: 0...20 )
                            .frame(height:40)
                        
                    }
                    .padding(.horizontal, 50)
                    
                    // 饱和度
                    HStack{
                        VStack{
                            Text("饱和").font(.body)
                            Text("\(store.appState.filter.saturationValue, specifier: "%.2f")").font(.caption)
                        }
                        Slider(value: $store.appState.filter.saturationValue
                            , in: 0...2 )
                            .frame(height:40)
                    }
                    .padding(.horizontal, 50)
                    
                    Spacer().frame(height:20)
                    
                }.frame(minWidth:600,
                        maxWidth: 600*2,
                        minHeight: 500,
                        maxHeight: 500*2)
        }
    }
    
    
    struct MyDropDelegate: DropDelegate {
        
        @Binding var displayImage: NSImage
        @Binding var originImage: NSImage
        var complete: ()->Void
        
        func dropEntered(info: DropInfo) {
            print("dddd")
        }
        
        func handleFileURLObject(_ url: URL) {
            if let image = NSImage(contentsOfFile: url.path) {
                displayImage = image
                originImage = image
                complete()
            } else {
                
            }
        }
        
        func performDrop(info: DropInfo) -> Bool {
            if let item = info.itemProviders(for: ["public.file-url"]).first {
                item.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                    DispatchQueue.main.async {
                        if let urlData = urlData as? Data {
                            let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                            self.handleFileURLObject(url as URL)
                        }
                    }
                }
                
                return true
                
            } else {
                return false
            }
        }
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Store())
    }
}

// 获取真实的图片大小， nsimage.size 返回图片大小不准确
extension NSImage{
    func getRealSize() -> CGSize {
        return .init(width: self.representations[0].pixelsWide, height: self.representations[0].pixelsHigh)
    }
}
