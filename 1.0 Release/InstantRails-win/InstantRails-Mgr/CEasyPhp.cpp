/* Instant Rails Manager 1.8
 * Copyright (c) 2005 Curt Hibbs
 * Copyright (c) 2002 Easyphp www.easyphp.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// CEasyPHP.cpp: implementation of the CEasyPHP class.
//
//////////////////////////////////////////////////////////////////////

#include "CEasyPhp.h"
#include "Utils.h"
#include "Langue.h"
#include <stdio.h>
#include <stdlib.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CEasyPHP::CEasyPHP()
{
	strncpy(m_szInstallPath, CUtils::GetEasyPhpPath(), sizeof(m_szInstallPath)-1);
	_snprintf(m_szIniPath, sizeof(m_szIniPath)-1, "%sInstantRails.ini", m_szInstallPath);
	_snprintf(m_szLogPath, sizeof(m_szLogPath)-1, "%sInstantRails.log", m_szInstallPath);
	GetModuleFileName(GetModuleHandle(NULL), m_szManagerPath, sizeof(m_szManagerPath)-1);

	strncpy(m_szAppName, "Instant Rails", sizeof(m_szAppName)-1);

	m_sMySql_Arguments[0] = '\0';
	m_bModeSSL = false;
	m_bCheckVersionAtStartup = false;
	m_bStartAsService = false;
	m_bForceNotepad = false;
	memset(m_sMySql_Arguments, 0, sizeof(m_sMySql_Arguments));
	m_bWinExpand = true;
	memset(m_szSelectedLang, 0, sizeof(m_szSelectedLang));

	char szReadConf[100] = {0};
	GetPrivateProfileString("InstantRails", "AutoStartServers", "", szReadConf, 100, IniPath());

	// cf http://www.easyphp.org/forums/read.php?f=7&i=90967&t=90967#reply_90967		
 	if (GetPrivateProfileString("InstantRails", "EasyPHPLogPath", "", szReadConf, MAX_PATH, IniPath()))
		strncpy(m_szLogPath, szReadConf, MAX_PATH-1);

	GetPrivateProfileString("InstantRails", "OldRunningPath", "", m_szOldRunningPath, sizeof(m_szOldRunningPath)-1, IniPath());
	if (m_szOldRunningPath[0] == '\0') // pas trouvé
		CUtils::GetLongPathName(m_szInstallPath, m_szOldRunningPath, sizeof(m_szOldRunningPath)-1);

	GetPrivateProfileString("InstantRails", "ForceNotepad", "N", szReadConf, 100, IniPath());		
	m_bForceNotepad = (szReadConf[0] == 'Y');

	GetPrivateProfileString("InstantRails", "AutoStartServers", "Y", szReadConf, 100, IniPath());		
	m_bAutoStartServeurs = (szReadConf[0] == 'Y');

	GetPrivateProfileString("InstantRails", "AutoStartEasyPhp", "N", szReadConf, 100, IniPath());
	m_bAutoStartEasyPhp = (szReadConf[0] == 'Y');

	GetPrivateProfileString("InstantRails", "AutoReloadConf", "Y", szReadConf, 100, IniPath());
	m_bAutoReloadConf = (szReadConf[0] == 'Y');

	GetPrivateProfileString("InstantRails", "CheckServerPorts", "Y", szReadConf, 100, IniPath());
	m_bCheckServerPorts = (szReadConf[0] == 'Y');

	GetPrivateProfileString("MySql", "MySqlArguments", "", szReadConf, 100, IniPath());
	strncpy(m_sMySql_Arguments, szReadConf, 255);

//		GetPrivateProfileString("InstantRails", "ModeSSL", "", szReadConf, 100, IniPath());
//		m_bModeSSL = (szReadConf[0] == 'Y');

	GetPrivateProfileString("InstantRails", "CheckVersion", "Y", szReadConf, 100, IniPath());
	m_bCheckVersionAtStartup = (szReadConf[0] == 'Y');

	if (CUtils::IsWindowsNTPlatform())
	{
		GetPrivateProfileString("InstantRails", "StartAsServices", "N", szReadConf, 100, IniPath());
		m_bStartAsService = (szReadConf[0] == 'Y');
	}
	GetPrivateProfileString("InstantRails", "ShowAlways", "N", szReadConf, 100, IniPath());
	m_bShowAlways = (szReadConf[0] == 'Y');
	GetPrivateProfileString("InstantRails", "ExpandPos", "", szReadConf, 100, IniPath());
	m_bWinExpand = (szReadConf[0] == 'Y');

	//GetPrivateProfileString("InstantRails", "Lang", CLangue::GuessPreferedLanguage(), m_szSelectedLang, 50, IniPath());

	// Init Path (pour les extensions, etc)...
	char szPath[2048] =  {0};
	_snprintf(szPath, sizeof(szPath)-1, "PATH=%s;%sruby\\bin;%sApache;%sPHP", getenv("PATH"), CUtils::GetEasyPhpPath(), CUtils::GetEasyPhpPath(), CUtils::GetEasyPhpPath());
	putenv(szPath);
/* Pour test...
	PROCESS_INFORMATION pi = {0};
	STARTUPINFO si = {0};
	BOOL bResult = ::CreateProcess(NULL, "cmd /k set", NULL, NULL, TRUE,
						CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi);
*/
}

