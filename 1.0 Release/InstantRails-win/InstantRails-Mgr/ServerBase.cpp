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

// ServerBase.cpp: implementation of the ServerBase class.
//
//////////////////////////////////////////////////////////////////////

#include "ServerBase.h"
#include "Utils.h"
#include <stdio.h>	// _snprintf
#include "GenConf.h"

ServerBase *ServerBase::m_pInstances[MAX_NB_INSTANCES] = {0};

UINT ServerBase::m_uiTimerIdent = SetTimer(NULL, 0, 700, (TIMERPROC) TimerProc);
bool ServerBase::ms_bCheckPort = true;

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

ServerBase::ServerBase(const char *szaServiceName, UINT naPort)
{
	char szMessageName[51] = {0};

	strncpy(m_szServiceName, szaServiceName, sizeof(m_szServiceName)-1);
	m_hServiceHandle = CUtils::GetThisService(m_szServiceName);

	memset((void *) &m_stProcInfo, 0, sizeof(PROCESS_INFORMATION));
	m_niPort = naPort;

	m_iServerState = SERVER_STOPPED;
	_snprintf(szMessageName, sizeof(szMessageName)-1, "EasyPhp_%s", m_szServiceName);
	m_uiWndMessage = ::RegisterWindowMessage(szMessageName);
	m_bAsService = false;
	m_hWnd = NULL;
	m_bIsRestarting = false;

	m_bConfReload = false;
	memset(m_szConfFile, 0, sizeof(m_szConfFile));
	memset(m_szTemplateConfFile, 0, sizeof(m_szTemplateConfFile));
	memset(m_szExePath, 0, sizeof(m_szExePath));

	CUtils::GetModifiedTime((LPCTSTR) m_szConfFile, &m_TimeConfModified);
	CUtils::GetModifiedTime((LPCTSTR) m_szTemplateConfFile, &m_TimeTemplateConfModified);
	
	// Mise a jour du tableau d'instances
	for (unsigned int niI = 0; niI < MAX_NB_INSTANCES; niI++)
	{
		if (m_pInstances[niI] == NULL)
		{
			m_pInstances[niI] = this;
			break;
		}
	}
}

ServerBase::~ServerBase()
{
	if (m_hServiceHandle)
		CloseServiceHandle(m_hServiceHandle);

	m_hServiceHandle = NULL;

	for (unsigned int niI = 0; niI < MAX_NB_INSTANCES; niI++)
	{
		if (m_pInstances[niI] == this)
			m_pInstances[niI] = NULL;
	}
}

DWORD ServerBase::Start()
{
	DWORD dwRetour = ERROR_SUCCESS;

	if (GetState() == SERVER_STOPPED)
	{
		if (VerifyConfFile())
		{
			m_iServerState = SERVER_START_PENDING;

			if (IsService())
			{
				if (!m_hServiceHandle)
					m_hServiceHandle = CUtils::GetThisService(m_szServiceName);
				if (m_hServiceHandle)
				{
					dwRetour = CUtils::StartThisService(m_hServiceHandle);
					CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId);
				}
				else dwRetour = GetLastError();
			}
			else
			{
				if (CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId))
				{
					CUtils::Log("%s ServerBase::Start ScanProcess -> %d", m_szServiceName, m_stProcInfo.dwProcessId);
					dwRetour = ERROR_SUCCESS;
				}
				else
				{
					bool biPortUsed = false;

					if (ms_bCheckPort)
					{
						DWORD dwProcID = 0;
						 if (CUtils::IsPortUsedByProcess(m_niPort, dwProcID, biPortUsed) == false)
							biPortUsed = CUtils::IsPortUsed(m_niPort);
					}

					if (biPortUsed == false)
						dwRetour = StartExe();
					else dwRetour = WSAEADDRINUSE;
				}
			}
		}
		else CUtils::Log("%s VerifyConfFile fail...", m_szServiceName);
	}

