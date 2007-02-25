/* InstantRails Manager 1.8
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

// EasyPhpDlg.cpp : implementation file
//

#include "EasyPHPDlg.h"
#include "EasyPHPAboutDlg.h"
#include "DialogBase.h"
#include "Utils.h"
#include "Langue.h"
#include "EasyPHP.h"
#include "PHPExtDlg.h"
#include "Preferences.h"
#include "GenConf.h"
#include "UpgradeDlg.h"

#include <Windowsx.h>
#include <shellapi.h>

#define TIMER_ID_ICONE			1
#define TIMER_ID_CHECKVERSION	2
#define TIMER_VALUE_ICONE		500

extern HINSTANCE g_hInstance;
extern bool g_bRelaunchManager;

HBITMAP BitmapFromStatus(SERVER_STATE saStatus);
const char *StringFromStatus(SERVER_STATE saStatus);

#include <commctrl.h> // ToolTip

// Ici a defaut de mieux...
FILETIME				m_TimePHPConfModified;
FILETIME				m_TimePHPTemplateConfModified;
char					m_szPHPTemplateINI[MAX_PATH] = {0};
UINT					m_uiPHPMessage = ::RegisterWindowMessage("EasyPhp_PHP");

// Access
CApache* CEasyPhpDlg::g_apache;
const char*    CEasyPhpDlg::g_installPath;
bool    CEasyPhpDlg::g_forceNotepad;

CApache* CEasyPhpDlg::GetApache()
{
	return g_apache;
}

const char* CEasyPhpDlg::GetInstallPath()
{
	return g_installPath;
}

bool CEasyPhpDlg::GetForceNotepad()
{
	return g_forceNotepad;
}

void CEasyPhpDlg::SetForceNotepad(bool newValue)
{
	g_forceNotepad = newValue;
}


/////////////////////////////////////////////////////////////////////////////
// CEasyPhpDlg dialog

CEasyPhpDlg::CEasyPhpDlg(HWND haParent /*=NULL*/):
	m_cstColorRef(RGB(0, 61, 121))
{
	// initialize static fields for external access
	g_apache = &m_cApache; 
	g_installPath = m_cEasyPHP.InstallPath();
	g_forceNotepad = m_cEasyPHP.ForceNotepad();

	m_hIcon[0] = LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_MAINFRAME));
	m_hIcon[1] = LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_APACHE_ONLY_RUN));
	m_hIcon[2] = LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_MYSQL_ONLY_RUN));
	m_hIcon[3] = LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP));

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	// Init
	char	szLangFilePath[MAX_PATH] = {0};
	_snprintf(szLangFilePath, sizeof(szLangFilePath)-1, "%slangues.txt", CUtils::GetEasyPhpPath());
	CLangue::SetLanguageFile(szLangFilePath);
	CLangue::SetCurrentLang(m_cEasyPHP.m_szSelectedLang);

	m_bStarted = false;
	m_bChangeService = false;

	m_cApache.SetService(m_cEasyPHP.m_bStartAsService);
	m_cMySql.SetService(m_cEasyPHP.m_bStartAsService);

	ServerBase::SetCheckPortBeforeStarting(m_cEasyPHP.m_bCheckServerPorts);

	m_cApache.SetSSLMode(m_cEasyPHP.m_bModeSSL);

	if (m_cEasyPHP.m_sMySql_Arguments[0] == '\0')
		_snprintf(m_cEasyPHP.m_sMySql_Arguments, 249, CLangue::LoadString(IDS_DEFAULT_MYSQLARG));

	m_cMySql.SetParameters((LPCTSTR) m_cEasyPHP.m_sMySql_Arguments);

	_snprintf(m_sPhpIni, sizeof(m_sPhpIni)-1, "%sApache\\php.ini", m_cEasyPHP.InstallPath());
	_snprintf(m_szPHPTemplateINI, sizeof(m_szPHPTemplateINI)-1, "%sconf_files\\php.ini", m_cEasyPHP.InstallPath());

	CUtils::GetModifiedTime((LPCTSTR) m_sPhpIni, &m_TimePHPConfModified);
	CUtils::GetModifiedTime((LPCTSTR) m_szPHPTemplateINI, &m_TimePHPTemplateConfModified);


	LOGBRUSH temp = {BS_SOLID, m_cstColorRef};
	m_hBrush = CreateBrushIndirect(&temp);

	m_hMenuServer = GetSubMenu(LoadMenu(g_hInstance, MAKEINTRESOURCE(IDM_SERVEUR)), 0);	
	m_hMainMenu = GetSubMenu(LoadMenu(g_hInstance, MAKEINTRESOURCE(IDM_START)), 0);
//	m_hMainMenu = GetSubMenu(LoadMenu(g_hInstance, MAKEINTRESOURCE(IDM_MAIN)), 0);

	m_uiServerSelected = -1;

	Create(IDD_TEMPLATE, haParent);
}

CEasyPhpDlg::~CEasyPhpDlg()
{
	if (m_hBrush)
		DeleteObject(m_hBrush);
}

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpDlg message handlers

bool CEasyPhpDlg::OnInitDialog()
{
	if (!CUtils::UserIsAdmin())
	{
		if (MessageBox(NULL, CLangue::LoadString(IDS_NOT_ADMIN), m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONQUESTION) != IDYES)
		{
			PostQuitMessage(10);
			return false;
		}
	}

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP)));

	SetWindowText(GetHandle(), m_cEasyPHP.GetAppName());

	m_NotifyIconData.cbSize = sizeof(NOTIFYICONDATA);
	m_NotifyIconData.hWnd = GetHandle();
	m_NotifyIconData.uID = 0;
	m_NotifyIconData.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
 	m_NotifyIconData.uCallbackMessage = WM_EASYPHP;
	m_NotifyIconData.hIcon = m_hIcon[3];
	strncpy(m_NotifyIconData.szTip, m_cEasyPHP.GetAppName(), sizeof(m_NotifyIconData.szTip)-1);
	Shell_NotifyIcon(NIM_ADD, &m_NotifyIconData);

	m_cApache.SetWindowNotify(GetHandle());
	m_cMySql.SetWindowNotify(GetHandle());

	if (CUtils::IsFixedDrive()==false && IsCmdlineOptionSet("install")==false)
    {
		if (MessageBox(GetHandle(), CLangue::LoadString(IDS_REMOVABLE_DRIVE), m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONQUESTION) == IDYES)
			RegenerateConfFiles(GetHandle());
    }
