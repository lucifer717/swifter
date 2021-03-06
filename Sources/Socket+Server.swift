//
//  Socket+Server.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/07/16.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

extension Socket {
    
    public class func tcpSocketForListen(port: in_port_t, forceIPv4: Bool = false, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
        
        #if os(Linux)
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        #endif
        
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Errno.description())
        }
        
        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)
        
        #if os(Linux)
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_family: sa_family_t(AF_INET),
                                       sin_port: port.bigEndian,
                                       sin_addr: in_addr(s_addr: in_addr_t(0)),
                                       sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
                
                bindResult = withUnsafePointer(&addr) {
                    bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in)))
                }
            } else {
                var addr = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                                        sin6_port: port.bigEndian,
                                        sin6_flowinfo: 0,
                                        sin6_addr: in6addr_any,
                                        sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) {
                    bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6)))
                }
            }
        #else
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_len: UInt8(strideof(sockaddr_in)),
                                       sin_family: UInt8(AF_INET),
                                       sin_port: port.bigEndian,
                                       sin_addr: in_addr(s_addr: in_addr_t(0)),
                                       sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
                
                bindResult = withUnsafePointer(&addr) {
                    bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in)))
                }
            } else {
                var addr = sockaddr_in6(sin6_len: UInt8(strideof(sockaddr_in6)),
                                        sin6_family: UInt8(AF_INET6),
                                        sin6_port: port.bigEndian,
                                        sin6_flowinfo: 0,
                                        sin6_addr: in6addr_any,
                                        sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) {
                    bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6)))
                }
            }
        #endif
        
        if bindResult == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.BindFailed(details)
        }
        
        if listen(socketFileDescriptor, maxPendingConnection ) == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.ListenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }

}
