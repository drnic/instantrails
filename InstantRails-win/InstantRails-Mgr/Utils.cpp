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
#include <wininet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <stdio.h>
#include <commctrl.h>

#include <Tlhelp32.h>	// Process32First/Next

#include "utils.h"
#include "EasyPHP.h"
#include "Langue.h"

#define BROWSER_AGENT_NAME		TEXT("EasyPHP Manager")

// Variables statiques
// Enumeration des processus en cours
unsigned int				CUtils::m_niInstanceCpt = 0;
SC_HANDLE					CUtils::m_hServiceManager = NULL;
OSVERSIONINFOEX				CUtils::m_stVersionInformation = {0};

HMODULE						CUtils::m_hKernel32 = NULL;
CREATETOOLHELP32SNAPSHOT	CUtils::m_pfCreateToolhelp32Snapshot = NULL;
PROCESS32FIRST				CUtils::m_pfProcess32First = NULL;
PROCESS32NEXT				CUtils::m_pfProcess32Next = NULL;
GETLONGPATHNAME				CUtils::m_pfGetLongPathName = NULL;

CUtils MonInstanceAMoi;

typedef struct stGetProcessTitle
{
	DWORD dwProcID;
	char szTitle[MAX_PATH];
} STGETPROCESSTITLE, *PSTGETPROCESSTITLE;

BOOL CALLBACK GetProcessTitleCallback(HWND hwnd, LPARAM lParam);


CUtils::CUtils()
{
	if (m_niInstanceCpt++ == 0) // premiere instance
	{
		if (!UserIsAdmin())
			CUtils::AdjustPrivileges();

		m_hServiceManager = OpenSCManager(NULL, NULL, UserIsAdmin() ? SC_MANAGER_ALL_ACCESS : SC_MANAGER_CONNECT);

		BOOL bOkVersion;

		memset(&m_stVersionInformation, 0, sizeof(OSVERSIONINFOEX));
		m_stVersionInformation.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
		if ((bOkVersion = GetVersionEx((OSVERSIONINFO *)&m_stVersionInformation)) == FALSE)
		{
			m_stVersionInformation.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
			bOkVersion = GetVersionEx((OSVERSIONINFO *)&m_stVersionInformation);
		}
		Log("Windows Version: %s %d.%d", m_stVersionInformation.dwPlatformId == VER_PLATFORM_WIN32_NT ? "NT" : "9X",
			m_stVersionInformation.dwMajorVersion, m_stVersionInformation.dwMinorVersion);

		m_hKernel32 = LoadLibrary("Kernel32.DLL");
		if (m_hKernel32)
		{
			m_pfCreateToolhelp32Snapshot = (CREATETOOLHELP32SNAPSHOT) ::GetProcAddress(m_hKernel32, "CreateToolhelp32Snapshot");
			m_pfProcess32First = (PROCESS32FIRST) ::GetProcAddress(m_hKernel32, "Process32First");
			m_pfProcess32Next = (PROCESS32NEXT) ::GetProcAddress(m_hKernel32, "Process32Next");
			// GetLongPathName pas present sur NT, alors qu'on en a pas besoin pour les NT.
			m_pfGetLongPathName = (GETLONGPATHNAME) ::GetProcAddress(m_hKernel32, "GetLongPathNameA");
		}
	}
}

CUtils::~CUtils()
{
	if (--m_niInstanceCpt == 0)
	{
        if (m_hServiceManager)
			CloseServiceHandle(m_hServiceManager);

		if (m_hKernel32)
			FreeLibrary(m_hKernel32);
		m_hKernel32 = NULL;
		m_pfCreateToolhelp32Snapshot = NULL;
		m_pfProcess32First = NULL;
		m_pfProcess32Next = NULL;
		m_pfGetLongPathName = NULL;
	}
}