//    else if (IsCmdlineOptionSet("install"))
//            OnInstall();
    else
    {
		char szLongCurrent[MAX_PATH] = {0};

		CUtils::GetLongPathName(m_cEasyPHP.InstallPath(), szLongCurrent, sizeof(szLongCurrent)-1);

		if (strcmp(szLongCurrent, m_cEasyPHP.OldRunningPath()) != ERROR_SUCCESS)
		{
			char szPrompt[500] = {0};

			_snprintf(szPrompt, sizeof(szPrompt)-1, CLangue::LoadString(IDS_FOLDER_CHANGED), m_cEasyPHP.OldRunningPath(), szLongCurrent);
			if (MessageBox(GetHandle(), szPrompt, m_cEasyPHP.GetAppName(), MB_OKCANCEL | MB_ICONQUESTION) == IDOK) {
				RegenerateConfFiles(GetHandle());
			}
			else {
				Shell_NotifyIcon(NIM_DELETE, &m_NotifyIconData);
				PostQuitMessage(0);
				return false;
			}
		}
    }

	if (m_cEasyPHP.m_bAutoStartServeurs || m_cEasyPHP.m_bStartAsService)
		Demarrer();

	// Ne pas le faire avant, sinon les serveurs risqueraient de redemarrer plusieurs fois
	// (a cause du RegenerateConfFiles)
	// A FAIRE verifier. Ca pourrait etre grave sous 98 vu que Mysql met du temps pour demarrer.
	m_cApache.SetConfReload(m_cEasyPHP.m_bAutoReloadConf);
	m_cMySql.SetConfReload(m_cEasyPHP.m_bAutoReloadConf);

	SetTimer(GetHandle(), TIMER_ID_ICONE, TIMER_VALUE_ICONE, NULL);
	SetTimer(GetHandle(), TIMER_ID_CHECKVERSION, 0, NULL);

	m_cEasyPHP.m_bWinExpand = !m_cEasyPHP.m_bWinExpand;
	OnExpand();

	SendDlgItemMessage(GetHandle(), ID_PIN, BM_SETIMAGE, IMAGE_BITMAP, 
		(LPARAM) LoadImage(g_hInstance, MAKEINTRESOURCE(m_cEasyPHP.m_bShowAlways ? IDB_PIN : IDB_NOPIN), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT | LR_LOADMAP3DCOLORS));
	::SetWindowPos(GetHandle(), m_cEasyPHP.m_bShowAlways ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

	if (m_cEasyPHP.m_bShowAlways)
		ShowWindow(GetHandle(), SW_SHOW);

/*	SendDlgItemMessage(GetHandle(), IDSL_VIEW, TBM_SETRANGE, FALSE, MAKELONG(0, 1));
	SendDlgItemMessage(GetHandle(), IDSL_VIEW, TBM_SETTICFREQ, 1, 0);
	SendDlgItemMessage(GetHandle(), IDSL_VIEW, TBM_SETPOS, TRUE, m_cEasyPHP.m_uiWinExpand);
*/
	SendDlgItemMessage(GetHandle(), ID_MENU, BM_SETIMAGE, IMAGE_BITMAP, 
		(LPARAM) LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_EASYPHP), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT | LR_LOADMAP3DCOLORS));
	SendDlgItemMessage(GetHandle(), ID_HELP_CONTEXT, BM_SETIMAGE, IMAGE_BITMAP, 
		(LPARAM) LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_HELP), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT | LR_LOADMAP3DCOLORS));
	SendDlgItemMessage(GetHandle(), ID_MINIMIZE, BM_SETIMAGE, IMAGE_BITMAP, 
		(LPARAM) LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_MINIMIZE), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT | LR_LOADMAP3DCOLORS));

//  Font fixe
//	SendMessage(GetItemHandle(IDC_LOG), WM_SETFONT, (WPARAM) GetStockObject(ANSI_FIXED_FONT), (LPARAM) TRUE);

	HMENU hSystemMenu = GetSystemMenu(GetHandle(), FALSE);
	DeleteMenu(hSystemMenu, 4, MF_BYPOSITION);
	DeleteMenu(hSystemMenu, 2, MF_BYPOSITION);
	DeleteMenu(hSystemMenu, 0, MF_BYPOSITION);
	InsertMenu(hSystemMenu, 2, MF_BYPOSITION, ID_PIN, CLangue::LoadString(IDS_ALWAYS_VISIBLE));
	EnableMenuItem(hSystemMenu, SC_CONTEXTHELP, MF_BYCOMMAND | MF_ENABLED);

	HMENU hDialogMenu = GetMenu(GetHandle());
	AppendMenu(hDialogMenu, MF_POPUP, (UINT) LoadMenu(NULL, MAKEINTRESOURCE(IDM_MENU_SERVEURS)), "Zob");
	AppendMenu(hDialogMenu, MF_STRING | MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 2), "&Fichiers logs");
	AppendMenu(hDialogMenu, MF_STRING | MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 3), "&Configuration");
	AppendMenu(hDialogMenu, MF_STRING | MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 0), "Aide");
	
	AppendMenu(GetSubMenu(hDialogMenu, 1), MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 5), NULL);
	AppendMenu(GetSubMenu(hDialogMenu, 1), MF_STRING | MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 6), "Aide");
	AppendMenu(GetSubMenu(hDialogMenu, 1), MF_STRING | MF_POPUP, (UINT) GetSubMenu(m_hMainMenu, 7), "Aide");

	if (CUtils::IsFixedDrive() == true)
		DeleteMenu(m_hMainMenu, ID_REGENERATE_CONF_FILES, MF_BYCOMMAND);

//	UpdateLang();

	return false;  // return TRUE  unless you set the focus to a control
}


void CEasyPhpDlg::OnInitMenuPopup(HMENU haMenu, int item, BOOL fSystemMenu)
{
	if (fSystemMenu)
	{
		CheckMenuItem(haMenu, ID_PIN, m_cEasyPHP.m_bShowAlways ? MF_CHECKED : MF_UNCHECKED);
	}
/*	else
	{
		switch (item)
		{
		case 2: 
				//DeleteMenu(haMenu, 0, MF_BYPOSITION);
				break;
		}
	}*/
}

void CEasyPhpDlg::OnTrayBarNotification(WPARAM wParam, LPARAM lParam)
{
	switch (lParam)
	{
	case WM_LBUTTONDBLCLK:
		::ShowWindow(GetHandle(), SW_RESTORE);
		::SetForegroundWindow(GetHandle());
		break;

	case WM_RBUTTONUP:	OnMenu();			break;
	}
}

void CEasyPhpDlg::OnTimer(UINT nIDEvent, LPARAM laParam)
{
	switch (nIDEvent)
	{
	case TIMER_ID_ICONE:
		{
			static int niCpt = 0;
			static bool bOldStartState = false;
			static SERVER_STATE siOldApache = SERVER_UNDEFINED, siOldMySql = SERVER_UNDEFINED;
			SERVER_STATE siApache = m_cApache.GetState(), siMySql = m_cMySql.GetState();
			char szMsg[100] = {0};

			if (siApache!=siOldApache || laParam!=0)
			{
				_snprintf(szMsg, sizeof(szMsg)-1, "%-20s", StringFromStatus(siApache));
				SetTextRefresh(IDC_STATUS_APACHE, szMsg);
				SendMessage(GetDlgItem(IDCB_APACHE), STM_SETIMAGE, IMAGE_BITMAP, (LPARAM) BitmapFromStatus(siApache));
			}
			if (siMySql!=siOldMySql || laParam!=0)
			{
				_snprintf(szMsg, sizeof(szMsg)-1, "%-20s", StringFromStatus(siMySql));
				SetTextRefresh(IDC_STATUS_MYSQL, szMsg);
				SendMessage(GetDlgItem(IDCB_MYSQL), STM_SETIMAGE, IMAGE_BITMAP, (LPARAM) BitmapFromStatus(siMySql));
			}
			siOldApache = siApache;
			siOldMySql = siMySql;

			Automate();
			
			if (niCpt++ % 2) 		// Switch d'icone de la tray-bar.
				m_NotifyIconData.hIcon = m_hIcon[0];
			else m_NotifyIconData.hIcon = m_hIcon[(m_cMySql.IsStarted() ? 2 : 0) + (m_cApache.IsStarted() ? 1 :0)];

			if (m_bStarted!=bOldStartState || niCpt==0 || laParam!=0)
				_snprintf(m_NotifyIconData.szTip, sizeof(m_NotifyIconData.szTip)-1, "%s (%s)", m_cEasyPHP.GetAppName(), CLangue::LoadString(m_bStarted ? IDS_STATE_STARTED : IDS_STATE_STOPPED));
			bOldStartState = m_bStarted;

//			::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM) m_NotifyIconData.hIcon);
			::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM) m_NotifyIconData.hIcon);

			Shell_NotifyIcon(NIM_MODIFY, &m_NotifyIconData);
		}
		break;

	case TIMER_ID_CHECKVERSION:
		{
			KillTimer(GetHandle(), TIMER_ID_CHECKVERSION);
//			if (m_cEasyPHP.m_bCheckVersionAtStartup)
//				OnCheckVersion(true);
/*
			DWORD dwThreadID;
			CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE) DebugThread, GetHandle(), 0, &dwThreadID);
*/		}
		break;
	}
}

