//
//  TelnetConstants.h
//  Telnet
//
//  Created by Adam Eberbach on 29/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef Telnet_TelnetConstants_h
#define Telnet_TelnetConstants_h

// JSON configuration data 

#define kTelnetOptionsArray         (@"Telnet Options")
#define kTelnetOptionNumber         (@"TelnetOptionNumber")
#define kTelnetOptionClassname      (@"TelnetOptionClassname")
#define kTelnetOptionSupported      (@"TelnetOptionIsSupported")
#define kTelnetOptionHostPerforms   (@"TelnetOptionHostPerforms")

// subnegotiation

#define	TELQUAL_IS      (0)	       /* option is... */
#define	TELQUAL_SEND	(1)	       /* send option */
#define	TELQUAL_INFO	(2)	       /* ENVIRON: informational version of IS */
#define BSD_VAR         (1)
#define BSD_VALUE       (0)
#define RFC_VAR         (0)
#define RFC_VALUE       (1)

#define kTelnetSubnegotiationSEND (1)
#define kTelnetSubnegotiationIS (0)

// special characters used in telnet protocol

#define kTelnetCharIAC  (255) // interpret as command
#define kTelnetCharDONT (254) // demands other party stop or confirms other party no longer expected to perform an option
#define kTelnetCharDO   (253) // requests other party perform or confirms expectation other party will perform an option
#define kTelnetCharWONT (252) // refusal to perform or continue performing an option
#define kTelnetCharWILL (251) // wants to begin, or confirms are now performing an option
#define kTelnetCharSB   (250) // subnegotiation follows
#define kTelnetCharGA   (249) // go ahead
#define kTelnetCharEL   (248) // erase line
#define kTelnetCharEC   (247) // erase character
#define kTelnetCharAYT  (246) // are you there?
#define kTelnetCharAO   (245) // abort output
#define kTelnetCharIP   (244) // interrupt process
#define kTelnetCharBRK  (243) // break
#define kTelnetCharDM   (242) // data mark (always accompanied by TCP urgent notification)
#define kTelnetCharNOP  (241) // no operation
#define kTelnetCharSE   (240) // end subnegotiation paramaters
#define kTelnetCharCR   (13)  // ASCII CR carriage return
#define kTelnetCharFF   (12)  // ASCII FF form feed
#define kTelnetCharVT   (11)  // ASCII VT vertical tab
#define kTelnetCharLF   (10)  // ASCII LF line feed
#define kTelnetCharHT   (9)   // ASCII HT horizontal tab
#define kTelnetCharBS   (8)   // ASCII BS backspace
#define kTelnetCharBEL  (7)   // ASCII BEL bell
#define kTelnetCharNUL  (0)   // ASCII NUL

// buffer size to use when processing input from network
#define kTelnetReadBufferSize (2048)

#define kTelnetMsgConnecting    ("Connecting...")

typedef enum _TelnetOption {
    kTelnetOptionBinaryTransmission = 0,          // [RFC856]
    kTelnetOptionEcho,                            // [RFC857]
    kTelnetOptionReconnection,                    // [NIC50005]
    kTelnetOptionSuppressGoAhead,                 // [RFC858]
    kTelnetOptionApproxMessageSizeNegotiation,    // [ETHERNET]
    kTelnetOptionStatus,                          // [RFC859]
    kTelnetOptionTimingMark,                      // [RFC860]
    kTelnetOptionRemoteControlledTransAndEcho,    // [RFC726]
    kTelnetOptionOutputLineWidth,                 // [NIC50005]
    kTelnetOptionOutputPageSize,                  // [NIC50005]
    kTelnetOptionOutputCarriageReturnDisposition, // [RFC652]
    kTelnetOptionOutputHorizontalTabStops,        // [RFC653]
    kTelnetOptionOutputHorizontalTabDisposition,  // [RFC654]
    kTelnetOptionOutputFormfeedDisposition,       // [RFC655]
    kTelnetOptionOutputVerticalTabstops,          // [RFC656]
    kTelnetOptionOutputVerticalTabDisposition,    // [RFC657]
    kTelnetOptionOutputLinefeedDisposition,       // [RFC658]
    kTelnetOptionExtendedASCII,                   // [RFC698]
    kTelnetOptionLogout,                          // [RFC727]
    kTelnetOptionByteMacro,                       // [RFC735]
    kTelnetOptionDataEntryTerminal,               // [RFC1043,RFC732]
    kTelnetOptionSUPDUP,                          // [RFC736,RFC734]
    kTelnetOptionSUPDUPOutput,                    // [RFC749]
    kTelnetOptionSendLocation,                    // [RFC779]
    kTelnetOptionTerminalType,                    // [RFC1091]          YES
    kTelnetOptionEndOfRecord,                     // [RFC885]
    kTelnetOptionTACACSUserIdentification,        // [RFC927]
    kTelnetOptionOutputMarking,                   // [RFC933]
    kTelnetOptionTerminalLocationNumber,          // [RFC946]
    kTelnetOptionTelnet3270Regime,                // [RFC1041]
    kTelnetOptionX_3PAD,                          // [RFC1053]
    kTelnetOptionNegotiateAboutWindowSize,        // [RFC1073]          ?
    kTelnetOptionTerminalSpeed,                   // [RFC1079]
    kTelnetOptionRemoteFlowControl,               // [RFC1372]
    kTelnetOptionLinemode,                        // [RFC1184]
    kTelnetOptionXDisplayLocation,                // [RFC1096]
    kTelnetOptionEnvironmentOption,               // [RFC1408]
    kTelnetOptionAuthenticationOption,            // [RFC2941]
    kTelnetOptionEncryptionOption,                // [RFC2946]
    kTelnetOptionNewEnvironmentOption,            // [RFC1572]
    kTelnetOptionTN3270E,                         // [RFC2355]
    kTelnetOptionXAUTH,                           // [Earhart]
    kTelnetOptionCHARSET,                         // [RFC2066]
    kTelnetOptionTelnetRemoteSerialPort,          // [Barnes]
    kTelnetOptionComPortControlOption,            // [RFC2217]
    kTelnetOptionTelnetSuppressLocalEcho,         // [Atmar]
    kTelnetOptionTelnetStartTLS,                  // [Boe]
    kTelnetOptionKERMIT,                          // [RFC2840]
    kTelnetOptionSENDURL,                         // [Croft]
    kTelnetOptionFORWARD_X					      // [Altman]
    
} TelnetOption;

typedef enum _TelnetState {
    
    kStateStart,
    kStateSeenCR,
    kStateSeenIAC,
    kStateSeenDO,
    kStateSeenDONT,
    kStateSeenWILL,
    kStateSeenWONT,
    kStateSeenSB,
    kStateSubnegotiating,
    kStateSubnegotiatingSeenIAC
    
} TelnetState;



#endif
