//
//  SensorFunctions.swift
//  LibreKit
//
//  Created by Julian Groen on 20/04/2021.
//  Copyright © 2021 Julian Groen. All rights reserved.
//

import Foundation


public class SensorFunctions {
    
    public static func decrypt(_ sensorId: Data, _ sensorInfo: Data, _ FRAMData: Data) -> Data {
        let l1: UInt16 = 0xa0c5
        let l2: UInt16 = 0x6860
        let l3: UInt16 = 0x14c6
        let l4: UInt16 = 0x0000

        var result = Data()
        for i in 0 ..< 43 {
            let i64 = UInt64(i)
            var y = word(sensorInfo[5], sensorInfo[4])
            if (i < 3 || i >= 40) {
                y = 0xcadc
            }

            var s1: UInt16 = 0
            if (sensorInfo[0] == 0xE5) {
                let ss1 = (word(sensorId[5], sensorId[4]) + y + i64)
                s1 = UInt16(ss1 & 0xffff)
            } else {
                let ss1 = ((word(sensorId[5], sensorId[4]) + (word(sensorInfo[5], sensorInfo[4]) ^ 0x44)) + i64)
                s1 = UInt16(ss1 & 0xffff)
            }

            let s2 = UInt16((word(sensorId[3], sensorId[2]) + UInt64(l4)) & 0xffff)
            let s3 = UInt16((word(sensorId[1], sensorId[0]) + (i64 << 1)) & 0xffff)
            let s4 = ((0x241a ^ l3))
            let key = process(s1, s2, s3, s4, l1, l2)

            result.append((FRAMData[i * 8 + 0] ^ UInt8(key[3] & 0xff)))
            result.append((FRAMData[i * 8 + 1] ^ UInt8((key[3] >> 8) & 0xff)))
            result.append((FRAMData[i * 8 + 2] ^ UInt8(key[2] & 0xff)))
            result.append((FRAMData[i * 8 + 3] ^ UInt8((key[2] >> 8) & 0xff)))
            result.append((FRAMData[i * 8 + 4] ^ UInt8(key[1] & 0xff)))
            result.append((FRAMData[i * 8 + 5] ^ UInt8((key[1] >> 8) & 0xff)))
            result.append((FRAMData[i * 8 + 6] ^ UInt8(key[0] & 0xff)))
            result.append((FRAMData[i * 8 + 7] ^ UInt8((key[0] >> 8) & 0xff)))
        }

        return result
    }
    
    public static func calibrate(_ bytes: Data) -> SensorCalibration {
        let i1 = read(bytes, 2, 0, 3)
        let i2 = read(bytes, 2, 3, 0xa)
        var i3 = Double(read(bytes, 0x150, 0, 8))
        if read(bytes, 0x150, 0x21, 1) != 0 { i3 = -i3 }
        let i4 = Double(read(bytes, 0x150, 8, 0xe))
        let i5 = Double(read(bytes, 0x150, 0x28, 0xc) << 2)
        let i6 = Double(read(bytes, 0x150, 0x34, 0xc) << 2)
        return SensorCalibration(i1: i1, i2: i2, i3: i3, i4: i4, i5: i5, i6: i6)
    }
    
    public static func read(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int) -> Int {
        guard bitCount != 0 else { return 0 }
        var res = 0
        for i in stride(from: 0, to: bitCount, by: 1) {
            let totalBitOffset = byteOffset * 8 + bitOffset + i
            let abyte = Int(floor(Float(totalBitOffset) / 8))
            let abit = totalBitOffset % 8
            if totalBitOffset >= 0 && ((buffer[abyte] >> abit) & 0x1) == 1 {
                res = res | (1 << i)
            }
        }
        return res
    }
    
    private static func op(_ value: UInt16, _ l1: UInt16, _ l2: UInt16) -> UInt16 {
        var res = value >> 2 // Result does not include these last 2 bits
        if ((value & 1) == 1) {
            res ^= l2
        }
        if ((value & 2) == 2) { // If second last bit is 1
            res ^= l1
        }
        return res
    }

    private static func word(_ high: UInt8, _ low: UInt8) -> UInt64 {
        return (UInt64(high) << 8) + UInt64(low & 0xff)
    }

    private static func process(_ s1: UInt16, _ s2: UInt16, _ s3: UInt16, _ s4: UInt16, _ l1: UInt16, _ l2: UInt16) -> [UInt16] {
        let r0 = op(s1, l1, l2) ^ s4
        let r1 = op(r0, l1, l2) ^ s3
        let r2 = op(r1, l1, l2) ^ s2
        let r3 = op(r2, l1, l2) ^ s1
        let r4 = op(r3, l1, l2)
        let r5 = op(r4 ^ r0, l1, l2)
        let r6 = op(r5 ^ r1, l1, l2)
        let r7 = op(r6 ^ r2, l1, l2)
        let f1 = ((r0 ^ r4))
        let f2 = ((r1 ^ r5))
        let f3 = ((r2 ^ r6))
        let f4 = ((r3 ^ r7))

        return [f1, f2, f3, f4]
    }
}

public class RedundancyCheck {
    
    public static let table: [UInt16] = [0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960]
    
    public static func parse(_ data: Data) -> UInt16 {
        var crc = data.reduce(UInt16(0xFFFF)) { ($0 >> 8) ^ table[Int(($0 ^ UInt16($1)) & 0xFF)] }
        var reverseCrc = UInt16(0)
        for _ in 0 ..< 16 {
            reverseCrc = reverseCrc << 1 | crc & 1
            crc >>= 1
        }
        return reverseCrc.byteSwapped
    }
        
    public static func parse(data: Data) -> Bool {
        guard data.count >= 344 else { return false }
        let vh = valid([UInt8] (data.subdata(in: 0..<24)))      //  24 bytes, i.e.  3 blocks a 8 bytes
        let vb = valid([UInt8] (data.subdata(in: 24..<320)))    // 296 bytes, i.e. 37 blocks a 8 bytes
        let vf = valid([UInt8] (data.subdata(in: 320..<344)))   //  24 bytes, i.e.  3 blocks a 8 bytes
        return (vh && vb && vf)
    }

    private static func valid(_ bytes: [UInt8]) -> Bool {
        let calculatedCrc = crc16(Array(bytes.dropFirst(2)), seed: 0xffff)
        let enclosedCrc =  (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
        return calculatedCrc == enclosedCrc
    }

    private static func crc16(_ message: [UInt8], seed: UInt16? = nil) -> UInt16 {
        var crc: UInt16 = seed != nil ? seed! : 0x0000
        for chunk in BytesSequence(chunkSize: 256, data: message) {
            for b in chunk {
                crc = (crc >> 8) ^ table[Int((crc ^ UInt16(b)) & 0xFF)]
            }
        }

        var reverseCrc = UInt16(0)
        for _ in 0..<16 {
            reverseCrc = reverseCrc << 1 | crc & 1
            crc >>= 1
        }
        return reverseCrc.byteSwapped
    }
}

fileprivate struct BytesSequence: Sequence {

    let chunkSize: Int
    let data: Array<UInt8>

    func makeIterator() -> AnyIterator<ArraySlice<UInt8>> {
        var offset:Int = 0

        return AnyIterator {
            let end = Swift.min(self.chunkSize, self.data.count - offset)
            let result = self.data[offset..<offset + end]
            offset += result.count
            return !result.isEmpty ? result : nil
        }
    }
}
