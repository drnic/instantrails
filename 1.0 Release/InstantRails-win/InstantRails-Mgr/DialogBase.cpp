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
// DialogBase.cpp: implementation of the CDialogBase class.
//
//////////////////////////////////////////////////////////////////////

#include "DialogBase.h"

#include <commctrl.h>

extern HINSTANCE g_hInstance;

//////////////////////////////////////////////////////////////////////
// WindowProc commune a toutes les instances de CDialogBase
//////////////////////////////////////////////////////////////////////
int WINAPI CDialogBase_WindowProc(HWND haWnd, UINT message, WPARAM wParam, LPARAM lParam) 
{
	if (message == WM_INITDIALOG)
		return ((CDialogBase *) lParam)->InitDialog(haWnd);
	else
	{
		CDialogBase *piDlgBase = (CDialogBase *) GetWindowLong(haWnd, GWL_USERDATA);
		return (piDlgBase ? piDlgBase->WindowProc(message, wParam, lParam) : FALSE);
	}
}

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

// Méthodes publiques
CDialogBase::CDialogBase()
{
	m_hWnd = NULL;
}

CDialogBase::~CDialogBase()
{
	SendMessage(m_hWnd, WM_DESTROY, 0, 0);
	EndDialog(m_hWnd, 0);
	SetWindowLong(m_hWnd, GWL_USERDATA, (LONG) NULL);
	m_hWnd = NULL;
}

int CDialogBase::Create(UINT naTemplateID, HWND haParent, bool baModal)
{
	if (baModal)
		return DialogBoxParam(g_hInstance, MAKEINTRESOURCE(naTemplateID), haParent, CDialogBase_WindowProc, (LPARAM) this);
	else
		return (int) CreateDialogParam(g_hInstance, MAKEINTRESOURCE(naTemplateID), haParent, CDialogBase_WindowProc, (LPARAM) this);
}

void CDialogBase::DoModal()
{
	MSG msg;

	// Pas vraiment modale, mais bon...
    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!IsDialogMessage(m_hWnd, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }  
}

HWND CDialogBase::GetHandle()
{
	return m_hWnd;
}

HWND CDialogBase::GetDlgItem(int niItemID)
{
	return ::GetDlgItem(m_hWnd, niItemID);
}

HWND CDialogBase::CreateTooltip(HWND hwnd, const char *szaTipText)
{
    TOOLINFO ti;
    unsigned int uid = 0;       // for ti initialization
    RECT rect;                  // for client area coordinates
	
    /* CREATE A TOOLTIP WINDOW */
    HWND hwndTT = CreateWindowEx(WS_EX_TOPMOST, TOOLTIPS_CLASS,
        NULL, WS_POPUP | TTS_NOPREFIX | TTS_ALWAYSTIP,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        hwnd, NULL, g_hInstance, NULL);

    SetWindowPos(hwndTT, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);
	ShowWindow(hwndTT, SW_SHOW);

    /* GET COORDINATES OF THE MAIN CLIENT AREA */
    GetClientRect (hwnd, &rect);
	
    /* INITIALIZE MEMBERS OF THE TOOLINFO STRUCTURE */
    ti.cbSize = sizeof(TOOLINFO);
    ti.uFlags = TTF_SUBCLASS;
    ti.hwnd = hwnd;
    ti.hinst = g_hInstance;
    ti.uId = uid;
    ti.lpszText = (char *) szaTipText;
        // Tooltip control will cover the whole window
    ti.rect.left = rect.left;    
    ti.rect.top = rect.top;
    ti.rect.right = rect.right;
    ti.rect.bottom = rect.bottom;
    
    LRESULT lRes = SendMessage(hwndTT, TTM_ADDTOOL, 0, (LPARAM) (LPTOOLINFO) &ti);

	return hwndTT;
} 


// Méthodes protected
int CDialogBase::WindowProc(UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
	case WM_COMMAND: return !OnCommand(wParam, lParam);
	}
	return FALSE; 	
}

// Méthodes privées
bool CDialogBase::InitDialog(HWND haWnd)
{
	m_hWnd = haWnd;
	SetWindowLong(m_hWnd, GWL_USERDATA, (LONG) this);

	return (OnInitDialog() ? true : false);
}
