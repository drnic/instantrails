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

// Apache.cpp: implementation of the CApache class.
//
//////////////////////////////////////////////////////////////////////

#include "CApache.h"

#include <stdio.h>

#include "utils.h"

// Constantes
#define APACHE_DEFAULT_PORT	80

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CApache::CApache() :
#ifdef V2
	ServerBase("Apache2", APACHE_DEFAULT_PORT)
#else
	ServerBase("Apache", APACHE_DEFAULT_PORT)
#endif
{
	char szTempPath[MAX_PATH] = {0};

	_snprintf(m_sServerRootPath, sizeof(m_sServerRootPath)-1, "%sApache\\", CUtils::GetEasyPhpPath());

	_snprintf(szTempPath, sizeof(szTempPath)-1, "%sconf\\httpd.conf", (LPCTSTR) m_sServerRootPath);
	SetConfFile(szTempPath);

	_snprintf(szTempPath, sizeof(szTempPath)-1, "%sconf_files\\httpd.conf", CUtils::GetEasyPhpPath());
	SetTemplateConfFile(szTempPath);

	_snprintf(szTempPath, MAX_PATH-1, "%sapache.exe", (LPCTSTR) m_sServerRootPath);
	SetExePath(szTempPath);

	m_sDocumentRootPath[0] = '\0';
	m_bModeSSL = false;

	ReadConfFile();

	if (m_sDocumentRootPath[0] == '\0')	// pas trouvé ? alors on assume {EasyPath}\www
		_snprintf(m_sDocumentRootPath, MAX_PATH-1, "%swww", CUtils::GetEasyPhpPath());

	CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId);
}

// Fonctions communes
DWORD CApache::Restart()
{
	DWORD dwRetour = ERROR_SUCCESS;
	
	if (IsStarted())
	{
		char szApacheRestartEvent[31] = {0};
		HANDLE hEventRestart = NULL;

		// Apache bug : use %d instead of %u ! (see on 9X)
		_snprintf(szApacheRestartEvent, sizeof(szApacheRestartEvent)-1, "ap%d_restart", GetProcID());
		CUtils::Log("Apache restart event: %s", szApacheRestartEvent);

		if ((hEventRestart=OpenEvent(EVENT_MODIFY_STATE, 0, szApacheRestartEvent)) != NULL)
		{
			SetQueryRestart(true);
			SetEvent(hEventRestart);
			CloseHandle(hEventRestart);
		}
		else
		{
			char szToExecute[MAX_PATH+50] = {0};

			_snprintf(szToExecute, sizeof(szToExecute)-1, "%s -k restart", (LPCTSTR) GetExePath());
			dwRetour = WinExec(szToExecute, SW_HIDE);
			if (dwRetour > 31)
				dwRetour = ERROR_SUCCESS;
		}
	}

	return dwRetour;
}

DWORD CApache::InstallService()
{
	DWORD dwRetour = ERROR_SUCCESS;
	char szPathToExecute[MAX_PATH+1] = {0};

	_snprintf(szPathToExecute, MAX_PATH, "%s -k install", (LPCTSTR) GetExePath());
	dwRetour = WinExec(szPathToExecute, SW_HIDE);

	if (dwRetour > 31)
		dwRetour = FinishInstallService();

	return dwRetour;
}

DWORD CApache::RemoveService()
{
	DWORD dwRetour = PreRemoveService();
	char szPathToExecute[MAX_PATH+1] = {0};

	_snprintf(szPathToExecute, MAX_PATH, "%s -k uninstall", (LPCTSTR) GetExePath());
	dwRetour = WinExec(szPathToExecute, SW_HIDE);

	if (dwRetour > 31)
		dwRetour = ERROR_SUCCESS;

	return dwRetour;
}

// Fonctions propres a Apache
const char *CApache::GetDocumentRootPath()
{
	return m_sDocumentRootPath;
}

bool CApache::GetSSLMode()
{
	return m_bModeSSL;
}

bool CApache::SetSSLMode(bool baNewSSLMode)
{
	m_bModeSSL = baNewSSLMode;
	return m_bModeSSL;
}