SC_HANDLE CUtils::CreateThisService(const char *szaServiceName, const char *szaPath)
{
    SC_HANDLE scHandle = NULL;

    if (m_hServiceManager)
    {
		scHandle = CreateService(m_hServiceManager, szaServiceName, szaServiceName,
					SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS|
					SERVICE_INTERACTIVE_PROCESS, SERVICE_AUTO_START,
					SERVICE_ERROR_NORMAL, szaPath, NULL, NULL, NULL,
                    NULL, NULL);
    }

	return scHandle;
}

BOOL CUtils::RemoveThisService(const char *szId)
{
	SC_HANDLE scHandle;
    BOOL biRet = FALSE;

	if (m_hServiceManager)
	{
		if (scHandle = OpenService(m_hServiceManager, szId, DELETE))
		{
			DeleteService(scHandle);
			CloseServiceHandle(scHandle);
			biRet = TRUE;
		}
	}

    return biRet;
}

SC_HANDLE CUtils::GetThisService(const char *szaServiceName)
{
	return (m_hServiceManager ? OpenService(m_hServiceManager, szaServiceName, UserIsAdmin() ? SERVICE_ALL_ACCESS : SERVICE_QUERY_STATUS) : NULL);
}

DWORD CUtils::StartThisService(SC_HANDLE phService)
{
    DWORD dwRetour = ERROR_SUCCESS;

    if (phService)
    {
        if (StartService(phService, 0, NULL) == FALSE)
		{
			dwRetour = GetLastError();

			// On ignore si l'erreur est "le service est deja lance"				
			if (dwRetour == ERROR_SERVICE_ALREADY_RUNNING)
				dwRetour = ERROR_SUCCESS;
		}
    }
	else dwRetour = ERROR_ACCESS_DENIED;

    return dwRetour;
}

DWORD CUtils::StopThisService(SC_HANDLE phService)
{
    DWORD dwRetour = ERROR_SUCCESS;

    if (phService)
    {
		SERVICE_STATUS stServiceStatus;

		stServiceStatus.dwWaitHint = 0;
        if (ControlService(phService, SERVICE_CONTROL_STOP, &stServiceStatus) == FALSE)
		{
			dwRetour = GetLastError();
			// On ignore si l'erreur est "le service n'est pas lance"				
			if (dwRetour == ERROR_SERVICE_NOT_ACTIVE)
				dwRetour = ERROR_SUCCESS;
		}
    }
    return dwRetour;
}

bool CUtils::IsWindowsNTPlatform()
{
	return !(GetVersion() & 0x80000000);
}

bool CUtils::IsWindowsNT()
{
	return (m_stVersionInformation.dwPlatformId == VER_PLATFORM_WIN32_NT &&
				m_stVersionInformation.dwMajorVersion == 4);
}

bool CUtils::IsWindowsXP()
{
	return (m_stVersionInformation.dwPlatformId == VER_PLATFORM_WIN32_NT &&
				m_stVersionInformation.dwMajorVersion == 5 && 
				m_stVersionInformation.dwMinorVersion == 1);
}

bool CUtils::UserIsAdmin()
{
    static bool bAdmin = FALSE, bAdminChecked = FALSE;

	if (!bAdminChecked)
	{
		if (CUtils::IsWindowsNTPlatform() == false)
			bAdmin = true;
		else
		{
			HANDLE hThread = NULL;
			TOKEN_GROUPS *ptg = NULL;
			DWORD cbTokenGroups;
			PSID psidAdmin;
			SID_IDENTIFIER_AUTHORITY SystemSidAuthority = SECURITY_NT_AUTHORITY;

			// Try to open the threads token...
			if (!OpenThreadToken(GetCurrentThread(), TOKEN_QUERY, FALSE, &hThread))
			{
				if (GetLastError() == ERROR_NO_TOKEN)
				{
					// ...if the thread doesn't have a token, then we open the process's token
					if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hThread))
							hThread = NULL;
				}
				else hThread = NULL;
			}

			// Handle sur le token valide
			if (hThread != NULL)
			{
				// Get the size of data waiting for us.
				if (GetTokenInformation(hThread, TokenGroups, NULL, 0, &cbTokenGroups) ||
								GetLastError() == ERROR_INSUFFICIENT_BUFFER)
				{
					if ((ptg = (TOKEN_GROUPS*)malloc(cbTokenGroups)) != NULL) 
					{
						if (GetTokenInformation(hThread, TokenGroups, ptg, cbTokenGroups, &cbTokenGroups))
						{
							// Maintenant nous avons Créer un Indentifiand appartenanant aux groupe ADMIN
							if (AllocateAndInitializeSid(&SystemSidAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &psidAdmin))
							{
								for (DWORD dwGroup= 0; dwGroup < ptg->GroupCount; dwGroup++)
								{
									if (EqualSid(ptg->Groups[dwGroup].Sid, psidAdmin))
									{
										bAdmin = TRUE;
										break;
									}
								}
								// Avant de sortir déallocation du SID créé ...
								FreeSid (psidAdmin);
							}
						}
						free(ptg);
					}
				}
				// Fermeture du handle ouvert par OpenThreadToken ou OpenProcessToken
				CloseHandle(hThread);
			}
		}
		bAdminChecked = TRUE;
	}
    return(bAdmin);
}

