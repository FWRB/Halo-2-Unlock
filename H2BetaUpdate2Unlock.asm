; ////////////////////////////////////////////////////////
; ////////////////// Preprocessor Stuff //////////////////
; ////////////////////////////////////////////////////////
BITS 32

; .hacks segment info:
%define ExecutableBaseAddress           00010000h           ; Base address of the executable
%define HacksSegmentAddress             007ff000h           ; Virtual address of the .hacks segment
%define HacksSegmentOffset              005b0000h           ; File offset of the .hacks segment
%define HacksSegmentSize                00002000h           ; Size of the .hacks segment


; Menu handler functions:
%define MenuHandler_MainMenu                            001B0E31h
%define MenuHandler_GamertagSelect                      002A7AA9h

%define Create_MainMenu_Campaign                        002A7ECEh
%define Create_XboxLive_Menu                            001AF41Ah
%define Create_MainMenu_XboxLive                        002A7EABh
%define Create_MainMenu_SplitScreen                     002A7E65h
%define Create_MainMenu_SystemLink                      002A7E88h
%define Create_MainMenu_OptionsMenu                     001B0C27h

%define LoadScreen                                      000D7143h

; Halo Game Variant Types
%define GameVariant_Slayer                              0
%define GameVariant_CTF                                 6
%define GameVariant_Assault                             7
%define GameVariant_Territories                         8
%define GameVariant_KOTH                                1
%define GameVariant_Race                                2
%define GameVariant_Oddball                             3
%define GameVariant_Juggernaut                          4
%define GameVariant_Headhunter                          5

; void PrintDebugMessage(int category, char *psMessage, char *psTimeStamp, bool bUnk);
%define PrintDebugMessage                               000AC800h

%define CreateNetworkSquadBrowserScreen                 001B3E40h

; Kernel imports:
%define imp_DbgPrint                                    0047492Ch

%define g_network_link                                  006E2DB8h
%define broadcast_search_globals_message_gateway        006E16E8h

%define c_network_message_gateway__send_message         0026AA60h
%define _broadcast_search_globals_get_session_nonce     00287E70h
%define get_transport_address                           00302A00h

%define setsockopt                                      00443DF4h
%define GetLastError                                    0031E829h
%define malloc                                          003930DEh
%define free                                            0039575Dh

    
; Macros
%macro HACK_FUNCTION 1
    %define %1          HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

%macro HACK_DATA 1
    %define %1          HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

; Functions in our .hacks segment.
HACK_FUNCTION Hack_PrintDebugMessage
HACK_FUNCTION Hack_MenuHandler_MainMenu

HACK_FUNCTION Hack_SendNetworkBroadcastReply_Hook
HACK_FUNCTION Hack_NetworkSquadListUpdate_Hook

HACK_FUNCTION Hack_LegaleseCustomText_Hook

HACK_DATA Hack_PrintMessageFormat
HACK_DATA Hack_EULA_Watermark
HACK_DATA Hack_GameVariantCategoryMenuOptionTable

HACK_DATA Hack_MenuHandler_MainMenu_JumpTable


; Compilation flags:
%define ENABLE_DEBUG_OUTPUT                             0


