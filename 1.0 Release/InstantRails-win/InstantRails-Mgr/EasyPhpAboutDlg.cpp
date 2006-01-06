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

// EasyPhpAboutDlg.cpp : implementation file
//

#include "EasyPhpAboutDlg.h"
#include "Utils.h"
#include "Langue.h"
#include "CEasyPHP.h"
#include "EasyPHP.h"
#include <stdio.h>

extern HINSTANCE g_hInstance;

#ifndef IDC_HAND
#define IDC_HAND            MAKEINTRESOURCE(32649)
#endif

// Winproc pour les static "liens web"
LRESULT CALLBACK StaticProc( HWND, UINT, WPARAM, LPARAM );
LRESULT OldProcStatic;

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpAboutDlg dialog


CEasyPhpAboutDlg::CEasyPhpAboutDlg(HWND paParent /*=NULL*/)
{
	m_hFont = NULL;
	m_hFontTitle = NULL;
	m_hFontLink = NULL;

	Create(IDD_TEMPLATE, paParent, true);
}

CEasyPhpAboutDlg::~CEasyPhpAboutDlg()
{
	if (m_hFont)
		DeleteObject(m_hFont);

	if (m_hFontTitle)
		DeleteObject(m_hFontTitle);

	if (m_hFontLink)
		DeleteObject(m_hFontLink);
}

int CEasyPhpAboutDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	switch (message)
	{
	case WM_COMMAND: OnCommand(waParam); break;

	case WM_CTLCOLORSTATIC:
		{
			HDC hiDC = (HDC) waParam;
			int niID = GetDlgCtrlID((HWND) laParam);

			switch (niID)
			{
			case IDC_LAURENT: 
			case IDC_EMMANUEL:
			case IDC_THIERRY:
			case IDC_HOME_PAGE_LINK:
				SelectObject(hiDC, niID != IDC_HOME_PAGE_LINK ? m_hFontLink : m_hFontTitle);
				SetTextColor(hiDC, COLORREF(RGB(0, 0, 238)));
				break;

			case IDC_TITLE:
				SelectObject(hiDC, m_hFontTitle);
				SetTextColor(hiDC, COLORREF(RGB(244, 244, 244)));
				break;

			case ID_OK:
			case ID_CHECK_VERSION:
			case ID_VIEW_LICENCE:
			case IDC_TRANSLATED_BY:
				break;

			default:
//				SelectObject(hiDC, m_hFont);
//				SetTextColor(hiDC, COLORREF(RGB(244, 244, 244)));
				SetTextColor(hiDC, COLORREF(RGB(0, 0, 0)));
				break;
			}

			SetBkMode(hiDC, TRANSPARENT); 	// transparent text.

			return (BOOL)GetStockObject(NULL_BRUSH);
		}
		break;

	case WM_CTLCOLORBTN:
		SetBkColor((HDC) waParam, RGB(244, 244, 244));
		return (BOOL)GetStockObject(WHITE_BRUSH);

/*	case WM_CTLCOLORDLG:
		return (BOOL) m_hDlgBrush;*/

	case WM_LBUTTONDOWN:
		PostMessage(GetHandle(), WM_NCLBUTTONDOWN, HTCAPTION, laParam);
		break;

	case WM_DESTROY:
		if (GetProp(GetHandle(),"region"))
		{
			DeleteObject(GetProp(GetHandle(),"region"));
			RemoveProp(GetHandle(),"region");
		}
		break;
	}
	return CEasyPHPDialogBase::WindowProc(message, waParam, laParam);
}

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpAboutDlg message handlers

