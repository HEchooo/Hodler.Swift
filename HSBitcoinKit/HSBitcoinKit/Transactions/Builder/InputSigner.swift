import HSCryptoKit
import HSHDWalletKit

class InputSigner {
    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPublicKeyInAddress
        case noPrivateKey
    }

    let hdWallet: IHDWallet

    init(hdWallet: IHDWallet) {
        self.hdWallet = hdWallet
    }

}

extension InputSigner: IInputSigner {

    func sigScriptData(transaction: Transaction, index: Int) throws -> [Data] {
        let input = transaction.inputs[index]

        guard let prevOutput = input.previousOutput else {
            throw SignError.noPreviousOutput
        }

        guard let pubKey = prevOutput.publicKey else {
            throw SignError.noPreviousOutputAddress
        }

        guard let publicKey = pubKey.raw else {
            throw SignError.noPublicKeyInAddress
        }

        guard let privateKeyData = try? hdWallet.privateKeyData(index: pubKey.index, external: pubKey.external) else {
            throw SignError.noPrivateKey
        }

        let serializedTransaction = try TransactionSerializer.serializedForSignature(transaction: transaction, inputIndex: index) + UInt32(1)
        let signatureHash = CryptoKit.sha256sha256(serializedTransaction)
        let signature = try CryptoKit.sign(data: signatureHash, privateKey: privateKeyData) + Data(bytes: [0x01])

        switch prevOutput.scriptType {
        case .p2pk, .p2wpkh: return [signature]
        default: return [signature, publicKey]
        }
    }

}
