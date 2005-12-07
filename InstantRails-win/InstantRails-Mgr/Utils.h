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

#include <time.h>
#include <Winsvc.h>

#include <Tlhelp32.h>	// Process32First/Next

// Dynamique car ces fonctions ne sont pas présentes sous NT
typedef HANDLE (WINAPI* CREATETOOLHELP32SNAPSHOT)(DWORD, DWORD);
typedef BOOL   (WINAPI* PROCESS32FIRST)(HANDLE, LPPROCESSENTRY32);
typedef BOOL   (WINAPI* PROCESS32NEXT)(HANDLE, LPPROCESSENTRY32);
typedef DWORD  (WINAPI* GETLONGPATHNAME)(LPCTSTR, LPTSTR, DWORD);

class CUtils
{
public:
	CUtils();
	~CUtils();

	// services
	static SC_HANDLE CreateThisService(const char *szaServiceName, const char *szaPath);
	static BOOL RemoveThisService(const char *szId);

	static SC_HANDLE GetThisService(const char *szaServiceName);
	static DWORD StartThisService(SC_HANDLE phService);
	static DWORD StopThisService(SC_HANDLE phService);

	// divers
	static bool IsWindowsNTPlatform();
	static bool IsWindowsNT();
	static bool IsWindowsXP();
	static bool UserIsAdmin();
	static bool GetModifiedTime(const char *szaFilePath, FILETIME *aTime);
	
	static bool ScanProcess(const char *pcaSearch, DWORD &dwaProcID, char *pcaPath = NULL);
	static bool ScanProcessByProcId(DWORD dwaProcID, char *pcaPath);
	static bool GetProcessTitle(DWORD dwaProcID, char *szaTitle, unsigned int naSize);
	static bool GetErrorMessage(DWORD dwaError, char **pszErrorMessage);

	static const char *GetEasyPhpPath();
	static void ConvertToUnixPath(char *szaPath);
//	static bool GetFileVersion(const char *szaFilePath, unsigned char szaVersionBuffer[4]);
//	static bool GetFileVersion(const char *szaFilePath, char *szaVersionBuffer);
//	static bool GetProductVersion(const char *szaFilePath, unsigned char szaVersionBuffer[4]);
//	static bool CheckVersion(const char *szaFileName, char pcaVersionBuff[50], char *pcaInfoSupp = NULL, int naInfoSuppLength = 0);
	static bool IsPortUsed(unsigned int naPortNumber);
	static bool IsPortUsedByProcess(unsigned int naPortNumber, DWORD &dwaProcID, bool &baPortUsed);
	static DWORD AdjustPrivileges();

	// szaURL [in] file to download
	// pcaFileName [out] temporary file downloaded
	static DWORD DownloadFile(const char*szaURL, char *pcaFileName, HWND haWinNotify, bool baAcceptRedirect=true);
	static UINT	 GetDownloadNotifyMsg();

	static bool IsFixedDrive();
	static DWORD GetLongPathName(LPCTSTR szaShort, LPTSTR szaLong, DWORD ccaBufferSize);

	static const char*CSVGetField(const char *pciCurrent, char **pciNext);

	static void Log(const char *, ...);

	static void ViewFile(const char *pcaPath);
	static void GotoURL(const char *szaURL);


private:
	static unsigned int					m_niInstanceCpt;

    static OSVERSIONINFOEX				m_stVersionInformation;

	// services
	static SC_HANDLE					m_hServiceManager;

	// Enumeration des processus en cours
	static HMODULE						m_hKernel32;
	static CREATETOOLHELP32SNAPSHOT		m_pfCreateToolhelp32Snapshot;
	static PROCESS32FIRST				m_pfProcess32First;
	static PROCESS32NEXT				m_pfProcess32Next;
	static GETLONGPATHNAME				m_pfGetLongPathName;
};

DWORD ListView_GetItemData(HWND hLVw, int nItem);
//#ifndef ListView_SetCheckState
//   #define ListView_SetCheckState(hwndLV, i, fCheck) \
//      ListView_SetItemState(hwndLV, i, \
//      INDEXTOSTATEIMAGEMASK((fCheck)+1), LVIS_STATEIMAGEMASK)
//#endif