CEasyPHP::~CEasyPHP()
{
	Save();
}

const char* CEasyPHP::GetAppName()
{
	return m_szAppName;
}

DWORD CEasyPHP::Save()
{
	static char szStartRegister[] = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
	HKEY hKeyStart = NULL;
	DWORD dwRetour = ERROR_SUCCESS;

	WritePrivateProfileString("InstantRails", "AutoStartServers", m_bAutoStartServeurs ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "ForceNotepad", m_bForceNotepad ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "AutoStartEasyPhp", m_bAutoStartEasyPhp ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "AutoReloadConf", m_bAutoReloadConf ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "CheckServerPorts", m_bCheckServerPorts ? "Y" : "N", IniPath());

//	WritePrivateProfileString("MySql", "MySqlArguments", m_sMySql_Arguments, IniPath());
//	WritePrivateProfileString("InstantRails", "ModeSSL", m_bModeSSL ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "CheckVersion", m_bCheckVersionAtStartup ? "Y" : "N", IniPath());
	// On met le path courant..
	CUtils::GetLongPathName(m_szInstallPath, m_szOldRunningPath, sizeof(m_szOldRunningPath)-1);
	WritePrivateProfileString("InstantRails", "OldRunningPath", m_szOldRunningPath, IniPath());

	if (CUtils::IsWindowsNTPlatform())
		WritePrivateProfileString("InstantRails", "StartAsServices", m_bStartAsService ? "Y" : "N", IniPath());
	WritePrivateProfileString("InstantRails", "ShowAlways", m_bShowAlways ? "Y" : "N", IniPath());

	WritePrivateProfileString("InstantRails", "ExpandPos", m_bWinExpand ? "Y" : "N", IniPath());
//	WritePrivateProfileString("InstantRails", "Lang", m_szSelectedLang, IniPath());

	HKEY hKey = NULL;
	if ((dwRetour = RegOpenKey(HKEY_CURRENT_USER, "Software\\EasyPhp", &hKey)) == ERROR_SUCCESS)
	{
		RegDeleteKey(hKey, "Configuration");
		RegCloseKey(hKey);
	}

	// Composition de la clé de redémarrage
	if ((dwRetour = RegOpenKeyEx(HKEY_LOCAL_MACHINE, szStartRegister, 0, KEY_ALL_ACCESS, &hKeyStart)) ==
			ERROR_SUCCESS)
	{
		if (m_bAutoStartEasyPhp)
		{
			char szProgramToLauchAtRestart[MAX_PATH] = {0};
			DWORD niSizeString = GetModuleFileName(GetModuleHandle(NULL), &(szProgramToLauchAtRestart[1]), MAX_PATH-2);

			szProgramToLauchAtRestart[0]='"';
			szProgramToLauchAtRestart[niSizeString+1]='"';

			RegSetValueEx(hKeyStart, m_szAppName, 0, REG_SZ, (CONST BYTE *)szProgramToLauchAtRestart,
									strlen(szProgramToLauchAtRestart) + 1);
		}
		else RegDeleteValue(hKeyStart, m_szAppName);
		RegCloseKey(hKeyStart);
	}

	return dwRetour;
}

const char* CEasyPHP::InstallPath()
{
	return m_szInstallPath;
}

bool CEasyPHP::ForceNotepad()
{
	return m_bForceNotepad;
}

const char* CEasyPHP::OldRunningPath()
{
	return m_szOldRunningPath;
}

const char* CEasyPHP::IniPath()
{
	return m_szIniPath;
}

const char* CEasyPHP::LogPath()
{
	return m_szLogPath;
}

const char* CEasyPHP::ManagerPath()
{
	return m_szManagerPath;
}