;-------------------------------------------------------------
; Main Patches (Basic/Entry)
;-------------------------------------------------------------

    ;---------------------------------------------------------
    ; Patch the XBE header to update game name
    ;---------------------------------------------------------
    dd      190h
    dd      (_xbe_header_name_end - _xbe_header_name_start)
    _xbe_header_name_start:

            dw      __?utf16?__(`Halo 2 Beta`),0

    _xbe_header_name_end:

    ;---------------------------------------------------------
    ; Change the EULA to our own watermark
    ;---------------------------------------------------------      
    dd          (001A9C00h - ExecutableBaseAddress)
    dd          (_screen_get_string_hook_end - _screen_get_string_hook_start)
    _screen_get_string_hook_start:

            ; Jump into our hook.
            mov     ecx, Hack_LegaleseCustomText_Hook
            jmp     ecx

    _screen_get_string_hook_end:

    ;---------------------------------------------------------
    ; Stop the "I Do Not Agree" button from quitting the game
    ;---------------------------------------------------------      
    dd          (001B0B83h - ExecutableBaseAddress)
    dd          (_i_dont_agree_end - _i_dont_agree_start)
    _i_dont_agree_start:

            ; Skip the call.
            times (001B0B8Ah - 001B0B83h) db 90h
            
    _i_dont_agree_end:

    ;---------------------------------------------------------
    ; Hook MenuHandler_MainMenu
    ;---------------------------------------------------------      
    dd          (MenuHandler_MainMenu - ExecutableBaseAddress)
    dd          (MenuHandler_MainMenu_end - MenuHandler_MainMenu_start)
    MenuHandler_MainMenu_start:

            ; Hook to detour.
            mov     eax, Hack_MenuHandler_MainMenu
            jmp     eax

    MenuHandler_MainMenu_end:

    ;---------------------------------------------------------
    ; MenuHandler_GamertagSelect -> Bypass xbl profile check
    ;---------------------------------------------------------
    dd          (MenuHandler_GamertagSelect - ExecutableBaseAddress) + 70h
    dd          (MenuHandler_GamertagSelect_end - MenuHandler_GamertagSelect_start)
    MenuHandler_GamertagSelect_start:

            %define GamertagSelect_Base     70h
            %define GamertagSelect_Target   0C2h

            ; Skip checks for xbl stuff.
            mov         ecx, (MenuHandler_GamertagSelect + GamertagSelect_Target)
            jmp         ecx

            %undef GamertagSelect_Target
            %undef GamertagSelect_Base

    MenuHandler_GamertagSelect_end:

    ;---------------------------------------------------------
    ; Patch function to allow 4 players instead of 2
    ;---------------------------------------------------------
    dd          (0x192851 - ExecutableBaseAddress) + 0x12
    dd          (check_player_signin_valid_end - check_player_signin_valid_start)
    check_player_signin_valid_start:

            ; Compare to make sure our player number is less than 4 instead of two. 
            ; (We're patching a "cmp    si, 2" to 4, but don't explicitly write the command because it'll compile with a 16 bit operand instead of 8)
            db      4

    check_player_signin_valid_end:

    ;---------------------------------------------------------
    ; Hook network squad list function that updates available sessions to jump into hacks segment
    ;---------------------------------------------------------
    dd          (00287F1Ch - ExecutableBaseAddress)
    dd          (_network_squad_list_update_end - _network_squad_list_update_start)
    _network_squad_list_update_start:

            ; Jump into hacks segment.
            mov     eax, Hack_NetworkSquadListUpdate_Hook
            jmp     eax

    _network_squad_list_update_end:

    ;---------------------------------------------------------
    ; Hook the function that sends the broadcast reply
    ;---------------------------------------------------------
    dd          (0027CDE1h - ExecutableBaseAddress)
    dd          (_send_broadcast_reply_end - _send_broadcast_reply_start)
    _send_broadcast_reply_start:

            ; Jump into hacks segment.
            lea     eax, [esp+38h]      ; game_data structure
            push    eax
            mov     eax, Hack_SendNetworkBroadcastReply_Hook
            jmp     eax

    _send_broadcast_reply_end:

    ;---------------------------------------------------------
    ; Show All Game Type Variants
    ;---------------------------------------------------------
    dd          (0x307773 - ExecutableBaseAddress)
    dd          (AddGameVariantMenuOptions_end - AddGameVariantMenuOptions_start)
    AddGameVariantMenuOptions_start:

            ; Loop through all game type indexes we want to load
            mov     ebx, 0

        AddGameVariantMenuOptions_Loop:
            ; Backup our index (ebx), run original code, restore our index.
            push    ebx
            mov     eax, [esi+70h]
            mov     ebx, 0xD3280
            call    ebx
            mov     ecx, [esi+70h]
            mov     ecx, [ecx+44h]
            mov     ebx, 0FFFFh
            and     eax, ebx
            pop     ebx

            ; Use our index into our game variant table to grab the enum value
            push    ebx
            push    ecx
            mov     ecx, Hack_GameVariantCategoryMenuOptionTable
            mov     ebx, dword [ecx+ebx*4]
            pop     ecx

            ; Add category with the given enum option
            mov     word [ecx+eax*4+2], bx
            pop     ebx
            inc     ebx
            cmp     ebx, 9
            jb      AddGameVariantMenuOptions_Loop
            
            ; Set ebx as what it should've been
            mov     ebx, 0FFFFh
            
    AddGameVariantMenuOptions_mid:
            times (0x30640F - (0x3063C6 + (AddGameVariantMenuOptions_mid - AddGameVariantMenuOptions_start))) db 0x90
    AddGameVariantMenuOptions_end:

;---------------------------------------------------------
; Debug Output
;---------------------------------------------------------      

%if ENABLE_DEBUG_OUTPUT != 0

    ;---------------------------------------------------------
    ; Patch log level
    ;---------------------------------------------------------      
    dd          (0014EBBFh - ExecutableBaseAddress)
    dd          (patch_log_level_end - patch_log_level_start)
    patch_log_level_start:

            mov     dword [587870h], 0

    patch_log_level_end:

    ;---------------------------------------------------------
    ; Print network debug messages
    ;---------------------------------------------------------      
    dd          (0014E675h - ExecutableBaseAddress)
    dd          (patch_print_net_dbg_end - patch_print_net_dbg_start)
    patch_print_net_dbg_start:

            nop
            nop

    patch_print_net_dbg_end:

    ;---------------------------------------------------------
    ; Hook debug print message function
    ;---------------------------------------------------------
    dd          (PrintDebugMessage - ExecutableBaseAddress)
    dd          (PrintDebugMessageHook_end - PrintDebugMessageHook_start)
    PrintDebugMessageHook_start:

            ; Jump to detour function.
            mov     eax, Hack_PrintDebugMessage
            jmp     eax

    PrintDebugMessageHook_end:

%endif

;-------------------------------------------------------------
; Assert/Data Mining Patches
;-------------------------------------------------------------

    ;---------------------------------------------------------
    ; DataMining_Collect (Disable data mining, since it holds up our start countdown process)
    ;---------------------------------------------------------
    dd            (0x14B258 - ExecutableBaseAddress)
    dd            (DataMining_Collect_end - DataMining_Collect_start)
    DataMining_Collect_start:

            ; Don't save datamine files.
            xor     eax, eax
            retn

    DataMining_Collect_end:

    ;---------------------------------------------------------
    ; Stop spewing errors about data mining
    ;---------------------------------------------------------
    dd            (0014B020h - ExecutableBaseAddress)
    dd            (_data_mine_flush_end - _data_mine_flush_start)
    _data_mine_flush_start:

            ; Stop spewing errors.
            xor     eax, eax
            retn

    _data_mine_flush_end:

    ;---------------------------------------------------------
    ; Skip trying to upload debug info
    ;---------------------------------------------------------
    dd            (001C3610h - ExecutableBaseAddress)
    dd            (_crash_report_send_end - _crash_report_send_start)
    _crash_report_send_start:

            ; Skip sending debug report.
            mov     al, 1
            retn 4

    _crash_report_send_end:

    ;---------------------------------------------------------
    ; Stop clients from crashing when negotiating new host                                    ; !game_results_get_game_recording()] is missing in TU2?
    ;---------------------------------------------------------
;    dd          (001CDBE8h - ExecutableBaseAddress)
;    dd          (_change_host_sim_check_end - _change_host_sim_check_start)
;    _change_host_sim_check_start:;
;
            ; Don't assert when checking if game simulation recording is enabled.
