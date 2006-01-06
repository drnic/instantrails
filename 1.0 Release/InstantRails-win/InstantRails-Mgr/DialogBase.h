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

// DialogBase.h: interface for the CDialogBase class.
//
// - Deriver la boite de dialogue de CDialogBase
// - Surcharger (au besoin) la WindowProc et OnInitDialog
// - Appeller Create(UINT naTemplateID, HWND haParent) dans le constructeur

//////////////////////////////////////////////////////////////////////

#pragma once

#include <windows.h>

class CDialogBase  
{
public:
	CDialogBase();
	~CDialogBase();

	int			Create(UINT naTemplateID, HWND haParent, bool baModal = false);
	void		DoModal();
	HWND		GetHandle();
	HWND		GetDlgItem(int niItemID);
	HWND		CreateTooltip(HWND hwnd, const char *szaTipText);

protected:
	// Fonction virtuelles a surcharger...
	virtual int WindowProc(UINT message, WPARAM wParam, LPARAM lParam);
	virtual bool OnInitDialog()									{ return true; };
	virtual bool OnCommand(WPARAM waCommand, LPARAM laParam)	{ return true; };

protected:
private:
	HWND	m_hWnd;

	// WindowProc commune a toutes les instances de CDialogBase
	friend int WINAPI CDialogBase_WindowProc(HWND haWnd, UINT message, WPARAM wParam, LPARAM lParam);
	bool InitDialog(HWND haWnd);
};
