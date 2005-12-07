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

// Apache.h: interface for the CApache class.
//
//////////////////////////////////////////////////////////////////////

#pragma once

#include "ServerBase.h"
#include "Redirect.h"

class CApache : public ServerBase, public CRedirect
{
public:
	CApache();

	// Fonctions communes
	DWORD				Restart();
	DWORD				InstallService();
	DWORD				RemoveService();
	// Fin fonctions communes

	const char *		GetDocumentRootPath();

	bool				GetSSLMode();
	bool				SetSSLMode(bool baNewSSLMode);

	bool				VerifyConfFile();

private:
	// Fonctions communes
	DWORD 				StartExe();
	DWORD 				StopExe();
	virtual int			ReadConfFile();
	// Fin fonctions communes

	// Variables Apache
	char				m_sServerRootPath[MAX_PATH];
	char				m_sDocumentRootPath[MAX_PATH];
	bool				m_bModeSSL;
};