/*	if (niRetour != 0)
		m_iServerState = SERVER_STOPPED;*/

	return dwRetour;
}

DWORD ServerBase::Stop()
{
	DWORD dwRetour = ERROR_SUCCESS;

	if (GetState() == SERVER_RUNNING)
	{
		if (IsService())
			dwRetour = CUtils::StopThisService(m_hServiceHandle);
		else
			dwRetour = StopExe();

		if (dwRetour == ERROR_SUCCESS)
			m_iServerState = SERVER_STOP_PENDING;
	}

	SetQueryRestart(false);

	return dwRetour;
}

DWORD ServerBase::Kill()
{
	DWORD dwError = ERROR_SUCCESS;

	if (!IsService())
	{
		HANDLE hProcess = NULL;
		
		m_iServerState = SERVER_STOP_PENDING;

		if (m_stProcInfo.dwProcessId == 0)
			CUtils::ScanProcess(GetExePath(), m_stProcInfo.dwProcessId);

		if (m_stProcInfo.dwProcessId != 0)
		{
			if ((hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, m_stProcInfo.dwProcessId)) != NULL)
			{
				if (TerminateProcess(hProcess, 0))
					m_stProcInfo.dwProcessId = 0;
				else dwError = GetLastError();
				CloseHandle(hProcess);
			}
			else dwError = GetLastError();
		}
	}

	return dwError;
}

DWORD ServerBase::FinishInstallService()
{
	if (m_hServiceHandle)
		CloseServiceHandle(m_hServiceHandle);

	Sleep(200);
	m_hServiceHandle = CUtils::GetThisService(m_szServiceName);

	return (m_hServiceHandle != NULL ? ERROR_SUCCESS : ERROR_FILE_NOT_FOUND);
}

DWORD ServerBase::PreRemoveService()
{
	DWORD dwRetour = ERROR_SUCCESS;

	if (m_hServiceHandle)
	{
		if (CloseServiceHandle(m_hServiceHandle) == FALSE)
			dwRetour = GetLastError();
		m_hServiceHandle = NULL;
	}
	return dwRetour;
}

const char*	ServerBase::GetServerName()
{
	return m_szServiceName;
}

void ServerBase::SetExePath(const char*szaExePath)
{
	strncpy(m_szExePath, szaExePath, sizeof(m_szExePath)-1);
}

const char *ServerBase::GetExePath()
{
	return m_szExePath;
}

SERVER_STATE ServerBase::GetState()
{
	return m_iServerState;
}

bool ServerBase::IsStarted()
{
	return (m_iServerState == SERVER_RUNNING);
}

UINT ServerBase::GetMessageId()
{
	return m_uiWndMessage;
}

bool ServerBase::SetService(bool baService)
{
	if (m_iServerState == SERVER_STOPPED)
	{
		m_bAsService = baService;
		return true;
	}
	else return false;
}

bool ServerBase::IsService()
{
	return m_bAsService;
}

bool ServerBase::GetQueryRestart()
{
	return m_bIsRestarting;
}

void ServerBase::SetQueryRestart(bool baIsRestarting)
{
	m_bIsRestarting = baIsRestarting;
}

void ServerBase::SetConfFile(const char*szaPathConf)
{
	strncpy(m_szConfFile, szaPathConf, sizeof(m_szConfFile)-1); 
	CUtils::GetModifiedTime((LPCTSTR) m_szConfFile, &m_TimeConfModified);
}

const char *ServerBase::GetTemplateConfFile()
{
	if (m_szTemplateConfFile[0] != 0)
		return m_szTemplateConfFile;
	else return m_szConfFile;
}

void ServerBase::SetTemplateConfFile(const char*szaTemplateConfPath)
{
	strncpy(m_szTemplateConfFile, szaTemplateConfPath, sizeof(m_szTemplateConfFile)-1); 
	CUtils::GetModifiedTime((LPCTSTR) m_szTemplateConfFile, &m_TimeTemplateConfModified);
}

