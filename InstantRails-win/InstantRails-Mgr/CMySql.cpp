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

// MySql.cpp: implementation of the CMySql class.
//
//////////////////////////////////////////////////////////////////////

#include "CMySql.h"
#include "utils.h"

#include  <io.h>	// _access
#include  <stdio.h>	// _snprintf

#include "resource.h"	// IDS_MYSQL_LANGUAGE
#include "Langue.h"

// Constantes
#define MYSQL_DEFAULT_PORT	3306

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CMySql::CMySql() :
	ServerBase("MySQL", MYSQL_DEFAULT_PORT)
{
	char szMySqlExe[4][_MAX_PATH] = { "mysqld.exe", "mysqld-nt.exe", "mysqld-opt.exe", "mysqld-shareware.exe"};
	char szMyIniPath[_MAX_PATH] = {0}, szExePath[_MAX_PATH] = {0};

	_snprintf(m_sMySqlPath, sizeof(m_sMySqlPath)-1, "%sMySql\\", CUtils::GetEasyPhpPath());

	for (int niI = 0; niI <= 3; niI++)
	{
		_snprintf(szExePath, _MAX_PATH-1, "%sbin\\%s", (LPCTSTR) m_sMySqlPath, szMySqlExe[niI]);
		if (_access(szExePath, 0) != -1)
		{
			SetExePath(szExePath);
			break;
		}
	}
 
/*	GetWindowsDirectory(szMyIniPath, MAX_PATH);
	strcat(szMyIniPath, "\\My.Ini");*/
	_snprintf(szMyIniPath, sizeof(szMyIniPath)-1, "%smy.ini", m_sMySqlPath);

	SetConfFile(szMyIniPath);

	char szTempPath[MAX_PATH] = {0};
	_snprintf(szTempPath, sizeof(szTempPath)-1, "%sconf_files\\my.ini", CUtils::GetEasyPhpPath());
	SetTemplateConfFile(szTempPath);

	m_szMySqlParams[0] = '\0';

	CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId);
	ReadConfFile();
}

// Fonctions communes
DWORD CMySql::Restart()
{
	DWORD dwRetour = ERROR_SUCCESS;

	if (IsService())
		dwRetour = CUtils::StopThisService(m_hServiceHandle);
	else
	{
		if ((dwRetour = Stop()) == ERROR_SUCCESS)
			dwRetour = Start();
	}

	SetQueryRestart(true);

	return dwRetour;
}

DWORD CMySql::InstallService()
{
	DWORD dwRetour = ERROR_SUCCESS;
	char szPathToExecute[MAX_PATH+1] = {0};

	_snprintf(szPathToExecute, MAX_PATH, "%s --install %s --defaults-file=\"%s\"", (LPCTSTR) GetExePath(), GetServerName(), m_szConfFile);
	dwRetour = WinExec(szPathToExecute, SW_HIDE);

	if (dwRetour > 31)
		dwRetour = ERROR_SUCCESS;
	else dwRetour = FinishInstallService();

	return dwRetour;
}

DWORD CMySql::RemoveService()
{
	DWORD dwRetour = PreRemoveService();
	char szPathToExecute[MAX_PATH+1] = {0};

	_snprintf(szPathToExecute, MAX_PATH, "%s --remove", (LPCTSTR) GetExePath());
	dwRetour = WinExec(szPathToExecute, SW_HIDE);

	if (dwRetour > 31)
		dwRetour = ERROR_SUCCESS;

	return dwRetour;
}

// Fonctions propres a MySql
void CMySql::SetParameters(const char *szaParameters)
{
	strncpy(m_szMySqlParams, szaParameters, 255);
}

