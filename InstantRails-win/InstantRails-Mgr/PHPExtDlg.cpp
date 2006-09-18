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

// PHPExtDlg.cpp : implementation file
//

#include "EasyPHPDlg.h"
#include "PHPExtDlg.h"
#include "ScgiDlg.h"
#include "Utils.h"
#include "Langue.h"
#include <stdio.h>
#include  <io.h>			// _access
#include <commctrl.h>
#include <string>

#define PHP_EXT_TAG_BEGIN	";PHPExt"
#define PHP_EXT_TAG_END		";/PHPExt"

extern HINSTANCE g_hInstance;


class CRailsApp
{
public:
	CRailsApp(const char *szaName)
	{
		char szRailsAppPath[MAX_PATH] = {0};
		
		_snprintf(szRailsAppPath, sizeof(szRailsAppPath)-1, "%srails_apps", CUtils::GetEasyPhpPath(), szaName);

		m_bPresent = false;
		m_bAvailable = false;
		m_sName = szaName;
		m_sPath = szRailsAppPath;

		if (_access(m_sPath.c_str(), 0) != -1)
		{
			HMODULE hExtDLL = NULL;

			m_bPresent = true;

			if ((hExtDLL = LoadLibrary(m_sPath.c_str())) != NULL)
			{
				m_bAvailable = true;
				FreeLibrary(hExtDLL);
			}
		}
	}

public:
	std::string m_sName;
	std::string m_sPath;
	bool		m_bPresent;
	bool		m_bAvailable;
};



CPHPExtDlg::CPHPExtDlg(HWND haParent, const char* szaPHPIniPath)
{
	strncpy(m_szPHPIniPath, szaPHPIniPath, MAX_PATH);
	m_bIsChanged = false;
	m_bIsInit = false;
	Create(IDD_TEMPLATE, haParent, true);
}

CPHPExtDlg::~CPHPExtDlg()
{
	m_szPHPIniPath[0] = '\0';

	ListView_DeleteAllItems(GetDlgItem(IDL_RAILS_APPS_LIST));
}

bool CPHPExtDlg::OnInitDialog()
{
	HWND hRailsAppsList = GetDlgItem(IDL_RAILS_APPS_LIST);
	LVCOLUMN stLvColumn = {0};

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	SendMessage(hRailsAppsList, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_CHECKBOXES );

	stLvColumn.mask = LVCF_TEXT | LVCF_WIDTH;
	stLvColumn.cx = 160;
	stLvColumn.pszText = "Rails Applications";
	SendMessage(hRailsAppsList, LVM_INSERTCOLUMN, 0, (LPARAM) &stLvColumn);

	PostMessage(GetHandle(), WM_COMMAND, ID_REFRESH_EXTENSION, 0);

	return true;
}

int CPHPExtDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	BOOL biTraite = TRUE;
	
	switch (message)
	{
	case WM_COMMAND:	OnCommand(waParam);											break;
	case WM_NOTIFY:		HANDLE_WM_NOTIFY(GetHandle(), waParam, laParam, OnNotify);	break;
	default: biTraite = FALSE;
	}

	return (biTraite ? biTraite : CEasyPHPDialogBase::WindowProc(message, waParam, laParam));
}

bool CPHPExtDlg::OnCommand(WPARAM waCommand)
{
	switch (waCommand)
	{
	case ID_CONFIG_MONGREL:
	case ID_START_MONGREL:
	case ID_START_WEBRICK:
	case ID_OPEN_RAILS_CONSOLE:
		if (GetCheckedItemCount() > 0)
		{
			if (OnRailsPreCommand(waCommand))
			{
				HWND hRailsAppsList = GetDlgItem(IDL_RAILS_APPS_LIST);
				LVITEM stLvItem = {0};
				char szAppName[121] = {0};
				stLvItem.mask = LVIF_TEXT;
				stLvItem.pszText = szAppName;
				stLvItem.cchTextMax = 120;
				int max = ListView_GetItemCount(hRailsAppsList);
				bool first = true;
				for (int ii = 0; ii < max; ii++)
				{
					stLvItem.iItem = ii;
					SendMessage(hRailsAppsList, LVM_GETITEM, 0, (LPARAM) &stLvItem);
					bool biChecked = (ListView_GetCheckState(hRailsAppsList, ii) == TRUE);
					if (biChecked)
					{
						OnRailsCommand(waCommand, szAppName, first);
						first = false;
					}
				}
			}
		}
		break;

	case ID_NEW_RAILS_APP:
		{
			SetCurrentDirectory(CEasyPhpDlg::GetInstallPath());
			char command[MAX_PATH] = {0};
			_snprintf(command, sizeof(command)-1, "cmd /k %suse_ruby.cmd", CEasyPhpDlg::GetInstallPath());
			WinExec(command, SW_SHOW);
		}
		break;

	case ID_REFRESH_EXTENSION:
		Refresh();
		break;

	case IDOK:
		DeleteAll();
		EndDialog(GetHandle(), m_bIsChanged ? IDOK : IDCANCEL);
		break;
	}
	return true;
}