/*void CEasyPhpDlg::OnPaint(bool baForceRefresh)
{
	static SERVER_STATE siOldApache = SERVER_UNDEFINED, siOldMySql = SERVER_UNDEFINED;
	static COLORREF cRed = RGB(255, 0, 0), cOrange = RGB(255, 128, 0), cGreen = RGB(0, 255, 0);
	LOGBRUSH cLogBrush = {BS_SOLID, 0, 0};
	SERVER_STATE siApache = m_cApache.GetState(), siMySql = m_cMySql.GetState();

	for (int niI = 0; niI < 2; niI++)
	{
		HDC hDC = ::GetWindowDC(GetItemHandle(niI == 0 ? IDC_STATUS_MYSQL : IDC_STATUS_APACHE));

		if (hDC)
		{
			switch (niI == 0 ? m_cMySql.GetState() : m_cApache.GetState())
			{
			case SERVER_RUNNING: cLogBrush.lbColor = cGreen; break;
			case SERVER_STOPPED: cLogBrush.lbColor = cRed; break;
			default:			 cLogBrush.lbColor = cOrange; break;
			}	

			HBRUSH hBrush = CreateBrushIndirect(&cLogBrush);
			HGDIOBJ hOld = (HPEN) SelectObject(hDC, hBrush);

			Ellipse(hDC, 5, 6, 15, 16);
			
			SelectObject(hDC, hOld);
			DeleteObject(hBrush);
			::ReleaseDC(GetHandle(), hDC);
		}
	}
*/
/*	static bool biBrushCreated = false;
	static HBRUSH hBrushGreen = NULL, hBrushOrange = NULL, hBrushRed = NULL;

	if (biBrushCreated == false)
	{
		LOGBRUSH cLogBrush = {BS_SOLID, 0, 0};

		cLogBrush.lbColor = RGB(0, 255, 0);
		hBrushGreen = CreateBrushIndirect(&cLogBrush);
		cLogBrush.lbColor = RGB(255, 128, 0);
		hBrushOrange = CreateBrushIndirect(&cLogBrush);
		cLogBrush.lbColor = RGB(255, 0, 0),
		hBrushRed = CreateBrushIndirect(&cLogBrush);
		biBrushCreated = true;
	}

	for (int niI = 0; niI < 2; niI++)
	{
		PAINTSTRUCT ps = {0};
		HWND hStatus = GetItemHandle(niI == 0 ? IDC_STATUS_MYSQL : ID_APACHE_MENU);
		RECT rect = {0};

//		if (GetUpdateRect(hStatus, &rect, FALSE) || baForceRefresh)
		{
            BeginPaint(GetHandle(), &ps);
            HDC hDC = GetDC(hStatus);
			HGDIOBJ hOld =  NULL;

			switch (niI == 0 ? m_cMySql.GetState() : m_cApache.GetState())
			{
			case SERVER_RUNNING: hOld = (HPEN) SelectObject(hDC, hBrushGreen); break;
			case SERVER_STOPPED: hOld = (HPEN) SelectObject(hDC, hBrushRed); break;
			default:			 hOld = (HPEN) SelectObject(hDC, hBrushOrange); break;
			}	

			Ellipse(hDC, 5, 6, 15, 16);
			
			ReleaseDC(GetHandle(), hDC);
	        EndPaint(GetHandle(), &ps);
		}
	}*/
/*
        case WM_PAINT:
                {
                        RECT rect = {0};
                        HWND hwndIcon = GetDlgItem(haDlg, IDI_PROFILE_IMAGE);

                        if (GetUpdateRect(hwndIcon, &rect, FALSE))
                        {
                                g_Dbs.Log("WM_PAINT");
                                BeginPaint(haDlg, &ps);
                                HDC hDC = GetDC(hwndIcon);

                                ImageList_Draw(l_hProfilImgList, niImageToDraw, hDC, 0, 0, ILD_TRANSPARENT);
    
                        }
                        return 0;
                }
                break;  
}*/

int CEasyPhpDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	static UINT l_msgTaskbarCreated = RegisterWindowMessage("TaskbarCreated");

	switch (message)
	{
	// Message Windows standards
	case WM_INITMENUPOPUP:	OnInitMenuPopup((HMENU) waParam, (UINT)LOWORD(laParam), (BOOL)HIWORD(laParam));	break;

	case WM_TIMER:			OnTimer(waParam, laParam);				break;
	case WM_COMMAND:		OnCommand(waParam, laParam);			break;
	case WM_ENDSESSION:		OnQuit();	DestroyWindow(GetHandle());	break;
	case WM_SYSCOMMAND:		switch (waParam)
							{
							case ID_PIN:		OnPinChange();		break;
							case SC_CLOSE:	
								{
									if (MessageBox(GetHandle(), CLangue::LoadString(IDS_PROMPT_QUIT), m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONERROR) == IDYES)
										OnQuit();
									break;
								}
							case SC_KEYMENU:	OnMenu(true);		break;
							}
							break;

	case WM_LBUTTONDOWN:
		PostMessage(GetHandle(), WM_NCLBUTTONDOWN, HTCAPTION, laParam);	break;

	case WM_SIZE:
		if (waParam == SIZE_MINIMIZED)
			ShowWindow(GetHandle(), SW_HIDE);
		break;

/*	case WM_VSCROLL:
		{
			if ((HWND) laParam == GetItemHandle(IDSL_VIEW))
				OnExpand(SendMessage((HWND) laParam, TBM_GETPOS, 0, 0));
		}
		break;*/
/*
 // CASTOR
case WM_HELP:

  LPHELPINFO lphi;
  HH_POPUP hp;

      lphi = (LPHELPINFO)lParam;

  switch (lphi->iCtrlId)
  {
//   case ID_BUG:
default:
    memset(&hp, 0, sizeofHH_POPUP());
    hp.cbStruct = sizeof(HH_POPUP);
    hp.pt.x = lphi->MousePos.x;
    hp.pt.y = lphi->MousePos.y;
    hp.clrForeground = RGB(0, 0, 192);
    hp.clrBackground = -1;
    hp.rcMargins.left = -1;
    hp.rcMargins.right = -1;
    hp.rcMargins.top = -1;
    hp.rcMargins.bottom = -1;
    hp.idString = 0;
    hp.pszText = "Ce bouton permet d'envoyer\r\nun bug report\r\nau
support technique...";
    HtmlHelp(hDlg, NULL, HH_DISPLAY_TEXT_POPUP, (DWORD)&hp);
    break;
  }
  break;
  default:
   return FALSE;
*/

/*	case WM_CTLCOLORDLG:
		return (int) m_hBrush;*/

	// Messages EasyPhp
	case WM_EASYPHP:		OnTrayBarNotification(waParam, laParam);	break;
	case WM_LOG:			LogMessage((const char *) laParam, LOG_DEBUGGER);
							break;

	default:
		if (message == m_cApache.GetMessageId())
		{
			switch(waParam)
			{
			case MSG_UNEXPECTED_END:
				m_bStarted = m_cApache.IsStarted() || m_cMySql.IsStarted();
				LogMessage(CLangue::LoadString(IDS_APACHEMSG_UNEXPECTED_END), LOG_APACHE, true);
				break;

			case MSG_LOG: LogMessage((const char *) laParam, LOG_APACHE);
				break;

			case MSG_ERROR_CONF:
				{
					char szBuffMessage[2000+MAX_PATH];

					_snprintf(szBuffMessage, 2000+MAX_PATH, CLangue::LoadString(IDS_ERROR_APACHE_CONF), (const char *) laParam);

					LogMessage("Erreur dans le fichier de configuration d'Apache", LOG_EASYPHP);

					if (MessageBox(GetHandle(), szBuffMessage, m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONERROR) == IDYES)
						PostMessage(GetHandle(), WM_COMMAND, ID_APACHE_CONF, 0);
				}
				break;

			case MSG_CHANGE_CONF:
				LogMessage(CLangue::LoadString(IDS_LOG_CHANGE_CONF), LOG_APACHE);
				if (m_cApache.GetConfReload())
					HandleServerActionError(m_cApache.Restart(), 0, IDS_ERROR_RESTART_SERVER);
				break;
			}
		}
		else if (message == m_cMySql.GetMessageId())
		{
			ServerBase *piServer = &m_cMySql;

			switch (waParam)
			{
			case MSG_UNEXPECTED_END:
				m_bStarted = m_cApache.IsStarted() || m_cMySql.IsStarted();
				LogMessage(CLangue::LoadString(IDS_MYSQLMSG_UNEXPECTED_END), LOG_MYSQL, true);
				if (MessageBox(GetHandle(), "Unexpected end of MySql... See log file ?", (LPCTSTR) piServer->GetServerName(), MB_YESNO+MB_ICONEXCLAMATION) == IDYES)
					PostMessage(GetHandle(), WM_COMMAND, ID_MYSQL_ERREUR_LOG, 0);
				break;

			case MSG_CHANGE_CONF:
				LogMessage(CLangue::LoadString(IDS_LOG_CHANGE_CONF), LOG_MYSQL);
				if (m_cMySql.GetConfReload())
					HandleServerActionError(m_cMySql.Restart(), 1, IDS_ERROR_RESTART_SERVER);
				break;
			}	
		}
		else if (message == m_uiPHPMessage)
		{
			switch (waParam)
			{
			case MSG_CHANGE_CONF:
				LogMessage(CLangue::LoadString(IDS_LOG_CHANGE_CONF), LOG_PHP);
				if (m_cApache.GetConfReload())
					HandleServerActionError(m_cApache.Restart(), 1, IDS_ERROR_RESTART_SERVER);
				break;
			}	
		}
		else if (message == l_msgTaskbarCreated)	// explorer.exe crach and restart
		{
			Shell_NotifyIcon(NIM_ADD, &m_NotifyIconData);
		}
		break;

	}
	return CEasyPHPDialogBase::WindowProc(message, waParam, laParam);
}

