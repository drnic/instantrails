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

class CEasyPhpAboutDlg : public CEasyPHPDialogBase
{
// Construction
public:
	CEasyPhpAboutDlg(HWND paParent = NULL);
	~CEasyPhpAboutDlg();

// Implementation
	virtual int WindowProc(UINT message, WPARAM waParam, LPARAM laParam);
	virtual bool OnInitDialog();

protected:
	virtual bool OnCommand(WPARAM waCommand);

private:
	enum { IDD_TEMPLATE = IDD_ABOUT };
	HFONT	m_hFont;
	HFONT	m_hFontTitle;
	HFONT	m_hFontLink;
};
