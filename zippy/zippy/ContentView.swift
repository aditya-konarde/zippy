import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .network
    
    enum Tab {
        case network, bonding
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NetworkStatusView()
                .tabItem {
                    Image(systemName: "network")
                    Text("Network")
                }
                .tag(Tab.network)
            
            NetworkBondingView()
                .tabItem {
                    Image(systemName: "link")
                    Text("Bonding")
                }
                .tag(Tab.bonding)
        }
    }
}

struct NetworkBondView: View {
    @StateObject var bondManager = NetworkBondManager()
    @State private var selectedInterfaces: Set<NWInterface> = []
    
    var body: some View {
        List {
            ForEach(NWInterface.interfaces(), id: \.self) { interface in
                HStack {
                    Button(action: {
                        if selectedInterfaces.contains(interface) {
                            selectedInterfaces.remove(interface)
                        } else {
                            selectedInterfaces.insert(interface)
                        }
                    }) {
                        Image(systemName: selectedInterfaces.contains(interface) ? "checkmark.circle" : "circle")
                    }
                    Text(interface.name)
                }
            }
            
            Button(action: {
                // Implement bonding logic
            }) {
                Text("Create Bond")
            }
        }
        .navigationTitle("Network Bonding")
    }
}