bool CUtils::GetModifiedTime(const char *szaFilePath, FILETIME *aTime)
{
	HANDLE hiFile;
	bool biRetour = false;

	if (aTime)
	{
		hiFile = CreateFile(szaFilePath, 0, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
		memset(aTime, 0, sizeof(FILETIME));

		if (hiFile)
		{
			if (!::GetFileTime((HANDLE)hiFile, NULL, NULL, aTime))
					memset((void *) aTime, 0, sizeof(FILETIME));
			else biRetour = true;
			CloseHandle(hiFile);
		}
	}
	return biRetour;
}

// Cherche les processus "pcaSearch" en cours...
// Renvoi le path et le ProcID du premier "pcaSearch" si trouvé.
bool CUtils::ScanProcess(const char *pcaSearch, DWORD &dwaProcID, char *pcaPath)
{
	bool biTrouve = false;
	if (m_pfCreateToolhelp32Snapshot && m_pfProcess32First && m_pfProcess32Next 
			&& pcaSearch && pcaSearch[0])
	{
		HANDLE hiTH = m_pfCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
		if (hiTH)
		{
			PROCESSENTRY32 stProcessEntry32;
			stProcessEntry32.dwSize = sizeof(PROCESSENTRY32);
			if (m_pfProcess32First(hiTH, &stProcessEntry32))
			{
				char szSearch[MAX_PATH+1] = {0}, *pciExeName = szSearch;

				strncpy(szSearch, pcaSearch, sizeof(szSearch)-1);
				if (IsWindowsNTPlatform())	// NT : stProcessEntry32.szExeFile contain short nalme
				{
					pciExeName = strrchr(szSearch, '\\');	// On ne prends que la fin
					if (pciExeName)
						pciExeName++;
					else pciExeName = szSearch;
				}
				else CUtils::GetLongPathName(szSearch, szSearch, sizeof(szSearch));

				strupr(pciExeName);
//				Log("Search \"%s\"", pciExeName);
				do
				{
//					Log("ScanProcess %s", stProcessEntry32.szExeFile);
					if (strcmp(strupr(stProcessEntry32.szExeFile), pciExeName) == ERROR_SUCCESS)
					{
						if (pcaPath != NULL)
							strncpy(pcaPath, stProcessEntry32.szExeFile, MAX_PATH);
						dwaProcID = stProcessEntry32.th32ProcessID;
						biTrouve = true;
					}
				}
				while (!biTrouve && m_pfProcess32Next(hiTH, &stProcessEntry32));
			}
			CloseHandle(hiTH);
		}
	}
	else
		Log("ScanProcess error. %p %p %p", m_pfCreateToolhelp32Snapshot, m_pfProcess32First, m_pfProcess32Next);

	return biTrouve;
}

bool CUtils::ScanProcessByProcId(DWORD dwaProcID, char *pcaPath)
{
	bool biTrouve = false;
	if (m_pfCreateToolhelp32Snapshot && m_pfProcess32First && m_pfProcess32Next)
	{
		HANDLE hiTH = m_pfCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
		if (hiTH)
		{
			PROCESSENTRY32 stProcessEntry32;
			stProcessEntry32.dwSize = sizeof(PROCESSENTRY32);
			if (m_pfProcess32First(hiTH, &stProcessEntry32))
			{
				do
				{
					if (stProcessEntry32.th32ProcessID == dwaProcID)
					{
						if (pcaPath != NULL)
							strncpy(pcaPath, stProcessEntry32.szExeFile, MAX_PATH);
						biTrouve = true;
					}
				}
				while (!biTrouve && m_pfProcess32Next(hiTH, &stProcessEntry32));
			}
			CloseHandle(hiTH);
		}
	}
	else
	{
		Log("ScanProcess error. %p %p %p", m_pfCreateToolhelp32Snapshot, m_pfProcess32First, m_pfProcess32Next);
	}

	return biTrouve;
}

bool CUtils::GetProcessTitle(DWORD dwaProcID, char *szaTitle, unsigned int naSize)
{
	STGETPROCESSTITLE stGPT = {0};

	stGPT.dwProcID = dwaProcID;
	EnumWindows(GetProcessTitleCallback, (LPARAM) &stGPT);

	if (stGPT.szTitle[0] != '\0')
	{
		strncpy(szaTitle, stGPT.szTitle, naSize);
		return true;
	}
	return false;
}

bool CUtils::GetErrorMessage(DWORD dwaError, char **pszErrorMessage)
{
	return (FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL, dwaError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) pszErrorMessage, 0, NULL) != 0);
}

