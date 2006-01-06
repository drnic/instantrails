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
#include <stdio.h>
#include "Langue.h"

unsigned char CLangue::m_uiCurrentLangIndex = 0;
char CLangue::m_szCurrentLang[50] = {0};
char CLangue::m_szLangFilePath[MAX_PATH] = {0};
char CLangue::m_szLangs[NB_MAX_LANGUE][50];
int CLangue::m_nbInstances = 0;

CLangue g_Lang;

extern HINSTANCE g_hInstance;

CLangue::CLangue()
{
	if (m_nbInstances++ == 0)
		memset(m_szLangFilePath, 0, sizeof(m_szLangFilePath));
}

bool CLangue::SetLanguageFile(const char *szaLangFilePath)
{
	char szLangue[20] = {0};

	strncpy(m_szLangFilePath, szaLangFilePath, sizeof(m_szLangFilePath)-1);
	memset(m_szLangs, 0, sizeof(m_szLangs));

	for (unsigned int niI = 0; niI < NB_MAX_LANGUE; niI++)
	{
		_snprintf(szLangue, 19, "Langue%d", niI);
		GetPrivateProfileString("Liste", szLangue, "", m_szLangs[niI], 50, m_szLangFilePath);
	}

	return true;
}

const char *CLangue::LoadString(UINT naID)
{
	static char pcaStrings[8][2048] = {0};
	static int niIndex = 0;
	char szaID[15] = {0}, szaLabel[50] = {0};
	bool biFoundInLangFile = false;
	niIndex = (niIndex == 7 ? 0 : niIndex+1);
/*

	if (m_szLangFilePath[0] != '\0')
	{
		itoa(naID, szaID, 10);
		GetPrivateProfileString("IDs", szaID, "", szaLabel, sizeof(szaLabel)-1, m_szLangFilePath);
		if (szaLabel[0] != '\0')
		{
			GetPrivateProfileString(m_szCurrentLang, szaLabel, "", pcaStrings[niIndex], sizeof(pcaStrings[niIndex])-1, m_szLangFilePath);
			if (pcaStrings[niIndex][0] != '\0')
			{
				biFoundInLangFile = true;
				char *pciBackSlash = NULL;

				// Gestion de quelques caractères d'echappement
				pciBackSlash = pcaStrings[niIndex];
				while ((pciBackSlash = strchr(pciBackSlash, '\\')) != NULL)
				{
					switch (pciBackSlash[1])
					{
					case 'r':	pciBackSlash[0] = ' ';
								pciBackSlash[1] = 10;
								break;
					case 'n':	pciBackSlash[0] = ' ';
								pciBackSlash[1] = 13;
								break;
					case 't':	pciBackSlash[0] = ' ';
								pciBackSlash[1] = 9;
								break;
					}
					pciBackSlash++;
				}
			}
		}
	}
*/	
	if (biFoundInLangFile == false)
	{
		// ressources
		::LoadString(g_hInstance, naID, pcaStrings[niIndex], sizeof(pcaStrings[niIndex])-1);
	}

	return pcaStrings[niIndex];
}

unsigned char CLangue::GetCurrentLang()
{
	return m_uiCurrentLangIndex;
}

bool CLangue::SetCurrentLang(unsigned char naNewCurrentLang)
{
	if (naNewCurrentLang < NB_MAX_LANGUE)
		if (m_szLangs[naNewCurrentLang][0]!='\0')
		{
			m_uiCurrentLangIndex = naNewCurrentLang;
			strncpy(m_szCurrentLang, m_szLangs[naNewCurrentLang], sizeof(m_szCurrentLang)-1);
			return true;
		}

	return false;
}

bool CLangue::SetCurrentLang(const char *szaNewCurrentLang)
{
	for (unsigned char niI = 0; m_szLangs[niI][0]!='\0' && niI<NB_MAX_LANGUE; niI++)
	{
		if (strcmp(m_szLangs[niI], szaNewCurrentLang) == ERROR_SUCCESS)
			return SetCurrentLang(niI);
	}

	return true;
}

unsigned char CLangue::GetLangCount()
{
	for (unsigned char niI = 0; m_szLangs[niI][0]!='\0' && niI<NB_MAX_LANGUE; niI++);
	return niI;
}

const char *CLangue::GetLang(unsigned char naLangIndex)
{
	return (naLangIndex < NB_MAX_LANGUE ? m_szLangs[naLangIndex] : "");
}

const char *CLangue::GuessPreferedLanguage()
{
	LANGID defLangID = GetUserDefaultLangID();

	switch (PRIMARYLANGID(defLangID))
	{
	case LANG_ALBANIAN: 	return "Albanian";
	case LANG_ARABIC:		return "Arabic";
    case LANG_CHINESE:		return "Chinese";
	case LANG_CZECH: 		return "Czech";
	case LANG_GERMAN: 		return "Deutch";
	case LANG_ENGLISH:		return "English";
	case LANG_FRENCH:		return "Français";
	case LANG_INDONESIAN:	return "Indonesian";
	case LANG_ITALIAN:		return "Italiano";
	case LANG_JAPANESE:		return "Japanese";
	case LANG_LITHUANIAN:	return "Lietuvio";
	case LANG_HUNGARIAN:	return "Magyar";
	case LANG_DUTCH:		return "Nederlands";
	case LANG_NORWEGIAN:	return "Norsk";
	case LANG_POLISH:		return "Polish";
	case LANG_PORTUGUESE:	return "Portugues";
	case LANG_RUSSIAN:		return "Russian";
	case LANG_SPANISH: 		return "Spanish";
	case LANG_SWEDISH:		return "Svenska";
	case LANG_TURKISH: 		return "Turkish";

	default:	return "English";
	}
}