// Fonctions privées communes
DWORD CApache::StartExe()
{
	DWORD niRetour = ERROR_SUCCESS;
	char szCommande[MAX_PATH+100] = {0};

	if (m_bModeSSL)
		_snprintf(szCommande, sizeof(szCommande)-1, "%s -k start -D SSL", GetExePath());
	else
#ifdef V2
		_snprintf(szCommande, sizeof(szCommande)-1, "%s", GetExePath());
#else
		_snprintf(szCommande, sizeof(szCommande)-1, "%s -k start", GetExePath());
#endif

	// A FAIRE utiliser tout le temps CreateProcess ?
	// StartChildProcess fout la merde si ont sort sans arreter apache.
	if (CUtils::IsWindowsNT())	// NT only..Scan Process not availble on NT.
	{
		STARTUPINFO start = {0};
		start.cb = sizeof(STARTUPINFO);
		start.lpTitle="Apache";
		start.lpReserved2=NULL;
		start.lpDesktop=NULL;
		start.lpReserved = NULL;
		start.dwFlags = STARTF_USESHOWWINDOW;
		start.wShowWindow = SW_HIDE;

		if (CreateProcess(NULL, szCommande, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, (LPCTSTR) m_sServerRootPath, &start, &m_stProcInfo) == 0)
		{
			niRetour = GetLastError();
			CUtils::Log("Apache::CreateProcess return %d", niRetour);
		}
		else niRetour = 0;
	}
	else
	{
		CUtils::Log("StartChildProcess \"%s\"", szCommande);
		if ((niRetour = StartChildProcess(szCommande, FALSE)) == 0)
		{
			Sleep(1500);	// On attends que le processus soit bien lancé...
			m_stProcInfo.dwProcessId = 0;
			CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId);
			CUtils::Log("Apache::StartExe ScanProcess found pid=%u", m_stProcInfo.dwProcessId);
		}
		else CUtils::Log("StartChildProcess fail %d \"%s\"", niRetour, szCommande);
	}

	return niRetour;
}

DWORD CApache::StopExe()
{
	DWORD dwRetour = ERROR_SUCCESS;

	if (IsStarted())
	{
		char szApacheShutdownEvent[30] = {0};
		HANDLE hEventShutdown = NULL;
			
		// Apache bug : use %d instead of %u ! (see on 9X)
		_snprintf(szApacheShutdownEvent, sizeof(szApacheShutdownEvent)-1, "ap%d_shutdown", GetProcID());
		CUtils::Log("Apache stop event: %s", szApacheShutdownEvent);

		if ((hEventShutdown=OpenEvent(EVENT_MODIFY_STATE, 0, szApacheShutdownEvent)) != NULL)
		{
			SetEvent(hEventShutdown);
			CloseHandle(hEventShutdown);
		}
		else
		{
			char szToExecute[MAX_PATH+50] = {0};

			CUtils::Log("Apache::StopExe stop event fail : %d", GetLastError());
			_snprintf(szToExecute, sizeof(szToExecute)-1, "%s -k shutdown", (LPCTSTR) GetExePath());
			dwRetour = WinExec(szToExecute, SW_HIDE);
			if (dwRetour > 31)
				dwRetour = ERROR_SUCCESS;
		}
	}

	TerminateChildProcess();

	return dwRetour;
}

int CApache::ReadConfFile()
{
	FILE *pFile = NULL;

	if ((pFile = fopen(GetConfFile(), "r+t")) != NULL)
	{
		char szLine[300] = {0};
		bool bDocumentRootFound = false, biPortFound = false;

		// renseigner les variables
		while (fgets(szLine, 300, pFile) && (biPortFound==false || bDocumentRootFound==false))
		{
			if (szLine[0] != '#')
			{
				if (strncmp(szLine, "Port", 4)==ERROR_SUCCESS && !biPortFound)
				{
					m_niPort = 0;
					// A FAIRE : prendre en compte Listen plutot que Port !
					sscanf(szLine, "Port %d\n", &m_niPort);
					biPortFound = true;
				}
				if (strstr(szLine, "DocumentRoot") && !bDocumentRootFound)
				{
					char *pciDocRoot = strchr(szLine, ' ');
					if (pciDocRoot)
					{
						pciDocRoot = strchr(pciDocRoot, '"');
						if (pciDocRoot)
						{
							strncpy(m_sDocumentRootPath, ++pciDocRoot, sizeof(m_sDocumentRootPath)-1);
							
							for (int niI = 0; m_sDocumentRootPath[niI]!='0'; niI++)
							{
								if (m_sDocumentRootPath[niI] == '/')
									m_sDocumentRootPath[niI] = '\\';
								else if (m_sDocumentRootPath[niI] == '"')
									m_sDocumentRootPath[niI] = '\0';
							}
							bDocumentRootFound = true;
						}
					}
				}
			}
		}

		fclose(pFile);
	}

	return 0;
}

