//
// Copyright 2021 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest
import SignalClient

class HsmEnclaveTests: TestCaseBase {

    func testCreateClient() {
        let validKey = IdentityKeyPair.generate().publicKey
        var hashes = HsmCodeHashList()
        try! hashes.append([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ])
        try! hashes.append([
            0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
            0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        ])
        let hsmEnclaveClient = try! HsmEnclaveClient(publicKey: validKey, codeHashes: hashes)
        let initialMessage = try! hsmEnclaveClient.initialRequest()
        XCTAssertEqual(112, initialMessage.count)
    }

    func testCreateClientFailsWithNoHashes() {
        let validKey = IdentityKeyPair.generate().publicKey
        let hashes = HsmCodeHashList()
        XCTAssertThrowsError(try HsmEnclaveClient(publicKey: validKey, codeHashes: hashes))
    }

    func testCompleteHandshakeWithoutInitialRequest() {
        let validKey = IdentityKeyPair.generate().publicKey
        var hashes = HsmCodeHashList()
        try! hashes.append([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ])
        let hsmEnclaveClient = try! HsmEnclaveClient(publicKey: validKey, codeHashes: hashes)
        let handshakeResponse: [UInt8] = [0x01, 0x02, 0x03]
        XCTAssertThrowsError(try hsmEnclaveClient.completeHandshake(handshakeResponse))
    }

    func testEstablishedSendFailsPriorToEstablishment() {
        let validKey = IdentityKeyPair.generate().publicKey
        var hashes = HsmCodeHashList()
        try! hashes.append([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ])
        let hsmEnclaveClient = try! HsmEnclaveClient(publicKey: validKey, codeHashes: hashes)
        let plaintextToSend: [UInt8] = [0x01, 0x02, 0x03]
        XCTAssertThrowsError(try hsmEnclaveClient.establishedSend(plaintextToSend))
    }

    func testEstablishedRecvFailsPriorToEstablishment() {
        let validKey = IdentityKeyPair.generate().publicKey
        var hashes = HsmCodeHashList()
        try! hashes.append([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        ])
        let hsmEnclaveClient = try! HsmEnclaveClient(publicKey: validKey, codeHashes: hashes)
        let receivedCiphertext: [UInt8] = [0x01, 0x02, 0x03]
        XCTAssertThrowsError(try hsmEnclaveClient.establishedRecv(receivedCiphertext))
    }
}