const char *ServerBase::GetConfFile()
{
	return m_szConfFile;
}

bool ServerBase::GetConfReload()
{
	return m_bConfReload;
}

void ServerBase::SetConfReload(bool baReloadApacheConf)
{
	m_bConfReload = baReloadApacheConf;
}

DWORD ServerBase::GetProcID(void)
{
	return m_stProcInfo.dwProcessId;
}

UINT ServerBase::GetPort()
{
	return m_niPort;
}

void ServerBase::SetCheckPortBeforeStarting(bool baCheckPort)
{
	ms_bCheckPort = baCheckPort;
}

void ServerBase::SetWindowNotify(HWND haWnd)
{
	m_hWnd = haWnd;
}

bool ServerBase::VerifyConfFile()
{
	return true;
}

// Privées
void CALLBACK ServerBase::TimerProc(HWND, UINT naMsg, UINT naIdent, DWORD dwaTime)
{
	for (unsigned int niI = 0; niI < MAX_NB_INSTANCES; niI++)
	{
		if (m_pInstances[niI] != NULL)
		{
			ServerBase *pServeur = m_pInstances[niI];

			if (pServeur->IsService() && pServeur->m_hServiceHandle)
			{
				SERVICE_STATUS stServiceStatus;

				QueryServiceStatus(pServeur->m_hServiceHandle, &stServiceStatus);
				switch (stServiceStatus.dwCurrentState)
				{
				case SERVICE_STOPPED : pServeur->m_iServerState = SERVER_STOPPED; break;
				case SERVICE_START_PENDING: pServeur->m_iServerState = SERVER_START_PENDING; break;
				case SERVICE_STOP_PENDING: pServeur->m_iServerState = SERVER_STOP_PENDING; break;
				case SERVICE_RUNNING:
					pServeur->m_iServerState = SERVER_RUNNING;
					if (pServeur->m_stProcInfo.dwProcessId == 0)
						CUtils::ScanProcess(pServeur->GetExePath(), pServeur->m_stProcInfo.dwProcessId);
					break;

				case SERVICE_CONTINUE_PENDING:
				case SERVICE_PAUSE_PENDING:
				case SERVICE_PAUSED: pServeur->m_iServerState = SERVER_START_PENDING; break;
				}
			}
			else
			{
				DWORD diRetour, dwLastError = ERROR_SUCCESS;
				BOOL biIsRunning = false;

				diRetour = GetProcessVersion(pServeur->m_stProcInfo.dwProcessId);
				if (diRetour == 0)
				{
					dwLastError = GetLastError();
					CUtils::Log("ServerBase::TimerProc : GetProcessVersion %s (pid: %u) error %d", pServeur->m_szServiceName, pServeur->m_stProcInfo.dwProcessId, dwLastError);
				}
				biIsRunning = (diRetour != 0 && pServeur->m_stProcInfo.dwProcessId);
				if(!biIsRunning)
				{
					// A FAIRE :  Utiliser CRedirect::OnChildTerminate()
					// Pas lancé
					if(pServeur->m_iServerState == SERVER_RUNNING && !pServeur->GetQueryRestart())
					{
						if (pServeur->m_hWnd)
							PostMessage(pServeur->m_hWnd, pServeur->m_uiWndMessage, (WPARAM)MSG_UNEXPECTED_END, (LPARAM) 0);
					}
					memset(&pServeur->m_stProcInfo, 0, sizeof(PROCESS_INFORMATION));
					pServeur->m_iServerState = SERVER_STOPPED;
				}
				else
				{
					// Lancé
					if (pServeur->m_iServerState == SERVER_STOP_PENDING)
					{
						// peut-etre pas la peine d'insister...
//						pServeur->Stop();
					}
					else 
					{
//					if (pServeur->m_iServerState == SERVER_START_PENDING)
						pServeur->m_iServerState = SERVER_RUNNING;
					}
				}
			}

			FILETIME aTime;

			// On regenere même si le serveur n'est pas lancé sinon il ne redemarrerait pas
			// si il y a une erreur dans le fichier de conf.
			CUtils::GetModifiedTime(pServeur->m_szTemplateConfFile, &aTime);
			if (aTime.dwLowDateTime && aTime.dwHighDateTime &&
				memcmp((void *) &aTime, (void *) &(pServeur->m_TimeTemplateConfModified), sizeof(FILETIME)))
			{
				// Fichier template modifié ? on le regenere ce qui provoque le rechargement (voir [1])
				char szEasyPHPPath[MAX_PATH] = {0};

				strncpy(szEasyPHPPath, CUtils::GetEasyPhpPath(), sizeof(szEasyPHPPath));
				szEasyPHPPath[strlen(szEasyPHPPath)-1] = '\0';	// vire le dernier '\'
				CUtils::ConvertToUnixPath(szEasyPHPPath);
				GenerateConfFile(szEasyPHPPath, pServeur->m_szTemplateConfFile, pServeur->m_szConfFile, '#');
				pServeur->m_TimeTemplateConfModified = aTime;
			}

			// [1]
			CUtils::GetModifiedTime(pServeur->m_szConfFile, &aTime);
			if (aTime.dwLowDateTime && aTime.dwHighDateTime &&
				memcmp((void *) &aTime, (void *) &(pServeur->m_TimeConfModified), sizeof(FILETIME)))
			{
				pServeur->ReadConfFile();
				PostMessage(pServeur->m_hWnd, pServeur->m_uiWndMessage, (WPARAM)MSG_CHANGE_CONF, (LPARAM) 0);
				pServeur->m_TimeConfModified = aTime;
			}
		}
	}
}