const char *CUtils::GetEasyPhpPath()
{
    static char szEasyPhpPath[MAX_PATH] = {0};

    if (szEasyPhpPath[0] == '\0')
    {
        char szPath[MAX_PATH] = {0};

		GetModuleFileName(NULL, szPath, sizeof(szPath)-1);
		char *pciLastBackSlash = strrchr(szPath, '\\');
		if (pciLastBackSlash)
		{
			*(pciLastBackSlash+1) = '\0';
			GetShortPathName(szPath, szEasyPhpPath, sizeof(szEasyPhpPath)-1);
			CUtils::Log("Easy Path = \"%s\" (\"%s\")", szEasyPhpPath, szPath);
		}
    }

    return szEasyPhpPath;
}

void CUtils::ConvertToUnixPath(char *szaPath)
{
	for (unsigned int niI=0; szaPath[niI]!='\0'; niI++)
		if (szaPath[niI] == '\\')
			szaPath[niI] = '/';
}

//bool CUtils::GetFileVersion(const char *szaFilePath, char *szaVersionBuffer)
//{
//	DWORD dwiLength, niTemp;
//	void *pInfoData = NULL;
//	bool biRetour = FALSE;

//	strcpy(szaVersionBuffer, INSTANT_RAILS_VERSION);
/*
	memset(szaVersionBuffer, 0, 4);

	dwiLength = GetFileVersionInfoSize((char *) szaFilePath, &niTemp);
	if (dwiLength)
	{
		pInfoData = malloc(dwiLength);
		if (pInfoData)
		{
			if (GetFileVersionInfo((char *) szaFilePath, 0, dwiLength, pInfoData))
			{
				VS_FIXEDFILEINFO *lpVerInfo;
				UINT niLength;

				if (VerQueryValue(pInfoData, TEXT("\\"), (LPVOID*)&lpVerInfo, &niLength))
				{
					szaVersionBuffer[0] = (unsigned char) (lpVerInfo->dwFileVersionMS >> 16);
					szaVersionBuffer[1] = (unsigned char) (lpVerInfo->dwFileVersionMS & 0xFFFF);
					szaVersionBuffer[2] = (unsigned char) (lpVerInfo->dwFileVersionLS >> 16);
					szaVersionBuffer[3] = (unsigned char) (lpVerInfo->dwFileVersionLS & 0xFFFF);
					biRetour = TRUE;
				}
			}
			free(pInfoData);
		}
	}
	return biRetour;
	*/
