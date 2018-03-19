; ////////////////////////////////////////////////////////
; ////////////////// Preprocessor Stuff //////////////////
; ////////////////////////////////////////////////////////
BITS 32

%define ExecutableBaseAddress			00010000h			; Base address of the executable
%define HacksSegmentAddress				00abc820h			; Virtual address of the .hacks segment
%define HacksSegmentOffset				0048e000h			; File offset of the .hacks segment
%define HacksSegmentSize				00002000h			; Size of the .hacks segment

; Macros
%macro HACK_FUNCTION 1
	%define %1			HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

%macro HACK_DATA 1
	%define %1			HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

; Menu handler functions
%define MenuHandler_MainMenu							000DA3D0h
%define MenuHandler_GamertagSelect						000DB970h
%define MenuHandler_MultiplayerProtocolSelect			000DE410h
%define MenuHandler_Settings							000D5070h
%define MenuHandler_SelectedSaveGameActions				0010D5C0h

%define Create_MainMenu_Campaign						002A37D7h
%define Create_XboxLive_Menu							001AF36Ah
%define Create_MainMenu_XboxLive						000DAB60h
%define Create_MainMenu_SplitScreen						002A376Eh
%define Create_MainMenu_SystemLink						002A3791h
%define Create_MainMenu_OptionsMenu						000DAC50h

%define Create_MultiplayerProtocolMenu					00050220h
%define Create_SplitScreenSignInMenu					000E1A00h
%define Create_SystemLinkSignInMenu						000E1A80h
%define Create_XboxLiveSignInMenu						000E1B00h

; Halo Engine Functions
%define ShowSinglePlayerSettings_offset					003056C8h
%define ShowSplitScreen_3_offset						002A37B4h ; Dumps you into the Xbox Live Menu afterwards
%define ShowScreenError_offset							001B818Ch
%define LoadScreen										000D68B0h

%define InitNetwork_offset								001A49F0h

; void DrawText(RECT *pPosSize, DWORD Unk1, DWORD Unk2, DWORD Unk3, char *pText, DWORD Unk4);
%define DrawText										0001C860h

; void PrintDebugMessage(int category, char *psMessage, char *psTimeStamp, bool bUnk);
%define PrintDebugMessage								00011760h

; void PrintDebugMessage2(void *Unkown, char *psMessage, ...);
%define PrintDebugMessage2								002BF530h

; Hooked Halo Engine Screen Creation Functions
%define CreateLegalAcceptanceScreen						000D37C9h

; Hooked Halo Engine Drawing Functions
%define DrawWatermark									000D62E0h

; broadcast_search_globals functions:
%define _broadcast_search_globals_get_session_nonce		001C84C0h
%define broadcast_search_globals_session_initialized	00734D0Ch
%define broadcast_search_globals_message_gateway		00734D08h

; life_cycle_globals:
%define life_cycle_globals_squad_session				00730E6Ch

; c_network_message_gateway functions:
%define c_network_message_gateway__send_message			001ADD80h

%define get_transport_address							0023B810h

%define g_network_link									0088B23Ch

%define _get_unicode_string_from_string_id				001ABA30h

%define vsprintf										002DEC50h
%define GetCurrentTickCount								002EE90Ch
%define GetLastError									00277660h
%define setsockopt										0034F1A1h
%define malloc											002E2AB1h
%define free											002E2C26h

; Kernel imports
%define imp_DbgPrint									0037F734h


; Functions in our .hacks segment.
HACK_FUNCTION Hack_PrintDebugMessage

HACK_FUNCTION Hack_LoadScreen

HACK_FUNCTION Hack_MenuHandler_Test_1
HACK_FUNCTION Hack_MenuHandler_CreateSystemLink
HACK_FUNCTION Hack_Create_MainMenu_Multiplayer

HACK_FUNCTION Hack_Settings_CreateGameVariants_Detour
HACK_FUNCTION Hack_Settings_EditGameVariants_Detour
HACK_FUNCTION Hack_Settings_Playlists_Detour

HACK_FUNCTION Hack_MenuHandler_MultiplayerProtocolSelect

HACK_FUNCTION Hack_NetworkSquadListUpdate_Hook
HACK_FUNCTION Hack_SendNetworkBroadcastReply_Hook

HACK_FUNCTION Hack_LegaleseCustomText_Hook

HACK_DATA Hack_PrintMessageFormat
HACK_DATA Hack_EULA_Watermark