bool CEasyPhpDlg::OnCommand(WPARAM wParam, LPARAM laParam) 
{
	switch (LOWORD(wParam))
	{
	case ID_APACHE_MENU:			OnMenuServeur(0);			break;
	case ID_MYSQL_MENU:				OnMenuServeur(1);			break;

	case ID_CHECK_VERSION:			OnCheckVersion();			break;
	case ID_RELEASE_NOTES:			OnReleaseNotes();			break;
	case ID_ABOUT:					OnAbout();					break;
	case ID_PIN:					OnPinChange();				break;
	case IDC_EXPAND:				OnExpand();					break;
	case ID_MENU:					OnMenu();					break;
	case ID_MINIMIZE:				ShowWindow(GetHandle(), SW_HIDE);break;

	// Menu
	case ID_AIDE_INTRO:				OnHelp();					break;
	case ID_AIDE_FAQ:				OnHelpFAQ();				break;
	case ID_AIDE_DEBUTER:			OnHelpDebuter();			break;
	case ID_HELP_MONGREL:			OnHelpMongrel();			break;
	case ID_HELP_FXRI:				OnFxri();					break;

	case ID_APACHE_ERREUR_LOG:		OnApacheErrorLog();			break;
	case ID_APACHE_ACCES_LOG:		OnApacheAccesLog();			break;
	case ID_MYSQL_ERREUR_LOG:		OnMySqlErrorLog();			break;
	case ID_EASYPHP_LOG:			OnEasyPhpLog();				break;

	case ID_APACHE_CONF:			OnApacheConf();				break;
	case ID_CONFIGURATION_PHPEXT:	OnPhpExtConf();				break;
	case ID_PHP_CONF:				OnPhpConf();				break;
	case ID_MYSQL_CONF:				OnMySqlConf();				break;
	case ID_MYADMIN_CONF:			OnMyAdmin();				break;
	case ID_EASYPHP_CONF:			OnPreferences();			break;
	case ID_CONFIGURE_WINDOW:		OnWindowHosts();			break;

	case ID_REGENERATE_CONF_FILES:	RegenerateConfFiles(GetHandle());		break;

// Traite dans l'INITDialog. Sinon on le fait 2 fois...
//	case ID_INSTALL:				OnInstall();				break;

	case ID_EXPLORER_DOCROOTFORSTATICPAGES:
                                    OnExploreDocRoot();			break;
	case ID_RAILSAPP_CONSOLE:		OnRailsAppConsole();		break;
	case ID_RAILSAPP_EXPLORER:		OnRailsAppExplore();		break;
	case ID_MANAGERAILSAPPS:		OnManageRailsApps();		break;		
	case ID_ADMINISTRATION:			OnAdministration();			break;
	case ID_BROWSE_WEB:				OnWebLocal();				break;
	case ID_START:					if (!m_bStarted) OnSwitch();break;
	case ID_STOP:					if (m_bStarted) OnSwitch(); break;
	case ID_RESTART:				OnRestart();				break;
	case ID_SWITCH:					OnSwitch();					break;
	case ID_QUIT:					OnQuit();					break;

	// Menu serveur
	case ID_SERVER_START:			OnServerStart();			break;
	case ID_SERVER_RESTART:			OnServerRestart();			break;
	case ID_SERVER_STOP:			OnServerStop();				break;
	case ID_SERVER_KILL:			OnServerKill();				break;
	case ID_RESTART_APACHE:			m_uiServerSelected = 0;
									OnServerRestart();			break;
	//
	case ID_HELP_CMDLINE:			OnHelpCmdLine();			break;
	}

	return true;
}

void CEasyPhpDlg::OnHelp()
{
//	char szHelpPage[MAX_PATH] = {0};

//	_snprintf(szHelpPage, sizeof(szHelpPage)-1, "file:///%shelp\\index.html", m_cEasyPHP.InstallPath());
	CUtils::GotoURL("http://instantrails.rubyforge.org/wiki/wiki.pl?Getting_Started"); 
}

void CEasyPhpDlg::OnHelpFAQ()
{
	CUtils::GotoURL("http://instantrails.rubyforge.org/wiki/wiki.pl");
}

void CEasyPhpDlg::OnHelpMongrel()
{
	CUtils::GotoURL("http://mongrel.rubyforge.org/docs/index.html");
}

void CEasyPhpDlg::OnHelpDebuter()
{
	CUtils::GotoURL(CLangue::LoadString(IDS_STARTPHP_URL));
}

// Menu Log
void CEasyPhpDlg::OnApacheErrorLog()
{
	char szApacheError[MAX_PATH] = {0};
	_snprintf(szApacheError, sizeof(szApacheError)-1, "%sapache\\logs\\error.log", m_cEasyPHP.InstallPath());
	CUtils::ViewFile(szApacheError);
}

void CEasyPhpDlg::OnApacheAccesLog()
{
	char szApacheAccesLog[MAX_PATH] = {0};
	_snprintf(szApacheAccesLog, sizeof(szApacheAccesLog)-1, "%sapache\\logs\\access.log", m_cEasyPHP.InstallPath());
	CUtils::ViewFile(szApacheAccesLog);
}

void CEasyPhpDlg::OnMySqlErrorLog()
{
	char szMySqlError[MAX_PATH] = {0};
	char szComputerName[50] = {0};
	DWORD dwSize = sizeof(szComputerName);

	GetComputerName(szComputerName, &dwSize);

	// Mysql replace spaces by '-' for log file name.
	for (int niI = 0; szComputerName[niI]!='\0'; niI++)
		if (szComputerName[niI]==' ')
			szComputerName[niI]='-';

	_snprintf(szMySqlError, sizeof(szMySqlError)-1, "\"%smysql\\data\\%s.err\"", m_cEasyPHP.InstallPath(), szComputerName);
	CUtils::ViewFile(szMySqlError);
}

void CEasyPhpDlg::OnEasyPhpLog()
{
	char szEasyPhpLog[MAX_PATH] = {0};
	_snprintf(szEasyPhpLog, sizeof(szEasyPhpLog)-1, "%sInstantRails.log", m_cEasyPHP.InstallPath());
	CUtils::ViewFile(szEasyPhpLog);
}

// Menu configuration
void CEasyPhpDlg::OnApacheConf()
{
	CUtils::ViewFile(m_cApache.GetTemplateConfFile());
}

void CEasyPhpDlg::OnPhpExtConf()
{
	CPHPExtDlg cPHPExt(GetHandle(), m_szPHPTemplateINI);
}

void CEasyPhpDlg::OnPhpConf()
{
//	CUtils::ViewFile(m_sPhpIni);
	CUtils::ViewFile(m_szPHPTemplateINI);
}

void CEasyPhpDlg::OnMySqlConf()
{
	CUtils::ViewFile(m_cMySql.GetTemplateConfFile());
}

