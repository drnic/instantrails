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

#define NB_MAX_LANGUE	30

class CLangue
{
public:
	CLangue();

	static bool				SetLanguageFile(const char *szaLangFilePath);
	static const char *		LoadString(UINT naID);
	static unsigned char	GetCurrentLang();
	static bool				SetCurrentLang(unsigned char naNewCurrentLang);
	static bool				SetCurrentLang(const char *szaNewCurrentLang);
	static unsigned char	GetLangCount();
	static const char *		GetLang(unsigned char naLangIndex);
	static const char *		GuessPreferedLanguage();

private:
	static unsigned char	m_uiCurrentLangIndex;
	static char				m_szCurrentLang[50];
	static char				m_szLangFilePath[MAX_PATH];
	static char				m_szLangs[NB_MAX_LANGUE][50];
	static int				m_nbInstances;
};