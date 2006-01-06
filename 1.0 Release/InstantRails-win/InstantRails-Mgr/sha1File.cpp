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

// ServerBase.cpp: implementation of the ServerBase class.
//
//////////////////////////////////////////////////////////////////////

#include "sha1File.h"
#include <stdio.h>

DWORD SHA1File(const char*szaFilePath, uint8_t Message_Digest[SHA1HashSize])
{
	int niReturn = 1;
	FILE *piFile = fopen(szaFilePath, "rb");

	if (piFile != NULL)
	{
		SHA1Context sha;

		niReturn = SHA1Reset(&sha);
		if (niReturn == ERROR_SUCCESS)
		{
			char szBuffer[1024] = {0};
			size_t niSize = 0;

			while (niReturn==ERROR_SUCCESS && (niSize = fread(szBuffer, 1, sizeof(szBuffer), piFile)) != 0)
				niReturn = SHA1Input(&sha, (const unsigned char *) szBuffer, niSize);

			if (niReturn == ERROR_SUCCESS)
				niReturn = SHA1Result(&sha, Message_Digest);
		}

		fclose(piFile);
	}

    return niReturn;
}

unsigned char charFromNib(unsigned char ucNib)
{
	return (ucNib>9 ? 'a'+ucNib- 10 : '0'+ucNib);
}

void HashByteToASCII(const unsigned char *pciByteHash,  char *szaASCIIHash)
{
	for (unsigned int niI = 0; niI < SHA1HashSize; niI++)
	{
		szaASCIIHash[niI*2] = charFromNib(pciByteHash[niI] >> 4);
		szaASCIIHash[niI*2+1] = charFromNib(pciByteHash[niI] & 0x0F);
	}
}

