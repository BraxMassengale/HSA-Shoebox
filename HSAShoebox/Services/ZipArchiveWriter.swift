import Foundation

struct ZipArchiveWriter: Sendable {
    func writeArchive(entries: [ArchiveEntry], to destinationURL: URL) throws {
        var localFileData = Data()
        var centralDirectory = Data()
        var offsets: [UInt32] = []

        for entry in entries {
            let normalizedPath = entry.path.replacingOccurrences(of: "\\", with: "/")
            let fileNameData = Data(normalizedPath.utf8)
            let crc = CRC32.checksum(for: entry.data)
            let dos = DOSDateTime(date: entry.modifiedAt)
            let offset = UInt32(localFileData.count)
            offsets.append(offset)

            localFileData.append(littleEndian(0x04034B50 as UInt32))
            localFileData.append(littleEndian(20 as UInt16))
            localFileData.append(littleEndian(0 as UInt16))
            localFileData.append(littleEndian(0 as UInt16))
            localFileData.append(littleEndian(dos.time))
            localFileData.append(littleEndian(dos.date))
            localFileData.append(littleEndian(crc))
            localFileData.append(littleEndian(UInt32(entry.data.count)))
            localFileData.append(littleEndian(UInt32(entry.data.count)))
            localFileData.append(littleEndian(UInt16(fileNameData.count)))
            localFileData.append(littleEndian(0 as UInt16))
            localFileData.append(fileNameData)
            localFileData.append(entry.data)

            centralDirectory.append(littleEndian(0x02014B50 as UInt32))
            centralDirectory.append(littleEndian(20 as UInt16))
            centralDirectory.append(littleEndian(20 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(dos.time))
            centralDirectory.append(littleEndian(dos.date))
            centralDirectory.append(littleEndian(crc))
            centralDirectory.append(littleEndian(UInt32(entry.data.count)))
            centralDirectory.append(littleEndian(UInt32(entry.data.count)))
            centralDirectory.append(littleEndian(UInt16(fileNameData.count)))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt16))
            centralDirectory.append(littleEndian(0 as UInt32))
            centralDirectory.append(littleEndian(offset))
            centralDirectory.append(fileNameData)
        }

        var archive = Data()
        archive.append(localFileData)
        let centralDirectoryOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.append(littleEndian(0x06054B50 as UInt32))
        archive.append(littleEndian(0 as UInt16))
        archive.append(littleEndian(0 as UInt16))
        archive.append(littleEndian(UInt16(entries.count)))
        archive.append(littleEndian(UInt16(entries.count)))
        archive.append(littleEndian(UInt32(centralDirectory.count)))
        archive.append(littleEndian(centralDirectoryOffset))
        archive.append(littleEndian(0 as UInt16))

        try archive.write(to: destinationURL, options: .atomic)
    }

    struct ArchiveEntry: Sendable {
        var path: String
        var data: Data
        var modifiedAt: Date

        init(path: String, data: Data, modifiedAt: Date = .now) {
            self.path = path
            self.data = data
            self.modifiedAt = modifiedAt
        }
    }
}

private struct DOSDateTime {
    let time: UInt16
    let date: UInt16

    init(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = max((components.year ?? 1980) - 1980, 0)
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = (components.second ?? 0) / 2

        self.time = UInt16((hour << 11) | (minute << 5) | second)
        self.date = UInt16((year << 9) | (month << 5) | day)
    }
}

private enum CRC32 {
    private static let polynomial: UInt32 = 0xEDB88320
    private static let table: [UInt32] = {
        (0..<256).map { value in
            var current = UInt32(value)
            for _ in 0..<8 {
                if current & 1 == 1 {
                    current = (current >> 1) ^ polynomial
                } else {
                    current >>= 1
                }
            }
            return current
        }
    }()

    static func checksum(for data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private func littleEndian<T: FixedWidthInteger>(_ value: T) -> Data {
    withUnsafeBytes(of: value.littleEndian) { Data($0) }
}
