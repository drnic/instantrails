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

// ServerBase.h: interface for the ServerBase class.
//
//////////////////////////////////////////////////////////////////////

#pragma once

#include "define.h"

#include <windows.h>	// HWND
#include <Winsvc.h>		// SC_HANDLE
#include <time.h>		// FILETIME

#define MAX_NB_INSTANCES	10

// Constantes pour messages renvoyés a la fenêtre
#define MSG_UNEXPECTED_END	0	// le serveur s'est terminé anormalement
#define MSG_LOG				1
#define MSG_ERROR_CONF		2
#define MSG_CHANGE_CONF		3	// changement dans le fichier de conf.

class ServerBase
{
public:
	ServerBase(const char *szaServiceName, UINT naPort);
	virtual ~ServerBase();

	virtual	DWORD			Start();
	virtual	DWORD			Stop();

	// Fonctions virtuelles pures
	virtual DWORD			Restart() = 0;
	virtual DWORD			InstallService() = 0;
	virtual DWORD			RemoveService() = 0;

	DWORD					Kill();

	bool					SetService(bool baService);
	bool					IsService();

	const char*				GetServerName();

	SERVER_STATE			GetState();
	bool					IsStarted();

	UINT					GetMessageId();

	bool					GetQueryRestart();
	void					SetQueryRestart(bool baIsRestarting);

	const char *			GetExePath();

	const char *			GetConfFile();
	const char *			GetTemplateConfFile();
	bool					GetConfReload();
	void					SetConfReload(bool baReloadApacheConf);

	DWORD					GetProcID(void);

	UINT					GetPort();
	static void				SetCheckPortBeforeStarting(bool baCheckPort);

	void					SetWindowNotify(HWND haWnd);

	virtual	bool			VerifyConfFile();

public:
	void					OnChildStarted(LPCSTR lpszCmdLine);
	virtual void			OnChildStdOutWrite(LPCSTR lpszOutput);
	virtual void			OnChildStdErrWrite(LPCSTR lpszOutput);
	virtual void			OnChildTerminate();

protected:
	void					SetConfFile(const char*szaPathConf);
	void					SetTemplateConfFile(const char*szaTemplateConfPath);
	void					SetExePath(const char*szaExePath);

	// Methodes
	DWORD					FinishInstallService();
	DWORD					PreRemoveService();

private:
	// ces 2 fonctions retournent 0 si succes, sinon la valeur d'un GetLastError()
	virtual DWORD			StartExe() = 0;
	virtual DWORD			StopExe() = 0;
	virtual int				ReadConfFile() { return 0; };

protected:
	PROCESS_INFORMATION		m_stProcInfo;
	SC_HANDLE				m_hServiceHandle;
	UINT					m_niPort;

	UINT					m_uiWndMessage;
	HWND					m_hWnd;			// Handle de la fenetre "cliente"

	char					m_szConfFile[MAX_PATH];
	char					m_szTemplateConfFile[MAX_PATH];

private:
	void					FormatOutputMessage(LPCSTR szaString, UINT naErrorCode = 0);

private:
	char					m_szServiceName[30];
	char					m_szExePath[MAX_PATH];
	SERVER_STATE			m_iServerState;

	bool					m_bAsService;
	bool					m_bIsRestarting;

	bool					m_bConfReload;

	FILETIME				m_TimeConfModified;
	FILETIME				m_TimeTemplateConfModified;

	// variables statiques
	static bool				ms_bCheckPort;
	static UINT				m_uiTimerIdent;
	static ServerBase *		m_pInstances[MAX_NB_INSTANCES];
	static void CALLBACK	TimerProc(HWND, UINT, UINT, DWORD);
};
