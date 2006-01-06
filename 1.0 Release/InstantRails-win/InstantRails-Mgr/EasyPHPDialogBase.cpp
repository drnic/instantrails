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

#include <windows.h>
#include "EasyPHPDialogBase.h"

//////////////////////////////////////////////////////////////////////////////////////////
#pragma comment(lib, "Msimg32.lib")
#pragma comment(lib, "Delayimp.lib")

class CShadeRect
{
public:
	CShadeRect()
	{
		OSVERSIONINFO stOSI = {0};

		m_bSupported = false;
		stOSI.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);

		if (GetVersionEx(&stOSI))	// Tout sauf 95 et NT4
			m_bSupported = (stOSI.dwMajorVersion!= 4 || stOSI.dwMinorVersion != 0);
		// m_bSupported = false;
	}

	bool IsSupported()	{ return m_bSupported; };

	void ShadeRect(HDC hdc, COLORREF colLeftTop, COLORREF colRightBottom, const RECT& rc)
	{
		if (IsSupported())
		{
			TRIVERTEX       vert[2] = {0};
			GRADIENT_RECT   gRect;

			vert[0].x       = rc.left;
			vert[0].y       = rc.top;
			vert[0].Red     = GetRValue(colLeftTop) << 8;
			vert[0].Green   = GetGValue(colLeftTop) << 8;
			vert[0].Blue    = GetBValue(colLeftTop) << 8;
			vert[0].Alpha   = 0x0000;
    
			vert[1].x       = rc.right;
			vert[1].y       = rc.bottom; 
			vert[1].Red     = GetRValue(colRightBottom) << 8;
			vert[1].Green   = GetGValue(colRightBottom) << 8;
			vert[1].Blue    = GetBValue(colRightBottom) << 8;
			vert[1].Alpha   = 0x0000;
    
			gRect.UpperLeft  = 0;
			gRect.LowerRight = 1;
    
			GradientFill(hdc, vert, 2, &gRect, 1, GRADIENT_FILL_RECT_V);
		}
	}

private:
	bool	m_bSupported;
};

CShadeRect g_cShadeRect;

int CEasyPHPDialogBase::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	switch (message)
	{
	case WM_SYSCOMMAND:
		{
			switch (waParam)
			{
			case SC_CLOSE: EndDialog(GetHandle(), 0); break;
			}
		}
		break;

	case WM_ERASEBKGND:
		{
			if (g_cShadeRect.IsSupported())
			{
				RECT rc;

				GetClientRect(GetHandle(), &rc);
//				g_cShadeRect.ShadeRect((HDC) waParam, RGB(150,173,218), RGB(255,255,255), rc);
//				g_cShadeRect.ShadeRect((HDC) waParam, RGB(204,0,0), RGB(255,255,255), rc);
//				g_cShadeRect.ShadeRect((HDC) waParam, RGB(204,51,51), RGB(255,255,255), rc);
//				g_cShadeRect.ShadeRect((HDC) waParam, RGB(204,102,102), RGB(255,255,255), rc);
				g_cShadeRect.ShadeRect((HDC) waParam, RGB(255,153,153), RGB(255,255,255), rc);
				return TRUE;
			}
		}
		break;

	case WM_CTLCOLORBTN:
//	case WM_CTLCOLORLISTBOX:	// Fout la merde si il y a des scrolls...
	case WM_CTLCOLORSTATIC:
		if (g_cShadeRect.IsSupported())
		{
			int niRet = SetBkMode((HDC) waParam, TRANSPARENT);
			return (BOOL)GetStockObject(HOLLOW_BRUSH);
		}
	}

	return 0;
}

// 5.00
#ifndef PM_QS_PAINT
#define PM_QS_PAINT         (QS_PAINT << 16)
#endif

void CEasyPHPDialogBase::SetTextRefresh(int idk, const char*szaText)
{
	HWND hwndText = GetDlgItem(idk);

	SetWindowText(hwndText, szaText);

	if (g_cShadeRect.IsSupported())
	{
		InvalidateRect(GetParent(hwndText), NULL, TRUE);

		MSG msg;
		HWND hiWnd = GetHandle();
		while (::PeekMessage(&msg, hiWnd, 0, 0, PM_REMOVE | PM_QS_PAINT))
			DispatchMessage(&msg);

		UpdateWindow(hwndText);
	}
}