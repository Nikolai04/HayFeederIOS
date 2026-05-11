import CoreBluetooth
import Foundation

final class HayFeederBluetooth: NSObject, ObservableObject {
    @Published var status = "Ready"
    @Published var isConnected = false
    @Published var isScanning = false

    private let deviceName = "HayFeeder"
    private let serviceUUID = CBUUID(string: "0000FE40-CC7A-482A-984A-7F2ED5B3E58F")
    private let characteristicUUID = CBUUID(string: "0000FE41-8E22-4541-9D4C-21EDAE82ED19")

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func toggleConnection() {
        if isConnected {
            write("S")
            status = "Disconnecting. Feeder returning to sleep."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.disconnectLocal()
            }
        } else {
            startScan()
        }
    }

    func startScan() {
        guard central.state == .poweredOn else {
            status = "Turn on Bluetooth first"
            return
        }

        disconnectLocal()
        isScanning = true
        status = "Scanning for HayFeeder"
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            if self.isScanning {
                self.central.stopScan()
                self.isScanning = false
                self.status = "Scan stopped: HayFeeder not found"
            }
        }
    }

    func setFeedingTimes(_ first: String, _ second: String, _ third: String) {
        write("F:\(first),\(second),\(third)")
    }

    private func syncPhoneTime() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        write("T:\(formatter.string(from: Date()))")
    }

    private func write(_ command: String) {
        guard let peripheral, let writeCharacteristic, let data = command.data(using: .utf8) else {
            status = "Not connected"
            return
        }

        let writeType: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.write)
            ? .withResponse
            : .withoutResponse
        peripheral.writeValue(data, for: writeCharacteristic, type: writeType)
        status = writeType == .withResponse ? "Writing \(command)" : "Write sent \(command)"
    }

    private func disconnectLocal() {
        isScanning = false
        isConnected = false
        writeCharacteristic = nil

        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
    }
}

extension HayFeederBluetooth: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            status = "Ready"
        } else {
            status = "Bluetooth unavailable"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let bestName = advertisedName ?? peripheral.name

        guard bestName == deviceName else {
            return
        }

        central.stopScan()
        isScanning = false
        self.peripheral = peripheral
        peripheral.delegate = self
        status = "Connecting..."
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        status = "Connected. Finding feeder service..."
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        writeCharacteristic = nil
        status = "Disconnected"
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        status = "Connect failed"
    }
}

extension HayFeederBluetooth: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services,
              let service = services.first(where: { $0.uuid == serviceUUID }) else {
            status = "HayFeeder service not found"
            return
        }

        peripheral.discoverCharacteristics([characteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics,
              let characteristic = characteristics.first(where: { $0.uuid == characteristicUUID }) else {
            status = "HayFeeder write characteristic not found"
            return
        }

        writeCharacteristic = characteristic
        isConnected = true
        status = "Connected. Time synced."
        syncPhoneTime()
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        status = error == nil ? "Write OK" : "Write failed"
    }
}