;            mov     al, 0
;            nop
;            nop
;            nop
;
;    _change_host_sim_check_end:
;
    ;---------------------------------------------------------
    ; Patch math assert (zedd's fix, helps 360 backcompat)
    ;---------------------------------------------------------      
    dd          (000AFEEEh - ExecutableBaseAddress)
    dd          (_fp_assert_end - _fp_assert_start)
    _fp_assert_start:

            ; Don't assert and jump to failure case.
            jmp     (000AFF12h - 000AFEEEh) + $

    _fp_assert_end:

;---------------------------------------------------------
; .hacks code segment
;---------------------------------------------------------
    dd          HacksSegmentOffset
    dd          (_hacks_code_end - _hacks_code_start)
    _hacks_code_start:

    ;---------------------------------------------------------
    ; Game Variant Category Menu Option Table
    ;---------------------------------------------------------
    _Hack_GameVariantCategoryMenuOptionTable:
            dd      GameVariant_Slayer
            dd      GameVariant_CTF
            dd      GameVariant_Assault
            dd      GameVariant_Territories
            dd      GameVariant_KOTH
            dd      GameVariant_Race
            dd      GameVariant_Oddball
            dd      GameVariant_Juggernaut
            dd      GameVariant_Headhunter

    ;---------------------------------------------------------
    ; void Hack_PrintDebugMessage(int category, char *psMessage, char *psTimeStamp, bool bUnk)
    ;---------------------------------------------------------
    _Hack_PrintDebugMessage:
            
            %define StackSize           0h
            %define StackStart          0h
            %define Category            4h
            %define psMessage           8h
            %define psTimeStamp         0Ch
            %define bUnknown            10h

            ; Setup stack frame.
            sub     esp, StackStart

            ; Print the message to debug output.
            push    dword [esp+StackSize+psMessage]         ; Debug message
            push    dword [esp+StackSize+psTimeStamp+4]     ; Time stamp
            push    Hack_PrintMessageFormat                 ; Format string
            call    dword [imp_DbgPrint]
            add     esp, 0Ch

            ; Destroy stack frame and return.
            add     esp, StackStart
            ret 10h

            %undef bUnknown
            %undef psTimeStamp
            %undef psMessage
            %undef Category
            %undef StackStart
            %undef StackSize

            align 4, db 0

    ;---------------------------------------------------------
    ; void Hack_MenuHandler_MainMenu(void *Unk1, void *Unk2)
    ;---------------------------------------------------------
    _Hack_MenuHandler_MainMenu:

            %define StackSize       4h
            %define StackStart      0h
            %define Unk1            4h
            %define Unk2            8h

            ; Setup stack frame.
            sub     esp, StackStart
            push    esi

            ;db 0CCh

            ; Get the selected menu option index and handle accordingly.
            mov     eax, [esp+StackSize+Unk2]
            movsx   eax, word [eax]
            cmp     eax, 6
            jl      _Hack_MenuHandler_MainMenu_jump
            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_jump:

            ; Load jump table address using menu index.
            jmp     dword [Hack_MenuHandler_MainMenu_JumpTable+eax*4]

    _Hack_MenuHandler_MainMenu_campaign:

            ; Setup campaign menu.
            push    Create_MainMenu_Campaign        ; Create menu function
            push    4
            push    3
            push    0
            push    dword [esp+StackSize+Unk1+10h]  ; pContext
            call    Hack_LoadScreen

            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_xbox_live:

            ; Setup xbox live menu.
            push    Create_MainMenu_XboxLive        ; Create menu function
            push    4
            push    5
            push    0
            push    dword [esp+StackSize+Unk1+10h]  ; pContext
            call    Hack_LoadScreen

            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_split_screen:

            ; Setup split screen menu.
            push    Create_MainMenu_SplitScreen     ; Create menu function
            push    4
            push    5
            push    0
            push    dword [esp+StackSize+Unk1+10h]  ; pContext
            call    Hack_LoadScreen

            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_system_link:

            ; Setup system link menu.
            push    Create_MainMenu_SystemLink      ; Create menu function
            push    4
            push    5
            push    0
            push    dword [esp+StackSize+Unk1+10h]  ; pContext
            call    Hack_LoadScreen

            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_options:

            ; Setup options menu.
            push    Create_MainMenu_OptionsMenu     ; Create menu function
            push    4
            push    5
            push    0
            push    dword [esp+StackSize+Unk1+10h]  ; pContext
            call    Hack_LoadScreen

            jmp     _Hack_MenuHandler_MainMenu_done

    _Hack_MenuHandler_MainMenu_saved_films:

    _Hack_MenuHandler_MainMenu_done:
            ; Destroy stack frame and return.
            pop     esi
            add     esp, StackStart
            ret 8

            %undef Unk2
            %undef Unk1
            %undef StackStart
            %undef StackSize

            align 4, db 0

    _Hack_MenuHandler_MainMenu_JumpTable:
            ; Jumptable:
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_campaign - _Hack_MenuHandler_MainMenu)
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_xbox_live - _Hack_MenuHandler_MainMenu)
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_split_screen - _Hack_MenuHandler_MainMenu)
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_system_link - _Hack_MenuHandler_MainMenu)
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_options - _Hack_MenuHandler_MainMenu)
            dd      Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_saved_films - _Hack_MenuHandler_MainMenu)

    ;---------------------------------------------------------
    ; void Hack_LoadScreen(void *pContext, DWORD Unk1, DWORD Unk2, DWORD Unk3, void *MenuCreateFunc)
    ;---------------------------------------------------------
    Hack_LoadScreen:

            %define StackSize       24h
            %define StackStart      1Ch
            %define MenuStruct      -1Ch
            %define SetupFunc       -4h
            %define pContext        4h
            %define Unk1            8h
            %define Unk2            0Ch
            %define Unk3            10h
            %define MenuCreateFunc  14h

            ; Setup stack frame.
            sub     esp, StackStart
            push    edx
            push    edi

            ; Get some value from the context pointer.
            mov     eax, [esp+StackSize+pContext]
            mov     eax, [eax]
            mov     ecx, [eax+4]

            xor     edx, edx
            inc     edx
            shl     edx, cl                 ; This value indicates if controller input is active on this screen or not

            ; Setup the menu struct.
            lea     ecx, [esp+StackSize+MenuStruct]             ; Pointer to menu struct
            push    dword [esp+StackSize+MenuCreateFunc]        ; Create menu function
            push    dword [esp+StackSize+Unk3+4]                ;
            push    dword [esp+StackSize+Unk2+8]                ;
            xor     ax, ax                                      ; Used by LoadScreen...
            push    edx                                         ; Some value calculated above
            mov     edx, dword [esp+StackSize+Unk1+10h]         ;
            mov     edi, LoadScreen
            call    edi

            ; Call setup function?
            call    [esp+StackSize+SetupFunc]

            ; Destroy stack frame and return.
            pop     edi
            pop     edx
            add     esp, StackStart
            ret 14h

            %undef MenuCreateFunc
            %undef Unk3
            %undef Unk2
            %undef Unk1
            %undef pContext
            %undef SetupFunc
            %undef MenuStruct
            %undef StackStart
            %undef StackSize

            align 4, db 0

    ;---------------------------------------------------------
    ; void Hack_NetworkSquadListUpdate_Hook()
    ;---------------------------------------------------------
    _Hack_NetworkSquadListUpdate_Hook:

            %define StackSize                   4Ch
            %define StackStart                  3Ch
            %define broadcast_option            -3Ch
            %define transport_addr              -38h
            %define broadcast_sockaddr          -1Ch
            %define broadcast_search_version    -0Ch
            %define broadcast_search_nonce      -8h

            ; Setup stack frame.
            sub     esp, StackStart
            push    ebx
            push    ecx
            push    esi
            push    edi

            ; Get the socket handle so we can set the broadcast option.
            mov     esi, dword [g_network_link]
            mov     esi, dword [esi+18h]
            mov     esi, dword [esi]

            ; Setup the broadcast option.
            lea     eax, [esp+StackSize+broadcast_option]
            mov     dword [eax], 1      ; broadcast_option = true

            ; Put the socket into broadcasting mode.
            push    4                   ; sizeof(broadcast_option)
            push    eax                 ; &broadcast_option
            push    20h                 ; SO_BROADCAST
            push    0FFFFh              ; SOL_SOCKET
            push    esi                 ; socket handle
            mov     eax, setsockopt
            call    eax
            cmp     eax, 0
            jz      _Hack_NetworkSquadListUpdate_Hook_continue

            ; Get the last error code.
            mov     eax, GetLastError
            call    eax
            db 0CCh

    _Hack_NetworkSquadListUpdate_Hook_continue:
            ; Setup the broadcast search data.
            mov     word [esp+StackSize+broadcast_search_version], 2        ; broadcast_search.protocol_version = 0
            mov     word [esp+StackSize+broadcast_search_version+2], 0      ; broadcast_search.reserved = 0

            ; Get the broadcast session nonce.
            lea     esi, [esp+StackSize+broadcast_search_nonce]
            mov     eax, _broadcast_search_globals_get_session_nonce
            call    eax

            ; Setup the broadcast sockaddr structure.
            lea     esi, [esp+StackSize+broadcast_sockaddr]     ; &broadcast_sockaddr
            mov     word [esi], 2                               ; broadcast_sockaddr.sin_family = AF_INET
            mov     word [esi+2], 03E9h                         ; broadcast_sockaddr.sin_port = 1001
            mov     dword [esi+4], 0FFFFFFFFh                   ; broadcast_sockaddr.sin_addr = INADDR_BROADCAST
            mov     dword [esi+8], 0
            mov     dword [esi+0Ch], 0

            ; Zero out the transport address struct.
            cld
            lea     edi, [esp+StackSize+transport_addr]
            mov     eax, 0
            mov     ecx, 7
            rep stosd               ; memset(&transport_addr, 0, sizeof(transport_addr));

            ; Convert the broadcast sockaddr to a transport address structure.
            lea     eax, [esp+StackSize+broadcast_sockaddr]     ; &broadcast_sockaddr
            lea     esi, [esp+StackSize+transport_addr]         ; &transport_addr
            push    16                                          ; sizeof(sockaddr_in)
            mov     ecx, get_transport_address
            call    ecx

            ; Get the context pointer thingo so we can send the network message.
            mov     ebx, dword [broadcast_search_globals_message_gateway]

            ; Send the broadcast message.
            lea     eax, [esp+StackSize+broadcast_search_version]
            push    eax                                         ; &broadcast_search_version
            push    12                                          ; sizeof(s_network_message_broadcast_search)
            push    2                                           ; _network_message_type_broadcast_search
            lea     eax, [esp+StackSize+transport_addr+0Ch]
            push    eax                                         ; &transport_addr
            push    ebx
            mov     eax, c_network_message_gateway__send_message
            call    eax

    _Hack_NetworkSquadListUpdate_Hook_done:
            ; Destroy stack frame.
            pop     edi
            pop     esi
            pop     ecx
            pop     ebx
            add     esp, StackStart

            ; Instructions we replaced in the hook.
            mov     al, [006E2ED4h]     ; Check which tick count to use
            test    al, al
            jz      _Hack_NetworkSquadListUpdate_Hook_use_tick_count

            ; Jump to trampoline.
            mov     eax, 00287F25h
            jmp     eax

    _Hack_NetworkSquadListUpdate_Hook_use_tick_count:

            ; Jump to trampoline.
            mov     eax, 00287F2Ch
            jmp     eax

            %undef broadcast_search_nonce
            %undef broadcast_search_version
            %undef broadcast_sockaddr
            %undef transport_addr
            %undef StackStart
            %undef StartSize

            align 4, db 0

    ;---------------------------------------------------------
    ; void Hack_SendNetworkBroadcastReply_Hook(void *game_data)
    ;---------------------------------------------------------
    _Hack_SendNetworkBroadcastReply_Hook:

            %define StackSize               44h
            %define StackStart              34h
            %define broadcast_search        -34h
            %define broadcast_option        -30h
            %define broadcast_sockaddr      -2Ch
            %define transport_addr          -1Ch
            %define game_data               0h      ; no return address so first arg is at +0

            ; Setup the stack frame.
            sub     esp, StackStart
            push    ebx
            push    ecx
            push    esi
            push    edi

            ; Save the broadcast search message pointer.
            mov     dword [esp+StackSize+broadcast_search], edi

            ; Get the socket handle so we can set the broadcast option.
            mov     esi, dword [g_network_link]
            mov     esi, dword [esi+18h]
            mov     esi, dword [esi]

            ; Setup the broadcast option.
            lea     eax, [esp+StackSize+broadcast_option]
            mov     dword [eax], 1      ; broadcast_option = true

            ; Put the socket into broadcasting mode.
            push    4                   ; sizeof(broadcast_option)
            push    eax                 ; &broadcast_option
            push    20h                 ; SO_BROADCAST
            push    0FFFFh              ; SOL_SOCKET
            push    esi                 ; socket handle
            mov     eax, setsockopt
            call    eax
            cmp     eax, 0
            jz      Hack_SendNetworkBroadcastReply_Hook_continue

            ; Get the last error code.
            mov     eax, GetLastError
            call    eax
            db 0CCh

    Hack_SendNetworkBroadcastReply_Hook_continue:

            ; Setup the broadcast sockaddr structure.
            lea     esi, [esp+StackSize+broadcast_sockaddr]     ; &broadcast_sockaddr
            mov     word [esi], 2                               ; broadcast_sockaddr.sin_family = AF_INET
            mov     word [esi+2], 03E9h                         ; broadcast_sockaddr.sin_port = 1001
            mov     dword [esi+4], 0FFFFFFFFh                   ; broadcast_sockaddr.sin_addr = INADDR_BROADCAST
            mov     dword [esi+8], 0
            mov     dword [esi+0Ch], 0

            ; Zero out the transport address struct.
            cld
            lea     edi, [esp+StackSize+transport_addr]
            mov     eax, 0
            mov     ecx, 7
            rep stosd               ; memset(&transport_addr, 0, sizeof(transport_addr));

            ; Convert the broadcast sockaddr to a transport address structure.
            lea     edi, [esp+StackSize+broadcast_sockaddr]     ; &broadcast_sockaddr
            lea     esi, [esp+StackSize+transport_addr]         ; &transport_addr
            push    16                                          ; sizeof(sockaddr_in)
            mov     ecx, get_transport_address
            call    ecx

            ; Allocate some memory for the reply data.
            push    1800            ; sizeof(s_network_message_broadcast_reply)
            mov     eax, malloc
            call    eax
            add     esp, 4          ; Cleanup from malloc()
            cmp     eax, 0
            jz      Hack_SendNetworkBroadcastReply_Hook_done
            mov     ecx, eax

            ;db 0CCh

            ; Setup the reply header using the nonce from the search message.
            mov     ebx, dword [esp+StackSize+broadcast_search]
            mov     word [ecx], 2           ; broadcast_reply_data.protocol = 0
            mov     word [ecx+2], 0
            mov     eax, dword [ebx+4]      ; broadcast_search.nonce
            mov     dword [ecx+4], eax      ; broadcast_reply_data.nonce = broadcast_search.nonce
            mov     eax, dword [ebx+8]      ; broadcast_search.nonce
            mov     dword [ecx+8], eax      ; broadcast_reply_data.nonce = broadcast_search.nonce

            ; Copy the game data into the rest of the message.
            mov     esi, dword [esp+StackSize+game_data]        ; src = game_data
            lea     edi, [ecx+0Ch]                              ; dst = broadcast_reply_data + sizeof(s_network_message_broadcast_search)
            push    ecx
            mov     ecx, 1788                                   ; size = sizeof(s_network_message_broadcast_reply) - sizeof(s_network_message_broadcast_search)
            rep movsb
            pop     ecx

            ; Save the address of the allocation for later.
            mov     dword [esp+StackSize+broadcast_search], ecx

            ; Get the context pointer thingo so we can send the network message.
            mov     ebx, dword [broadcast_search_globals_message_gateway]

            ; Send the broadcast message.
            push    ecx                                         ; &broadcast_reply_data
            push    1800                                        ; sizeof(s_network_message_broadcast_reply)
            push    3                                           ; _network_message_type_broadcast_reply
            lea     eax, [esp+StackSize+transport_addr+0Ch]
            push    eax                                         ; &transport_addr
            push    ebx
            mov     eax, c_network_message_gateway__send_message
            call    eax

            ; Free the allocation we made for the reply data.
            mov     eax, [esp+StackSize+broadcast_search]
            push    eax
            mov     eax, free
            call    eax
            add     esp, 4

    Hack_SendNetworkBroadcastReply_Hook_done:
            ; Destroy the stack frame and return.
            pop     edi
            pop     esi
            pop     ecx
            pop     ebx
            add     esp, StackStart

            ; Jump back into function.
            pop     eax                 ; Bullshit because we can't push ret 4
            mov     eax, 0027CE48h
            jmp     eax

            %undef game_data
            %undef transport_addr
            %undef broadcast_sockaddr
            %undef broadcast_option
            %undef broadcast_search
            %undef StackStart
            %undef StackSize

            align 4, db 0


    ;---------------------------------------------------------
    ; void Hack_LegaleseCustomText_Hook([ebx] string_id string_handle, [eax] datum_index tag)
    ;---------------------------------------------------------
    _Hack_LegaleseCustomText_Hook:

            %define StackSize           14h
            %define StackStart          8h
            %define tag                 -8h
            %define string_handle       -4h

            ; Setup the stack frame.
            sub     esp, StackStart
            push    ebx
            push    ecx
            push    edx
            mov     dword [esp+StackSize+string_handle], ebx
            mov     dword [esp+StackSize+tag], eax

            ; Check for the ids_legal_mumbo_jumbo string id.
            cmp     ebx, 11001525h
            jnz     _Hack_LegaleseCustomText_Hook_load_string

            ;db 0CCh

            ; Allocate a scratch buffer for the decrypted string.
            push    2048
            mov     eax, malloc
            call    eax
            add     esp, 4
            mov     edx, eax
            push    eax

            ; Set the string address to our custom string.
            mov     eax, Hack_EULA_Watermark
            mov     ecx, 0FFh

    _Hack_LegaleseCustomText_Hook_decrypt:
            ; Decrypt the string.
            mov     bx, word [eax]
            cmp     bx, 0
            jz      _Hack_LegaleseCustomText_Hook_decrypt_done

            ; Decrypt data.
            xor     bl, cl
            xor     cl, bl
            mov     word [edx], bx

            ; Next iteration.
            add     eax, 2
            add     edx, 2
            jmp     _Hack_LegaleseCustomText_Hook_decrypt

    _Hack_LegaleseCustomText_Hook_decrypt_done:
            ; Null terminate the string.
            mov     word [edx], bx

            ; Set the address of the decrypted string.
            pop     eax

            jmp     _Hack_LegaleseCustomText_Hook_done

    _Hack_LegaleseCustomText_Hook_load_string:
            ; Destroy the stack frame and continue original code
            pop     edx
            pop     ecx
            pop     ebx
            add     esp, StackStart

            ; Every call to this has ecx as 0, so since we used it to jump here, restore this
            xor     ecx, ecx

            ; Execute original code we replaced and jump back to original code path
            cmp     eax, 0FFFFFFFFh
            push    esi
            push    edi
            mov     edi, ecx
            mov     ecx, 0x1A9C09
            jmp     ecx

    _Hack_LegaleseCustomText_Hook_done:
            ; Destroy the stack frame and return.
            pop     edx
            pop     ecx
            pop     ebx
            add     esp, StackStart
            retn

            %undef string_handle
            %undef StackStart
            %undef StackSize

            align 4, db 0

    _Hack_PrintMessageFormat:
        db '[%s] %s',0
        align 4, db 0

    _Hack_EULA_Watermark:
        db 0xD0, 0x00, 0xFF, 0x00, 0xA3, 0x00, 0x83, 0x00, 0xA3, 0x00, 0x83, 0x00, 0xA3, 0x00, 0x83, 0x00
        db 0xA3, 0x00, 0x83, 0x00, 0xA3, 0x00, 0x83, 0x00, 0xA3, 0x00, 0x83, 0x00, 0xA3, 0x00, 0x83, 0x00
        db 0xA3, 0x00, 0x83, 0x00, 0xC1, 0x00, 0xB8, 0x00, 0x98, 0x00, 0xF9, 0x00, 0x9A, 0x00, 0xF9, 0x00
        db 0x9C, 0x00, 0xEC, 0x00, 0x98, 0x00, 0xF1, 0x00, 0x9F, 0x00, 0xF8, 0x00, 0xD8, 0x00, 0xAC, 0x00
        db 0xC4, 0x00, 0xAD, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0x9F, 0x00, 0xF8, 0x00, 0x8A, 0x00, 0xEF, 0x00
        db 0x8A, 0x00, 0xE7, 0x00, 0x82, 0x00, 0xEC, 0x00, 0x98, 0x00, 0xB8, 0x00, 0xC1, 0x00, 0xAE, 0x00
        db 0xDB, 0x00, 0xFB, 0x00, 0x9A, 0x00, 0xFD, 0x00, 0x8F, 0x00, 0xEA, 0x00, 0x8F, 0x00, 0xB5, 0x00
        db 0xB8, 0x00, 0xB2, 0x00, 0xE4, 0x00, 0xC4, 0x00, 0xE4, 0x00, 0xC4, 0x00, 0xE4, 0x00, 0xC4, 0x00
        db 0xE4, 0x00, 0xB8, 0x00, 0x98, 0x00, 0xB8, 0x00, 0x98, 0x00, 0xB8, 0x00, 0x98, 0x00, 0xB8, 0x00
        db 0x98, 0x00, 0xDA, 0x00, 0xAF, 0x00, 0xC1, 0x00, 0xA6, 0x00, 0xCF, 0x00, 0xAA, 0x00, 0x8A, 0x00
        db 0xE3, 0x00, 0x90, 0x00, 0xB0, 0x00, 0xD1, 0x00, 0xA6, 0x00, 0xC3, 0x00, 0xB0, 0x00, 0xDF, 0x00
        db 0xB2, 0x00, 0xD7, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xAF, 0x00, 0xC7, 0x00, 0xAE, 0x00, 0xDD, 0x00
        db 0xFD, 0x00, 0x9A, 0x00, 0xFB, 0x00, 0x96, 0x00, 0xF3, 0x00, 0xD3, 0x00, 0xBA, 0x00, 0xC9, 0x00
        db 0xE9, 0x00, 0x88, 0x00, 0xFF, 0x00, 0x9A, 0x00, 0xE9, 0x00, 0x86, 0x00, 0xEB, 0x00, 0x8E, 0x00
        db 0xA2, 0x00, 0xAF, 0x00, 0xA5, 0x00, 0x85, 0x00, 0xA5, 0x00, 0x85, 0x00, 0xD9, 0x00, 0xF9, 0x00
        db 0xD9, 0x00, 0xF9, 0x00, 0xD9, 0x00, 0xF9, 0x00, 0xD9, 0x00, 0x85, 0x00, 0xDA, 0x00, 0xFA, 0x00
        db 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00
        db 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00
        db 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0xDA, 0x00, 0x98, 0x00, 0xF9, 0x00, 0x97, 0x00
        db 0xF6, 0x00, 0x98, 0x00, 0xF9, 0x00, 0x8A, 0x00, 0xAA, 0x00, 0xCB, 0x00, 0xB9, 0x00, 0xDC, 0x00
        db 0xFC, 0x00, 0x9D, 0x00, 0xEA, 0x00, 0x8F, 0x00, 0xFC, 0x00, 0x93, 0x00, 0xFE, 0x00, 0x9B, 0x00
        db 0xB5, 0x00, 0x95, 0x00, 0x98, 0x00, 0x92, 0x00, 0xB2, 0x00, 0x92, 0x00, 0xB2, 0x00, 0x92, 0x00
        db 0xB2, 0x00, 0x92, 0x00, 0xCE, 0x00, 0xE2, 0x00, 0xC5, 0x00, 0xEB, 0x00, 0x8B, 0x00, 0xA6, 0x00
        db 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00
        db 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00
        db 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00
        db 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00
        db 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA8, 0x00, 0x88, 0x00, 0xA5, 0x00, 0xF2, 0x00, 0xDC, 0x00
        db 0x84, 0x00, 0xA9, 0x00, 0xA4, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00
        db 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xF2, 0x00, 0xAE, 0x00, 0x8E, 0x00
        db 0xAE, 0x00, 0x8E, 0x00, 0xEE, 0x00, 0xC0, 0x00, 0xE0, 0x00, 0xC0, 0x00, 0xE0, 0x00, 0x80, 0x00
        db 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00
        db 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00
        db 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0x8E, 0x00, 0x83, 0x00, 0x89, 0x00
        db 0xA9, 0x00, 0x89, 0x00, 0xA9, 0x00, 0x89, 0x00, 0xA9, 0x00, 0x89, 0x00, 0xA9, 0x00, 0x89, 0x00
        db 0xA9, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0xFD, 0x00, 0xDD, 0x00, 0xFD, 0x00
        db 0xDD, 0x00, 0xFD, 0x00, 0xDD, 0x00, 0xFD, 0x00, 0x9D, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00
        db 0x93, 0x00, 0xF3, 0x00, 0xDE, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0x8F, 0x00, 0xA3, 0x00, 0x8D, 0x00, 0xA0, 0x00, 0x9A, 0x00, 0xC6, 0x00, 0xCB, 0x00
        db 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00
        db 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0x9D, 0x00, 0xBD, 0x00, 0x9D, 0x00
        db 0xBD, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xE1, 0x00
        db 0xC1, 0x00, 0xE1, 0x00, 0xC1, 0x00, 0xA1, 0x00, 0x8F, 0x00, 0xAF, 0x00, 0x8F, 0x00, 0xAF, 0x00
        db 0x8F, 0x00, 0xAF, 0x00, 0x8F, 0x00, 0xEF, 0x00, 0xC2, 0x00, 0xEC, 0x00, 0xB3, 0x00, 0x93, 0x00
        db 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00
        db 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00
        db 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00
        db 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xCC, 0x00, 0x93, 0x00
        db 0xBD, 0x00, 0x93, 0x00, 0xBE, 0x00, 0x93, 0x00, 0xB4, 0x00, 0x94, 0x00, 0xB4, 0x00, 0x94, 0x00
        db 0xB8, 0x00, 0x95, 0x00, 0xB2, 0x00, 0x89, 0x00, 0xA6, 0x00, 0xAB, 0x00, 0xA1, 0x00, 0x81, 0x00
        db 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00
        db 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xDD, 0x00, 0xFD, 0x00
        db 0xDD, 0x00, 0xFD, 0x00, 0x9D, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00
        db 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xF3, 0x00, 0xDE, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xB0, 0x00, 0x9D, 0x00, 0xB3, 0x00, 0x9D, 0x00, 0xC2, 0x00, 0x9D, 0x00, 0xC2, 0x00
        db 0xEC, 0x00, 0xC2, 0x00, 0x9D, 0x00, 0xB1, 0x00, 0x91, 0x00, 0xB1, 0x00, 0xEE, 0x00, 0xC0, 0x00
        db 0xED, 0x00, 0xC0, 0x00, 0xE7, 0x00, 0xC7, 0x00, 0xE7, 0x00, 0xC7, 0x00, 0xE7, 0x00, 0xC7, 0x00
        db 0xE7, 0x00, 0xC7, 0x00, 0xE7, 0x00, 0xC7, 0x00, 0xEB, 0x00, 0xC7, 0x00, 0xEA, 0x00, 0xC7, 0x00
        db 0xE0, 0x00, 0xC0, 0x00, 0xE0, 0x00, 0xCC, 0x00, 0xEB, 0x00, 0xC4, 0x00, 0xC9, 0x00, 0xC3, 0x00
        db 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00
        db 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00
        db 0xE3, 0x00, 0xC3, 0x00, 0xA3, 0x00, 0x8D, 0x00, 0xAD, 0x00, 0x8D, 0x00, 0xAD, 0x00, 0xCD, 0x00
        db 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00
        db 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0xC3, 0x00, 0xE3, 0x00, 0x83, 0x00, 0xAE, 0x00, 0x80, 0x00
        db 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00
        db 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xFF, 0x00
        db 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0x80, 0x00, 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xF1, 0x00
        db 0xDF, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xF2, 0x00, 0xDF, 0x00, 0xF8, 0x00, 0xD8, 0x00, 0xF8, 0x00
        db 0xD8, 0x00, 0xF8, 0x00, 0xD4, 0x00, 0xF3, 0x00, 0xD3, 0x00, 0xF3, 0x00, 0xD3, 0x00, 0xFC, 0x00
        db 0xF1, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00
        db 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00
        db 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0xDB, 0x00, 0xFB, 0x00
        db 0xDB, 0x00, 0xFB, 0x00, 0x9B, 0x00, 0xB5, 0x00, 0x95, 0x00, 0xB5, 0x00, 0x95, 0x00, 0xF5, 0x00
        db 0xD8, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00
        db 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00
        db 0xA7, 0x00, 0xC7, 0x00, 0xA7, 0x00, 0x8A, 0x00, 0xA7, 0x00, 0x89, 0x00, 0xA7, 0x00, 0x80, 0x00
        db 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00
        db 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0x87, 0x00, 0xA7, 0x00, 0xF8, 0x00, 0xD6, 0x00, 0xFB, 0x00
        db 0xDC, 0x00, 0xFC, 0x00, 0xDC, 0x00, 0xFC, 0x00, 0xD0, 0x00, 0xF7, 0x00, 0xFA, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00
        db 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0x90, 0x00, 0xBD, 0x00
        db 0xE2, 0x00, 0xC2, 0x00, 0xE2, 0x00, 0xC2, 0x00, 0xA2, 0x00, 0x8F, 0x00, 0xA1, 0x00, 0xFE, 0x00
        db 0xA1, 0x00, 0xFE, 0x00, 0xDE, 0x00, 0xF2, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0xDE, 0x00, 0x81, 0x00
        db 0xDE, 0x00, 0xFE, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0xD2, 0x00, 0xFE, 0x00, 0xDE, 0x00, 0x81, 0x00
        db 0xDE, 0x00, 0xF2, 0x00, 0xDF, 0x00, 0xF2, 0x00, 0xD5, 0x00, 0xF5, 0x00, 0xD5, 0x00, 0xF9, 0x00
        db 0xD5, 0x00, 0xF5, 0x00, 0xD8, 0x00, 0xF5, 0x00, 0xD5, 0x00, 0xF5, 0x00, 0xD9, 0x00, 0xFE, 0x00
        db 0xF3, 0x00, 0xF9, 0x00, 0xF4, 0x00, 0xFE, 0x00, 0xF3, 0x00, 0xF9, 0x00, 0xF4, 0x00, 0xFE, 0x00
        db 0xF3, 0x00, 0xF9, 0x00, 0xAD, 0x00, 0xC5, 0x00, 0xA0, 0x00, 0x80, 0x00, 0xEE, 0x00, 0x87, 0x00
        db 0xE9, 0x00, 0x83, 0x00, 0xE2, 0x00, 0x91, 0x00, 0xB1, 0x00, 0xDA, 0x00, 0xB4, 0x00, 0xDB, 0x00
        db 0xAC, 0x00, 0x8C, 0x00, 0xFB, 0x00, 0x93, 0x00, 0xF2, 0x00, 0x86, 0x00, 0xA6, 0x00, 0xDF, 0x00
        db 0xB0, 0x00, 0xC5, 0x00, 0xE5, 0x00, 0x81, 0x00, 0xE8, 0x00, 0x8C, 0x00, 0xA2, 0x00, 0x82, 0x00
        db 0xD6, 0x00, 0xBE, 0x00, 0xDB, 0x00, 0xA2, 0x00, 0x85, 0x00, 0xF7, 0x00, 0x92, 0x00, 0xB2, 0x00
        db 0xD1, 0x00, 0xBE, 0x00, 0xD3, 0x00, 0xBA, 0x00, 0xD4, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xF5, 0x00
        db 0x9A, 0x00, 0xE8, 0x00, 0xC8, 0x00, 0xB1, 0x00, 0xDE, 0x00, 0xAB, 0x00, 0x87, 0x00, 0xA7, 0x00
        db 0xC6, 0x00, 0xA8, 0x00, 0xCC, 0x00, 0xEC, 0x00, 0x9B, 0x00, 0xF2, 0x00, 0x9E, 0x00, 0xF2, 0x00
        db 0xD2, 0x00, 0xA1, 0x00, 0xC9, 0x00, 0xA6, 0x00, 0xD0, 0x00, 0xB5, 0x00, 0x95, 0x00, 0xE1, 0x00
        db 0x89, 0x00, 0xE0, 0x00, 0x93, 0x00, 0xB3, 0x00, 0xD1, 0x00, 0xB0, 0x00, 0xDE, 0x00, 0xBF, 0x00
        db 0xD1, 0x00, 0xB0, 0x00, 0x90, 0x00, 0xE3, 0x00, 0x8C, 0x00, 0xAC, 0x00, 0xCA, 0x00, 0xAB, 0x00
        db 0xD9, 0x00, 0xF9, 0x00, 0x8C, 0x00, 0xFC, 0x00, 0xDC, 0x00, 0xA5, 0x00, 0xCA, 0x00, 0xBF, 0x00
        db 0xCD, 0x00, 0xED, 0x00, 0x8C, 0x00, 0xFF, 0x00, 0x8C, 0x00, 0xAC, 0x00, 0xD5, 0x00, 0xBA, 0x00
        db 0xCF, 0x00, 0xE8, 0x00, 0x84, 0x00, 0xE8, 0x00, 0xC8, 0x00, 0xBF, 0x00, 0xD0, 0x00, 0xBE, 0x00
        db 0x99, 0x00, 0xED, 0x00, 0xCD, 0x00, 0xA3, 0x00, 0xC6, 0x00, 0xA3, 0x00, 0xC7, 0x00, 0xE7, 0x00
        db 0x93, 0x00, 0xFC, 0x00, 0xDC, 0x00, 0xA9, 0x00, 0xC7, 0x00, 0xAB, 0x00, 0xC4, 0x00, 0xA7, 0x00
        db 0xCC, 0x00, 0xEC, 0x00, 0x9E, 0x00, 0xFB, 0x00, 0x98, 0x00, 0xF7, 0x00, 0x99, 0x00, 0xB9, 0x00
        db 0xD8, 0x00, 0xAA, 0x00, 0xC7, 0x00, 0xA8, 0x00, 0xDA, 0x00, 0xFA, 0x00, 0x8E, 0x00, 0xE1, 0x00
        db 0xC1, 0x00, 0xA9, 0x00, 0xC8, 0x00, 0xBE, 0x00, 0xDB, 0x00, 0xFB, 0x00, 0x9A, 0x00, 0xBA, 0x00
        db 0xDC, 0x00, 0xB0, 0x00, 0xD1, 0x00, 0xBC, 0x00, 0xD5, 0x00, 0xBB, 0x00, 0xDC, 0x00, 0xFC, 0x00
        db 0x8F, 0x00, 0xE4, 0x00, 0x91, 0x00, 0xFD, 0x00, 0x91, 0x00, 0xBF, 0x00, 0x00, 0x00

        align 4, db 0

    _hacks_code_end:

; ////////////////////////////////////////////////////////
; //////////////////// End of file ///////////////////////
; ////////////////////////////////////////////////////////
dd -1
