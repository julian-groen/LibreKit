//
//  LibreUtilities.swift
//  Libre2Client
//
//  Created by Reimar Metzen on 12.03.21.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import Foundation

class LibreUtility {
    static private let key: [UInt16] = [0xA0C5, 0x6860, 0x0000, 0x14C6]

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

    public static func decryptFRAM(_ sensorId: Data, _ sensorInfo: Data, _ FRAMData: Data) -> Data {
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
            let key = processCrypto2(s1, s2, s3, s4, l1, l2)
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

    public static func usefulFunction(sensorUID: Data, x: UInt16, y: UInt16) -> [UInt8] {
        let blockKey = processCrypto(input: prepareVariables(sensorUID: sensorUID, x: x, y: y))
        let low = blockKey[0]
        let high = blockKey[1]

        let r1 = low ^ 0x4163
        let r2 = high ^ 0x4344

        return [UInt8(truncatingIfNeeded: r1), UInt8(truncatingIfNeeded: r1 >> 8), UInt8(truncatingIfNeeded: r2), UInt8(truncatingIfNeeded: r2 >> 8)]
    }

    public static func prepareVariables(sensorUID: Data, x: UInt16, y: UInt16) -> [UInt16] {
        let s1 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[5], sensorUID[4])) + UInt(x) + UInt(y))
        let s2 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[3], sensorUID[2])) + UInt(key[2]))
        let s3 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[1], sensorUID[0])) + UInt(x) * 2)
        let s4 = 0x241a ^ key[3]

        return [s1, s2, s3, s4]
    }

    public static func prepareVariables2(sensorUID: Data, i1: UInt16, i2: UInt16, i3: UInt16, i4: UInt16) -> [UInt16] {
        let s1 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[5], sensorUID[4])) + UInt(i1))
        let s2 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[3], sensorUID[2])) + UInt(i2))
        let s3 = UInt16(truncatingIfNeeded: UInt(UInt16(sensorUID[1], sensorUID[0])) + UInt(i3) + UInt(key[2]))
        let s4 = UInt16(truncatingIfNeeded: UInt(i4) + UInt(key[3]))

        return [s1, s2, s3, s4]
    }

    public static func processCrypto(input: [UInt16]) -> [UInt16] {
        func op(_ value: UInt16) -> UInt16 {
            // We check for last 2 bits and do the xor with specific value if bit is 1
            var res = value >> 2 // Result does not include these last 2 bits

            if value & 1 != 0 { // If last bit is 1
                res = res ^ key[1]
            }

            if value & 2 != 0 { // If second last bit is 1
                res = res ^ key[0]
            }

            return res
        }

        let r0 = op(input[0]) ^ input[3]
        let r1 = op(r0) ^ input[2]
        let r2 = op(r1) ^ input[1]
        let r3 = op(r2) ^ input[0]
        let r4 = op(r3)
        let r5 = op(r4 ^ r0)
        let r6 = op(r5 ^ r1)
        let r7 = op(r6 ^ r2)

        let f1 = r0 ^ r4
        let f2 = r1 ^ r5
        let f3 = r2 ^ r6
        let f4 = r3 ^ r7

        return [f4, f3, f2, f1]
    }

    public static func processCrypto2(_ s1: UInt16, _ s2: UInt16, _ s3: UInt16, _ s4: UInt16, _ l1: UInt16, _ l2: UInt16) -> [UInt16] {
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

class Libre2Utility {
    public static func word(_ high: UInt8, _ low: UInt8) -> UInt16 {
        return UInt16(high) << 8 + UInt16(low)
    }
    
    public static func wordByte(_ d: UInt16, _ index: UInt16) -> UInt8 {
        return UInt8((d >> (8 * index)) & 0xff)
    }
    
    public static func readBits(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int) -> Int {
        guard bitCount != 0 else {
            return 0
        }
        var res = 0
        for i in 0 ..< bitCount {
            let totalBitOffset = byteOffset * 8 + bitOffset + i
            let byte = Int(floor(Float(totalBitOffset) / 8))
            let bit = totalBitOffset % 8
            if totalBitOffset >= 0 && ((Int(buffer[byte]) >> bit) & 0x1) == 1 {
                res = res | (1 << i)
            }
        }
        return res
    }

    public static func writeBits(_ buffer: Data, _ byteOffset: Int, _ bitOffset: Int, _ bitCount: Int, _ value: Int) -> Data {
        var res = buffer
        for i in 0 ..< bitCount {
            let totalBitOffset = byteOffset * 8 + bitOffset + i
            let byte = Int(floor(Double(totalBitOffset) / 8))
            let bit = totalBitOffset % 8
            let bitValue = (value >> i) & 0x1
            res[byte] = (res[byte] & ~(1 << bit) | (UInt8(bitValue) << bit))
        }
        return res
    }
    
    private static func crc16(_ data: Data) -> UInt16 {
        let crc16table: [UInt16] = [0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960]
        var crc = data.reduce(UInt16(0xFFFF)) { ($0 >> 8) ^ crc16table[Int(($0 ^ UInt16($1)) & 0xFF)] }
        var reverseCrc = UInt16(0)
        for _ in 0 ..< 16 {
            reverseCrc = reverseCrc << 1 | crc & 1
            crc >>= 1
        }
        return reverseCrc.byteSwapped
    }
    
    public static func readCalibrationInfo(bytes: Data) -> CalibrationInfo {
        let i1 = Libre2Utility.readBits(bytes, 2, 0, 3)
        let i2 = Libre2Utility.readBits(bytes, 2, 3, 0xa)
        var i3 = Double(Libre2Utility.readBits(bytes, 0x150, 0, 8))

        if Libre2Utility.readBits(bytes, 0x150, 0x21, 1) != 0 {
            i3 = -i3
        }

        let i4 = Double(Libre2Utility.readBits(bytes, 0x150, 8, 0xe))
        let i5 = Double(Libre2Utility.readBits(bytes, 0x150, 0x28, 0xc) << 2)
        let i6 = Double(Libre2Utility.readBits(bytes, 0x150, 0x34, 0xc) << 2)
        
        return CalibrationInfo(i1: i1, i2: i2, i3: i3, i4: i4, i5: i5, i6: i6)
    }

    public static func streamingUnlockPayload(sensorUID: Data, info: Data, enableTime: UInt32, unlockCount: UInt16) -> [UInt8] {
        // First 4 bytes are just int32 of timestamp + unlockCount
        let time = enableTime + UInt32(unlockCount)
        let b: [UInt8] = [UInt8(time & 0xFF), UInt8((time >> 8) & 0xFF), UInt8((time >> 16) & 0xFF), UInt8((time >> 24) & 0xFF)]

        // Then we need data of activation command and enable command that were sent to sensor
        let ad = LibreUtility.usefulFunction(sensorUID: sensorUID, x: 0x1b, y: 0x1b6a)
        let ed = LibreUtility.usefulFunction(sensorUID: sensorUID, x: 0x1e, y: UInt16(enableTime & 0xFFFF) ^ UInt16(info[5], info[4]))

        let t11 = UInt16(ed[1], ed[0]) ^ UInt16(b[3], b[2])
        let t12 = UInt16(ad[1], ad[0])
        let t13 = UInt16(ed[3], ed[2]) ^ UInt16(b[1], b[0])
        let t14 = UInt16(ad[3], ad[2])

        let t2 = LibreUtility.processCrypto(input: LibreUtility.prepareVariables2(sensorUID: sensorUID, i1: t11, i2: t12, i3: t13, i4: t14))

        // TODO extract if secret
        let t31 = crc16(Data([0xc1, 0xc4, 0xc3, 0xc0, 0xd4, 0xe1, 0xe7, 0xba, UInt8(t2[0] & 0xFF), UInt8((t2[0] >> 8) & 0xFF)])).byteSwapped
        let t32 = crc16(Data([UInt8(t2[1] & 0xFF), UInt8((t2[1] >> 8) & 0xFF), UInt8(t2[2] & 0xFF), UInt8((t2[2] >> 8) & 0xFF), UInt8(t2[3] & 0xFF), UInt8((t2[3] >> 8) & 0xFF)])).byteSwapped
        let t33 = crc16(Data([ad[0], ad[1], ad[2], ad[3], ed[0], ed[1]])).byteSwapped
        let t34 = crc16(Data([ed[2], ed[3], b[0], b[1], b[2], b[3]])).byteSwapped

        let t4 = LibreUtility.processCrypto(input: LibreUtility.prepareVariables2(sensorUID: sensorUID, i1: t31, i2: t32, i3: t33, i4: t34))

        let res = [UInt8(t4[0] & 0xFF), UInt8((t4[0] >> 8) & 0xFF), UInt8(t4[1] & 0xFF), UInt8((t4[1] >> 8) & 0xFF), UInt8(t4[2] & 0xFF), UInt8((t4[2] >> 8) & 0xFF), UInt8(t4[3] & 0xFF), UInt8((t4[3] >> 8) & 0xFF)]

        return [b[0], b[1], b[2], b[3], res[0], res[1], res[2], res[3], res[4], res[5], res[6], res[7]]
    }

    public static func decryptBLE(sensorUID: Data, data: Data) throws -> [UInt8] {
        let d = LibreUtility.usefulFunction(sensorUID: sensorUID, x: 0x1b, y: 0x1b6a)
        let x = UInt16(d[1], d[0]) ^ UInt16(d[3], d[2]) | 0x63
        let y = UInt16(data[1], data[0]) ^ 0x63

        var key = [UInt8]()
        var initialKey = LibreUtility.processCrypto(input: LibreUtility.prepareVariables(sensorUID: sensorUID, x: x, y: y))

        for _ in 0 ..< 8 {
            key.append(UInt8(truncatingIfNeeded: initialKey[0]))
            key.append(UInt8(truncatingIfNeeded: initialKey[0] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[1]))
            key.append(UInt8(truncatingIfNeeded: initialKey[1] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[2]))
            key.append(UInt8(truncatingIfNeeded: initialKey[2] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[3]))
            key.append(UInt8(truncatingIfNeeded: initialKey[3] >> 8))
            initialKey = LibreUtility.processCrypto(input: initialKey)
        }

        let result = data[2...].enumerated().map { i, value in
            value ^ key[i]
        }

        guard crc16(Data(result.prefix(42))) == UInt16(result[42], result[43]) else {
            struct DecryptBLEError: LocalizedError {
                var errorDescription: String? { "BLE data decryption failed" }
            }
            throw DecryptBLEError()
        }

        return result
    }
        
    public static func parseBLEData( _ data: Data, calibrationInfo: CalibrationInfo) -> (wearTimeMinutes: Int, trend: [Measurement], history: [Measurement]) {
        var measurementTrend: [Measurement] = []
        var measurementHistory: [Measurement] = []
        let wearTimeMinutes = Int(word(data[41], data[40]))
        //let crc = word(data[43], data[42])

        let delay = 2
        let ints = [0, 2, 4, 6, 7, 12, 15]
        var historyCount = 0
        for i in 0 ..< 10 {
            let rawGlucose = Double(readBits(data, i * 4, 0, 0xe))
            if rawGlucose == 0 {
                continue
            }
            
            let rawTemperature = readBits(data, i * 4, 0xe, 0xc) << 2
            var rawTemperatureAdjustment = readBits(data, i * 4, 0x1a, 0x5) << 2
            
            let negativeAdjustment = readBits(data, i * 4, 0x1f, 0x1)
            if negativeAdjustment != 0 {
                rawTemperatureAdjustment = -rawTemperatureAdjustment
            }
            
            var idValue = wearTimeMinutes
            if i < 7 {
                idValue -= ints[i]
            } else {
                historyCount += 1
                idValue = ((idValue - delay) / 15) * 15 - 15 * (i - 7)
            }

            let date = Date().addingTimeInterval(TimeInterval(-60 * (wearTimeMinutes - idValue)))
            let measurement = Measurement(id: idValue, date: date, rawGlucose: rawGlucose, rawTemperature: Double(rawTemperature), rawTemperatureAdjustment: Double(rawTemperatureAdjustment), calibrationInfo: calibrationInfo)
            
            if i < 7 {
                measurementTrend.append(measurement)
            } else {
                measurementHistory.append(measurement)
            }
        }
        
        return (wearTimeMinutes, measurementTrend.sorted(by: { $0.id < $1.id }), measurementHistory.sorted(by: { $0.id < $1.id }))
    }
}
