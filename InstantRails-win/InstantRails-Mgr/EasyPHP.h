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

#include "resource.h"

#define INSTANT_RAILS_VERSION "1.1"

#define WM_EASYPHP				WM_USER+1
#define WM_LOG					WM_USER+2
#define WM_GETAPACHESTATE		WM_USER+5
#define WM_GETMYSQLSTATE		WM_USER+6

struct stCommande
{
	const char*	m_szOption;
	UINT		m_uiMsg;
	bool		m_bSet;
};

extern stCommande g_stCommandes[];
bool IsCmdlineOptionSet(const char *szaOption);