void CEasyPhpDlg::OnMyAdmin()
{
	BrowseLocalURL("mysql/");
}

// Menu principal
void CEasyPhpDlg::OnRestart() 
{
	if (m_bStarted)
	{
		LogMessage(CLangue::LoadString(IDS_LOG_RESTART_SERVERS), LOG_EASYPHP);
		if (m_cApache.VerifyConfFile())
		{
			HandleServerActionError(m_cApache.Restart(), 0, IDS_ERROR_RESTART_SERVER);
			HandleServerActionError(m_cMySql.Restart(), 1, IDS_ERROR_RESTART_SERVER);
		}
	}
}

void CEasyPhpDlg::OnSwitch() 
{
	if (m_bStarted)
		Arreter();
	else Demarrer();
}

void CEasyPhpDlg::OnExploreDocRoot()
{
	CUtils::Log("OnExplore : %s", m_cApache.GetDocumentRootPath());
	ShellExecute(NULL, "explore", m_cApache.GetDocumentRootPath(), NULL, NULL, SW_SHOW);
}

void CEasyPhpDlg::OnRailsAppConsole()
{
	SetCurrentDirectory(CEasyPhpDlg::GetInstallPath());
	char command[MAX_PATH] = {0};
	_snprintf(command, sizeof(command)-1, "cmd /k %suse_ruby.cmd", m_cEasyPHP.InstallPath());
	WinExec(command, SW_SHOW);
}

void CEasyPhpDlg::OnFxri()
{
	SetCurrentDirectory(CEasyPhpDlg::GetInstallPath());
	char command[MAX_PATH] = {0};
	_snprintf(command, sizeof(command)-1, "%sruby\\bin\\rubyw.exe %sruby\\bin\\fxri.bat", m_cEasyPHP.InstallPath(), m_cEasyPHP.InstallPath());
	WinExec(command, SW_SHOW);
}

void CEasyPhpDlg::OnRailsAppExplore()
{
	char szRailsApps[MAX_PATH] = {0};
	_snprintf(szRailsApps, sizeof(szRailsApps)-1, "%srails_apps", m_cEasyPHP.InstallPath());
	CUtils::Log("OnExplore : %s", szRailsApps);
	ShellExecute(NULL, "explore", szRailsApps, NULL, NULL, SW_SHOW);
}

void CEasyPhpDlg::OnAdministration()
{
	if (m_cApache.GetState() == SERVER_RUNNING)
		BrowseLocalURL("home/");
}

void CEasyPhpDlg::OnWebLocal()
{
	if (m_cApache.GetState() == SERVER_RUNNING)
		BrowseLocalURL("");
}

void CEasyPhpDlg::OnQuit()
{
	if (!m_cEasyPHP.m_bStartAsService)
		Arreter();

	Shell_NotifyIcon(NIM_DELETE, &m_NotifyIconData);
	PostQuitMessage(0);
}

void CEasyPhpDlg::OnServerStart()
{
    DWORD dwRetour = ERROR_SUCCESS;
    ServerBase *piServer = NULL;
    
    if (m_uiServerSelected == 0)
            piServer = &m_cApache;
    else piServer = &m_cMySql;
    
    dwRetour = piServer->Start();

    if (dwRetour == WSAEADDRINUSE)
    {
        char szPrompt[512] = {0};
		bool biPortUsed = false;
		DWORD dwProcID = 0;

        CUtils::IsPortUsedByProcess(piServer->GetPort(), dwProcID, biPortUsed);
		if (biPortUsed)
		{
			char szExeName[MAX_PATH] = {0};
			char szExeTitle[MAX_PATH] = {0};
			char szExeTot[MAX_PATH] = {0};

			CUtils::ScanProcessByProcId(dwProcID, szExeName);
			CUtils::GetProcessTitle(dwProcID, szExeTitle, sizeof(szExeTitle)-1);

			_snprintf(szExeTot, sizeof(szExeTot), "\"%s\" (%s)", szExeTitle, szExeName);
			_snprintf(szPrompt, sizeof(szPrompt), CLangue::LoadString(IDS_PORT_OCCUPE_XP), piServer->GetServerName(), piServer->GetPort(), szExeTot);
		}
        else
			strncpy(szPrompt, CLangue::LoadString(IDS_PORT_OCCUPE), sizeof(szPrompt)-1);

        LogMessage(szPrompt, m_uiServerSelected == 0 ? LOG_APACHE : LOG_MYSQL);
        MessageBox(GetHandle(), szPrompt, (LPCTSTR) piServer->GetServerName(), MB_OK+MB_ICONEXCLAMATION);
    }
    else HandleServerActionError(dwRetour, m_uiServerSelected, IDS_SERVER_RUN_ERROR);

    m_uiServerSelected = -1;
}

void CEasyPhpDlg::OnServerRestart()
{
	DWORD dwRetour = ERROR_SUCCESS;

	switch (m_uiServerSelected)
	{
	case 0: dwRetour = m_cApache.Restart(); break;
	case 1: dwRetour = m_cMySql.Restart(); break;
	}
	HandleServerActionError(dwRetour, m_uiServerSelected, IDS_ERROR_RESTART_SERVER);

	m_uiServerSelected = -1;
}

void CEasyPhpDlg::OnServerStop()
{
	DWORD dwRetour = ERROR_SUCCESS;

	switch (m_uiServerSelected)
	{
	case 0: dwRetour = m_cApache.Stop(); break;
	case 1: dwRetour = m_cMySql.Stop(); break;
	}
	HandleServerActionError(dwRetour, m_uiServerSelected, IDS_ERROR_STOP_SERVER);

	m_uiServerSelected = -1;
}

void CEasyPhpDlg::OnServerKill()
{
	DWORD dwRetour = ERROR_SUCCESS;

	switch (m_uiServerSelected)
	{
	case 0: dwRetour = m_cApache.Kill(); break;
	case 1: dwRetour = m_cMySql.Kill(); break;
	}

	m_uiServerSelected = -1;
}

void CEasyPhpDlg::OnHelpCmdLine()
{
	unsigned int niI = 0;
	char szBuffer[1024] = {0};

	while (g_stCommandes[niI].m_uiMsg)
	{
		_snprintf(szBuffer, sizeof(szBuffer)-1, "%s%s\t\t%s\n", szBuffer, g_stCommandes[niI].m_szOption, CLangue::LoadString(g_stCommandes[niI].m_uiMsg));
		niI++;
	}
	MessageBox(GetHandle(), szBuffer, m_cEasyPHP.GetAppName(), MB_OK);
}

void CEasyPhpDlg::OnMenuServeur(UINT naServeur)
{
	if (m_hMenuServer)
	{
		SERVER_STATE eState = (naServeur == 0 ? m_cApache.GetState() : m_cMySql.GetState());
		RECT rect;

		GetWindowRect(GetDlgItem(naServeur == 0 ? ID_APACHE_MENU : ID_MYSQL_MENU), &rect);

		SetMenuDefaultItem(m_hMenuServer, eState == SERVER_RUNNING ? ID_SERVER_STOP : ID_SERVER_START, FALSE);

		// Menu configuration
		EnableMenuItem(m_hMenuServer, ID_SERVER_START, eState == SERVER_STOPPED ? MF_ENABLED : MF_GRAYED);
		EnableMenuItem(m_hMenuServer, ID_SERVER_RESTART, eState == SERVER_RUNNING  ? MF_ENABLED : MF_GRAYED);				
		EnableMenuItem(m_hMenuServer, ID_SERVER_STOP, eState == SERVER_RUNNING ? MF_ENABLED : MF_GRAYED);

		if (naServeur == 0 ? m_cApache.IsService() : m_cMySql.IsService())
			EnableMenuItem(m_hMenuServer, ID_SERVER_KILL, MF_BYCOMMAND | MF_GRAYED);
		else EnableMenuItem(m_hMenuServer, ID_SERVER_KILL, (eState == SERVER_STOP_PENDING || eState == SERVER_START_PENDING) ? MF_ENABLED : MF_GRAYED);

		m_uiServerSelected = naServeur;

		::SetForegroundWindow(GetHandle());
		TrackPopupMenu(m_hMenuServer, TPM_LEFTALIGN, rect.left, rect.bottom, 0, GetHandle(), NULL);
		::PostMessage(GetHandle(), WM_NULL, 0, 0);
	}
}