void CPHPExtDlg::OnNotify(HWND haDlg, WPARAM waParam, LPNMHDR paNMHDR)
{
	if (paNMHDR->idFrom==IDL_RAILS_APPS_LIST)
	{
		switch (paNMHDR->code)
		{
		case LVN_ITEMCHANGED:
			if (m_bIsInit==false && GetCheckedItemCount() > 0)
			{
				EnableWindow(GetDlgItem(ID_CONFIG_MONGREL), TRUE);
				EnableWindow(GetDlgItem(ID_START_MONGREL), TRUE);
				EnableWindow(GetDlgItem(ID_START_WEBRICK), TRUE);
				EnableWindow(GetDlgItem(ID_OPEN_RAILS_CONSOLE), TRUE);
			}
			else
			{
				EnableWindow(GetDlgItem(ID_CONFIG_MONGREL), FALSE);
				EnableWindow(GetDlgItem(ID_START_MONGREL), FALSE);
				EnableWindow(GetDlgItem(ID_START_WEBRICK), FALSE);
				EnableWindow(GetDlgItem(ID_OPEN_RAILS_CONSOLE), FALSE);
			}
			break;
		}
	}
}

void CPHPExtDlg::Refresh()
{
	char szCurrentDir[MAX_PATH] = {0}, szRADir[MAX_PATH] = {0};
	HWND hRailsAppsList = GetDlgItem(IDL_RAILS_APPS_LIST);
	char szRailsAppPath[MAX_PATH] = {0};

	m_bIsInit = true;

	_snprintf(szRailsAppPath, sizeof(szRailsAppPath)-1, "%srails_apps", CUtils::GetEasyPhpPath());

	if (GetCurrentDirectory(sizeof(szCurrentDir)-1, szCurrentDir) == 0)
		szCurrentDir[0] = '\0';

	_snprintf(szRADir, sizeof(szRADir)-1, "%srails_apps\\", CUtils::GetEasyPhpPath());
	SetCurrentDirectory(szRADir);

	EnableWindow(GetDlgItem(ID_CONFIG_MONGREL), FALSE);
	EnableWindow(GetDlgItem(ID_START_MONGREL), FALSE);
	EnableWindow(GetDlgItem(ID_START_WEBRICK), FALSE);
	EnableWindow(GetDlgItem(ID_OPEN_RAILS_CONSOLE), FALSE);
	SetCursor(LoadCursor(NULL, IDC_WAIT));
	SendMessage(hRailsAppsList, WM_SETREDRAW, FALSE, 0);

	DeleteAll();

	DWORD dwOldErrorMode = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);
	LVITEM stLvItem = {0};
	int niIIndex = 0;

	stLvItem.mask = LVIF_TEXT | LVIF_PARAM;
	stLvItem.iSubItem = 0;

	WIN32_FIND_DATA FindFileData;
	HANDLE hFind;
	char szPathExtensionFilter[MAX_PATH] = {0};

	_snprintf(szPathExtensionFilter, sizeof(szPathExtensionFilter)-1, "*.*", szRailsAppPath);
	
	hFind = FindFirstFile(szPathExtensionFilter, &FindFileData);

	if (hFind)
	{
		LVFINDINFO stLVFI = {0};

		stLVFI.flags = LVFI_STRING;
		stLVFI.vkDirection = VK_NEXT;

		do
		{
			if ((FindFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)!=0 &&
				FindFileData.cFileName[0] != '.') {
				stLVFI.psz = FindFileData.cFileName;

				if (ListView_FindItem(hRailsAppsList, -1, &stLVFI) == -1)
				{
					stLvItem.pszText = FindFileData.cFileName;
					stLvItem.iItem = niIIndex;
					stLvItem.lParam = (LPARAM) new CRailsApp(FindFileData.cFileName);
					SendMessage(hRailsAppsList, LVM_INSERTITEM, 0, (LPARAM) &stLvItem);
					niIIndex++;
				}
			}
		}
		while (FindNextFile(hFind, &FindFileData));
		FindClose(hFind);
	}

	if (szCurrentDir[0])
		SetCurrentDirectory(szCurrentDir);

	SetErrorMode(dwOldErrorMode);

	SendMessage(hRailsAppsList, WM_SETREDRAW, TRUE, 0);
	SetCursor(LoadCursor(NULL, IDC_ARROW));

	m_bIsInit = false;
}

