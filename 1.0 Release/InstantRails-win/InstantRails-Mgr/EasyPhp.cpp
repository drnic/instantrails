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

// EasyPhp.cpp : Defines the class behaviors for the application.
//

#include "EasyPhpDlg.h"
#include "EasyPhp.h"
#include "Utils.h"

#include <commctrl.h> // InitCommonControlsEx
#include <stdio.h>

HINSTANCE g_hInstance = NULL;
bool g_bRelaunchManager = false;

void TraiteLigneDeCommande(HWND haEasyDlg);
void InitLigneDeCommande();

int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, 
						LPSTR lpCmdLine, int nCmdShow)
{
	HANDLE hiMutex = CreateMutex(NULL, TRUE, "EasyPhpMutex");

	InitLigneDeCommande();

	// On verifie qu'il n'y ait qu'une seule instance du programme.
	if (hiMutex!=NULL && GetLastError()!=ERROR_ALREADY_EXISTS)
	{	
		WSADATA stWSData;
		INITCOMMONCONTROLSEX iccex = {0};
			
		g_hInstance = hInstance;

		// Init Common controls...
		iccex.dwICC = ICC_WIN95_CLASSES;
		iccex.dwSize = sizeof(INITCOMMONCONTROLSEX);
		InitCommonControlsEx(&iccex);

		// Init winsock...
		WSAStartup(MAKEWORD(1, 0), &stWSData);
		
		CUtils::Log("Start Instant Rails, cmdline = %s", lpCmdLine);
		CEasyPhpDlg dlg;
		MSG msg;
		
		HWND hiDlg = dlg.GetHandle();
		TraiteLigneDeCommande(hiDlg);

#ifndef _DEBUG
		try
		{
#endif
			while (GetMessage(&msg, NULL, 0, 0))
			{
				// On gere les raccourcis clavier
				if (msg.message == WM_KEYDOWN && !(HIWORD(msg.lParam) & KF_REPEAT))
				{
					if (GetKeyState(VK_CONTROL) & 0x8000)
					{
						switch (msg.wParam)
						{
						case 'E': PostMessage(hiDlg, WM_COMMAND, ID_EASYPHP_CONF, 0); break;
						case 'X': PostMessage(hiDlg, WM_COMMAND, ID_CONFIGURATION_PHPEXT, 0); break;
						case 'Y': PostMessage(hiDlg, WM_COMMAND, ID_MYADMIN_CONF, 0); break;
						case 'U': PostMessage(hiDlg, WM_COMMAND, ID_CHECK_VERSION, 0); break;
						}
					}
					else
					{
						switch (msg.wParam)
						{
						case VK_F1: PostMessage(hiDlg, WM_COMMAND, ID_AIDE_INTRO, 0); break;
						case VK_F2: PostMessage(hiDlg, WM_COMMAND, ID_START, 0); break;
						case VK_F3: PostMessage(hiDlg, WM_COMMAND, ID_STOP, 0); break;
						case VK_F5: PostMessage(hiDlg, WM_COMMAND, ID_RESTART, 0); break;
						case VK_F7: PostMessage(hiDlg, WM_COMMAND, ID_BROWSE_WEB, 0); break;
						case VK_F8: PostMessage(hiDlg, WM_COMMAND, ID_EXPLORE_DOCROOT, 0); break;
						}
					}
				}

				if (!IsDialogMessage(hiDlg, &msg))
				{
					TranslateMessage(&msg);
					DispatchMessage(&msg);
				}
			}
			WSACleanup();
#ifndef _DEBUG
		}
		catch(...)
		{
			MessageBox(hiDlg, "'Unexpected' crash....\nPlease relaunch the application", "Instant Rails", MB_OK | MB_ICONSTOP);
			CUtils::Log("Unexpected' crash");
			g_bRelaunchManager = true;
		}
		CUtils::Log("End Instant Rails...");
#endif
	}
	else
	{
		HWND hiDlg = ::FindWindow(NULL, "Instant Rails");

		CUtils::Log("New instance Instant Rails, cmdline = %s", lpCmdLine);
		SetForegroundWindow(hiDlg);
		TraiteLigneDeCommande(hiDlg);
	}

	if (hiMutex)
	{
		ReleaseMutex(hiMutex);
		CloseHandle(hiMutex);
	}

	if (g_bRelaunchManager)
	{
		char szExePath[MAX_PATH] = {0};

		GetModuleFileName(NULL, szExePath, sizeof(szExePath)-1);
		WinExec(szExePath, SW_SHOW);
	}

	return ERROR_SUCCESS;
}

stCommande g_stCommandes[] =
{
	{"start",	ID_START, false},
	{"stop",	ID_STOP, false},
	{"restart",	ID_RESTART, false},
	{"browse",	ID_BROWSE_WEB, false},
	{"quit",	ID_QUIT, false},
	{"?",		ID_HELP_CMDLINE, false},
	{"help",	ID_HELP_CMDLINE, false},
	{"show",	ID_EASYPHP_CONF, false},
	{"about",	ID_ABOUT, false},
	{"install", ID_INSTALL, false},
	{"hide",	ID_MINIMIZE, false},
	{"",		0, false}
};

void TraiteLigneDeCommande(HWND haEasyDlg)
{
	for (unsigned int niI = 0; g_stCommandes[niI].m_uiMsg; niI++)
	{
		if (g_stCommandes[niI].m_bSet)
			PostMessage(haEasyDlg, WM_COMMAND, g_stCommandes[niI].m_uiMsg, 0);
	}
}

void InitLigneDeCommande()
{
	for (int niI = 1; niI < __argc; niI++)
	{
		for (unsigned int niJ = 0; g_stCommandes[niJ].m_uiMsg; niJ++)
		{
			if (stricmp(g_stCommandes[niJ].m_szOption, &(__argv[niI][1])) == ERROR_SUCCESS)
			{
				g_stCommandes[niJ].m_bSet = true;
				break;
			}
		}
	}
}

bool IsCmdlineOptionSet(const char *szaOption)
{
	for (unsigned int niI = 0; g_stCommandes[niI].m_uiMsg; niI++)
		if (stricmp(g_stCommandes[niI].m_szOption, szaOption) == ERROR_SUCCESS)
			return g_stCommandes[niI].m_bSet;

	return false;
}