//	return TRUE;
//}

/*
bool CUtils::GetProductVersion(const char *szaFilePath, unsigned char szaVersionBuffer[4])
{
	DWORD dwiLength, niTemp;
	void *pInfoData = NULL;
	bool biRetour = FALSE;

	memset(szaVersionBuffer, 0, 4);

	dwiLength = GetFileVersionInfoSize((char *) szaFilePath, &niTemp);
	if (dwiLength)
	{
		pInfoData = malloc(dwiLength);
		if (pInfoData)
		{
			if (GetFileVersionInfo((char *) szaFilePath, 0, dwiLength, pInfoData))
			{
				VS_FIXEDFILEINFO *lpVerInfo;
				UINT niLength;

				if (VerQueryValue(pInfoData, TEXT("\\"), (LPVOID*)&lpVerInfo, &niLength))
				{
					szaVersionBuffer[0] = (unsigned char) (lpVerInfo->dwProductVersionMS >> 16);
					szaVersionBuffer[1] = (unsigned char) (lpVerInfo->dwProductVersionMS & 0xFFFF);
					szaVersionBuffer[2] = (unsigned char) (lpVerInfo->dwProductVersionLS >> 16);
					szaVersionBuffer[3] = (unsigned char) (lpVerInfo->dwProductVersionLS & 0xFFFF);
					biRetour = TRUE;
				}
			}
			free(pInfoData);
		}
	}
	return biRetour;
}
*/

/*
bool CUtils::CheckVersion(const char *szaFileName, char pcaVersionBuff[50], char *pcaInfoSupp, int naInfoSuppLength)
{
	bool biRetour = false;
	HINTERNET hSession = NULL, hOpenUrlHandle = NULL;

	pcaVersionBuff[0] = '\0';
	if (hSession = InternetOpen(BROWSER_AGENT_NAME, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0))
	{
		unsigned char pciVersion[4] = {0};
		char szCheckVerURL[MAX_PATH] = {0};
		
		GetFileVersion(szaFileName, pciVersion);

		_snprintf(szCheckVerURL, sizeof(szCheckVerURL)-1, "http://www.easyphp.org/checkeasyphp.php3?v=%d.%d.%d.%d",
			pciVersion[0], pciVersion[1], pciVersion[2], pciVersion[3]);

		hOpenUrlHandle = InternetOpenUrl(hSession, szCheckVerURL, NULL, 0, INTERNET_FLAG_RELOAD | INTERNET_FLAG_RAW_DATA, 0);
		if (hOpenUrlHandle)
		{
			DWORD dwNbRead = 0;
			char szBuff[1024] = {0};

			if (InternetReadFile(hOpenUrlHandle, (LPVOID) szBuff, sizeof(szBuff), &dwNbRead))
			{
				szBuff[dwNbRead] = '\0';
				if (strstr(szBuff, "EasyPhpVersion"))
				{
					char szVerBuffer[50] = {0};
					if (sscanf(szBuff, "EasyPhpVersion=%s", szVerBuffer) != EOF)
					{
						strncpy(pcaVersionBuff, szVerBuffer, 49);
						biRetour = true;
						if (pcaInfoSupp)
						{
							char *pciReturn = strchr(szBuff, '\n');
							if (pciReturn)
								strncpy(pcaInfoSupp, pciReturn+1, naInfoSuppLength);
						}
					}
				} 
			}
			InternetCloseHandle(hOpenUrlHandle); 
		}

		InternetCloseHandle(hSession);
	}
	return biRetour;
}
*/

bool CUtils::IsPortUsed(unsigned int naPortNumber)
{
	bool biRetour = false;
	SOCKET m_socket = NULL;
	sockaddr_in sa1;

	m_socket = socket(AF_INET, SOCK_STREAM, 0);

	memset(&sa1, 0, sizeof(sockaddr_in));
	sa1.sin_family = AF_INET;
	sa1.sin_port = htons(naPortNumber);
	sa1.sin_addr.s_addr = inet_addr("127.0.0.1");

	if (connect(m_socket,(LPSOCKADDR) &sa1, sizeof(sa1)) == ERROR_SUCCESS)
		biRetour = true;

	closesocket(m_socket);

	return biRetour;
}