;-------------------------------------------------------------
; Main Patches (Basic/Entry)
;-------------------------------------------------------------		

	;---------------------------------------------------------
	; Change the EULA to our own watermark
	;---------------------------------------------------------		
	dd			(00232331h - ExecutableBaseAddress)
	dd			(_screen_get_string_hook_end - _screen_get_string_hook_start)
	_screen_get_string_hook_start:

			; Jump into our hook.
			mov		edx, Hack_LegaleseCustomText_Hook
			jmp		edx

	_screen_get_string_hook_end:

	;---------------------------------------------------------
	; Stop the "I Do Not Agree" button from quiting the game
	;---------------------------------------------------------		
	dd			(0010E6B9h - ExecutableBaseAddress)
	dd			(_i_dont_agree_end - _i_dont_agree_start)
	_i_dont_agree_start:

			; Skip the call.
			retn 8

	_i_dont_agree_end:


	;---------------------------------------------------------
	; Hook MenuHandler_MainMenu
	;---------------------------------------------------------		
	dd			(MenuHandler_MainMenu + 193h) - ExecutableBaseAddress
	dd			(MenuHandler_MainMenu_end - MenuHandler_MainMenu_start)
	MenuHandler_MainMenu_start:

			mov     dword [esi+4B0h], Hack_MenuHandler_Test_1	; campaign
			mov     [esi+4BCh], edi
			mov     [esi+4B8h], edi
			mov     [esi+4C0h], edi
			mov     [esi+4B4h], eax
			mov     [esi+4C4h], esi
			mov     dword [esi+4C8h], Hack_Create_MainMenu_Multiplayer	; multiplayer
			mov     [esi+4D4h], edi
			mov     [esi+4D0h], edi
			mov     [esi+4D8h], edi
			mov     [esi+4CCh], eax
			mov     [esi+4DCh], esi
			mov     dword [esi+4E0h], Create_MainMenu_XboxLive ; xbox live
			mov     [esi+4ECh], edi
			mov     [esi+4E8h], edi
			mov     [esi+4F0h], edi
			mov     [esi+4E4h], eax
			mov     [esi+4F4h], esi
			mov     dword [esi+4F8h], Hack_MenuHandler_Test_1	; credits
			mov     [esi+504h], edi
			mov     [esi+500h], edi
			mov     [esi+508h], edi
			mov     [esi+4FCh], eax
			mov     [esi+50Ch], esi
			mov     dword [esi+510h], Create_MainMenu_OptionsMenu	; settings
			mov     [esi+51Ch], edi
			mov     [esi+518h], edi
			mov     [esi+520h], edi
			mov     [esi+514h], eax
			mov     [esi+524h], esi
			mov     dword [esi+528h], 0DACB0h	; demos

	MenuHandler_MainMenu_end:

	;---------------------------------------------------------
	; MenuHandler_GamertagSelect -> Bypass xbl profile check shit
	;---------------------------------------------------------
	dd			(MenuHandler_GamertagSelect - ExecutableBaseAddress) + 65h
	dd			(MenuHandler_GamertagSelect_end - MenuHandler_GamertagSelect_start)
	MenuHandler_GamertagSelect_start:

			%define GamertagSelect_Target	94h

			; Bypass "don't sign in" block
			jmp		near (GamertagSelect_Target - 65h) + $

			%undef GamertagSelect_Target

	MenuHandler_GamertagSelect_end:

	dd			(MenuHandler_GamertagSelect - ExecutableBaseAddress) + 10Bh
	dd			(MenuHandler_GamertagSelect2_end - MenuHandler_GamertagSelect2_start)
	MenuHandler_GamertagSelect2_start:

			%define GamertagSelect_Target	12Eh

			; Bypass "don't sign in" block
			jmp		(GamertagSelect_Target - 10Bh) + $

			%undef GamertagSelect_Target

	MenuHandler_GamertagSelect2_end:

	;---------------------------------------------------------
	; Patch function xbox live enabled check
	;---------------------------------------------------------
	dd			(Create_MainMenu_XboxLive - ExecutableBaseAddress) + 2Fh
	dd			(check_for_xbl_profile_end - check_for_xbl_profile_start)
	check_for_xbl_profile_start:

			nop
			nop

	check_for_xbl_profile_end:

	;---------------------------------------------------------
	; Patch function to allow 4 players instead of 2
	;---------------------------------------------------------
	dd			(0x51900 - ExecutableBaseAddress) + 1Eh
	dd			(check_player_signin_valid_end - check_player_signin_valid_start)
	check_player_signin_valid_start:

			; Compare to make sure our player number is less than 4 instead of two. 
			; (We are patching a "cmp 	si, 2" to 4, but don't explicitly write the command because it'll compile with a 16 bit operand instead of 8)
			db 		4

	check_player_signin_valid_end:

	;---------------------------------------------------------
	; Hook network squad list function that updates available sessions to jump into hacks segment
	;---------------------------------------------------------
	dd			(001C856Ch - ExecutableBaseAddress)
	dd			(_network_squad_list_update_end - _network_squad_list_update_start)
	_network_squad_list_update_start:

			; Jump into hacks segment.
			mov		eax, Hack_NetworkSquadListUpdate_Hook
			jmp		eax

	_network_squad_list_update_end:

	;---------------------------------------------------------
	; Hook the function that sends the broadcast reply
	;---------------------------------------------------------
	dd			(001C1B7Ch - ExecutableBaseAddress)
	dd			(_send_broadcast_reply_end - _send_broadcast_reply_start)
	_send_broadcast_reply_start:

			; Jump into hacks segment.
			lea		eax, [esp+34h]		; game_data structure
			push	eax
			mov		eax, Hack_SendNetworkBroadcastReply_Hook
			jmp		eax

	_send_broadcast_reply_end:

	;---------------------------------------------------------
	; MenuHandler_MultiplayerProtocolSelect -> hook into hacks segment
	;---------------------------------------------------------
	dd			(MenuHandler_MultiplayerProtocolSelect - ExecutableBaseAddress)
	dd			(MenuHandler_MultiplayerProtocolSelect_end - MenuHandler_MultiplayerProtocolSelect_start)
	MenuHandler_MultiplayerProtocolSelect_start:	

			; Jump to hacks segment.
			mov		eax, Hack_MenuHandler_MultiplayerProtocolSelect
			jmp		eax

	MenuHandler_MultiplayerProtocolSelect_end:

	;---------------------------------------------------------
	; MenuHandler_CreateNewVariant -> unlock "Create New" variants menu
	;---------------------------------------------------------
	dd            (0xDC8E0 - ExecutableBaseAddress) + 17h
	dd            (_unlock_create_variant_end - _unlock_create_variant_start)
	_unlock_create_variant_start:

			; Jump to detour.
			mov		eax, Hack_Settings_CreateGameVariants_Detour
			jmp		eax

	_unlock_create_variant_end:

	;---------------------------------------------------------
	; MenuHandler_Settings -> unlock "Game Variants" and "Playlists" menu
	;---------------------------------------------------------
	dd            (MenuHandler_Settings - ExecutableBaseAddress) + 74h
	dd            (_unlock_variant_settings_end - _unlock_variant_settings_start)
	_unlock_variant_settings_start:

			; Jump to detour.
			mov		eax, Hack_Settings_EditGameVariants_Detour
			jmp		eax

	_unlock_variant_settings_end:

	dd            (MenuHandler_Settings - ExecutableBaseAddress) + 53h
	dd            (_unlock_playlists_settings_end - _unlock_playlists_settings_start)
	_unlock_playlists_settings_start:

			; Jump to detour.
			mov		eax, Hack_Settings_Playlists_Detour
			jmp		eax

	_unlock_playlists_settings_end:

	;---------------------------------------------------------
	; MenuHandler_SelectedSaveGameActions -> unlock edit game variant and delete profile
	;---------------------------------------------------------
	dd            (MenuHandler_SelectedSaveGameActions - ExecutableBaseAddress) + 11Fh
	dd            (_unlock_edit_variant_end - _unlock_edit_variant_start)
	_unlock_edit_variant_start:

			; Skip to load menu block.
			mov		eax, (MenuHandler_SelectedSaveGameActions + 151h)
			jmp		eax

	_unlock_edit_variant_end:

	dd            (MenuHandler_SelectedSaveGameActions - ExecutableBaseAddress) + 59h
	dd            (_unlock_delete_profile_end - _unlock_delete_profile_start)
	_unlock_delete_profile_start:

			; Skip to load menu block.
			times	(6Bh - 59h) db 90h

	_unlock_delete_profile_end:

	;---------------------------------------------------------
	; Show All Game Type Variants
	;---------------------------------------------------------
	dd            (0010A169h - ExecutableBaseAddress)
	dd            (AddGameVariantMenuOptions_end - AddGameVariantMenuOptions_start)
	AddGameVariantMenuOptions_start:
	        push	ebx

	        ; Start an index 0 for game type index
	        mov		ebx, 0

	        ; Loop through all game type indexes we want to load
	_Hack_GameVariant_Options_Load_Loop:
	        mov     eax, [ebp+6Ch]
	        mov     ecx, 0002C080h
	        call    ecx
	        mov     edx, [ebp+6Ch]
	        mov     ecx, [edx+44h]

	        and     eax, 0FFFFh
	        mov     [ecx+eax*4+2], bx ; Unlock the game type @ index bx
	        inc     ebx
	        cmp     ebx, 9
	        jb      _Hack_GameVariant_Options_Load_Loop

	        pop		ebx

	AddGameVariantMenuOptions_mid:
	        times (0x10A1B9 - (0x10A169 + (AddGameVariantMenuOptions_mid - AddGameVariantMenuOptions_start))) db 90h

	AddGameVariantMenuOptions_end:

	;---------------------------------------------------------
	; Show All Squad Settings (Rename Lobby, Choose New Leader, Boot Player) in System Link
	;---------------------------------------------------------
	dd            (0x000D97E1 - ExecutableBaseAddress)
	dd            (PopulateSquadSettings_end - PopulateSquadSettings_start)
	PopulateSquadSettings_start:
	        push ebx

	        ; Start at option index 0
	        mov ebx, 0

	        ; Loop through all options we want to populate
	    PopulateSquadSettings_Populate_Loop:
	        mov     eax, [ebp+6Ch]
	        mov     ecx, 0002C080h
	        call    ecx
	        mov     ecx, [ebp+6Ch]
	        mov     edx, [ecx+44h]

	        and     eax, 0FFFFh
	        mov     [edx+eax*4+2], bx ; Unlock the option at index bx
	        inc     ebx
	        cmp     ebx, 7
	        jb      PopulateSquadSettings_Populate_Loop

	        pop ebx

	PopulateSquadSettings_mid:
	        times (0xD9889 - (0xD97E1 + (PopulateSquadSettings_mid - PopulateSquadSettings_start))) db 0x90
	PopulateSquadSettings_end:

	;---------------------------------------------------------
	; Bypass squad abandonment when selecting game types in non-xbox-live games
	;---------------------------------------------------------
	dd			(0x00154159 - ExecutableBaseAddress)
	dd			(_bad_things_in_ui_end - _bad_things_in_ui_start)
	_bad_things_in_ui_start:

			; Just return instead of abandoning the active squad.
			add		esp, 1Ch
			retn

	_bad_things_in_ui_end:

	;---------------------------------------------------------
	; Remove network requirement
	;---------------------------------------------------------
	dd            (0x00051945 - ExecutableBaseAddress)
	dd            (_check_network_end - _check_network_start)
	_check_network_start:

			; Skip displaying the error.
			jmp		(0x61 - 0x45) + $

	_check_network_end:

;-------------------------------------------------------------
; Debug Output
;-------------------------------------------------------------

	;---------------------------------------------------------
	; Patch log level
	;---------------------------------------------------------		
	dd			(0014D3CFh - ExecutableBaseAddress)
	dd			(patch_log_level_end - patch_log_level_start)
	patch_log_level_start:
	
	;		mov		dword [580C88h], 0
	
	patch_log_level_end:

	;---------------------------------------------------------
	; Print network debug messages
	;---------------------------------------------------------		
	dd			(0008E517h - ExecutableBaseAddress)
	dd			(patch_print_net_dbg_end - patch_print_net_dbg_start)
	patch_print_net_dbg_start:
	
	;		nop
	;		nop
	
	patch_print_net_dbg_end:

	dd			(0008E409h - ExecutableBaseAddress)
	dd			(patch_print_net_dbg_end2 - patch_print_net_dbg_start2)
	patch_print_net_dbg_start2:
	
	;		nop
	;		nop
	;		nop
	;		nop
	;		nop
	;		nop
	
	patch_print_net_dbg_end2:

	;---------------------------------------------------------
	; Stop everything from printing twice
	;---------------------------------------------------------
	dd			(00011A0Ah - ExecutableBaseAddress)
	dd			(DontPrintTwice_end - DontPrintTwice_start)
	DontPrintTwice_start:	
	
	;		; Don't print shit twice.
	;		times 10 db 90h
	
	DontPrintTwice_end:

	;---------------------------------------------------------
	; Hook debug print message function
	;---------------------------------------------------------
	dd			(PrintDebugMessage - ExecutableBaseAddress)
	dd			(PrintDebugMessageHook_end - PrintDebugMessageHook_start)
	PrintDebugMessageHook_start:	
	
			; Jump to detour function.
	;		mov		eax, Hack_PrintDebugMessage
	;		jmp		eax
	
	PrintDebugMessageHook_end:

;-------------------------------------------------------------
; Assert/Data Mining Patches
;-------------------------------------------------------------

	;---------------------------------------------------------
	; DataMining_Collect (Disable data mining, since it holds up our start countdown process)
	;---------------------------------------------------------
	dd            (0x36BB8 - ExecutableBaseAddress)
	dd            (DataMining_Collect_end - DataMining_Collect_start)
	DataMining_Collect_start:

			; Don't save datamine files.
			xor		eax, eax
	        retn

	DataMining_Collect_end:

	;---------------------------------------------------------
	; Stop trying to send debug info to random MS IP address
	;---------------------------------------------------------
	dd			(0x00119200 - ExecutableBaseAddress) + 19h
	dd			(_netdebug_thread_proc_end - _netdebug_thread_proc_start)
	_netdebug_thread_proc_start:

			; Skip the call which tries to upload debug info.
			times 5 db 90h

	_netdebug_thread_proc_end:


