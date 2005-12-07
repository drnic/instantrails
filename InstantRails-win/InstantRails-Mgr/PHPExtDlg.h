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

#pragma once

#include "resource.h"
#include "EasyPHPDialogBase.h"

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpAboutDlg dialog

class CPHPExtDlg : public CEasyPHPDialogBase
{
// Construction
public:
	CPHPExtDlg(HWND haParent, const char* szaPHPIniPath);
	~CPHPExtDlg();

// Implementation
	virtual bool	OnInitDialog();

protected:
	virtual int		WindowProc(UINT message, WPARAM wParam, LPARAM lParam);
	virtual bool	OnCommand(WPARAM waCommand);
	void			OnNotify(HWND haWnd, WPARAM waParam, LPNMHDR paNMHDR);

	void			Refresh();
	int				GetCheckedItemCount();
	bool			OnRailsPreCommand(WPARAM waCommand);
	void			OnRailsCommand(WPARAM waCommand, LPSTR szAppName, bool firstApp);

private:
	void			DeleteAll();

	enum { IDD_TEMPLATE = IDD_PHPEXT };
	char	m_szPHPIniPath[MAX_PATH+1];
	bool	m_bIsChanged;
	bool	m_bIsInit;
};