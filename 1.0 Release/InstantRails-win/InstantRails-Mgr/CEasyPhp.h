/* EasyPHP Manager 1.8
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

// CEasyPHP.h: interface for the CEasyPHP class.
//
//////////////////////////////////////////////////////////////////////

#pragma once

#include <windows.h>

class CEasyPHP
{
public:
	CEasyPHP();
	virtual ~CEasyPHP();

	const char*			GetAppName();

	DWORD Save();

	const char* InstallPath();
	bool ForceNotepad();
	const char* OldRunningPath();
	const char* IniPath();
	const char* LogPath();
	const char* ManagerPath();

protected:
	char		m_szInstallPath[MAX_PATH];
	char		m_szOldRunningPath[MAX_PATH];
	char		m_szIniPath[MAX_PATH];
	char		m_szLogPath[MAX_PATH];
	char		m_szManagerPath[MAX_PATH];
	char		m_szAppName[20];

public:
	// Parametres de configuration
	bool			m_bAutoStartServeurs;
	bool			m_bForceNotepad;
	bool			m_bForceServers;
	bool			m_bAutoStartEasyPhp;
	bool			m_bAutoReloadConf;
	bool			m_bCheckServerPorts;
	char			m_sMySql_Arguments[255];
	bool			m_bModeSSL;
	bool			m_bCheckVersionAtStartup;
	bool			m_bStartAsService;
	bool			m_bShowAlways;
	bool			m_bWinExpand;
	char			m_szSelectedLang[50];
};
