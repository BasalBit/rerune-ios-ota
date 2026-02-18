import Foundation

var transportOverrideForTests: httpTransport?

func sdkResetForTests() {
    runtimeState.shared.resetRuntime()
    transportOverrideForTests = nil
}

func sdkConfigureTransportForTests(_ transport: httpTransport?) {
    transportOverrideForTests = transport
}