;-------------------------------------------------------------
; .hacks code segment
;-------------------------------------------------------------
	dd			HacksSegmentOffset
	dd			(_hacks_code_end - _hacks_code_start)
	_hacks_code_start:

	;---------------------------------------------------------
	; void Hack_PrintDebugMessage(int category, char *psMessage, char *psTimeStamp, bool bUnk)
	;---------------------------------------------------------
	_Hack_PrintDebugMessage:
			
			%define StackSize			0h
			%define StackStart			0h
			%define Category			4h
			%define psMessage			8h
			%define psTimeStamp			0Ch
			%define bUnknown			10h

			; Setup stack frame.
			sub		esp, StackStart

			; Print the message to debug output.
			push	dword [esp+StackSize+psMessage]			; Debug message
			push	dword [esp+StackSize+psTimeStamp+4]		; Time stamp
			push	Hack_PrintMessageFormat					; Format string
			call	dword [imp_DbgPrint]
			add		esp, 0Ch

			; Destroy stack frame and return.
			add		esp, StackStart
			ret 10h

			%undef bUnknown
			%undef psTimeStamp
			%undef psMessage
			%undef Category
			%undef StackStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; void Hack_MenuHandler_Test_1(void *pContext, void *Unk)
	;---------------------------------------------------------
	_Hack_MenuHandler_Test_1:

			%define StackSize		0h
			%define StackStart		0h
			%define pContext		4h
			%define Unk				8h

			; Setup stack frame.
			sub		esp, StackStart

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	0004FC60h			; Menu handler address
			push	3
			push	4
			push	eax
			call	_Hack_LoadScreen

			; Destroy stack frame and return.
			add		esp, StackStart
			ret 8

			%undef StackStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; void Hack_MenuHandler_CreateSystemLink(void *pContext, void *Unk)
	;---------------------------------------------------------
	_Hack_MenuHandler_CreateSystemLink:

			%define StackSize		0h
			%define StackStart		0h
			%define pContext		4h
			%define Unk				8h

			; Setup stack frame.
			sub		esp, StackStart

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	000E1A80h			; Menu handler address
			push	3
			push	4
			push	eax
			call	_Hack_LoadScreen

			; Destroy stack frame and return.
			add		esp, StackStart
			ret 8

			%undef StackStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; void Hack_Create_MainMenu_Multiplayer(void *pContext, void *Unk)
	;---------------------------------------------------------
	_Hack_Create_MainMenu_Multiplayer:

			%define StackSize		0h
			%define StackStart		0h
			%define pContext		4h
			%define Unk				8h

			; Setup stack frame.
			sub		esp, StackStart

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	Create_MultiplayerProtocolMenu			; Menu handler address
			push	3
			push	4					; window index
			push	eax
			call	_Hack_LoadScreen

			; Destroy stack frame and return.
			add		esp, StackStart
			ret 8

			%undef StackStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; void Hack_MenuHandler_MultiplayerProtocolSelect(void *pContext, void *Unk)
	;---------------------------------------------------------
	_Hack_MenuHandler_MultiplayerProtocolSelect:

			%define StackSize		0Ch
			%define StackStart		0h
			%define pContext		4h
			%define Unk				8h

			; Setup stack frame.
			sub		esp, StackStart
			push	ecx
			push	esi
			push	edi

			; Get the selected option index.
			mov		eax, [esp+StackSize+Unk]
			mov		ecx, [eax]					; selected option index

			; Check if it is valid.
			cmp		ecx, 0FFFFFFFFh
			jz		_Hack_MenuHandler_MultiplayerProtocolSelect_done

			; Handle accordingly.
			movsx	eax, cx
			cmp		eax, 0
			jz		_Hack_MenuHandler_MultiplayerProtocolSelect_split_screen
			dec		eax
			jz		_Hack_MenuHandler_MultiplayerProtocolSelect_system_link
			dec		eax
			jz		_Hack_MenuHandler_MultiplayerProtocolSelect_xbox_live
			jmp		_Hack_MenuHandler_MultiplayerProtocolSelect_done

	_Hack_MenuHandler_MultiplayerProtocolSelect_split_screen:

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	Create_SplitScreenSignInMenu			; Menu handler address
			push	3
			push	4					; window index
			push	eax
			call	_Hack_LoadScreen
			jmp		_Hack_MenuHandler_MultiplayerProtocolSelect_done

	_Hack_MenuHandler_MultiplayerProtocolSelect_system_link:

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	Create_SystemLinkSignInMenu			; Menu handler address
			push	3
			push	4					; window index
			push	eax
			call	_Hack_LoadScreen
			jmp		_Hack_MenuHandler_MultiplayerProtocolSelect_done

	_Hack_MenuHandler_MultiplayerProtocolSelect_xbox_live:

			; Load the menu.
			mov		eax, dword [esp+StackSize+pContext]
			push	Create_XboxLiveSignInMenu			; Menu handler address
			push	3
			push	4					; window index
			push	eax
			call	_Hack_LoadScreen
			jmp		_Hack_MenuHandler_MultiplayerProtocolSelect_done

	_Hack_MenuHandler_MultiplayerProtocolSelect_done:
			; Destroy the stack frame and return.
			pop		edi
			pop		esi
			pop		ecx
			add		esp, StackStart
			retn 8

			%undef Unk
			%undef pContext
			%undef StartStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; Hack_Settings_CreateGameVariants_Detour -> Unlock game variants settings detour
	;---------------------------------------------------------
	_Hack_Settings_CreateGameVariants_Detour:

			; Load the variant settings menu.
			mov		eax, dword [esp+28h]	; Context pointer
			push	000D4AC0h				; Create menu function
			push	3
			push	4
			push	eax
			mov		eax, Hack_LoadScreen
			call	eax

			; Return.
			pop		edi
			pop		esi
			add		esp, 1Ch
			retn 8

	;---------------------------------------------------------
	; Hack_Settings_GameVariants_Detour -> Unlock game variants settings detour
	;---------------------------------------------------------
	_Hack_Settings_EditGameVariants_Detour:

			; Load the variant settings menu.
			mov		eax, dword [esp+28h]	; Context pointer
			push	000D4A40h				; Create menu function
			push	3
			push	4
			push	eax
			mov		eax, Hack_LoadScreen
			call	eax

			; Return.
			pop		esi
			pop		ebx
			add		esp, 1Ch
			retn 8

	;---------------------------------------------------------
	; Hack_Settings_Playlists_Detour -> Unlock playlists settings detour
	;---------------------------------------------------------
	_Hack_Settings_Playlists_Detour:

			; Load the playlists settings menu.
			mov		eax, dword [esp+28h]	; Context pointer
			push	0010A850h				; Create menu function
			push	3
			push	4
			push	eax
			mov		eax, Hack_LoadScreen
			call	eax

			; Return.
			pop		esi
			pop		ebx
			add		esp, 1Ch
			retn 8

	;---------------------------------------------------------
	; void Hack_LoadScreen(void *pContext, DWORD Unk1, DWORD Unk2, DWORD Unk3, void *MenuCreateFunc)
	;---------------------------------------------------------
	_Hack_LoadScreen:

			%define StackSize		24h
			%define StackStart		1Ch
			%define MenuStruct_1C	-1Ch
			%define MenuStruct_1A	-1Ah
			%define MenuStruct_18	-18h
			%define MenuStruct_14	-14h
			%define MenuStruct_10	-10h
			%define MenuStruct_C	-0Ch
			%define MenuStruct_8	-8h
			%define MenuStruct_4	-4h
			%define pContext		4h
			%define Unk1			8h
			%define Unk2			0Ch
			%define MenuCreateFunc	10h

			; Setup stack frame.
			sub		esp, StackStart
			push	edx
			push	edi

			;db 0CCh

			; Get some value from the context pointer.
			mov		eax, [esp+StackSize+pContext]
			mov		ecx, [eax]
			mov		ecx, [ecx+4]

			or		eax, 0FFFFFFFFh
			mov		edx, 1
			shl		edx, cl					; This value indicates if controller input is active on this screen or not

			; Setup the menu struct.
			mov		dword [esp+StackSize+MenuStruct_1C], 0
			mov		dword [esp+StackSize+MenuStruct_10], eax
			mov		dword [esp+StackSize+MenuStruct_C], eax
			mov		dword [esp+StackSize+MenuStruct_8], eax
			mov		word [esp+StackSize+MenuStruct_1A], dx
			mov		eax, dword [esp+StackSize+Unk2]
			mov		dword [esp+StackSize+MenuStruct_18], eax	; Unk2
			mov		eax, dword [esp+StackSize+Unk1]
			mov		dword [esp+StackSize+MenuStruct_14], eax	; Unk1
			mov		eax, dword [esp+StackSize+MenuCreateFunc]
			mov		dword [esp+StackSize+MenuStruct_4], eax		; MenuCreateFunc

			; Call the menu create function.
			lea		ecx, [esp+StackSize+MenuStruct_1C]			; Pointer to menu struct
			call	eax

			; Destroy stack frame and return.
			pop		edi
			pop		edx
			add		esp, StackStart
			ret 10h

			%undef MenuCreateFunc
			%undef Unk2
			%undef Unk1
			%undef pContext
			%undef MenuStruct_4
			%undef MenuStruct_8
			%undef MenuStruct_C
			%undef MenuStruct_10
			%undef MenuStruct_14
			%undef MenuStruct_18
			%undef MenuStruct_1A
			%undef MenuStruct_1C
			%undef StackStart
			%undef StackSize

			align 4, db 0

	;---------------------------------------------------------
	; void Hack_NetworkSquadListUpdate_Hook()
	;---------------------------------------------------------
	_Hack_NetworkSquadListUpdate_Hook:

			%define StackSize					4Ch
			%define StackStart					3Ch
			%define broadcast_option			-3Ch
			%define transport_addr				-38h
			%define broadcast_sockaddr			-1Ch
			%define broadcast_search_version	-0Ch
			%define broadcast_search_nonce		-8h

			; Setup stack frame.
			sub		esp, StackStart
			push	ebx
			push	ecx
			push	esi
			push	edi

			; Get the socket handle so we can set the braodcast option.
			mov		esi, dword [g_network_link]
			mov		esi, dword [esi+28h]
			mov		esi, dword [esi]

			; Setup the broadcast option.
			lea		eax, [esp+StackSize+broadcast_option]
			mov		dword [eax], 1		; broadcast_option = true

			; Put the socket into broadcasting mode.
			push	4					; sizeof(broadcast_option)
			push	eax					; &broadcast_option
			push	20h					; SO_BROADCAST
			push	0FFFFh				; SOL_SOCKET
			push	esi					; socket handle
			mov		eax, setsockopt
			call	eax
			cmp		eax, 0
			jz		_Hack_NetworkSquadListUpdate_Hook_continue

			; Get the last error code.
			mov		eax, GetLastError
			call	eax
			db 0CCh

	_Hack_NetworkSquadListUpdate_Hook_continue:
			; Setup the broadcast search data.
			mov		word [esp+StackSize+broadcast_search_version], 0		; broadcast_search.protocol_version = 0
			mov		word [esp+StackSize+broadcast_search_version+2], 0		; broadcast_search.reserved = 0

			; Get the broadcast session nonce.
			lea		esi, [esp+StackSize+broadcast_search_nonce]
			mov		eax, _broadcast_search_globals_get_session_nonce
			call	eax

			; Setup the broadcast sockaddr structure.
			lea		esi, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
			mov		word [esi], 2								; broadcast_sockaddr.sin_family = AF_INET
			mov		word [esi+2], 03E9h							; broadcast_sockaddr.sin_port = 1001
			mov		dword [esi+4], 0FFFFFFFFh					; broadcast_sockaddr.sin_addr = INADDR_BROADCAST
			mov		dword [esi+8], 0
			mov		dword [esi+0Ch], 0

			; Zero out the transport address struct.
			cld
			lea		edi, [esp+StackSize+transport_addr]
			mov		eax, 0
			mov		ecx, 7
			rep stosd				; memset(&transport_addr, 0, sizeof(transport_addr));

			; Convert the broadcast sockaddr to a transport address structure.
			mov		ebx, 16										; sizeof(sockaddr_in)
			lea		eax, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
			lea		esi, [esp+StackSize+transport_addr]
			push	esi											; &transport_addr
			mov		ecx, get_transport_address
			call	ecx

			; Get the context pointer thingo so we can send the network message.
			mov		ebx, dword [broadcast_search_globals_message_gateway]

			; Send the broadcast message.
			lea		eax, [esp+StackSize+broadcast_search_version]
			push	eax											; &broadcast_search_version
			push	12											; sizeof(s_network_message_broadcast_search)
			push	2											; _network_message_type_broadcast_search
			lea		eax, [esp+StackSize+transport_addr+0Ch]
			push	eax											; &transport_addr
			mov		eax, c_network_message_gateway__send_message
			call	eax

	_Hack_NetworkSquadListUpdate_Hook_done:
			; Destroy stack frame.
			pop		edi
			pop		esi
			pop		ecx
			pop		ebx
			add		esp, StackStart

			; Instructions we replaced in the hook.
			mov		al, [00590321h]		; Check which tick count to use
			test	al, al
			jz		_Hack_NetworkSquadListUpdate_Hook_use_tick_count

			; Jump to trampoline.
			mov		eax, 001C8575h
			jmp		eax

	_Hack_NetworkSquadListUpdate_Hook_use_tick_count:

			; Jump to trampoline.
			mov		eax, 001C857Ch
			jmp		eax

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

			%define StackSize				44h
			%define StackStart				34h
			%define broadcast_search		-34h
			%define broadcast_option		-30h
			%define broadcast_sockaddr		-2Ch
			%define transport_addr			-1Ch
			%define game_data				0h		; no return address so first arg is at +0

			; Setup the stack frame.
			sub		esp, StackStart
			push	ebx
			push	ecx
			push	esi
			push	edi

			; Save the broadcast search message pointer.
			mov		dword [esp+StackSize+broadcast_search], ebx

			; Get the socket handle so we can set the braodcast option.
			mov		esi, dword [g_network_link]
			mov		esi, dword [esi+28h]
			mov		esi, dword [esi]

			; Setup the broadcast option.
			lea		eax, [esp+StackSize+broadcast_option]
			mov		dword [eax], 1		; broadcast_option = true

			; Put the socket into broadcasting mode.
			push	4					; sizeof(broadcast_option)
			push	eax					; &broadcast_option
			push	20h					; SO_BROADCAST
			push	0FFFFh				; SOL_SOCKET
			push	esi					; socket handle
			mov		eax, setsockopt
			call	eax
			cmp		eax, 0
			jz		Hack_SendNetworkBroadcastReply_Hook_continue

			; Get the last error code.
			mov		eax, GetLastError
			call	eax
			db 0CCh

	Hack_SendNetworkBroadcastReply_Hook_continue:

			; Setup the broadcast sockaddr structure.
			lea		esi, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
			mov		word [esi], 2								; broadcast_sockaddr.sin_family = AF_INET
			mov		word [esi+2], 03E9h							; broadcast_sockaddr.sin_port = 1001
			mov		dword [esi+4], 0FFFFFFFFh					; broadcast_sockaddr.sin_addr = INADDR_BROADCAST
			mov		dword [esi+8], 0
			mov		dword [esi+0Ch], 0

			; Zero out the transport address struct.
			cld
			lea		edi, [esp+StackSize+transport_addr]
			mov		eax, 0
			mov		ecx, 7
			rep stosd				; memset(&transport_addr, 0, sizeof(transport_addr));

			; Convert the broadcast sockaddr to a transport address structure.
			mov		ebx, 16										; sizeof(sockaddr_in)
			lea		eax, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
			lea		esi, [esp+StackSize+transport_addr]
			push	esi											; &transport_addr
			mov		ecx, get_transport_address
			call	ecx

			; Allocate some memory for the reply data.
			push	1060			; sizeof(s_network_message_broadcast_reply)
			mov		eax, malloc
			call	eax
			add		esp, 4			; Cleanup from malloc()
			cmp		eax, 0
			jz		Hack_SendNetworkBroadcastReply_Hook_done
			mov		ecx, eax

			;db 0CCh

			; Setup the reply header using the nonce from the search message.
			mov		ebx, dword [esp+StackSize+broadcast_search]
			mov		dword [ecx], 0			; broadcast_reply_data.protocol = 0
			mov		eax, dword [ebx+4]		; broadcast_search.nonce
			mov		dword [ecx+4], eax		; broadcast_reply_data.nonce = broadcast_search.nonce
			mov		eax, dword [ebx+8]		; broadcast_search.nonce
			mov		dword [ecx+8], eax		; broadcast_reply_data.nonce = broadcast_search.nonce

			; Copy the game data into the rest of the message.
			mov		esi, dword [esp+StackSize+game_data]		; src = game_data
			lea		edi, [ecx+0Ch]								; dst = broadcast_reply_data + sizeof(s_network_message_broadcast_search)
			push	ecx
			mov		ecx, 1048									; size = sizeof(s_network_message_broadcast_reply) - sizeof(s_network_message_broadcast_search)
			rep movsb
			pop		ecx

			; Save the address of the allocation for later.
			mov		dword [esp+StackSize+broadcast_search], ecx

			; Get the context pointer thingo so we can send the network message.
			mov		ebx, dword [broadcast_search_globals_message_gateway]

			; Send the broadcast message.
			push	ecx											; &broadcast_reply_data
			push	1060										; sizeof(s_network_message_broadcast_reply)
			push	3											; _network_message_type_broadcast_reply
			lea		eax, [esp+StackSize+transport_addr+0Ch]
			push	eax											; &transport_addr
			mov		eax, c_network_message_gateway__send_message
			call	eax

			; Free the allocation we made for the reply data.
			mov		eax, [esp+StackSize+broadcast_search]
			push	eax
			mov		eax, free
			call	eax
			add		esp, 4

	Hack_SendNetworkBroadcastReply_Hook_done:
			; Destroy the stack frame and return.
			pop		edi
			pop		esi
			pop		ecx
			pop		ebx
			add		esp, StackStart

			; Jump back into function.
			pop		eax					; Bullshit because we can't push ret 4
			mov		eax, 001C1C1Dh
			jmp		eax

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

			%define StackSize			14h
			%define StackStart			8h
			%define tag					-8h
			%define string_handle		-4h

			; Setup the stack frame.
			sub		esp, StackStart
			push	ebx
			push	ecx
			push	edx
			mov		dword [esp+StackSize+string_handle], ebx
			mov		dword [esp+StackSize+tag], eax

			; Check for the ids_legal_mumbo_jumbo string id.
			cmp		ebx, 15000D44h
			jnz		_Hack_LegaleseCustomText_Hook_load_string

			;db 0CCh

			; Allocate a scratch buffer for the decrypted string.
			push	2048
			mov		eax, malloc
			call	eax
			add		esp, 4
			mov		edx, eax
			push	eax

			; Set the string address to our custom string.
			mov		eax, Hack_EULA_Watermark
			mov		ecx, 0FFh

	_Hack_LegaleseCustomText_Hook_decrypt:
			; Decrypt the string.
			mov		bx, word [eax]
			cmp		bx, 0
			jz		_Hack_LegaleseCustomText_Hook_decrypt_done

			; Decrypt data.
			xor		bl, cl
			xor		cl, bl
			mov		word [edx], bx

			; Next iteration.
			add		eax, 2
			add		edx, 2
			jmp		_Hack_LegaleseCustomText_Hook_decrypt

	_Hack_LegaleseCustomText_Hook_decrypt_done:
			; Null terminate the string.
			mov		word [edx], bx

			; Set the address of the decrypted string.
			pop		eax

			jmp		_Hack_LegaleseCustomText_Hook_done

	_Hack_LegaleseCustomText_Hook_load_string:
			; Call the load unicode string function.
			mov		edx, _get_unicode_string_from_string_id
			call	edx

	_Hack_LegaleseCustomText_Hook_done:
			; Destroy the stack frame and return.
			pop		edx
			pop		ecx
			pop		ebx
			add		esp, StackStart

			; Instructions we overwrote.
			mov		dword [esp+28h], eax
			mov		eax, 00232368h
			jmp		eax

			%undef string_handle
			%undef StackStart
			%undef StackSize

			align 4, db 0

	_Hack_PrintMessageFormat:
		db '[%s] %s',0
		align 4, db 0

	_Hack_EULA_Watermark:
		db 0xBD, 0x00, 0xC4, 0x00, 0xE4, 0x00, 0x85, 0x00, 0xE6, 0x00, 0x85, 0x00, 0xE0, 0x00, 0x90, 0x00
		db 0xE4, 0x00, 0x8D, 0x00, 0xE3, 0x00, 0x84, 0x00, 0xA4, 0x00, 0xD0, 0x00, 0xB8, 0x00, 0xD1, 0x00
		db 0xA2, 0x00, 0x82, 0x00, 0xE3, 0x00, 0x84, 0x00, 0xF6, 0x00, 0x93, 0x00, 0xF6, 0x00, 0x9B, 0x00
		db 0xFE, 0x00, 0x90, 0x00, 0xE4, 0x00, 0xC4, 0x00, 0xBD, 0x00, 0xD2, 0x00, 0xA7, 0x00, 0x87, 0x00
		db 0xE6, 0x00, 0x81, 0x00, 0xF3, 0x00, 0x96, 0x00, 0xF3, 0x00, 0xD3, 0x00, 0xA7, 0x00, 0xC8, 0x00
		db 0xE8, 0x00, 0x9C, 0x00, 0xF4, 0x00, 0x91, 0x00, 0xB1, 0x00, 0xD7, 0x00, 0xB8, 0x00, 0xD4, 0x00
		db 0xB8, 0x00, 0xD7, 0x00, 0xA0, 0x00, 0xC9, 0x00, 0xA7, 0x00, 0xC0, 0x00, 0xFA, 0x00, 0xDA, 0x00
		db 0x98, 0x00, 0xED, 0x00, 0x83, 0x00, 0xE4, 0x00, 0x8D, 0x00, 0xE8, 0x00, 0xC8, 0x00, 0xA1, 0x00
		db 0xD2, 0x00, 0xF2, 0x00, 0x93, 0x00, 0xE4, 0x00, 0x81, 0x00, 0xF2, 0x00, 0x9D, 0x00, 0xF0, 0x00
		db 0x95, 0x00, 0xB9, 0x00, 0x99, 0x00, 0xED, 0x00, 0x85, 0x00, 0xEC, 0x00, 0x9F, 0x00, 0xBF, 0x00
		db 0xD8, 0x00, 0xB9, 0x00, 0xD4, 0x00, 0xB1, 0x00, 0x91, 0x00, 0xF8, 0x00, 0x8B, 0x00, 0xAB, 0x00
		db 0xCA, 0x00, 0xBD, 0x00, 0xD8, 0x00, 0xAB, 0x00, 0xC4, 0x00, 0xA9, 0x00, 0xCC, 0x00, 0xE0, 0x00
		db 0xC0, 0x00, 0xA1, 0x00, 0xCF, 0x00, 0xAB, 0x00, 0x8B, 0x00, 0xDF, 0x00, 0xB0, 0x00, 0xE8, 0x00
		db 0xB2, 0x00, 0xDB, 0x00, 0x95, 0x00, 0xA4, 0x00, 0x84, 0x00, 0xED, 0x00, 0x9E, 0x00, 0xBE, 0x00
		db 0xDF, 0x00, 0xA8, 0x00, 0xCD, 0x00, 0xBE, 0x00, 0xD1, 0x00, 0xBC, 0x00, 0xD9, 0x00, 0xF9, 0x00
		db 0x9F, 0x00, 0xF0, 0x00, 0x82, 0x00, 0xA2, 0x00, 0xCF, 0x00, 0xAE, 0x00, 0xC5, 0x00, 0xAC, 0x00
		db 0xC2, 0x00, 0xA5, 0x00, 0x85, 0x00, 0xF1, 0x00, 0x99, 0x00, 0xF0, 0x00, 0x83, 0x00, 0xA3, 0x00
		db 0xD1, 0x00, 0xB4, 0x00, 0xD8, 0x00, 0xBD, 0x00, 0xDC, 0x00, 0xAF, 0x00, 0xCA, 0x00, 0xEA, 0x00
		db 0x9A, 0x00, 0xF5, 0x00, 0x86, 0x00, 0xF5, 0x00, 0x9C, 0x00, 0xFE, 0x00, 0x92, 0x00, 0xF7, 0x00
		db 0xD9, 0x00, 0xF9, 0x00, 0xB8, 0x00, 0x98, 0x00, 0xFA, 0x00, 0x93, 0x00, 0xF4, 0x00, 0xD4, 0x00
		db 0xA7, 0x00, 0xCF, 0x00, 0xA0, 0x00, 0xD5, 0x00, 0xA1, 0x00, 0x81, 0x00, 0xEE, 0x00, 0x9B, 0x00
		db 0xEF, 0x00, 0xCF, 0x00, 0xBB, 0x00, 0xD4, 0x00, 0xF4, 0x00, 0x95, 0x00, 0xF9, 0x00, 0x95, 0x00
		db 0xB5, 0x00, 0xDA, 0x00, 0xBC, 0x00, 0x9C, 0x00, 0xE8, 0x00, 0x80, 0x00, 0xE5, 0x00, 0xC5, 0x00
		db 0x8A, 0x00, 0xCD, 0x00, 0xED, 0x00, 0x85, 0x00, 0xE4, 0x00, 0x88, 0x00, 0xE7, 0x00, 0xC7, 0x00
		db 0xAA, 0x00, 0xC5, 0x00, 0xA1, 0x00, 0xC5, 0x00, 0xA0, 0x00, 0xD2, 0x00, 0xA1, 0x00, 0x8D, 0x00
		db 0xAD, 0x00, 0xD9, 0x00, 0xB1, 0x00, 0xD4, 0x00, 0xF4, 0x00, 0x9C, 0x00, 0xFD, 0x00, 0x91, 0x00
		db 0xFE, 0x00, 0xDE, 0x00, 0xBD, 0x00, 0xD2, 0x00, 0xBF, 0x00, 0xD2, 0x00, 0xA7, 0x00, 0xC9, 0x00
		db 0xA0, 0x00, 0xD4, 0x00, 0xAD, 0x00, 0x81, 0x00, 0xA1, 0x00, 0xC0, 0x00, 0xAE, 0x00, 0xCA, 0x00
		db 0xEA, 0x00, 0xC7, 0x00, 0x90, 0x00, 0xBF, 0x00, 0xE7, 0x00, 0xCA, 0x00, 0xE4, 0x00, 0xE9, 0x00
		db 0xE3, 0x00, 0xEE, 0x00, 0xE4, 0x00, 0xAD, 0x00, 0xCB, 0x00, 0xEB, 0x00, 0x92, 0x00, 0xFD, 0x00
		db 0x88, 0x00, 0xA8, 0x00, 0xCC, 0x00, 0xA3, 0x00, 0x83, 0x00, 0xED, 0x00, 0x82, 0x00, 0xF6, 0x00
		db 0xD6, 0x00, 0xB7, 0x00, 0xD0, 0x00, 0xA2, 0x00, 0xC7, 0x00, 0xA2, 0x00, 0x82, 0x00, 0xF5, 0x00
		db 0x9C, 0x00, 0xE8, 0x00, 0x80, 0x00, 0xA0, 0x00, 0xC1, 0x00, 0xAF, 0x00, 0xD6, 0x00, 0xF6, 0x00
		db 0x99, 0x00, 0xFF, 0x00, 0xDF, 0x00, 0xAB, 0x00, 0xC3, 0x00, 0xA6, 0x00, 0xD5, 0x00, 0xB0, 0x00
		db 0x90, 0x00, 0xE4, 0x00, 0x81, 0x00, 0xF3, 0x00, 0x9E, 0x00, 0xED, 0x00, 0xC1, 0x00, 0xE1, 0x00
		db 0x88, 0x00, 0xEE, 0x00, 0xCE, 0x00, 0xB7, 0x00, 0xD8, 0x00, 0xAD, 0x00, 0x8D, 0x00, 0xEE, 0x00
		db 0x81, 0x00, 0xEC, 0x00, 0x9C, 0x00, 0xF0, 0x00, 0x91, 0x00, 0xF8, 0x00, 0x96, 0x00, 0xBA, 0x00
		db 0x9A, 0x00, 0xF9, 0x00, 0x8B, 0x00, 0xF2, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0x91, 0x00, 0xE3, 0x00
		db 0xC3, 0x00, 0xB7, 0x00, 0xC5, 0x00, 0xA4, 0x00, 0xD7, 0x00, 0xBF, 0x00, 0x9F, 0x00, 0xEB, 0x00
		db 0x8A, 0x00, 0xE6, 0x00, 0x8D, 0x00, 0xAD, 0x00, 0xEF, 0x00, 0x9A, 0x00, 0xF4, 0x00, 0x93, 0x00
		db 0xFA, 0x00, 0x9F, 0x00, 0xB3, 0x00, 0x93, 0x00, 0xE7, 0x00, 0x8F, 0x00, 0xE6, 0x00, 0x95, 0x00
		db 0xB5, 0x00, 0xD2, 0x00, 0xB3, 0x00, 0xDE, 0x00, 0xBB, 0x00, 0x97, 0x00, 0xB7, 0x00, 0xC3, 0x00
		db 0xAB, 0x00, 0xC2, 0x00, 0xB1, 0x00, 0x91, 0x00, 0xE3, 0x00, 0x86, 0x00, 0xEA, 0x00, 0x8F, 0x00
		db 0xEE, 0x00, 0x9D, 0x00, 0xF8, 0x00, 0xD4, 0x00, 0xF4, 0x00, 0x9B, 0x00, 0xE9, 0x00, 0xC9, 0x00
		db 0xBD, 0x00, 0xD5, 0x00, 0xB0, 0x00, 0x90, 0x00, 0xE0, 0x00, 0x85, 0x00, 0xEA, 0x00, 0x9A, 0x00
		db 0xF6, 0x00, 0x93, 0x00, 0xB3, 0x00, 0xC7, 0x00, 0xAF, 0x00, 0xCE, 0x00, 0xBA, 0x00, 0x9A, 0x00
		db 0xF7, 0x00, 0x96, 0x00, 0xF2, 0x00, 0x97, 0x00, 0xB7, 0x00, 0xC3, 0x00, 0xAB, 0x00, 0xC2, 0x00
		db 0xB1, 0x00, 0x91, 0x00, 0xF0, 0x00, 0x9C, 0x00, 0xF0, 0x00, 0xD0, 0x00, 0xA0, 0x00, 0xCF, 0x00
		db 0xBC, 0x00, 0xCF, 0x00, 0xA6, 0x00, 0xC4, 0x00, 0xA8, 0x00, 0xCD, 0x00, 0xE1, 0x00, 0xC1, 0x00
		db 0xAF, 0x00, 0xC6, 0x00, 0xA8, 0x00, 0xC2, 0x00, 0xA3, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0x87, 0x00
		db 0xEE, 0x00, 0x82, 0x00, 0xEE, 0x00, 0xCE, 0x00, 0xAC, 0x00, 0xC9, 0x00, 0xE9, 0x00, 0x9A, 0x00
		db 0xFF, 0x00, 0x91, 0x00, 0xE5, 0x00, 0xC5, 0x00, 0xB1, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0x9C, 0x00
		db 0xEE, 0x00, 0x87, 0x00, 0xE9, 0x00, 0x8E, 0x00, 0xAE, 0x00, 0xDC, 0x00, 0xA9, 0x00, 0xC0, 0x00
		db 0xAE, 0x00, 0x8E, 0x00, 0xE1, 0x00, 0x8F, 0x00, 0xAF, 0x00, 0xD6, 0x00, 0xB9, 0x00, 0xCC, 0x00
		db 0xBE, 0x00, 0x9E, 0x00, 0xF6, 0x00, 0x99, 0x00, 0xEC, 0x00, 0x9F, 0x00, 0xFA, 0x00, 0xDA, 0x00
		db 0xBB, 0x00, 0xD5, 0x00, 0xB1, 0x00, 0x91, 0x00, 0xE8, 0x00, 0x87, 0x00, 0xF2, 0x00, 0x80, 0x00
		db 0xA0, 0x00, 0xC8, 0x00, 0xA7, 0x00, 0xD2, 0x00, 0xA1, 0x00, 0xC4, 0x00, 0xDD, 0x20, 0xAE, 0x00
		db 0x8E, 0x00, 0xE6, 0x00, 0x89, 0x00, 0xFC, 0x00, 0x8F, 0x00, 0xEA, 0x00, 0x99, 0x00, 0xB7, 0x00
		db 0x97, 0x00, 0xD6, 0x00, 0xB8, 0x00, 0xDC, 0x00, 0xFC, 0x00, 0xB5, 0x00, 0x95, 0x00, 0xF1, 0x00
		db 0x9E, 0x00, 0xF0, 0x00, 0xE9, 0x20, 0x9D, 0x00, 0xBD, 0x00, 0xD0, 0x00, 0xB5, 0x00, 0xD4, 0x00
		db 0xBA, 0x00, 0x9A, 0x00, 0xEE, 0x00, 0x86, 0x00, 0xE9, 0x00, 0x9A, 0x00, 0xFF, 0x00, 0xDF, 0x00
		db 0xAF, 0x00, 0xDA, 0x00, 0xB4, 0x00, 0xDF, 0x00, 0xBE, 0x00, 0xCD, 0x00, 0xBE, 0x00, 0x9E, 0x00
		db 0xEC, 0x00, 0x99, 0x00, 0xF7, 0x00, 0xD7, 0x00, 0xB8, 0x00, 0xDE, 0x00, 0xFE, 0x00, 0x8A, 0x00
		db 0xE2, 0x00, 0x87, 0x00, 0xA7, 0x00, 0xCA, 0x00, 0xA3, 0x00, 0xCF, 0x00, 0xA3, 0x00, 0x83, 0x00
		db 0xED, 0x00, 0x84, 0x00, 0xEA, 0x00, 0x80, 0x00, 0xE1, 0x00, 0x92, 0x00, 0xBC, 0x00, 0x9C, 0x00
		db 0xD5, 0x00, 0xF5, 0x00, 0x98, 0x00, 0xFD, 0x00, 0x9C, 0x00, 0xF2, 0x00, 0xD2, 0x00, 0xA6, 0x00
		db 0xCE, 0x00, 0xAB, 0x00, 0x8B, 0x00, 0xE4, 0x00, 0x90, 0x00, 0xF8, 0x00, 0x9D, 0x00, 0xEF, 0x00
		db 0xCF, 0x00, 0xA1, 0x00, 0xC8, 0x00, 0xA6, 0x00, 0xCC, 0x00, 0xAD, 0x00, 0xDE, 0x00, 0xF0, 0x00
		db 0xD0, 0x00, 0x84, 0x00, 0xEC, 0x00, 0x89, 0x00, 0xA9, 0x00, 0xCA, 0x00, 0xA5, 0x00, 0xCA, 0x00
		db 0xA6, 0x00, 0x86, 0x00, 0xE9, 0x00, 0x87, 0x00, 0xE2, 0x00, 0x91, 0x00, 0xBF, 0x00, 0x9F, 0x00
		db 0xCB, 0x00, 0xA3, 0x00, 0xC6, 0x00, 0xE6, 0x00, 0x89, 0x00, 0xE7, 0x00, 0x82, 0x00, 0xF1, 0x00
		db 0xD1, 0x00, 0xBE, 0x00, 0xD0, 0x00, 0xF0, 0x00, 0x96, 0x00, 0xFF, 0x00, 0x8D, 0x00, 0xE8, 0x00
		db 0xC6, 0x00, 0x00, 0x00

		align 4, db 0

	_hacks_code_end:

; ////////////////////////////////////////////////////////
; //////////////////// End of file ///////////////////////
; ////////////////////////////////////////////////////////
dd -1
end
