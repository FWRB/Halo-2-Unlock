@ECHO OFF


REM Applies the patch to an XBE with the newly created .hacks code segment, and outputs the result to a new location.
REM If you didn't add a new code segment to your XBE, do so using XboxImageXploder.
REM NOTE: All files must be in the current batch files folder.

ECHO COMPILING ALPHA...
ECHO -------------------
SET PATCH_PATH="%~dp0\H2AlphaUnlock.asm"
SET IN_PATH="%~dp0\alpha_ext.xbe"
SET OUT_PATH="%~dp0\alpha_unlocked.xbe"
IF EXIST %PATCH_PATH% (
	IF EXIST %IN_PATH% (
		XePatcher.exe -p %PATCH_PATH% -proc x86 -bin %IN_PATH% -o %OUT_PATH%
	) ELSE (
		ECHO Cannot find XBE with extended .hacks code segment at %PATCH_PATH%
	)
) ELSE (
	ECHO Cannot find patch file at %PATCH_PATH%
)

ECHO.
ECHO.

ECHO COMPILING BETA...
ECHO -------------------
SET PATCH_PATH="%~dp0\H2BetaUnlock.asm"
SET IN_PATH="%~dp0\beta_ext.xbe"
SET OUT_PATH="%~dp0\beta_unlocked.xbe"
IF EXIST %PATCH_PATH% (
	IF EXIST %IN_PATH% (
		XePatcher.exe -p %PATCH_PATH% -proc x86 -bin %IN_PATH% -o %OUT_PATH%
	) ELSE (
		ECHO Cannot find XBE with extended .hacks code segment at %PATCH_PATH%
	)
) ELSE (
	ECHO Cannot find patch file at %PATCH_PATH%
)


REM Pause to allow the user to read command output
PAUSE
