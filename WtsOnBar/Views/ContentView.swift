import SwiftUI
import AppKit
import WebKit

struct ContentView: View {
    var body: some View {
        //top
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                NSApplication.shared.terminate(self)
            })
            {
                Text("Quit App")
                .font(.caption)
                .fontWeight(.semibold)
            }
            .padding(16.0)
            .frame(height: nil)
            .frame(width: 360.0, alignment: .bottom)
        }
        .padding(0)
        .frame(width: 680, height: 600, alignment: .top)
        
        //tab
        TabView {
            Text("The First Tab")
                .tabItem {
                    //Image(systemName: "1.square.fill")
                    Text("First")
                }
            Text("Another Tab")
                .tabItem {
                    //Image(systemName: "2.square.fill")
                    Text("Second")
                }
            Text("The Last Tab")
                .tabItem {
                    //Image(systemName: "3.square.fill")
                    Text("Third")
                }
        }
        .font(.headline)
        
        
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