// IpHlpApi Non documented functions/structures
#include <iprtrmib.h>
typedef struct {
  DWORD   dwState;        // state of the connection
  DWORD   dwLocalAddr;    // address on local computer
  DWORD   dwLocalPort;    // port number on local computer
  DWORD   dwRemoteAddr;   // address on remote computer
  DWORD   dwRemotePort;   // port number on remote computer
  DWORD	  dwProcessId;
} MIB_TCPEXROW, *PMIB_TCPEXROW;

typedef struct {
	DWORD			dwNumEntries;
	MIB_TCPEXROW	table[ANY_SIZE];
} MIB_TCPEXTABLE, *PMIB_TCPEXTABLE;

typedef DWORD (WINAPI *PALLOCATEANDGETTCPEXTABLEFROMSTACK)(
  PMIB_TCPEXTABLE *pTcpTable,  // buffer for the connection table
  BOOL bOrder,               // sort the table?
  HANDLE heap,
  DWORD zero,
  DWORD flags
);

bool CUtils::IsPortUsedByProcess(unsigned int naPortNumber, DWORD &dwaProcID, bool &baPortUsed)
{
	bool biRetour = false;
	static PALLOCATEANDGETTCPEXTABLEFROMSTACK pAllocateAndGetTcpExTableFromStack = (PALLOCATEANDGETTCPEXTABLEFROMSTACK) GetProcAddress(LoadLibrary("iphlpapi.dll"), "AllocateAndGetTcpExTableFromStack");

	baPortUsed = false;

	if (pAllocateAndGetTcpExTableFromStack)
	{
		PMIB_TCPEXTABLE tcpExTable;

		if (pAllocateAndGetTcpExTableFromStack( &tcpExTable, TRUE, GetProcessHeap(), 2, 2 ) == ERROR_SUCCESS)
		{
			for(DWORD niI = 0; niI<tcpExTable->dwNumEntries && biRetour==false; niI++)
			{
				tcpExTable->table[niI].dwLocalPort = htons((u_short)tcpExTable->table[niI].dwLocalPort);
				if (tcpExTable->table[niI].dwLocalPort==naPortNumber && tcpExTable->table[niI].dwState==2) //2: LISTENNING
				{
					dwaProcID = tcpExTable->table[niI].dwProcessId;
					baPortUsed = true;
				}
			}
			biRetour = true;
		}
	}

	return biRetour;
}