// Boite de configuration
void CEasyPhpDlg::OnPinChange()
{
	m_cEasyPHP.m_bShowAlways = !m_cEasyPHP.m_bShowAlways;
	::SetWindowPos(GetHandle(), m_cEasyPHP.m_bShowAlways ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	SendDlgItemMessage(GetHandle(), ID_PIN, BM_SETIMAGE, IMAGE_BITMAP, 
		(LPARAM) LoadImage(g_hInstance, MAKEINTRESOURCE(m_cEasyPHP.m_bShowAlways ? IDB_PIN : IDB_NOPIN), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT | LR_LOADMAP3DCOLORS));
}

void CEasyPhpDlg::OnMenu(bool baFromKey)
{
	if (m_hMainMenu)
	{
		POINT iPos = {0};
		char pciLabelEtat[70] = {0};
		bool m_bStopped = (m_cApache.GetState() == SERVER_STOPPED && m_cMySql.GetState() == SERVER_STOPPED);
		bool m_bApacheRun = (m_cApache.GetState() == SERVER_RUNNING);
		bool m_bMySqlRun = (m_cMySql.GetState() == SERVER_RUNNING);

		if (baFromKey == false)
			GetCursorPos(&iPos);
		else
		{
			RECT rc;

			GetWindowRect(GetDlgItem(ID_MENU), &rc);
			iPos.x = rc.left + 10;
			iPos.y = rc.top + 10;
		}

		if (!(m_bStopped || m_bStarted))
			strncpy(pciLabelEtat, CLangue::LoadString(IDS_PENDING), sizeof(pciLabelEtat)-1);
		else _snprintf(pciLabelEtat, sizeof(pciLabelEtat)-1, "%s\t%s", 
					CLangue::LoadString(m_bStarted ? IDS_STOP : IDS_START),
					m_bStarted ? "F3" : "F2");

		ModifyMenu(m_hMainMenu, ID_SWITCH, MF_BYCOMMAND | MF_STRING, ID_SWITCH, pciLabelEtat);
		SetMenuDefaultItem(m_hMainMenu, ID_SWITCH, FALSE);

		// Menu configuration
		EnableMenuItem(m_hMainMenu, ID_CONFIGURATION_PHPEXT, MF_ENABLED);
		EnableMenuItem(m_hMainMenu, ID_PHP_CONF, MF_ENABLED);				
		EnableMenuItem(m_hMainMenu, ID_MYADMIN_CONF, m_bApacheRun && m_bMySqlRun? MF_ENABLED : MF_GRAYED);

		// Menu principal
		EnableMenuItem(m_hMainMenu, ID_ADMINISTRATION, m_bApacheRun ? MF_ENABLED : MF_GRAYED);
		EnableMenuItem(m_hMainMenu, ID_BROWSE_WEB, m_bApacheRun ? MF_ENABLED : MF_GRAYED);
		EnableMenuItem(m_hMainMenu, ID_RESTART, !m_bStarted ? MF_GRAYED : MF_ENABLED);
		EnableMenuItem(m_hMainMenu, ID_SWITCH, m_bStopped || m_bStarted ? MF_ENABLED : MF_GRAYED);

		::SetForegroundWindow(GetHandle());
		TrackPopupMenu(m_hMainMenu, TPM_LEFTALIGN, iPos.x, iPos.y, 0, GetHandle(), NULL);
		::PostMessage(GetHandle(), WM_NULL, 0, 0);
	}
}

void CEasyPhpDlg::OnExpand()
{
	RECT rect, rectListBox;

	m_cEasyPHP.m_bWinExpand = !m_cEasyPHP.m_bWinExpand;

	GetWindowRect(GetHandle(), &rect);
	GetWindowRect(GetDlgItem(IDC_LOG), &rectListBox);

	int dwDeltaY = (m_cEasyPHP.m_bWinExpand == false ? rectListBox.top-rect.top : rectListBox.bottom-rect.top + 10);
	SetWindowPos(GetHandle(), m_cEasyPHP.m_bShowAlways ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, rect.right-rect.left, dwDeltaY, SWP_NOMOVE);
	SetWindowText(GetDlgItem(IDC_EXPAND), m_cEasyPHP.m_bWinExpand ? " < " : " > ");
	InvalidateRect(GetHandle(), NULL, TRUE);
}

void CEasyPhpDlg::OnWindowHosts()
{
	LPCSTR windir = getenv("WINDIR");
	char hosts[MAX_PATH+1] = {0};
	_snprintf(hosts, sizeof(hosts), "%s\\system32\\drivers\\etc\\hosts", windir);
	CUtils::ViewFile(hosts);
}

void CEasyPhpDlg::OnPreferences()
{
	bool biOldStartAsService = m_cEasyPHP.m_bStartAsService;

	CPreferencesDlg cPreferences(GetHandle(), &m_cEasyPHP);	
	if (m_cEasyPHP.m_bStartAsService != biOldStartAsService)
	{
		DWORD dwError = ERROR_SUCCESS;

		if (m_cApache.GetState() == SERVER_RUNNING)
			HandleServerActionError(m_cApache.Stop(), 0, IDS_ERROR_STOP_SERVER);
		if (m_cMySql.GetState() == SERVER_RUNNING)
			HandleServerActionError(m_cMySql.Stop(), 1, IDS_ERROR_STOP_SERVER);

		m_bChangeService = true;
	}
	ServerBase::SetCheckPortBeforeStarting(m_cEasyPHP.m_bCheckServerPorts);

	m_cApache.SetConfReload(m_cEasyPHP.m_bAutoReloadConf);
	m_cApache.SetSSLMode(m_cEasyPHP.m_bModeSSL);
	
	m_cMySql.SetParameters((LPCTSTR) m_cEasyPHP.m_sMySql_Arguments);

//	UpdateLang();

	m_cEasyPHP.Save();
}

void CEasyPhpDlg::OnInstall()
{
/*
	m_cEasyPHP.m_bStartAsService = false;
	m_cApache.SetService(false);
	m_cMySql.SetService(false);
	RegenerateConfFiles(GetHandle());

	char szDest[MAX_PATH+1] = {0};
	_snprintf(szDest, sizeof(szDest), "%ssafe\\httpd-safe.conf", m_cEasyPHP.InstallPath());
	CopyFile(m_cApache.GetConfFile(), szDest, FALSE);
	_snprintf(szDest, sizeof(szDest), "%ssafe\\my-safe.ini", m_cEasyPHP.InstallPath());
	CopyFile(m_cMySql.GetConfFile(), szDest, FALSE);
	_snprintf(szDest, sizeof(szDest), "%ssafe\\php-safe.ini", m_cEasyPHP.InstallPath());
	CopyFile(m_sPhpIni, szDest, FALSE);
*/
}

void CEasyPhpDlg::OnReleaseNotes()
{
//	char szHelpPage[MAX_PATH] = {0};

//	_snprintf(szHelpPage, sizeof(szHelpPage)-1, "file:///%shelp\\releasenotes.html", m_cEasyPHP.InstallPath());
	CUtils::GotoURL("http://instantrails.rubyforge.org/wiki/wiki.pl?Release_Notes"); 
}

void CEasyPhpDlg::OnAbout()
{
	CEasyPhpAboutDlg DlgAbout(GetHandle());
}

void CEasyPhpDlg::OnCheckVersion(bool baOnStartup)
{
	/*
	{
		CUpgradeDlg cUpgradeDlg(baOnStartup);

		UINT niRet = cUpgradeDlg.Show(GetHandle());

		if (niRet & RESTART_MANAGER)
		{
			if (MessageBox(GetHandle(), CLangue::LoadString(IDS_UPDATE_NEED_RESTART), m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONASTERISK) == IDYES)
			{
				PostMessage(GetHandle(), WM_QUIT, 0, 0);
				g_bRelaunchManager = true;
			}
		}
		else
		{
			if (niRet & RESTART_APACHE)
				HandleServerActionError(m_cApache.Restart(), 0, IDS_ERROR_RESTART_SERVER);
			if (niRet & RESTART_MYSQL)
				HandleServerActionError(m_cMySql.Restart(), 0, IDS_ERROR_RESTART_SERVER);
		}
	}
*/
	
/*
	HCURSOR hOldCursor = ::SetCursor(::LoadCursor(NULL, IDC_WAIT));
	char szCurrentVersion[50] = {0};
	char szInfoSupp[100] = {0};
	bool biCheck = CUtils::CheckVersion(m_cEasyPHP.ManagerPath(), szCurrentVersion, szInfoSupp, sizeof(szInfoSupp)-1);
	
	::SetCursor(hOldCursor);

	if (biCheck)
	{
		if (szCurrentVersion[0])
		{
			unsigned char pciThisVersion[4] = {0};
			char szThisVersion[50] = {0};

			CUtils::GetFileVersion(m_cEasyPHP.ManagerPath(), pciThisVersion);
			
			_snprintf(szThisVersion, sizeof(szThisVersion)-1, "%d.%d.%d.%d",
				pciThisVersion[0], pciThisVersion[1], pciThisVersion[2], pciThisVersion[3]);

			if (strcmp(szThisVersion, szCurrentVersion))
			{
				char szPrompt[255] = {0};
				char szGrosPrompt[512] = {0};
				
				_snprintf(szPrompt, sizeof(szPrompt)-1, CLangue::LoadString(IDS_NEW_EASYPHP_VERSION), szCurrentVersion);
				_snprintf(szGrosPrompt, sizeof(szGrosPrompt)-1, "%s\nv %s:\n%s", szPrompt, szCurrentVersion, szInfoSupp);
				if (MessageBox(GetHandle(), (LPCTSTR) szGrosPrompt, m_cEasyPHP.GetAppName(), MB_YESNO | MB_ICONASTERISK) == IDYES)
					CUtils::GotoURL("http://www.easyphp.org/");
			}
		}
	}
*/
}

// Fonctions protected
void CEasyPhpDlg::Demarrer()
{
	LogMessage(CLangue::LoadString(IDS_LOG_START_SERVERS), LOG_EASYPHP);

	for (unsigned int niI = 0; niI < 2; niI++)
	{
		m_uiServerSelected = niI;
		OnServerStart();
	}
}

void CEasyPhpDlg::Arreter()
{
	LogMessage(CLangue::LoadString(IDS_LOG_STOP_SERVERS), LOG_EASYPHP);
	m_cApache.Stop();
	m_cMySql.Stop();

	m_NotifyIconData.hIcon = LoadIcon(g_hInstance, (LPCTSTR) IDR_MAINFRAME);
	Shell_NotifyIcon(NIM_MODIFY, &m_NotifyIconData);
}

void CEasyPhpDlg::Automate()
{
	SERVER_STATE siApache = m_cApache.GetState(), siMySql = m_cMySql.GetState();

	m_bStarted = (siApache==SERVER_RUNNING && siMySql==SERVER_RUNNING);

	// Pas propre... a deplacer
	FILETIME aTime;
	CUtils::GetModifiedTime(m_szPHPTemplateINI, &aTime);
	if (aTime.dwLowDateTime && aTime.dwHighDateTime &&
		memcmp((void *) &aTime, (void *) &(m_TimePHPTemplateConfModified), sizeof(FILETIME)))
	{
		PostMessage(GetHandle(), m_uiPHPMessage, (WPARAM)MSG_CHANGE_CONF, (LPARAM) 0);
		GenerateConfFile(CUtils::GetEasyPhpPath(), m_szPHPTemplateINI, (LPCTSTR) m_sPhpIni, ';');
		CUtils::GetModifiedTime((LPCTSTR) m_szPHPTemplateINI, &m_TimePHPTemplateConfModified);
//		m_cApache.SetQueryRestart(true);	// Fait par MSG_CHANGE_CONF
	}


	if (m_cApache.GetQueryRestart() && siApache==SERVER_STOPPED)
	{
		m_cApache.SetQueryRestart(false);
//		on verifie avant le stop !
//		if (m_cApache.VerifyConfFile())
			HandleServerActionError(m_cApache.Start(), 0, IDS_SERVER_RUN_ERROR);
	}
	else if (m_cMySql.GetQueryRestart() && siMySql==SERVER_STOPPED)
	{
		m_cMySql.SetQueryRestart(false);
		HandleServerActionError(m_cMySql.Start(), 1, IDS_SERVER_RUN_ERROR);
	}
	else
	{
		if ((m_cMySql.GetState()==SERVER_STOPPED && m_cApache.GetState()==SERVER_STOPPED) 
				&& m_bChangeService)
		{
			m_bChangeService = false;

			if (m_cEasyPHP.m_bStartAsService)
			{
				HandleServerActionError(m_cApache.InstallService(), 0, IDS_ERROR_INSTALL_SERVICE);
				HandleServerActionError(m_cMySql.InstallService(), 1, IDS_ERROR_INSTALL_SERVICE);
			}
			else
			{
				HandleServerActionError(m_cApache.RemoveService(), 0, IDS_ERROR_REMOVE_SERVICE);
				HandleServerActionError(m_cMySql.RemoveService(), 1, IDS_ERROR_REMOVE_SERVICE);
			}
			m_cApache.SetService(m_cEasyPHP.m_bStartAsService);
			m_cMySql.SetService(m_cEasyPHP.m_bStartAsService);

			m_cApache.SetQueryRestart(true);
			m_cMySql.SetQueryRestart(true);
		}
/*
		else 
		{
			if (m_cMySql.GetState()==SERVER_STOPPED && m_cApache.GetState()==SERVER_RUNNING)
				m_cApache.Stop();
			else 
			if (m_cMySql.GetState()==SERVER_RUNNING && m_cApache.GetState()==SERVER_STOPPED)
				m_cMySql.Stop();
		}*/
	}
}

// Fonctions privées

HBITMAP BitmapFromStatus(SERVER_STATE saStatus)
{
	static HBITMAP hVert = (HBITMAP) ::LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_VERT), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT);
	static HBITMAP hOrange = (HBITMAP) ::LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_ORANGE), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT);
	static HBITMAP hRouge = (HBITMAP) ::LoadImage(g_hInstance, MAKEINTRESOURCE(IDB_ROUGE), IMAGE_BITMAP, 0, 0, LR_LOADTRANSPARENT);

	switch (saStatus)
	{
	case SERVER_RUNNING:		return hVert;
	case SERVER_START_PENDING:
	case SERVER_STOP_PENDING:	return hOrange;
		break;
	default: return hRouge ;
	}
}

