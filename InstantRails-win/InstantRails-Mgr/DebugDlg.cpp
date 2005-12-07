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

// DebugDlg.cpp: implementation of the CDebugDlg class.
//
//////////////////////////////////////////////////////////////////////

#include "DebugDlg.h"

#include <stdio.h>

#include "EasyPHP.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

int DebugThread(HWND haWnd)
{
	SOCKET listen_socket, msgsock;
	int socket_type=SOCK_STREAM, retval;
	char szLogBuffer[256] = {0}, *pcaNL;

	char szWindowsPath[MAX_PATH], m_sPhpIni[MAX_PATH];
	GetWindowsDirectory(szWindowsPath, MAX_PATH);

	_snprintf(m_sPhpIni, MAX_PATH-1, "%s\\php.ini", szWindowsPath);
	int m_uiDebuggerPort = GetPrivateProfileInt("debugger", "debugger.port", 7869, m_sPhpIni);

	if ((listen_socket = socket(AF_INET, socket_type, 0)) != INVALID_SOCKET )
	{
		struct sockaddr_in local, from;
		int fromlen;
		char szBuffer[255];

		local.sin_family = AF_INET;
		local.sin_addr.s_addr = INADDR_ANY; 

		/* 
		 * Port MUST be in Network Byte Order
		 */
		local.sin_port = htons(m_uiDebuggerPort);

		if (bind(listen_socket,(struct sockaddr*)&local,sizeof(local) ) == SOCKET_ERROR)
		{
			int niError = WSAGetLastError();
			fprintf(stderr,"bind() failed with error %d\n", niError);
			return -1;
		}

		if (socket_type != SOCK_DGRAM)
		{
			if (listen(listen_socket,5) == SOCKET_ERROR) 
			{
				DWORD lastError = WSAGetLastError();
				fprintf(stderr,"listen() failed with error %d\n",lastError);
				return -1;
			}
		}

		while (1)
		{
			fromlen =sizeof(from);
			//
			// accept() doesn't make sense on UDP, since we do not listen()
			//
			if (socket_type != SOCK_DGRAM) {
				msgsock = accept(listen_socket,(struct sockaddr*)&from, &fromlen);
				if (msgsock == INVALID_SOCKET) {
					fprintf(stderr,"accept() error %d\n",WSAGetLastError());
					WSACleanup();
					return -1;
				}
				_snprintf(szLogBuffer, sizeof(szLogBuffer)-1, "Connexion acceptée de %s, port %d", 
							inet_ntoa(from.sin_addr),
							htons(from.sin_port)) ;
				SendMessage(haWnd, WM_LOG, 0, (LPARAM) szLogBuffer);
				szLogBuffer[0] = '\0';
			}
			else
				msgsock = listen_socket;

			while(msgsock)
			{
			//
			// In the case of SOCK_STREAM, the server can do recv() and 
			// send() on the accepted socket and then close it.

			// However, for SOCK_DGRAM (UDP), the server will do
			// recvfrom() and sendto()  in a loop.

			memset(szBuffer, 0, sizeof(szBuffer));

			if (socket_type != SOCK_DGRAM)
				retval = recv(msgsock,szBuffer,sizeof(szBuffer),0 );
			else {
				retval = recvfrom(msgsock,szBuffer,sizeof(szBuffer),0,
					(struct sockaddr *)&from,&fromlen);
				printf("Received datagram from %s\n",inet_ntoa(from.sin_addr));
			}
				
			if (retval == SOCKET_ERROR) {
				closesocket(msgsock);
				msgsock = 0;
				fprintf(stderr,"recv() failed: error %d\n",WSAGetLastError());
				break;
			}
			if (retval == 0) {
				closesocket(msgsock);
				msgsock = 0;
				printf("Client closed connection\n");
				break;
			}
			/*printf("Received %d bytes, data [%s] from client\n",retval,Buffer);*/

			_snprintf(szLogBuffer, sizeof(szLogBuffer)-1, "%s%s", szLogBuffer, szBuffer);
			if ((pcaNL = strchr(szLogBuffer, '\r')) != NULL)
			{
				*pcaNL = '\0';
				SendMessage(haWnd, WM_LOG, 0, (LPARAM) szLogBuffer);
				szLogBuffer[0] = '\0';
			}
			//need to send ack here to match php debugger
			if (socket_type != SOCK_DGRAM)
				retval = send(msgsock,"ack",3,0);
			else
				retval = sendto(msgsock,"ack",3,0,
					(struct sockaddr *)&from,fromlen);
			if (retval == SOCKET_ERROR) {
				fprintf(stderr,"send() failed: error %d\n",WSAGetLastError());
			}
	
			continue;
			} //end receive loop

			if (socket_type != SOCK_DGRAM && msgsock){
				printf("Terminating connection\n\n");
				closesocket(msgsock);
			}
		}
	}
	else 
	{
		int error = WSAGetLastError();
		int niI = error;
	}


	return 0;
}
