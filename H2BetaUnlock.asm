; ////////////////////////////////////////////////////////
; ////////////////// Preprocessor Stuff //////////////////
; ////////////////////////////////////////////////////////
BITS 32

%define ExecutableBaseAddress			00010000h			; Base address of the executable
%define HacksSegmentAddress				007f4eb0h			; Virtual address of the .hacks segment
%define HacksSegmentOffset				005a9000h			; File offset of the .hacks segment
%define HacksSegmentSize				00002000h			; Size of the .hacks segment

; Macros
%macro HACK_FUNCTION 1
	%define %1			HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

%macro HACK_DATA 1
	%define %1			HacksSegmentAddress + (_%1 - _hacks_code_start)
%endmacro

; Menu handler functions
%define MenuHandler_MainMenu							001AF2F4h
%define MenuHandler_GamertagSelect						002A33B2h

%define Create_MainMenu_Campaign						002A37D7h
%define Create_XboxLive_Menu							001AF36Ah
%define Create_MainMenu_XboxLive						002A37B4h
%define Create_MainMenu_SplitScreen						002A376Eh
%define Create_MainMenu_SystemLink						002A3791h
%define Create_MainMenu_OptionsMenu						001AF108h

; Halo Engine Functions
%define ShowSinglePlayerSettings_offset					003056C8h
%define ShowSplitScreen_3_offset						002A37B4h ; Dumps you into the Xbox Live Menu afterwards
%define ShowScreenError_offset							001B818Ch
%define LoadScreen										000D68B0h

%define InitNetwork_offset								001A49F0h

; void DrawText(RECT *pPosSize, DWORD Unk1, DWORD Unk2, DWORD Unk3, char *pText, DWORD Unk4);
%define DrawText										0001C860h

; void PrintDebugMessage(int category, char *psMessage, char *psTimeStamp, bool bUnk);
%define PrintDebugMessage								000AC020h

; Hooked Halo Engine Screen Creation Functions
%define CreateLegalAcceptanceScreen						000D37C9h
%define CreateNetworkSquadBrowserScreen					001B2357h

; Hooked Halo Engine Drawing Functions
%define DrawWatermark									000D62E0h

; Hook Installs, this may be in some random memory location
; Using hacks to achieve a code cave
%define hkInstall_XInputGetState_offset					00468CECh
%define hkInstall_HandleGamertagSelect_offset			002A3422h

; Kernel imports
%define imp_DbgPrint									004705ECh

%define g_network_link									006DA5C0h
%define broadcast_search_globals_message_gateway		006D8EF0h

%define c_network_message_gateway__send_message			002679B0h
%define _broadcast_search_globals_get_session_nonce		002842A0h
%define get_transport_address							002FE6C0h

%define setsockopt										0043FAB4h
%define GetLastError									003140F3h
%define malloc											00388A1Eh
%define free											0038B09Dh


; Functions in our .hacks segment.
HACK_FUNCTION Hack_PrintDebugMessage
HACK_FUNCTION Hack_MenuHandler_MainMenu

HACK_FUNCTION Hack_SendNetworkBroadcastReply_Hook
HACK_FUNCTION Hack_NetworkSquadListUpdate_Hook

HACK_DATA Hack_PrintMessageFormat
HACK_DATA Hack_FieldOfView
HACK_DATA Hack_CoffeeWatermark

HACK_DATA Hack_MenuHandler_MainMenu_JumpTable





;---------------------------------------------------------
; Disable EULA acceptance screen
;---------------------------------------------------------		
dd			(CreateLegalAcceptanceScreen - ExecutableBaseAddress)
dd			(CreateLegalAcceptanceScreen_end - CreateLegalAcceptanceScreen_start)
CreateLegalAcceptanceScreen_start:

		; Return out of the function to disable it
		retn

CreateLegalAcceptanceScreen_end:

;---------------------------------------------------------
; Disable watermark drawing function
;---------------------------------------------------------
dd			(DrawWatermark - ExecutableBaseAddress)
dd			(DrawWatermark_end - DrawWatermark_start)
DrawWatermark_start:

		%define StackSize		8h
		%define StackStart		8h
		%define MsgPos			-8h

		; Setup stack frame.
		sub		esp, StackStart

		; Setup the watermark size/position.
		lea		eax, [esp+StackSize+MsgPos]
		mov		word [eax], 360			; Pos X
		mov		word [eax+2], 250		; Pos Y
		mov		word [eax+4], 400		; Width?
		mov		word [eax+6], 550		; Height?

		; Draw a bitch'in watermark.
		push	0
		push	Hack_CoffeeWatermark
		push	0
		push	0
		push	0
		push	eax
		mov		eax, DrawText
		call	eax

		; Destroy stack frame and return.
		add		esp, StackStart
		retn