const char *StringFromStatus(SERVER_STATE saStatus)
{
	switch (saStatus)
	{
	case SERVER_RUNNING:	return CLangue::LoadString(IDS_STATE_STARTED);
	case SERVER_STOPPED:	return CLangue::LoadString(IDS_STATE_STOPPED);
	case SERVER_START_PENDING:
	case SERVER_STOP_PENDING:
		return CLangue::LoadString(IDS_PENDING);
	}
	return "undefined";
}

DWORD CEasyPhpDlg::HandleServerActionError(DWORD dwaError, int naServeurIndex, UINT naActionPrompt)
{
	if (dwaError != ERROR_SUCCESS)
	{
		char *szError = NULL;
		char szPrompt[256] = {0}, szPrompt2[300] = {0};

		if (CUtils::GetErrorMessage(dwaError, &szError))
		{
			int niLength = strlen(szError);
			if (niLength >= 2)
				szError[niLength-2] = '\0';

			_snprintf(szPrompt, sizeof(szPrompt)-1, CLangue::LoadString(naActionPrompt), (LPCTSTR) szError);
			_snprintf(szPrompt2, sizeof(szPrompt2)-1, "%s (%d)", szPrompt, dwaError);
			LocalFree(szError);
		}
		else strncpy(szPrompt2, CLangue::LoadString(naActionPrompt), 255);
		LogMessage(szPrompt2, naServeurIndex == 0 ? LOG_APACHE : LOG_MYSQL);
		MessageBox(GetHandle(), szPrompt2, naServeurIndex == 0 ? "Apache" : "MySql", MB_OK);
	}

	return dwaError;
}

