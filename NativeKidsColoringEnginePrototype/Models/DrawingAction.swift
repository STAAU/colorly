import Compression
import Foundation

struct PixelPayload {
    let bytes: Data
    let uncompressedCount: Int
    let isCompressed: Bool

    init(raw: Data) {
        uncompressedCount = raw.count
        guard !raw.isEmpty else {
            bytes = raw
            isCompressed = false
            return
        }

        var encoded = Data(count: raw.count + 256)
        let encodedCount = raw.withUnsafeBytes { source in
            encoded.withUnsafeMutableBytes { destination in
                guard
                    let src = source.bindMemory(to: UInt8.self).baseAddress,
                    let dst = destination.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_encode_buffer(
                    dst,
                    destination.count,
                    src,
                    source.count,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }

        if encodedCount > 0, encodedCount < raw.count {
            encoded.removeSubrange(encodedCount..<encoded.count)
            bytes = encoded
            isCompressed = true
        } else {
            bytes = raw
            isCompressed = false
        }
    }

    func decoded() -> Data? {
        guard isCompressed else { return bytes }
        var decoded = Data(count: uncompressedCount)
        let decodedCount = bytes.withUnsafeBytes { source in
            decoded.withUnsafeMutableBytes { destination in
                guard
                    let src = source.bindMemory(to: UInt8.self).baseAddress,
                    let dst = destination.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_decode_buffer(
                    dst,
                    destination.count,
                    src,
                    source.count,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }
        return decodedCount == uncompressedCount ? decoded : nil
    }
}

struct TilePatch {
    let rect: CGRect
    let before: PixelPayload
    let after: PixelPayload

    var storedByteCount: Int { before.bytes.count + after.bytes.count }
}

struct DrawingAction {
    let patches: [TilePatch]

    var storedByteCount: Int {
        patches.reduce(0) { $0 + $1.storedByteCount }
    }
}