DrawWatermark_end:

;---------------------------------------------------------
; 
;---------------------------------------------------------		
dd			(0014D3CFh - ExecutableBaseAddress)
dd			(patch_log_leve_end - patch_log_level_start)
patch_log_level_start:

		mov		dword [580C88h], 0

patch_log_leve_end:

;---------------------------------------------------------
; Print network debug messages
;---------------------------------------------------------		
dd			(0014CE95h - ExecutableBaseAddress)
dd			(patch_print_net_dbg_end - patch_print_net_dbg_start)
patch_print_net_dbg_start:

		nop
		nop

patch_print_net_dbg_end:

;---------------------------------------------------------
; Hook debug print message function
;---------------------------------------------------------
dd			(PrintDebugMessage - ExecutableBaseAddress)
dd			(PrintDebugMessageHook_end - PrintDebugMessageHook_start)
PrintDebugMessageHook_start:

		; Jump to detour function.
		push	Hack_PrintDebugMessage
		ret

PrintDebugMessageHook_end:

;---------------------------------------------------------
; Hook MenuHandler_MainMenu
;---------------------------------------------------------		
dd			(MenuHandler_MainMenu - ExecutableBaseAddress)
dd			(MenuHandler_MainMenu_end - MenuHandler_MainMenu_start)
MenuHandler_MainMenu_start:

		; Hook to detour.
		push	Hack_MenuHandler_MainMenu
		ret

MenuHandler_MainMenu_end:

;---------------------------------------------------------
; MenuHandler_GamertagSelect -> Bypass xbl profile check shit
;---------------------------------------------------------
dd			(MenuHandler_GamertagSelect - ExecutableBaseAddress) + 70h
dd			(MenuHandler_GamertagSelect_end - MenuHandler_GamertagSelect_start)
MenuHandler_GamertagSelect_start:

		%define GamertagSelect_Base		70h
		%define GamertagSelect_Target	0C2h

		; Skip checks for xbl stuff.
		push		(MenuHandler_GamertagSelect + GamertagSelect_Target)
		ret

		%undef GamertagSelect_Target
		%undef GamertagSelect_Base

MenuHandler_GamertagSelect_end:

;---------------------------------------------------------
; Hook network squad list function that updates available sessions to jump into hacks segment
;---------------------------------------------------------
dd			(0028434Ch - ExecutableBaseAddress)
dd			(_network_squad_list_update_end - _network_squad_list_update_start)
_network_squad_list_update_start:

		; Jump into hacks segment.
		push	Hack_NetworkSquadListUpdate_Hook
		ret

_network_squad_list_update_end:

;---------------------------------------------------------
; Hook the function that sends the broadcast reply
;---------------------------------------------------------
dd			(0027950Eh - ExecutableBaseAddress)
dd			(_send_broadcast_reply_end - _send_broadcast_reply_start)
_send_broadcast_reply_start:

		; Jump into hacks segment.
		lea		eax, [esp+38h]		; game_data structure
		push	eax
		push	Hack_SendNetworkBroadcastReply_Hook
		ret

_send_broadcast_reply_end:

;---------------------------------------------------------
; Field of view hack
;---------------------------------------------------------		
dd			(00103F6Dh - ExecutableBaseAddress)
dd			(_field_of_view_hack_end - _field_of_view_hack_start)
_field_of_view_hack_start:

		movss	xmm0, [Hack_FieldOfView]

_field_of_view_hack_end:

;---------------------------------------------------------
; .hacks code segment
;---------------------------------------------------------
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
		; void Hack_MenuHandler_MainMenu(void *Unk1, void *Unk2)
		;---------------------------------------------------------
_Hack_MenuHandler_MainMenu:

		%define StackSize		4h
		%define StackStart		0h
		%define Unk1			4h
		%define Unk2			8h

		; Setup stack frame.
		sub		esp, StackStart
		push	esi

		;db 0CCh

		; Get the selected menu option index and handle accordingly.
		mov		eax, [esp+StackSize+Unk2]
		movsx	eax, word [eax]
		cmp		eax, 6
		jl		_Hack_MenuHandler_MainMenu_jump
		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_jump:

		; Load jump table address using menu index.
		jmp		dword [Hack_MenuHandler_MainMenu_JumpTable+eax*4]

