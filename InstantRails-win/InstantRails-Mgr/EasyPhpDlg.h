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

// EasyPhpDlg.h : header file
//

#pragma once

#include "CEasyPhp.h"
#include "CApache.h"
#include "CMySql.h"
#include "DebugDlg.h"
#include "EasyPHPDialogBase.h"

#include "resource.h"

#include <shellapi.h>
#include <stdio.h>

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpDlg dialog

class CEasyPhpDlg : public CEasyPHPDialogBase
{
// Construction
public:
	CEasyPhpDlg(HWND paParent = NULL);	// standard constructor
	virtual ~CEasyPhpDlg();

	virtual int WindowProc(UINT message, WPARAM wParam, LPARAM lParam);
	virtual bool OnInitDialog();

// Access
	static CApache* GetApache();
	static const char* GetInstallPath();


// Implementation
protected:
	// Windows
	void OnInitMenuPopup(HMENU haMenu, int item, BOOL fSystemMenu);
	virtual bool OnCommand(WPARAM waCommand, LPARAM laParam);
	void OnTimer(UINT nIDEvent, LPARAM laParam);

	void OnTrayBarNotification(WPARAM wParam, LPARAM lParam);

	// Menu Aide
	void OnHelp();
	void OnFxri();
	void OnHelpFAQ();
	void OnHelpDebuter();

	// Menu configuration
	void OnApacheConf();
	void OnPhpExtConf();
	void OnPhpConf();
	void OnMyAdmin();
	void OnMySqlConf();
	void OnPreferences();
	void OnWindowHosts();

	void OnInstall();

	// menu de logs
	void OnApacheErrorLog();
	void OnApacheAccesLog();
	void OnMySqlErrorLog();
	void OnEasyPhpLog();

	// Menu principal
	void OnExploreDocRoot();
	void OnRailsAppConsole();
	void OnRailsAppExplore();
	void OnManageRailsApps();
	void OnAdministration();
	void OnWebLocal();
	void OnRestart();
	void OnSwitch();
	void OnQuit();

	// boite de dialogue
	void OnPinChange();
	void OnMenu(bool baFromKey = false);
	void OnMenuServeur(UINT naServeur);
	void OnExpand();
	void OnReleaseNotes();
	void OnAbout();
	void OnCheckVersion(bool baOnStartup=false);

	// Menu serveur
	void OnServerStart();
	void OnServerRestart();
	void OnServerStop();
	void OnServerKill();

	// 	
	void OnHelpCmdLine();

private:
	enum { IDD_TEMPLATE = IDD_EASYPHP_DIALOG };

	void	Demarrer();
	void	Arreter();
	void	Automate();

	void BrowseLocalURL(const char *szaURL);
	DWORD	HandleServerActionError(DWORD dwaError, int naServeurIndex, UINT naActionPrompt);
	void	LogMessage(const char *szaMessage, UINT naType, bool baAlertInTray = false);	

	void	UpdateLang();

// Propriétés
	// Appli
	const COLORREF		m_cstColorRef;
	NOTIFYICONDATA		m_NotifyIconData;
	HICON				m_hIcon[4];
	HBRUSH				m_hBrush;
	HMENU				m_hMenuServer;
	HMENU				m_hMainMenu;

	CMySql				m_cMySql;
	CApache				m_cApache;

	// used for external access to these values
	static CApache*		g_apache;
	static const char*	g_installPath; 

	// EasyPhp
	CEasyPHP			m_cEasyPHP;			// parametres
	bool				m_bStarted;
	bool				m_bChangeService;

	//					Pas beau mais flemme... 
	//					-1 : pas de selection
	//					0 : apache
	//					1 : MySql
	int					m_uiServerSelected;

//	CDebugDlg			m_cDebugDlg;

	// Php			
	char				m_sPhpIni[MAX_PATH];
};
