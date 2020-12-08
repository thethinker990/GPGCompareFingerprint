#cs
    GPGCompareFingerprint - Comparing a fingerprint from the first *.asc-File in the script directory with the fingerprint stored in the clipboard.
    Copyright (C) 2020  Patrick Schnitzer

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
	
	===========================================
		Author:  Patrick Schnitzer
		Date:    08.12.2020 16:55

		Purpose: Easy comparison if the gpg fingerprint matches
				 Compares the first found *.asc file in the script folder
				 with the fingerprint stored in the clipboard
	
		Source:  https://github.com/thethinker990/GPGCompareFingerprint
	--------------------------------------------
	Returns
	--------
		Display the result in a message box
	--------------------------------------------
	Revision History
	-----------------
		08.12.2020 PS: Initial Version
	===========================================
#ce

#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <String.au3>

Local $cpData, $gpgPID, $GPGCommand, $gpgFingerprintTemp, $gpgFingerprintArray, $gpgFingerprintFound

; Look for PGP ASCII Armored file
If Not FileExists(".\*.asc") Then
	$ErrorMessage = "No PGP ASCII Armored File found in the script directory."
	If MsgBox($MB_RETRYCANCEL + $MB_ICONINFORMATION, "No File", $ErrorMessage) <> $IDRETRY Then Exit
EndIf

; Retrieve the data stored in the clipboard and remove blanks.
$cpData = StringReplace(ClipGet(), " ", "")

; ClipGet() error handling
Switch @error
	Case 0
		; Display the data returned by ClipGet.
		; MsgBox($MB_OK + $MB_ICONINFORMATION, "Content", "The following data is stored in the clipboard: " & @CRLF & $cpData)

	Case 1
		$ErrorMessage = "The Clipboard is empty."
		If MsgBox($MB_RETRYCANCEL + $MB_ICONINFORMATION, "Clipboard Empty", $ErrorMessage) <> $IDRETRY Then Exit

	Case 2
		$ErrorMessage = "The value was no string."
		If MsgBox($MB_RETRYCANCEL + $MB_ICONWARNING, "Data Error", $ErrorMessage) <> $IDRETRY Then Exit	

	Case 3 To 4
		$ErrorMessage = "Can not access clipboard."
		MsgBox($MB_OK + $MB_ICONWARNING, "Data Error", $ErrorMessage)
		Exit

	Case Else
		$ErrorMessage = "Unknown Error."
		MsgBox($MB_OK + $MB_ICONERROR, "Error", $ErrorMessage)
		Exit
EndSwitch

; Run GPG on command line hidden
$GPGCommand = "gpg --with-colons --import-options show-only --import --fingerprint *.asc"
$gpgPID = Run(@ComSpec & " /c " & $GPGCommand, "", @SW_HIDE, $STDOUT_CHILD)

; Wait until the process has closed using the PID returned by Run.
ProcessWaitClose($gpgPID)

; Read the Stdout stream of the PID returned by Run. Split at new line and store it in array
$gpgFingerprintArray = StringSplit(StdoutRead($gpgPID),@CRLF)

; StdoutRead() error handling
Select 
	Case @error <> 0
		$ErrorMessage = "Unknown Error while reading stdout from ComSpec."
		MsgBox($MB_OK + $MB_ICONERROR, "Error", $ErrorMessage)
		Exit
EndSelect

; Parse fingerprint
For $i = 0 To UBound($gpgFingerprintArray)
	If StringInStr($gpgFingerprintArray[$i],"fpr") Then
		$gpgFingerprintTemp = _StringBetween($gpgFingerprintArray[$i],":",":")
		$gpgFingerprintFound = $gpgFingerprintTemp[UBound($gpgFingerprintTemp)-1]
		ExitLoop
	EndIf
Next

; Compare fingerprint from gpg with clipboard data
If StringInStr($gpgFingerprintFound, $cpData) <> 0 And StringCompare($gpgFingerprintFound, $cpData) = 0 Then
	MsgBox($MB_OK + $MB_ICONINFORMATION	,"", "The fingerprint does match." & @CRLF & _
										$gpgFingerprintFound & " (File)" & @CRLF & _
										$cpData & " (Clipboard)")
Else
	MsgBox($MB_OK + $MB_ICONWARNING	,"", "The fingerprint doesn't match." & @CRLF & _
										$gpgFingerprintFound & " (File)" & @CRLF & _
										$cpData & " (Clipboard)")
EndIf
