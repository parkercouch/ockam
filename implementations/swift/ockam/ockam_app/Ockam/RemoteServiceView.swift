import SwiftUI

struct RemoteServiceView: View {
    @State private var isHovered = false
    @State private var isOpen = false
    @ObservedObject var service: Service

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    func closeWindow() {
        self.presentationMode.wrappedValue.dismiss()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "circle")
                    .foregroundColor(
                        service.enabled ? (service.available ? .green : .red) : .orange
                    )
                    .frame(maxWidth: 16, maxHeight: 16)

                VStack(alignment: .leading) {
                    Text(service.sourceName).font(.title3).lineLimit(1)
                    if !service.enabled {
                        Text(verbatim: "Disconnected").font(.caption)
                    } else {
                        if service.available {
                            let address =
                            if let scheme = service.scheme {
                                scheme + "://" + service.address.unsafelyUnwrapped + ":"
                                + String(service.port.unsafelyUnwrapped)
                            } else {
                                service.address.unsafelyUnwrapped + ":"
                                + String(service.port.unsafelyUnwrapped)
                            }
                            Text(verbatim: address).font(.caption).lineLimit(1)
                        } else {
                            Text(verbatim: "Connecting...").font(.caption)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 32, height: 32)
                    .rotationEffect(
                        isOpen ? Angle.degrees(90.0) : Angle.degrees(0), anchor: .center)
            }
            .padding(3)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isOpen = !isOpen
                }
            }
            .onHover { hover in
                isHovered = hover
            }
            .background(isHovered ? Color.gray.opacity(0.25) : Color.clear)
            .cornerRadius(4)

            if isOpen {
                VStack(spacing: 0) {
                    if service.available {
                        if service.enabled {
                            let address =
                            service.address.unsafelyUnwrapped + ":"
                            + String(service.port.unsafelyUnwrapped)
                            if let scheme = service.scheme {
                                let url =
                                scheme + "://" + service.address.unsafelyUnwrapped + ":"
                                + String(service.port.unsafelyUnwrapped)
                                ClickableMenuEntry(
                                    text: "Open " + url,
                                    action: {
                                        if let url = URL(string: url) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    })
                            }
                            ClickableMenuEntry(
                                text: "Copy " + address, clicked: "Copied!",
                                action: {
                                    copyToClipboard(address)
                                    self.closeWindow()
                                })
                        }
                    }

                    if service.enabled {
                        ClickableMenuEntry(
                            text: "Disconnect",
                            action: {
                                disable_accepted_service(service.id)
                            })
                    } else {
                        ClickableMenuEntry(
                            text: "Connect",
                            action: {
                                enable_accepted_service(service.id)
                            })
                    }
                }
            }
        }
    }
}


struct RemoteServiceView_Previews: PreviewProvider {
    @State static var state = swift_demo_application_state()

    static var previews: some View {
        VStack {
            ForEach(state.groups[0].incomingServices) { service in
                RemoteServiceView(service: service)
            }
            ForEach(state.groups[1].incomingServices) { service in
                RemoteServiceView(service: service)
            }
            ForEach(state.groups[2].incomingServices) { service in
                RemoteServiceView(service: service)
            }
        }
        .frame(width: 300, height: 600)
    }
}