bool CEasyPhpAboutDlg::OnInitDialog() 
{
	unsigned char pciVer[4] = {0};

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

/*
	HRGN hRgn;
	RECT rect;
	GetClientRect(GetHandle(), &rect);
	hRgn = CreateEllipticRgn(5,5,rect.right-5,rect.bottom-5);
	SetWindowRgn(GetHandle(),hRgn,TRUE);
	SetProp(GetHandle(),"region",hRgn);
*/
	// Initialisation des variables membres
	HFONT hiFont = (HFONT) SendMessage(GetHandle(), WM_GETFONT, 0, 0);
	LOGFONT lf;
	GetObject(hiFont, sizeof(lf), &lf);
	lf.lfUnderline = TRUE;
	m_hFontLink = CreateFontIndirect(&lf);

	lf.lfUnderline = FALSE;
	m_hFont = CreateFontIndirect(&lf);

	lf.lfWeight = FW_EXTRABOLD;
	lf.lfUnderline = TRUE;
	m_hFontTitle = CreateFontIndirect(&lf);

	// 
//	char szModuleName[MAX_PATH] = {0};
//	GetModuleFileName(g_hInstance, szModuleName, sizeof(szModuleName));
//	CUtils::GetFileVersion(szModuleName, pciVer);

	OldProcStatic = SetWindowLong(GetDlgItem(IDC_HOME_PAGE_LINK), GWL_WNDPROC, (LONG) (WNDPROC) StaticProc);
	SetWindowLong(GetDlgItem(IDC_LAURENT),GWL_WNDPROC, (LONG) (WNDPROC) StaticProc);
	SetWindowLong(GetDlgItem(IDC_EMMANUEL),GWL_WNDPROC, (LONG) (WNDPROC) StaticProc);
	SetWindowLong(GetDlgItem(IDC_THIERRY), GWL_WNDPROC, (LONG) (WNDPROC) StaticProc);

	SetFocus(GetDlgItem(IDOK));
	
	CreateTooltip(GetDlgItem(IDC_HOME_PAGE_LINK), "http://instantrails.rubyforge.org/");
//	CreateTooltip(GetDlgItem(IDC_LAURENT), "laurent@abbal.com");
//	CreateTooltip(GetDlgItem(IDC_EMMANUEL), "manu@manucorp.com");
//	CreateTooltip(GetDlgItem(IDC_THIERRY), "thierry@easyphp.org");

	char szTitle[200] = {0};
	_snprintf(szTitle, sizeof(szTitle)-1, "%s %s", CLangue::LoadString(IDS_ABOUT_TITLE),
			INSTANT_RAILS_VERSION);
	SetWindowText(GetHandle(), szTitle); 
	
/*
	SetWindowText(GetDlgItem(IDC_PRESENTATION), CLangue::LoadString(IDS_ABOUT_PRESENTATION));
	SetWindowText(GetDlgItem(IDC_SEE_SITE), CLangue::LoadString(IDS_ABOUT_VISIT_SITE));
	SetWindowText(GetDlgItem(ID_VIEW_LICENCE), CLangue::LoadString(IDS_ABOUT_SEE_LICENCE));
	SetWindowText(GetDlgItem(ID_CHECK_VERSION), CLangue::LoadString(IDS_ABOUT_CHECK_VERSION));
	SetWindowText(GetDlgItem(IDC_TRANSLATED_BY), CLangue::LoadString(IDS_TRANSLATED_BY));
*/

/*	static char szLicenseBufferCorrected[30200] = {0};
	if (szLicenseBufferCorrected[0] == 0)
	{
		FILE *pFile = fopen("d:\\easyphp\\gpl.txt", "r");

		if (pFile)
		{
			char szLicenseBuffer[30000] = {0};

			fread(szLicenseBuffer, 30000, 1, pFile);
			for (int niI = 0, niJ = 0; szLicenseBuffer[niI] != 0; niI++, niJ++)
			{
				if (szLicenseBuffer[niI] == 10)
					szLicenseBufferCorrected[niJ++] = 13;
				szLicenseBufferCorrected[niJ] = szLicenseBuffer[niI];
			}
			fclose(pFile);
		}
	}
	if (szLicenseBufferCorrected[0] != 0)
		SetWindowText(GetItemHandle(IDE_LICENCE), szLicenseBufferCorrected);
*/
	return true;  // return TRUE unless you set the focus to a control
	              // EXCEPTION: OCX Property Pages should return FALSE
}

bool CEasyPhpAboutDlg::OnCommand(WPARAM waCommand)
{
	switch (waCommand)
	{
	case ID_VIEW_LICENCE:
		{
			char szLicencePath[MAX_PATH] = {0};

			_snprintf(szLicencePath, sizeof(szLicencePath)-1, "%s\\gpl.txt", CUtils::GetEasyPhpPath());
			ShellExecute(NULL, "open", szLicencePath, NULL, NULL, SW_SHOW);
		}
		break;
	case ID_CHECK_VERSION:  SendMessage(GetParent(GetHandle()), WM_COMMAND, ID_CHECK_VERSION, 0); break;
	case IDCANCEL:
	case IDOK:				EndDialog(GetHandle(), waCommand);	break;

	case IDC_HOME_PAGE_LINK:ShellExecute(NULL, "open", "http://instantrails.rubyforge.org/", NULL, NULL, SW_SHOW);	 break;
//	case IDC_LAURENT:		ShellExecute(NULL, "open", "mailto:laurent@abbal.com?subject=EasyPhp", NULL, NULL, SW_SHOW); break;
	case IDC_EMMANUEL:		ShellExecute(NULL, "open", "http://blog.curthibbs.us/", NULL, NULL, SW_SHOW); break;
//	case IDC_THIERRY:		ShellExecute(NULL, "open", "mailto:thierry@easyphp.org?subject=EasyPhp", NULL, NULL, SW_SHOW); break;
	}

	return true;
}

//
LRESULT CALLBACK StaticProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
	HCURSOR hOld;

    switch (iMsg)
    {
	case WM_SETCURSOR: hOld = SetCursor(LoadCursor(NULL, MAKEINTRESOURCE(IDC_HAND))); return TRUE;
    }
    return(CallWindowProc((WNDPROC) OldProcStatic, hwnd, iMsg, wParam, lParam));
}