_Hack_MenuHandler_MainMenu_campaign:

		; Setup campaign menu.
		push	Create_MainMenu_Campaign		; Create menu function
		push	4
		push	3
		push	0
		push	dword [esp+StackSize+Unk1+10h]	; pContext
		call	Hack_LoadScreen

		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_xbox_live:

		; Setup xbox live menu.
		;mov		esi, dword [esp+StackSize+Unk1]
		;push	ecx
		;mov		eax, Create_XboxLive_Menu
		;call	eax

		; Setup campaign menu.
		push	Create_MainMenu_XboxLive		; Create menu function
		push	4
		push	5
		push	0
		push	dword [esp+StackSize+Unk1+10h]	; pContext
		call	Hack_LoadScreen

		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_split_screen:

		; Setup split screen menu.
		push	Create_MainMenu_SplitScreen		; Create menu function
		push	4
		push	5
		push	0
		push	dword [esp+StackSize+Unk1+10h]	; pContext
		call	Hack_LoadScreen

		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_system_link:

		; Setup system link menu.
		push	Create_MainMenu_SystemLink		; Create menu function
		push	4
		push	5
		push	0
		push	dword [esp+StackSize+Unk1+10h]	; pContext
		call	Hack_LoadScreen

		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_options:

		; Setup options menu.
		push	Create_MainMenu_OptionsMenu		; Create menu function
		push	4
		push	5
		push	0
		push	dword [esp+StackSize+Unk1+10h]	; pContext
		call	Hack_LoadScreen

		jmp		_Hack_MenuHandler_MainMenu_done

_Hack_MenuHandler_MainMenu_saved_films:

_Hack_MenuHandler_MainMenu_done:
		; Destroy stack frame and return.
		pop		esi
		add		esp, StackStart
		ret 8

		%undef Unk2
		%undef Unk1
		%undef StackStart
		%undef StackSize

		align 4, db 0

_Hack_MenuHandler_MainMenu_JumpTable
		; Jumptable:
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_campaign - _Hack_MenuHandler_MainMenu)
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_xbox_live - _Hack_MenuHandler_MainMenu)
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_split_screen - _Hack_MenuHandler_MainMenu)
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_system_link - _Hack_MenuHandler_MainMenu)
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_options - _Hack_MenuHandler_MainMenu)
		dd		Hack_MenuHandler_MainMenu + (_Hack_MenuHandler_MainMenu_saved_films - _Hack_MenuHandler_MainMenu)

		;---------------------------------------------------------
		; void Hack_LoadScreen(void *pContext, DWORD Unk1, DWORD Unk2, DWORD Unk3, void *MenuCreateFunc)
		;---------------------------------------------------------
Hack_LoadScreen:

		%define StackSize		24h
		%define StackStart		1Ch
		%define MenuStruct		-1Ch
		%define SetupFunc		-4h
		%define pContext		4h
		%define Unk1			8h
		%define Unk2			0Ch
		%define Unk3			10h
		%define MenuCreateFunc	14h

		; Setup stack frame.
		sub		esp, StackStart
		push	edx
		push	edi

		; Get some value from the context pointer.
		mov		eax, [esp+StackSize+pContext]
		mov		eax, [eax]
		mov		ecx, [eax+4]

		xor		edx, edx
		inc		edx
		shl		edx, cl					; This value indicates if controller input is active on this screen or not

		; Setup the menu struct.
		lea		ecx, [esp+StackSize+MenuStruct]				; Pointer to menu struct
		push	dword [esp+StackSize+MenuCreateFunc]		; Create menu function
		push	dword [esp+StackSize+Unk3+4]				;
		push	dword [esp+StackSize+Unk2+8]				;
		xor		ax, ax										; Used by LoadScreen...
		push	edx											; Some value calculated above
		mov		edx, dword [esp+StackSize+Unk1+10h]			;
		mov		edi, LoadScreen
		call	edi

		; Call setup function?
		call	[esp+StackSize+SetupFunc]

		; Destroy stack frame and return.
		pop		edi
		pop		edx
		add		esp, StackStart
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
		mov		esi, dword [esi+18h]
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
		mov		word [esp+StackSize+broadcast_search_version], 2		; broadcast_search.protocol_version = 0
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
		lea		eax, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
		lea		esi, [esp+StackSize+transport_addr]			; &transport_addr
		push	16											; sizeof(sockaddr_in)
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
		push	ebx
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
		mov		al, [006DA6DCh]		; Check which tick count to use
		test	al, al
		jz		_Hack_NetworkSquadListUpdate_Hook_use_tick_count

		; Jump to trampoline.
		push	00284355h
		ret

