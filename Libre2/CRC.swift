//
//  CRC.swift
//  Libre2Client
//
//  Created by Julian Groen on 11/05/2020.
//  Copyright © 2020 Julian Groen. All rights reserved.
//
//  Part of this code is taken from
//  CRC.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 25/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

final class Crc {
    
    /// Table of precalculated crc16 values
    private static let crc16table: [UInt16] = [0, 4489, 8978, 12955, 17956, 22445, 25910, 29887, 35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735, 4225, 264, 13203, 8730, 22181, 18220, 30135, 25662, 40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510, 8450, 12427, 528, 5017, 26406, 30383, 17460, 21949, 44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797, 12675, 8202, 4753, 792, 30631, 26158, 21685, 17724, 48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572, 16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011, 52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859, 21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786, 57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634, 25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073, 61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921, 29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848, 65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696, 33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623, 2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999, 38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398, 6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774, 42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685, 10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061, 46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460, 14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836, 50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747, 19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123, 54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522, 23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898, 59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809, 27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185, 63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584, 31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960]
    
    public static func parse(data: Data) -> Bool {
        let header = 0..<24    //  24 bytes, i.e.  3 blocks a 8 bytes
        let body = 24..<320    // 296 bytes, i.e. 37 blocks a 8 bytes
        let footer = 320..<344 //  24 bytes, i.e.  3 blocks a 8 bytes

        if data.count < 344 {
            return false
        }
        
        return Crc.hasValidCrc([UInt8] (data.subdata(in: header))) && Crc.hasValidCrc([UInt8] (data.subdata(in: body))) && Crc.hasValidCrc([UInt8] (data.subdata(in: footer)))
    }
    
    public static func hasValidCrc(_ bytes: [UInt8]) -> Bool {
        let calculatedCrc = Crc.crc16(Array(bytes.dropFirst(2)), seed: 0xffff)
        let enclosedCrc =  (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
        
        return calculatedCrc == enclosedCrc
    }
    
    /// Returns a byte array with correct crc in first two bytes (calculated over the remaining bytes).
    ///
    /// In case some bytes of the original byte array are tweaked, the original crc does not match the remainaing bytes any more. This function calculates the correct crc of the bytes from byte #0x02 to the end and replaces the first two bytes with the correct crc.
    ///
    /// - Parameter bytes: byte array
    /// - Returns: byte array with correct crc in first two bytes
    static func bytesWithCorrectCRC(_ bytes: [UInt8]) -> [UInt8] {
        let calculatedCrc = Crc.crc16(Array(bytes.dropFirst(2)), seed: 0xffff)

        var correctedBytes = bytes
        correctedBytes[0] = UInt8(calculatedCrc >> 8)
        correctedBytes[1] = UInt8(calculatedCrc & 0x00FF)
        
        return correctedBytes
    }
    
    private static func crc16(_ message: [UInt8], seed: UInt16? = nil) -> UInt16 {
        var crc: UInt16 = seed != nil ? seed! : 0x0000
        for chunk in BytesSequence(chunkSize: 256, data: message) {
            for b in chunk {
                crc = (crc >> 8) ^ crc16table[Int((crc ^ UInt16(b)) & 0xFF)]
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
