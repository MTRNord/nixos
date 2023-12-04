{
  lib,
  pkgs,
  config,
  ...
}: {
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      asterisk = {
        withOpus = true;
      };
    };
  };
  services.asterisk = {
    enable = true;
    confFiles = {
      "cel.conf" = ''
        [general]
        enable = yes
        apps=dial,park
        events=ALL
      '';
      "cdr.conf" = ''
        [general]
        enable = yes
      '';
      "extensions.conf" = ''
        [tests]
        exten => 100,1,Answer()
        same => n,Verbose(0, 1s)
        same => n,Wait(1)
        same => n,Verbose(0, Playing jazz)
        same => n,Playback(/var/lib/asterisk/sounds/music/waiting)
        same => n,Hangup()

        [epvpn]
        exten => _00XXXX!,1,Set(CALLERID(num)=2903)
        same => n,Verbose(0, Going to play hello)
        same => n,BackGround(/var/lib/asterisk/sounds/en/calling)
        same => n,Verbose(0, Going to dial ''${EXTEN:2}@eventphone)
        same => n,Dial(PJSIP/''${EXTEN:2}@eventphone,30,r)

        [internals]
        include => epvpn
        include => tests
        exten => 200,1,Answer()
        same => n,Verbose(0, Going to play hello)
        same => n,BackGround(/var/lib/asterisk/sounds/en/calling)
        same => n,Verbose(0, Going to dial ''${PJSIP_DIAL_CONTACTS(webrtc_client)})
        same => n,Dial(''${PJSIP_DIAL_CONTACTS(webrtc_client)},30,rm)

        exten => 6001,hint,PJSIP/6001

        exten => i,1,Answer()
        same  => n,Playback(/var/lib/asterisk/sounds/en/check-number-dial-again)
        same => n,Hangup()

        [externals]
        exten => 2903,1,Answer()
        same => n,BackGround(/var/lib/asterisk/sounds/en/agent-newlocation)
        same => n,Verbose(0, Going to wait for exten)
        same => n,WaitExten(30)
        same => n,Verbose(0, After wait for exten. Hanging up)
        same => n,Playback(/var/lib/asterisk/sounds/en/cannot-complete-as-dialed)
        same => n,Hangup()

        ; exten => 7903,1,Answer()
        ; same => n,BackGround(/var/lib/asterisk/sounds/en/agent-newlocation)
        ; same => n,Verbose(0, Going to wait for exten)
        ; same => n,WaitExten(30)
        ; same => n,Verbose(0, After wait for exten. Hanging up)
        ; same => n,Playback(/var/lib/asterisk/sounds/en/cannot-complete-as-dialed)
        ; same => n,Hangup()

        exten => 1,1,Answer()
        same => n,Verbose(0, Routing to 6001)
        ;same => n,BackGround(/var/lib/asterisk/sounds/music/waiting)
        same => n,Dial(''${PJSIP_DIAL_CONTACTS(6001)},30,rm)
        same => n,Verbose(0, Failed to call 6001. Hanging up)
        same => n,Playback(/var/lib/asterisk/sounds/en/cannot-complete-as-dialed)
        same => n,Hangup()

        exten => 1-NOANSWER,1,Playback(/var/lib/asterisk/sounds/en/all-circuits-busy-now)
        same => n,Hangup()

        exten => i,1,Answer()
        same  => n,Playback(/var/lib/asterisk/sounds/en/check-number-dial-again)
        same => n,Hangup()

        [webrtc]
        include => tests

        exten => 6001,1,Answer()
        same => n,Verbose(0, Routing to 6001)
        same => n,Dial(''${PJSIP_DIAL_CONTACTS(6001)},30,rm)
        same => n,Verbose(0, Failed to call 6001. Hanging up)
        same => n,Playback(/var/lib/asterisk/sounds/en/cannot-complete-as-dialed)
        same => n,Hangup()

        [unauthorized]
      '';

      "logger.conf" = ''
        [general]

        [logfiles]
        ; Add debug output to log
        syslog.local0 => notice,warning,error,dtmf,debug,verbose
      '';

      "musiconhold.conf" = ''
        [general]
        [default]
        mode=files
        directory=/var/lib/asterisk/sounds/music/
      '';

      "http.conf" = ''
        [general]
        enabled = yes
        bindaddr = 127.0.0.1
        bindport=8088

        enablestatic=yes
        prefix=
        sessionlimit=100
        session_inactivity=30000
        session_keep_alive=15000
      '';
    };
  };
}