DWORD CUtils::DownloadFile(const char*szaURL, char *pcaFileName, HWND haWinNotify, bool baAcceptRedirect)
{
	DWORD dwRetour = ERROR_SUCCESS;
	HINTERNET hInternetSession = NULL, hOpenRequest = NULL;

	// INTERNET_OPEN_TYPE_PRECONFIG : que ca marche aussi derriere un proxy
	if((hInternetSession = InternetOpen(BROWSER_AGENT_NAME, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL,0)) != NULL)
	{
		if ((hOpenRequest = InternetOpenUrl(hInternetSession, szaURL, NULL, 0, 
					INTERNET_FLAG_RAW_DATA | INTERNET_FLAG_RELOAD | (baAcceptRedirect ? 0 : INTERNET_FLAG_NO_AUTO_REDIRECT), 0)) != NULL)
		{
			char szStatusBuffer[1500] = {0};
			DWORD dwErrorIndex = 0, dwBuffLength = sizeof(szStatusBuffer);

			if (HttpQueryInfo(hOpenRequest, HTTP_QUERY_STATUS_CODE, szStatusBuffer, &dwBuffLength, &dwErrorIndex))
			{
				if (strcmp(szStatusBuffer, "200") == ERROR_SUCCESS)
				{
					char pciTempPath[MAX_PATH+1] = {0};
					FILE *piFile = NULL;

					GetTempPath(sizeof(pciTempPath)-1, pciTempPath);
					GetTempFileName(pciTempPath, "InstantRails", 0, pcaFileName);

					if ((piFile = fopen(pcaFileName, "wb")) != NULL)
					{
						char pciBuffer[20000] = {0};
						DWORD dwSizeToRead = 1, dwSizeRead, dwTotalRead = 0;

						while(dwSizeToRead != 0)
						{
							if(InternetQueryDataAvailable(hOpenRequest, &dwSizeToRead, 0, 0))
							{
								if(dwSizeToRead && InternetReadFile(hOpenRequest,(LPVOID)pciBuffer, sizeof(pciBuffer), &dwSizeRead))
								{
									fwrite(pciBuffer, dwSizeRead, 1, piFile);
									if (haWinNotify)
									{
										dwTotalRead += dwSizeRead;
										SendMessage(haWinNotify, GetDownloadNotifyMsg(), 0, dwTotalRead);
									}
								}
							}
						}

						fclose(piFile);
					}
					else dwRetour = ERROR_FILE_NOT_FOUND;
				}
				else dwRetour = atoi(szStatusBuffer);
			}
			else dwRetour = GetLastError();

			InternetCloseHandle(hOpenRequest);
		}
		else dwRetour = GetLastError();

		InternetCloseHandle(hInternetSession);
	}
	else dwRetour = GetLastError();

	return dwRetour;
}

UINT CUtils::GetDownloadNotifyMsg()
{
	static UINT MSG_DOWNLOAD_FILE_NOTIFY = ::RegisterWindowMessage("EasyManager_Download_Message");
	return MSG_DOWNLOAD_FILE_NOTIFY;
}

bool CUtils::IsFixedDrive()
{
	static bool biIsFixedDriveInit = false, 
		biIsFixedDrive = false;

	if (biIsFixedDriveInit == false)
	{
		char szDrive[MAX_PATH+1] = {0};

		GetModuleFileName(NULL, szDrive, sizeof(szDrive)-1);
		szDrive[3] = '\0';
		
		UINT uiType = GetDriveType(szDrive);
		biIsFixedDrive = (uiType == DRIVE_FIXED);

		biIsFixedDriveInit = true;
	}

	return biIsFixedDrive;
}


DWORD CUtils::GetLongPathName(LPCTSTR szaShort, LPTSTR szaLong, DWORD ccaBufferSize)
{
	typedef DWORD   (WINAPI* GETLONGPATHNAME)(LPCTSTR , LPCTSTR, DWORD);
    static GETLONGPATHNAME pfGetLongPathName = (GETLONGPATHNAME) GetProcAddress(GetModuleHandle("KERNEL32"), "GetLongPathNameA");

	if (pfGetLongPathName)
		return pfGetLongPathName(szaShort, szaLong, ccaBufferSize);
    else
	{
		strncpy(szaLong, szaShort, ccaBufferSize);
		return strlen(szaLong);
	}
}

const char*CUtils::CSVGetField(const char *pcaCurrent, char **pcaNextField)
{
	if (pcaNextField != NULL)
		*pcaNextField = NULL;

	if (pcaCurrent != NULL)
	{
		char *pciNext = strchr(pcaCurrent, ';');

		if (pciNext)
		{
			*pciNext++='\0';
			if (pcaNextField)
				*pcaNextField = pciNext;
		}
		else
		{
			// dernier champ : on vire le \n
			char *pciLF = strchr(pcaCurrent, '\n');
			if (pciLF)
				*pciLF = '\0';
		}
	}

	return pcaCurrent;
}