void ServerBase::OnChildStarted(LPCSTR lpszCmdLine)
{
//	SendMessage(m_hWnd, m_uiWndMessage, MSG_LOG, (LPARAM) "Debut");
}

void ServerBase::OnChildStdOutWrite(LPCSTR lpszOutput)
{
	FormatOutputMessage(lpszOutput);
}

void ServerBase::OnChildStdErrWrite(LPCSTR lpszOutput)
{
	FormatOutputMessage(lpszOutput);
}

void ServerBase::OnChildTerminate()
{
	/*
	if(pServeur->m_iServerState == SERVER_RUNNING && !pServeur->GetQueryRestart())
	{
		if (pServeur->m_hWnd)
			PostMessage(pServeur->m_hWnd, pServeur->m_uiWndMessage, (WPARAM)MSG_UNEXPECTED_END, (LPARAM) 0);
	}
	memset(&pServeur->m_stProcInfo, 0, sizeof(PROCESS_INFORMATION));
	pServeur->m_iServerState = SERVER_STOPPED;
	*/

	
//	SendMessage(m_hWnd, m_uiWndMessage, MSG_LOG, (LPARAM) "Fin");
}

void ServerBase::FormatOutputMessage(LPCSTR szaString, UINT naErrorCode)
{
	if (szaString)
	{
		int niI = 0, niCptChar = 0;
		char *szString = strdup(szaString);
		char *szDebut = szString;
		const cLimiteText = 55; 
			
		while (szString[niI] != '\0')
		{
			if (szString[niI] == '\r')
			{
				szString[niI] = '\0';
				SendMessage(m_hWnd, m_uiWndMessage, MSG_LOG, (LPARAM) szDebut);
				szDebut = szString + niI + 2;
				niCptChar = 0;
			}
			else if (niCptChar == cLimiteText)
			{
				char cOld = szString[niI];
				szString[niI] = '\0';
				SendMessage(m_hWnd, m_uiWndMessage, MSG_LOG, (LPARAM) szDebut);
				szString[niI] = cOld;
				szDebut = szString + niI;
				niCptChar = 0;
			}
			else niCptChar++;
			niI++;
		}
		if (*szDebut != '\0')
			SendMessage(m_hWnd, m_uiWndMessage, MSG_LOG, (LPARAM) szDebut);
	}
}