bool CApache::VerifyConfFile()
{
	char szCmdLine[2*MAX_PATH] = {0};
	char szFileCheck[MAX_PATH] = {0};
	char szBatPath[MAX_PATH] = {0};
	static char szBuffer[2000] = {0};
	bool biRetour = true;
	FILE *piFile = NULL;
	static bool biLock = false;

	// Marche mal sous 9X...
	if (GetVersion() & 0x80000000)
		return true;

	if (biLock)
		return false;

	biLock = true;

	_snprintf(szCmdLine, 2*MAX_PATH-1, "%sApache.exe -t 2> %s", m_sServerRootPath, szFileCheck);
//	StartChildProcess(szCmdLine);

	// On lance la commande Apache -t > chkap.txt a partir d'un .bat
	// sinon ca ne marche pas avec WinExec, et system() affiche une fenetre
	// console

	_snprintf(szFileCheck, MAX_PATH-1, "%schkap.txt", m_sServerRootPath);
	_snprintf(szCmdLine, 2*MAX_PATH-1, "%sApache.exe -t 2> %s", m_sServerRootPath, szFileCheck);
	_snprintf(szBatPath, MAX_PATH-1, "%schkap.bat", m_sServerRootPath);

	// Genere le .bat
	if ((piFile = fopen(szBatPath, "w")) != NULL)
	{
		fprintf(piFile, "%s\n", szCmdLine);
		fclose(piFile);
	}

//	ShellExecute(NULL, "open", szBatPath, NULL, NULL, SW_HIDE);
	// Execution du .bat
//	WinExec(szBatPath, SW_HIDE);

	STARTUPINFO lpStartupInfo = {0};
	PROCESS_INFORMATION		stProcInfo;
	_snprintf(szCmdLine, 2*MAX_PATH-1, "cmd /C %s", szBatPath);

	lpStartupInfo.cb = sizeof(STARTUPINFO);
	lpStartupInfo.dwFlags = STARTF_USESHOWWINDOW;
	lpStartupInfo.wShowWindow = SW_HIDE;

	if (!CreateProcess(NULL, szCmdLine, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, NULL, &lpStartupInfo, &stProcInfo))
	{
		DWORD dwRetour = GetLastError();
		CUtils::Log("CApache::VerifyConfFile CreateProcess fail %d \"%s\"", dwRetour, szCmdLine);
	}
	else
	{
		bool biContinue = true;
		// On est obligé d'attendre que le .bat soit terminé....
		for (int niCpt = 0; niCpt < 3 && biContinue; niCpt++)
		{
			Sleep(300);

			// Lecture du résultat
			if ((piFile = fopen(szFileCheck, "r")) != NULL)
			{
				char *pciLastCR;
				int nbRead = fread(szBuffer,1,  2000, piFile);

				biContinue = (nbRead < 10);

				if (!biContinue)
				{
					szBuffer[nbRead] = '\0';
					if ((pciLastCR = strrchr(szBuffer, '\n')) != NULL)
						*pciLastCR = '\0';
					biRetour = (strstr(szBuffer, "Syntax OK") != NULL);
				}
				fclose(piFile);
			}
		}
		DeleteFile(szFileCheck);
		DeleteFile(szBatPath);
	//	Sleep(1000);	// Sinon le processus n'est pas fini et ScanProcess renvoi celui-ci...
		DWORD dwWait = WaitForSingleObject(stProcInfo.hProcess, 3000);
		if (dwWait == WAIT_TIMEOUT)
			CUtils::Log("VerifyConfFile : WaitForSingleObject timeout for pid %u", stProcInfo.dwProcessId);

		if (!biRetour)
			SendMessage(m_hWnd, GetMessageId(), MSG_ERROR_CONF, (LPARAM) szBuffer);
	}

	biLock = false;

	return biRetour;
}