DWORD CUtils::AdjustPrivileges()
{
	DWORD dwRetour = ERROR_SUCCESS;
	HANDLE process = GetCurrentProcess();

	// get a token to adjust privileges
	HANDLE token = NULL;
	if(!OpenProcessToken(process, TOKEN_ADJUST_PRIVILEGES, &token))
		dwRetour = GetLastError();
	else
	{
		// set new privileges
		static TCHAR *P[] = {
			SE_CREATE_TOKEN_NAME,
			SE_ASSIGNPRIMARYTOKEN_NAME,
			SE_TCB_NAME,
			SE_LOAD_DRIVER_NAME,
			SE_DEBUG_NAME,
			SE_TAKE_OWNERSHIP_NAME,

		};

        TOKEN_PRIVILEGES  *	Priv;
		TCHAR				buf[1024] = {0};

        Priv = (PTOKEN_PRIVILEGES) buf;
        Priv->PrivilegeCount = 0;

        for(int j = 0; j < sizeof P/sizeof P[0]; ++j)
		{
			if(LookupPrivilegeValue(NULL, P[j], &Priv->Privileges[0].Luid))
			{
				Priv->Privileges[j].Attributes  = SE_PRIVILEGE_ENABLED;
				Priv->PrivilegeCount++;
			}
			else dwRetour = GetLastError();
		}
		// modify token privileges
		if(!AdjustTokenPrivileges(token, FALSE, Priv, 0, NULL, NULL))
			dwRetour = GetLastError();
	}

	return dwRetour;
}

void CUtils::Log(const char *szFormat, ...)
{
	const int DBSBUFSIZE = 1024;
	char szResult[DBSBUFSIZE] = {0};
	char szResultTotal[DBSBUFSIZE+3] = {0};
	const char *m_szTitle_Dbs = "EasyPHP";
	VOID FAR *valist=&szFormat+1;
	SYSTEMTIME sysTime;

	GetLocalTime(&sysTime);

	_vsnprintf(szResult, DBSBUFSIZE, szFormat, (LPSTR) valist);
	_snprintf(szResultTotal, DBSBUFSIZE, "%02d/%02d %02d:%02d:%02d %s %s",sysTime.wDay, sysTime.wMonth, sysTime.wHour, sysTime.wMinute, sysTime.wSecond, m_szTitle_Dbs,szResult);

	strcat(szResultTotal, "\n");
	OutputDebugString(szResultTotal);
}

BOOL CALLBACK GetProcessTitleCallback(HWND hwnd, LPARAM lParam)
{
	PSTGETPROCESSTITLE piGPT = (PSTGETPROCESSTITLE) lParam;

	if (lParam)
	{
		DWORD dwID = 0;

		GetWindowThreadProcessId(hwnd, &dwID) ;

		if(dwID == piGPT->dwProcID)
		{
			GetWindowText(hwnd, piGPT->szTitle, sizeof(piGPT->szTitle)-1);
			return FALSE;
		}
		return TRUE;
	}
	else return FALSE;
}

DWORD ListView_GetItemData(HWND hLVw, int nItem)
{
    LV_ITEM lvi;
    memset(&lvi, 0, sizeof(LV_ITEM));
    lvi.iItem = nItem;
    lvi.mask = LVIF_PARAM;

    ListView_GetItem( hLVw, &lvi);
    return (DWORD)lvi.lParam;
}
void CUtils::ViewFile(const char * pcaPath)
{
	if (pcaPath)
	{
//		if ((int) ShellExecute(NULL, "open", pcaPath, NULL, NULL, SW_SHOW) <= 32)
//		{
			char szToExecute[MAX_PATH] = {0};
			_snprintf(szToExecute, MAX_PATH-1, "notepad %s", pcaPath);
			WinExec(szToExecute, SW_SHOW);
//		}
	}
}

void CUtils::GotoURL(const char *szaURL)
{
	if (((int) ShellExecute(NULL, "open", szaURL, NULL, NULL, SW_SHOW)) <= 32)
	{
		char szPrompt[200] = {0};

		_snprintf(szPrompt, sizeof(szPrompt)-1, CLangue::LoadString(IDS_ERROR_BROWSER), szaURL);
		MessageBox(NULL, szPrompt, "Instant Rails", MB_OK | MB_ICONERROR);
	}
}