int CPHPExtDlg::GetCheckedItemCount()
{
	int count = 0;
	HWND hRailsAppsList = GetDlgItem(IDL_RAILS_APPS_LIST);
	LVITEM stLvItem = {0};
	char szAppName[121] = {0};

	stLvItem.mask = LVIF_TEXT;
	stLvItem.pszText = szAppName;
	stLvItem.cchTextMax = 120;

	int max = ListView_GetItemCount(hRailsAppsList);

	for (int ii = 0; ii < max; ii++)
	{
		stLvItem.iItem = ii;
		SendMessage(hRailsAppsList, LVM_GETITEM, 0, (LPARAM) &stLvItem);
		bool biChecked = (ListView_GetCheckState(hRailsAppsList, ii) == TRUE);
//		fprintf(phPHPIniFile, "%sextension=%s.dll\n", biChecked ? "" : ";", stLvItem.pszText);
		if (biChecked)
			count++;
	}

	return count;
}

void CPHPExtDlg::DeleteAll()
{
	HWND hRailsAppsList = GetDlgItem(IDL_RAILS_APPS_LIST);
	unsigned int niCount = ListView_GetItemCount(hRailsAppsList);

	for (unsigned int ii = 0; ii < niCount; ii++)
	{
		try
		{
			CRailsApp *piPHPExt = (CRailsApp *) ListView_GetItemData(hRailsAppsList, ii);

			if (piPHPExt)
				delete piPHPExt;
		}
		catch (...)
		{
		}
	}

	ListView_DeleteAllItems(hRailsAppsList);
}

bool CPHPExtDlg::OnRailsPreCommand(WPARAM waCommand)
{
	switch (waCommand)
	{
	case ID_CONFIG_MONGREL:
		{
		}
		break;

	case ID_START_MONGREL:
		break;

	case ID_OPEN_RAILS_CONSOLE:
		break;
	}
	return true;
}

void CPHPExtDlg::OnRailsCommand(WPARAM waCommand, LPSTR szAppName, bool firstApp)
{
	const char* installPath = CEasyPhpDlg::GetInstallPath();
	char src[MAX_PATH+1] = {0};
	char dest[MAX_PATH+1] = {0};

	char iniPath[MAX_PATH];
	_snprintf(iniPath, sizeof(iniPath)-1, "%sInstantRails.ini", installPath);

	char mode[50] = {0};
	char port[50] = {0};

	GetPrivateProfileString(szAppName, "mode", "development", mode, 50, iniPath);
	GetPrivateProfileString(szAppName, "port", "3000", port, 50, iniPath);

	switch (waCommand)
	{
	case ID_CONFIG_MONGREL:
		{
				CScgiDlg cMongrel(GetHandle(), szAppName);
		}
		break;

	case ID_START_MONGREL:
		{
			_snprintf(dest, sizeof(dest), "%srails_apps\\%s", installPath, szAppName);
			SetCurrentDirectory(dest);
			_snprintf(src, sizeof(src), "%sruby\\bin\\ruby.exe %sruby\\bin\\mongrel_rails start -e %s -p %s", installPath, installPath, mode, port);
			WinExec(src, SW_SHOW);
		}
		break;

	case ID_START_WEBRICK:
		{
			_snprintf(dest, sizeof(dest), "%srails_apps\\%s", installPath, szAppName);
			SetCurrentDirectory(dest);
			_snprintf(src, sizeof(src), "%sruby\\bin\\ruby.exe script\\server -e %s -p %s", installPath, mode, port);
			WinExec(src, SW_SHOW);
		}
		break;

	case ID_OPEN_RAILS_CONSOLE:
		{
			_snprintf(dest, sizeof(dest), "%srails_apps\\%s", installPath, szAppName);
			SetCurrentDirectory(dest);
			_snprintf(src, sizeof(src), "%sruby\\bin\\ruby.exe script\\console", installPath);
			WinExec(src, SW_SHOW);
		}
		break;
	}
}

