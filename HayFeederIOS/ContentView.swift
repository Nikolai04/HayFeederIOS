import SwiftUI

struct ContentView: View {
    @StateObject private var bluetooth = HayFeederBluetooth()

    @AppStorage("feed1Hour") private var feed1Hour = "14"
    @AppStorage("feed1Minute") private var feed1Minute = "00"
    @AppStorage("feed2Hour") private var feed2Hour = "19"
    @AppStorage("feed2Minute") private var feed2Minute = "00"
    @AppStorage("feed3Hour") private var feed3Hour = "23"
    @AppStorage("feed3Minute") private var feed3Minute = "00"
    @AppStorage("bothSlotsPerFeed") private var bothSlotsPerFeed = true
    @State private var alertText: String?

    private let selectedPhoto = ["hay_photo_1", "hay_photo_2", "hay_photo_3", "hay_photo_4"].randomElement()!
    private let background = Color(red: 18 / 255, green: 20 / 255, blue: 22 / 255)
    private let text = Color(red: 238 / 255, green: 238 / 255, blue: 232 / 255)
    private let mutedText = Color(red: 183 / 255, green: 188 / 255, blue: 184 / 255)
    private let accent = Color(red: 244 / 255, green: 218 / 255, blue: 145 / 255)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("HayFeeder")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.top, 26)

                Text(bluetooth.status)
                    .font(.system(size: 16))
                    .foregroundStyle(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text("Next feed: \(nextFeedText(now: context.date))")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(text)
                        .padding(.vertical, 8)
                }

                Button(bluetooth.isConnected ? "Disconnect and sleep" : "Scan and connect") {
                    bluetooth.toggleConnection()
                }
                .buttonStyle(OutlineButtonStyle(color: mutedText, text: text, background: background))
                .disabled(bluetooth.isScanning && !bluetooth.isConnected)

                Text("Feeding times")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                timeRow(label: "Feed 1", hour: $feed1Hour, minute: $feed1Minute)
                timeRow(label: "Feed 2", hour: $feed2Hour, minute: $feed2Minute)
                timeRow(label: "Feed 3", hour: $feed3Hour, minute: $feed3Minute)

                Button("SET") {
                    setFeedingTimes()
                }
                .buttonStyle(OutlineButtonStyle(color: mutedText, text: text, background: background))
                .disabled(!bluetooth.isConnected)
                .padding(.top, 6)

                Button(bothSlotsPerFeed ? "Both slots per feed: ON" : "Both slots per feed: OFF") {
                    bothSlotsPerFeed.toggle()
                    bluetooth.setBothSlotsPerFeed(bothSlotsPerFeed)
                }
                .buttonStyle(OutlineButtonStyle(color: mutedText, text: text, background: background))
                .disabled(!bluetooth.isConnected)

                Image(selectedPhoto)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .padding(.top, 24)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(background.ignoresSafeArea())
        .onChange(of: bluetooth.isConnected) { connected in
            if connected {
                bluetooth.setBothSlotsPerFeed(bothSlotsPerFeed)
            }
        }
        .alert("HayFeeder", isPresented: Binding(
            get: { alertText != nil },
            set: { if !$0 { alertText = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertText ?? "")
        }
    }

    private func timeRow(label: String, hour: Binding<String>, minute: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(text)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("KL")
                .foregroundStyle(text)
                .font(.system(size: 18))
                .frame(width: 34)

            timeField(hour)
            Text(":")
                .foregroundStyle(text)
                .font(.system(size: 24))
                .frame(width: 16)
            timeField(minute)
        }
    }

    private func timeField(_ value: Binding<String>) -> some View {
        TextField("", text: value)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .foregroundStyle(text)
            .font(.system(size: 20))
            .frame(width: 58)
            .textFieldStyle(.plain)
            .onChange(of: value.wrappedValue) { newValue in
                value.wrappedValue = String(newValue.filter(\.isNumber).prefix(2))
            }
    }

    private func setFeedingTimes() {
        guard let first = normalizedTime(hour: feed1Hour, minute: feed1Minute),
              let second = normalizedTime(hour: feed2Hour, minute: feed2Minute),
              let third = normalizedTime(hour: feed3Hour, minute: feed3Minute) else {
            alertText = "Use hours 0-23 and minutes 0-59"
            return
        }

        guard minutes(first) < minutes(second), minutes(second) < minutes(third) else {
            alertText = "Feed times must be in order"
            return
        }

        feed1Hour = String(first.prefix(2))
        feed1Minute = String(first.suffix(2))
        feed2Hour = String(second.prefix(2))
        feed2Minute = String(second.suffix(2))
        feed3Hour = String(third.prefix(2))
        feed3Minute = String(third.suffix(2))

        bluetooth.setFeedingTimes(first, second, third)
    }

    private func nextFeedText(now date: Date) -> String {
        let schedule = [
            normalizedTime(hour: feed1Hour, minute: feed1Minute) ?? "14:00",
            normalizedTime(hour: feed2Hour, minute: feed2Minute) ?? "19:00",
            normalizedTime(hour: feed3Hour, minute: feed3Minute) ?? "23:00"
        ].map(minutes)

        let now = Calendar.current.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let next = schedule.first(where: { $0 > nowMinutes }) ?? schedule[0]
        return String(format: "%02d:%02d", next / 60, next % 60)
    }

    private func normalizedTime(hour: String, minute: String) -> String? {
        guard let hourValue = Int(hour), let minuteValue = Int(minute),
              (0...23).contains(hourValue), (0...59).contains(minuteValue) else {
            return nil
        }

        return String(format: "%02d:%02d", hourValue, minuteValue)
    }

    private func minutes(_ time: String) -> Int {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        return parts[0] * 60 + parts[1]
    }
}

struct OutlineButtonStyle: ButtonStyle {
    let color: Color
    let text: Color
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(text.opacity(configuration.isPressed ? 0.7 : 1))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 1)
            )
    }
}

#Preview {
    ContentView()
}