void CEasyPhpDlg::LogMessage(const char *szaMessage, UINT naType, bool baAlertInTray)
{
	SYSTEMTIME stTime = {0};
	static char szBuffer[256] = {0};
	char *szAppi = (char *) m_cEasyPHP.GetAppName();

	switch (naType)
	{
	case LOG_MYSQL:		szAppi = "MySql  "; break;
	case LOG_APACHE:	szAppi = "Apache "; break;
	case LOG_PHP:		szAppi = "PHP    "; break;
	case LOG_DEBUGGER:	szAppi = "Debug"; break;
	}

	GetLocalTime(&stTime);

	_snprintf(szBuffer, sizeof(szBuffer)-1, "%02d/%02d %02d:%02d:%02d %s: %s", stTime.wDay, stTime.wMonth, stTime.wHour, stTime.wMinute, stTime.wSecond, szAppi, szaMessage);


	FILE *m_piFile = fopen(m_cEasyPHP.LogPath(), "a");

	if (m_piFile != NULL)
	{
		fprintf(m_piFile, "%s\n", szBuffer);
 		fclose(m_piFile);
	}

	static HWND hiList = GetDlgItem(IDC_LOG);
	SendMessage(hiList, LB_SETCURSEL, SendMessage(hiList, LB_ADDSTRING, 0, (LPARAM) szBuffer), 0);
	InvalidateRect(hiList, NULL, TRUE);

	if (baAlertInTray)
	{
/*        m_NotifyIconData.uFlags = NIF_INFO;
        m_NotifyIconData.dwInfoFlags = NIIF_WARNING;	// NIIF_ERROR
        strncpy(m_NotifyIconData.szInfoTitle, m_sAppName, 63); 
        strncpy(m_NotifyIconData.szInfo, szBuffer, 255);
        m_NotifyIconData.uTimeout = 15000; // in milliseconds
        Shell_NotifyIcon(NIM_MODIFY, &m_NotifyIconData);*/
	}
}

void CEasyPhpDlg::UpdateLang()
{
/*
	// Tooltip
	CreateTooltip(GetDlgItem(IDC_STATUS_APACHE), CLangue::LoadString(IDS_HELPCTX_IDC_STATUS_APACHE));
	CreateTooltip(GetDlgItem(IDC_STATUS_MYSQL), CLangue::LoadString(IDS_HELPCTX_IDC_STATUS_MYSQL));
	CreateTooltip(GetDlgItem(ID_PIN), CLangue::LoadString(IDS_HELPCTX_ID_PIN));
	CreateTooltip(GetDlgItem(ID_HELP_CONTEXT), CLangue::LoadString(IDS_HELPCTX_ID_HELP_CONTEXT));
	CreateTooltip(GetDlgItem(IDC_EXPAND), CLangue::LoadString(IDS_HELPCTX_IDSL_VIEW));

	// Menus
	MENUITEMINFO stMII = {0};
	char szItemBuffer[61] = {0};
	stMII.cbSize = sizeof(stMII);
	//stMII.fMask = 0x00000040;	//MIIM_STRING avec #define WINVER 0x0500
	stMII.dwTypeData = szItemBuffer;
	//if (::__major == 4 && __minor = 0)	// marche sous 2K
	stMII.fType = MFT_STRING;
	stMII.fMask = MIIM_TYPE;

	// Menu serveur
	strncpy(szItemBuffer, CLangue::LoadString(IDS_START), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMenuServer, ID_SERVER_START, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_SERVER_RESTART), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMenuServer, ID_SERVER_RESTART, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_STOP), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMenuServer, ID_SERVER_STOP, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_SERVER_KILL), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMenuServer, ID_SERVER_KILL, FALSE, &stMII);

	// Menu principal
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_HELP), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, 0, TRUE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_LOGFILES), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, 2, TRUE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_CONFIGURATION), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, 3, TRUE, &stMII);
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tF8", CLangue::LoadString(IDS_MENU_EXPLORE));
	SetMenuItemInfo(m_hMainMenu, ID_EXPLORE_DOCROOT, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_ADMINISTRATION), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_ADMINISTRATION, FALSE, &stMII);
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tF7", CLangue::LoadString(IDS_MENU_WEBLOCAL));
	SetMenuItemInfo(m_hMainMenu, ID_BROWSE_WEB, FALSE, &stMII);
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tF5", CLangue::LoadString(IDS_SERVER_RESTART));
	SetMenuItemInfo(m_hMainMenu, ID_RESTART, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_QUIT), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_QUIT, FALSE, &stMII);

	// Sous menus
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tF1", CLangue::LoadString(IDS_MENU_HELP_INTRODUCTION));
	SetMenuItemInfo(m_hMainMenu, ID_AIDE_INTRO, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_HELP_STARTPHP), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_AIDE_DEBUTER, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_HELP_FAQ), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_AIDE_FAQ, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_ABOUT_TITLE), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_ABOUT, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_LOGFILES_APACHE_ERR), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_APACHE_ERREUR_LOG, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_LOGFILES_APACHE_ACCESS), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_APACHE_ACCES_LOG, FALSE, &stMII);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_MENU_LOGFILES_MYSQLERR), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_MYSQL_ERREUR_LOG, FALSE, &stMII);
	strncpy(szItemBuffer, m_cEasyPHP.GetAppName(), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(m_hMainMenu, ID_EASYPHP_LOG, FALSE, &stMII);
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tCTRL+X", CLangue::LoadString(IDS_MENU_CONFIGURATION_EXTENSIONSPHP));
	SetMenuItemInfo(m_hMainMenu, ID_CONFIGURATION_PHPEXT, FALSE, &stMII);
	_snprintf(szItemBuffer, sizeof(szItemBuffer)-1, "%s\tCTRL+E", m_cEasyPHP.GetAppName());
	SetMenuItemInfo(m_hMainMenu, ID_EASYPHP_CONF, FALSE, &stMII);

	// Dialogue
	SetWindowText(GetDlgItem(IDC_STATUS), CLangue::LoadString(IDS_MAIN_STATUS));

	HMENU hSystemMenu = GetSystemMenu(GetHandle(), FALSE);
	strncpy(szItemBuffer, CLangue::LoadString(IDS_ALWAYS_VISIBLE), sizeof(szItemBuffer)-1);
	SetMenuItemInfo(hSystemMenu, ID_PIN, FALSE, &stMII);
//
//	SetMenuItemText(
//	InsertMenu(hSystemMenu, 2, MF_BYPOSITION, ID_PIN, );
//	SetMenuItemInfo(m_hMainMenu, ID_MYSQL_ERREUR_LOG, FALSE, &stMII);
//

	OnTimer(TIMER_ID_ICONE, 1);		// Forcer la mise a jour...
*/	
}

void CEasyPhpDlg::OnManageRailsApps() {
	CPHPExtDlg cPHPExt(GetHandle(), m_szPHPTemplateINI);
}

void CEasyPhpDlg::BrowseLocalURL(const char *szaURL)
{
	if (m_cApache.IsStarted())	// Can be reached from shortcuts.
	{
		char szPage[128] = {0};

/*		bool isGoodName = true;
		char szCompName[MAX_PATH] = {0};
		DWORD liSize = MAX_PATH;
		GetComputerName(szCompName, &liSize);

		// Si le nom d'ordi a des caracteres à la con on prends "127.0.0.1"
		for (int niI = 0; szCompName[niI]!='\0' && isGoodName; niI++)
			isGoodName = isalpha(szCompName[niI]) || isdigit(szCompName[niI]);
		_snprintf(szURL, MAX_PATH, "http://%s:%d/", !isGoodName||szCompName[0]=='\0' ? "127.0.0.1" : szCompName, m_cApache.GetPort());
*/
		if (m_cApache.GetPort() != 80)
			_snprintf(szPage, sizeof(szPage)-1, "http://127.0.0.1:%d/%s", m_cApache.GetPort(), szaURL);
		else _snprintf(szPage, sizeof(szPage)-1, "http://127.0.0.1/%s", szaURL);
		CUtils::GotoURL(szPage);
	}
}
