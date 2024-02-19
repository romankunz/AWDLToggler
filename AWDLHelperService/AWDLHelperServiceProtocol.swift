import Foundation

/// The protocol that this service will vend as its API. This protocol must be visible to both the service and the process hosting the service.
@objc(AWDLHelperServiceProtocol) public protocol AWDLHelperServiceProtocol {
    
    /// Enables the AWDL interface. The completion handler returns a Bool indicating success or failure, and an optional Error.
    func enableAWDL(with reply: @escaping (Bool, Error?) -> Void)
    
    /// Disables the AWDL interface. The completion handler returns a Bool indicating success or failure, and an optional Error.
    func disableAWDL(with reply: @escaping (Bool, Error?) -> Void)
}