// Fonctions privées communes
DWORD CMySql::StartExe()
{
	STARTUPINFO lpStartupInfo = {0};
	DWORD dwRetour = ERROR_SUCCESS;
	char szToExecute[MAX_PATH+500] = {0}, szParameters[300] = {0};

//	_snprintf(szParameters, sizeof(szParameters)-1, "--defaults-file=D:\\Easyphp\\mysql\\my.ini --basedir=\"D:\\Easyphp\\mysql\\\"", (LPCTSTR) m_sMySqlPath, m_szMySqlParams);
//	CUtils::ConvertToUnixPath(szParameters);

//	_snprintf(szToExecute, sizeof(szToExecute)-1, "%s %s", GetExePath(), szParameters);
	_snprintf(szToExecute, sizeof(szToExecute)-1, "%s --defaults-file=\"%s\" --language=%s", GetExePath(), m_szConfFile, CLangue::LoadString(IDS_MYSQL_LANGUAGE));
//	_snprintf(szToExecute, sizeof(szToExecute)-1, "%s --language=%s", GetExePath(), CLangue::LoadString(IDS_MYSQL_LANGUAGE));
	lpStartupInfo.cb = sizeof(STARTUPINFO);
	lpStartupInfo.dwFlags = STARTF_USESHOWWINDOW;
	lpStartupInfo.wShowWindow = SW_HIDE;

	CUtils::Log("CreateProcess \"%s\"", szToExecute);
/*	StartChildProcess(szToExecute, FALSE);
	Sleep(50);*/
	if (!CreateProcess(NULL, szToExecute, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, NULL, &lpStartupInfo, &m_stProcInfo))
	{
		dwRetour = GetLastError();
		CUtils::Log("CreateProcess fail %d \"%s\"", dwRetour, szToExecute);
	}
	else dwRetour = ERROR_SUCCESS;

	return dwRetour;
}

DWORD CMySql::StopExe()
{
	DWORD dwRetour = ERROR_SUCCESS;
	HANDLE hEventShutdown = NULL;
	char szShutdownEvent[31] =  {0};

	_snprintf(szShutdownEvent, sizeof(szShutdownEvent)-1, "MySQLShutdown%u", GetProcID());

	CUtils::Log("MySqlSutdown event = %s", szShutdownEvent);
	if ((hEventShutdown=OpenEvent(EVENT_MODIFY_STATE, 0, szShutdownEvent)) != NULL)
	{
		SetEvent(hEventShutdown);
		CloseHandle(hEventShutdown);
	}
	else
	{
		dwRetour = GetLastError();
		CUtils::Log("MySqlSutdown event open fail = %d", dwRetour);

//		if (dwRetour==ERROR_FILE_NOT_FOUND || )
		{
			char szToExecute[MAX_PATH+50] = {0};

			_snprintf(szToExecute, sizeof(szToExecute)-1, "%sbin\\mysqladmin.exe -u root shutdown", (LPCTSTR) m_sMySqlPath);
			dwRetour = WinExec(szToExecute, SW_HIDE);
			if (dwRetour > 31)
				dwRetour = ERROR_SUCCESS;
		}
	}

	return dwRetour;
}

int CMySql::ReadConfFile()
{
	// bug http://www.easyphp.org/forums/read.php?f=7&i=115491&t=114487#reply_115491
	m_niPort = GetPrivateProfileInt("mysqld", "Port", MYSQL_DEFAULT_PORT, m_szTemplateConfFile);
/*
	char pciCommandLine[MAX_PATH*2];
	char pciTempFile[MAX_PATH];

	::GetTempFileName(".", "Eas", 0, pciTempFile);

	_snprintf(pciCommandLine, sizeof(pciCommandLine)-1, "%smysql\\bin\\mysqladmin.exe variables > %s", m_szInstallPath, pciTempFile);

	STARTUPINFO lpStartupInfo = {0};
	PROCESS_INFORMATION lpProcessInfo = {0};

//	if (WinExec(pciCommandLine, SW_HIDE))
	if (CreateProcess(NULL, pciCommandLine, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, NULL, 
		&lpStartupInfo, &lpProcessInfo))
//	if (system(pciCommandLine) != -1)
	{
		FILE *piFile = fopen(pciTempFile, "r");
		if (piFile)
		{
			char pciLine[300];
			while(fgets(pciLine, 300, piFile) != NULL)
			{
				if (pciLine[0] == '|')
				{
					char pciVar[50], pciVal[MAX_PATH];
					sscanf(pciLine, "");
					m_MySqlVariables.InsertItem(-1, pciLine);
//					m_MySqlVariables.SetItemText(0, 
				}
			}
			fclose(piFile);
		}
	}
	
	DeleteFile(pciTempFile);
*/
	return 0;
}