_Hack_NetworkSquadListUpdate_Hook_use_tick_count:

		; Jump to trampoline.
		push	0028435Ch
		ret

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
		mov		dword [esp+StackSize+broadcast_search], edi

		; Get the socket handle so we can set the braodcast option.
		mov		esi, dword [g_network_link]
		mov		esi, dword [esi+18h]
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
		lea		eax, [esp+StackSize+broadcast_sockaddr]		; &broadcast_sockaddr
		lea		esi, [esp+StackSize+transport_addr]			; &transport_addr
		push	16											; sizeof(sockaddr_in)
		mov		ecx, get_transport_address
		call	ecx

		; Allocate some memory for the reply data.
		push	1800			; sizeof(s_network_message_broadcast_reply)
		mov		eax, malloc
		call	eax
		add		esp, 4			; Cleanup from malloc()
		cmp		eax, 0
		jz		Hack_SendNetworkBroadcastReply_Hook_done
		mov		ecx, eax

		;db 0CCh

		; Setup the reply header using the nonce from the search message.
		mov		ebx, dword [esp+StackSize+broadcast_search]
		mov		word [ecx], 2			; broadcast_reply_data.protocol = 0
		mov		word [ecx+2], 0
		mov		eax, dword [ebx+4]		; broadcast_search.nonce
		mov		dword [ecx+4], eax		; broadcast_reply_data.nonce = broadcast_search.nonce
		mov		eax, dword [ebx+8]		; broadcast_search.nonce
		mov		dword [ecx+8], eax		; broadcast_reply_data.nonce = broadcast_search.nonce

		; Copy the game data into the rest of the message.
		mov		esi, dword [esp+StackSize+game_data]		; src = game_data
		lea		edi, [ecx+0Ch]								; dst = broadcast_reply_data + sizeof(s_network_message_broadcast_search)
		push	ecx
		mov		ecx, 1788									; size = sizeof(s_network_message_broadcast_reply) - sizeof(s_network_message_broadcast_search)
		rep movsb
		pop		ecx

		; Save the address of the allocation for later.
		mov		dword [esp+StackSize+broadcast_search], ecx

		; Get the context pointer thingo so we can send the network message.
		mov		ebx, dword [broadcast_search_globals_message_gateway]

		; Send the broadcast message.
		push	ecx											; &broadcast_reply_data
		push	1800										; sizeof(s_network_message_broadcast_reply)
		push	3											; _network_message_type_broadcast_reply
		lea		eax, [esp+StackSize+transport_addr+0Ch]
		push	eax											; &transport_addr
		push	ebx
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
		push	0027956Bh
		ret 4

		%undef game_data
		%undef transport_addr
		%undef broadcast_sockaddr
		%undef broadcast_option
		%undef broadcast_search
		%undef StackStart
		%undef StackSize

		align 4, db 0

_Hack_PrintMessageFormat:
	db '[%s] %s',0
	align 4, db 0

_Hack_FieldOfView:
	dd 1.5

_Hack_CoffeeWatermark:
	db "Grim Rocks Halo's Socks", 0
	;db	"//\"
	;db	"V  \"
	;db	" \  \_"
	;db	"  \,'.`-."
	;db	"   \\ `. `.       "
	;db	"   ( \  `. `-.                        _,.-:\"
	;db	"	\ \    `.  `-._             __..--' ,-';/"
	;db	"	 \ `.    `-.   `-..___..---'   _.--' ,'/"
	;db	"	  `. `.     `-._        __..--'    ,' /"
	;db	"		`. `-_      ``--..''       _.-' ,'"
	;db	"		  `-_ `-.___        __,--'   ,'"
	;db	"			 `-.__  `----'''    __.-'"
	;db	"                  `--..____..--'"
	align 4, db 0

_hacks_code_end:

; ////////////////////////////////////////////////////////
; //////////////////// End of file ///////////////////////
; ////////////////////////////////////////////////////////
dd -1
end