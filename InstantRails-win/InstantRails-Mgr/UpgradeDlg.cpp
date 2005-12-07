

#include "UpgradeDlg.h"
#include "Utils.h"
#include "Langue.h"
#include "SHA1File.h"

#include <commctrl.h>
#include <string>

extern HINSTANCE g_hInstance;

// pas top
static char l_szCurrentUpgradeName[MAX_PATH] = {0};
static DWORD l_szCurrentUpgradeSize = 0;

#define HASH_SIZE		SHA1HashSize*2

class CEasyFile
{
public:
	CEasyFile()
	{
		Init();
	}

	CEasyFile(const char *szName, unsigned int naCurrentVer)
	{
		Init();
		m_sName = szName;

		m_uiCurrentVersion = naCurrentVer;
		m_uiNewVersion = m_uiCurrentVersion;
	}

	bool IsUpgradable()
	{
		uint8_t	szEmptyHash[HASH_SIZE] = {0};

		return (m_uiNewVersion > m_uiCurrentVersion &&
					memcmp(szEmptyHash, m_Hash, HASH_SIZE) != ERROR_SUCCESS
				);
	}

	bool ReadFromWebCSV(const char *szaBuffer)
	{
		bool biRetour = false;
		char *pciFileName = NULL;
		char *pciVersion = NULL;
		char *pciRestart = NULL;
		char *pciFileSize = NULL;
		char *pciComment = NULL;

		pciFileName = (char *) CUtils::CSVGetField(szaBuffer, &pciVersion);
		pciVersion = (char *) CUtils::CSVGetField(pciVersion, &pciRestart);
		pciRestart = (char *) CUtils::CSVGetField(pciRestart, &pciFileSize);
		pciFileSize = (char *) CUtils::CSVGetField(pciFileSize, &pciComment);
		pciComment = (char *) CUtils::CSVGetField(pciComment, NULL);
		
		if (pciFileName && pciVersion)
		{
			m_sName = pciFileName;
			m_uiNewVersion = atoi(pciVersion);

			if (pciRestart)
				m_uiRestart = atoi(pciRestart);
			if (pciFileSize)
				m_uiFileSize = (atoi(pciFileSize));
			m_sComment = pciComment;
			biRetour = true;
		}

		return biRetour;
	}

protected:
	void Init()
	{
		// Champs lu dans upgrade.dat
		m_sName = "";
		m_uiCurrentVersion = 0;

		// Champs provenant du script Web
		m_uiNewVersion = 0;
		m_uiRestart = 0;
		m_uiFileSize = 0;
		memset(m_Hash, 0, sizeof(m_Hash));
	}

public:
	std::string		m_sName;
	unsigned int	m_uiCurrentVersion;
	unsigned int	m_uiNewVersion;
	std::string		m_sComment;

	// Pour les fichiers binaires....
	// Si le flag est mis, on renomme le fichier courant, on copie le fichier et on affiche la
	// boite de dialogue pour dire de redemarrer le manager.
	unsigned char	m_uiRestart;
	unsigned int	m_uiFileSize;
	uint8_t			m_Hash[HASH_SIZE+1];	// +1 for '\0' (for display)
};

CUpgradeDlg::CUpgradeDlg(bool baOnStartup)
{
	m_bOnStartup = baOnStartup;
}


UINT CUpgradeDlg::Show(HWND haParent)
{
	return Create(IDD_TEMPLATE, haParent, true); // modale
}

void CUpgradeDlg::SaveAndClean(FILE *paFileToSave)
{
	HWND hUpgradeFileList = GetDlgItem(IDL_UPDATEFILELIST);
	unsigned int niNb = ListView_GetItemCount(hUpgradeFileList);

	for (unsigned int niI = 0; niI < niNb; niI++)
	{
		CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(hUpgradeFileList, niI);

		if (piEF != NULL)
		{
			if (paFileToSave)
				fprintf(paFileToSave, "%s;%d\n", piEF->m_sName.c_str(), piEF->m_uiCurrentVersion);

			delete piEF;
		}
	}
}

bool CUpgradeDlg::OnInitDialog()
{
	HWND hUpgradeFileList = GetDlgItem(IDL_UPDATEFILELIST);
	LVCOLUMN stLvColumn = {0};

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	SendMessage(hUpgradeFileList, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_CHECKBOXES | LVS_EX_INFOTIP);

	stLvColumn.mask = LVCF_TEXT | LVCF_WIDTH;
	stLvColumn.cx = 175;
	stLvColumn.pszText = (char *) CLangue::LoadString(IDS_UPDATE_FILE);
	SendMessage(hUpgradeFileList, LVM_INSERTCOLUMN, 0, (LPARAM) &stLvColumn);
	stLvColumn.cx = 47;
	stLvColumn.pszText = (char *) CLangue::LoadString(IDS_UPDATE_CURRENT_VERSION);
	SendMessage(hUpgradeFileList, LVM_INSERTCOLUMN, 1, (LPARAM) &stLvColumn);
	stLvColumn.cx = 45;
	stLvColumn.pszText = (char *) CLangue::LoadString(IDS_UPDATE_NEW_VERSION);
	SendMessage(hUpgradeFileList, LVM_INSERTCOLUMN, 2, (LPARAM) &stLvColumn);
	stLvColumn.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
	stLvColumn.fmt = LVCFMT_RIGHT;
	stLvColumn.cx = 60;
	stLvColumn.pszText = (char *) CLangue::LoadString(IDS_UPDATE_FILE_SIZE);
	SendMessage(hUpgradeFileList, LVM_INSERTCOLUMN, 3, (LPARAM) &stLvColumn);
	stLvColumn.fmt = LVCFMT_CENTER;
	stLvColumn.cx = 280;
	stLvColumn.pszText = (char *) CLangue::LoadString(IDS_UPDATE_FILE_HASH);
	SendMessage(hUpgradeFileList, LVM_INSERTCOLUMN, 4, (LPARAM) &stLvColumn);


	char szUpgradeFileDatFileName[MAX_PATH+1] = {0};

	_snprintf(szUpgradeFileDatFileName, sizeof(szUpgradeFileDatFileName)-1, "%s\\upgrade.dat", CUtils::GetEasyPhpPath());
	FILE *piUpgradeDataFile = fopen(szUpgradeFileDatFileName, "rt");

	if (piUpgradeDataFile)
	{
		LVITEM stLvItem = {0};
		char szIToA[10] = {0};
		char szBuffer[150] = {0};
		int niCpt = 0;

		stLvItem.mask = LVIF_TEXT | LVIF_PARAM;
		stLvItem.iSubItem = 0;

		while (fgets(szBuffer, sizeof(szBuffer)-1, piUpgradeDataFile))
		{
			char *pciSep = strchr(szBuffer, ';');

			if (pciSep)
			{
				*pciSep++ = '\0';
				CEasyFile *piEF = new CEasyFile(szBuffer, atoi(pciSep));

				stLvItem.pszText = (char *) piEF->m_sName.c_str();
				stLvItem.iItem = niCpt;
				stLvItem.lParam = (LPARAM) piEF;
				ListView_InsertItem(hUpgradeFileList, &stLvItem);

				ListView_SetItemText(hUpgradeFileList, niCpt, 1, itoa(piEF->m_uiCurrentVersion, szIToA, 10));
				ListView_SetCheckState(hUpgradeFileList, niCpt, FALSE);
				niCpt++;
			}
		}

		fclose(piUpgradeDataFile);
	}
	
	PostMessage(GetHandle(), WM_COMMAND, ID_REFRESH_UPDATE, 0);

	return true;
}

bool CUpgradeDlg::OnCommand(WPARAM waCommand, LPARAM laParam)
{
	DWORD dwEndDialog = 0;

	switch (waCommand)
	{
	case ID_REFRESH_UPDATE:
		OnRefreshUpdate();
		break;

	case IDOK:
		dwEndDialog = OnUpgrade();
		// pas de break;

	case IDCANCEL:
		{
			// Sauvegarde et suppression
			char szUpgradeFileDatFileName[MAX_PATH+1] = {0};
			_snprintf(szUpgradeFileDatFileName, sizeof(szUpgradeFileDatFileName)-1, "%s\\upgrade.dat", CUtils::GetEasyPhpPath());
			FILE *piUpgradeDataFile = fopen(szUpgradeFileDatFileName, "wt");

			SaveAndClean(piUpgradeDataFile);

			if (piUpgradeDataFile)
				fclose(piUpgradeDataFile);

			EndDialog(GetHandle(), dwEndDialog);
		}
		break;
	}
	
	return true;
}

void CUpgradeDlg::OnRefreshUpdate()
{
	HWND hUpgradeFileList = GetDlgItem(IDL_UPDATEFILELIST);
	unsigned int niNb = ListView_GetItemCount(hUpgradeFileList);
	HCURSOR hOldCursor = ::SetCursor(::LoadCursor(NULL, IDC_WAIT));
	char szVerFileName[MAX_PATH+1] = {0};
	char szURL[MAX_PATH] = {0};
//	unsigned char cFileVer[4];

	// A FAIRE CUtils::GetFileVersion();//G

//			_snprintf(szURL, sizeof(szURL), "http://www.easyphp.org/upgrade/upgrade.php?updateVer=1801&langue=%s", CLangue::GetLang(CLangue::GetCurrentLang()));
	_snprintf(szURL, sizeof(szURL), "http://www.easyphp.org/upgrade/1802.dat");
	if (CUtils::DownloadFile(szURL, szVerFileName, NULL) == ERROR_SUCCESS)
	{
		if (szVerFileName[0] != 0)
		{
			FILE *piCurrentVersionFile = fopen(szVerFileName, "r+t");

			if (piCurrentVersionFile != NULL)
			{
				char szFileVerBuffer[200] = {0};
				LVITEM stLvItem = {0};

				stLvItem.mask = LVIF_TEXT | LVIF_PARAM;
				stLvItem.iSubItem = 0;

				while (fgets(szFileVerBuffer, sizeof(szFileVerBuffer)-1, piCurrentVersionFile))
				{
					CEasyFile cEF;
						
					if (cEF.ReadFromWebCSV(szFileVerBuffer))
					{
						char szIToA[10] = {0};
						CEasyFile *piEF = NULL;
						int niIndex = -1;	// Index de l'item, soir celui trouvé, soit celui insere

						for (unsigned int niI = 0; niIndex==-1&& niI<niNb; niI++)
						{
							piEF = (CEasyFile *) ListView_GetItemData(hUpgradeFileList, niI);

							if (piEF != NULL)
							{
								if (cEF.m_sName == piEF->m_sName)
								{
									piEF->m_uiNewVersion = cEF.m_uiNewVersion;
									piEF->m_uiRestart = cEF.m_uiRestart;
									piEF->m_uiFileSize = cEF.m_uiFileSize;
									piEF->m_sComment = cEF.m_sComment;
									niIndex = niI;
								}
							}
						}

						if (niIndex==-1)	// Pas trouvé : on rajoute
						{
							piEF = new CEasyFile(cEF);

							if (piEF)
							{
								niIndex = ListView_GetItemCount(hUpgradeFileList);
								stLvItem.pszText = (char *) piEF->m_sName.c_str();
								stLvItem.iItem = niIndex;
								stLvItem.lParam = (LPARAM) piEF;
								ListView_InsertItem(hUpgradeFileList, &stLvItem);
							}
						}
						
						if (piEF && niIndex!=-1)
						{
							ListView_SetItemText(hUpgradeFileList, niIndex, 1, piEF->m_uiCurrentVersion ? itoa(piEF->m_uiCurrentVersion, szIToA, 10) : "  -  ");
							ListView_SetItemText(hUpgradeFileList, niIndex, 2, piEF->m_uiNewVersion ? itoa(piEF->m_uiNewVersion, szIToA, 10) : "  -  ");
							ListView_SetItemText(hUpgradeFileList, niIndex, 3, itoa(piEF->m_uiFileSize, szIToA, 10));
						}
					}
				}
				fclose(piCurrentVersionFile);
			}

			DeleteFile(szVerFileName);
		}
	}
	else SetTextRefresh(IDC_UPDATE_MESSAGE, CLangue::LoadString(IDS_UPDATE_WEB_FILE_ERROR));


	bool biHashFileGood = false;
//			_snprintf(szURL, sizeof(szURL), "http://www.easyphp.org/upgrade/check/hash.dat", CLangue::GetLang(CLangue::GetCurrentLang()));
	strncpy(szURL, "http://yarglah.free.fr/check/hash.dat", sizeof(szURL)-1);
	if (CUtils::DownloadFile(szURL, szVerFileName, NULL, false) == ERROR_SUCCESS)
	{
		FILE *piHashFile = fopen(szVerFileName, "rt");

		if (piHashFile)
		{
			char szBuffer[120] = {0};
			unsigned int niNb = ListView_GetItemCount(hUpgradeFileList);

			while (fgets(szBuffer, sizeof(szBuffer)-1, piHashFile))
			{
				char *pciFileIdent = NULL;
				char *pciFileHash = NULL;
				bool biFound = false;

				pciFileIdent = (char *) CUtils::CSVGetField(szBuffer, &pciFileHash);
				pciFileHash = (char *) CUtils::CSVGetField(pciFileHash, NULL);

				if (pciFileIdent && pciFileHash)
				{
					int niHashLenth = strlen(pciFileHash);
					if (niHashLenth == HASH_SIZE)
					{
						for (unsigned int niI = 0; biFound==false&& niI<niNb; niI++)
						{
							CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(hUpgradeFileList, niI);

							if (piEF != NULL)
							{
								if (strcmp(pciFileIdent, piEF->m_sName.c_str())==ERROR_SUCCESS)
								{
									strupr(pciFileHash);
									memcpy(piEF->m_Hash, pciFileHash, HASH_SIZE);
									ListView_SetItemText(hUpgradeFileList, niI, 4, (char *) piEF->m_Hash);
									biFound = true;
								}
							}
						}
					}
				}
			}
			biHashFileGood = true;

			fclose(piHashFile);
		}

		DeleteFile(szVerFileName);
	}

	if (biHashFileGood == false)
	{
		if (m_bOnStartup == false)
		{
			SetTextRefresh(IDC_UPDATE_MESSAGE, CLangue::LoadString(IDS_UPDATE_HASH_DATA_ERROR));
			MessageBox(GetHandle(), CLangue::LoadString(IDS_UPDATE_HASH_DATA_ERROR), "EasyPHP", MB_OK);
		}
		SaveAndClean(NULL);
		EndDialog(GetHandle(), 0);
	}
	else
	{
		// MAJ Check
		bool biAtLeastOneToUpgrade = false;
		niNb = ListView_GetItemCount(hUpgradeFileList);
		for (unsigned int niI = 0; niI < niNb; niI++)
		{
			CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(hUpgradeFileList, niI);

			bool biFileIsUpgradable = (piEF ? piEF->IsUpgradable() : FALSE); 
			biAtLeastOneToUpgrade |= biFileIsUpgradable;
			ListView_SetCheckState(hUpgradeFileList, niI, biFileIsUpgradable);
		}

		SetTextRefresh(IDC_UPDATE_MESSAGE, biAtLeastOneToUpgrade == false ? CLangue::LoadString(IDS_UPDATE_UP_TO_DATE) : "");
		EnableWindow(GetDlgItem(IDOK), biAtLeastOneToUpgrade==true);
		if (biAtLeastOneToUpgrade == false)
		{
			if (m_bOnStartup == false)
				MessageBox(GetHandle(), CLangue::LoadString(IDS_UPDATE_UP_TO_DATE), "EasyPHP", MB_OK | MB_ICONINFORMATION);
			SaveAndClean(NULL);
			EndDialog(GetHandle(), 0);
		}
	}

	::SetCursor(hOldCursor);
}

UINT CUpgradeDlg::OnUpgrade()
{
	HWND hUpgradeFileList = GetDlgItem(IDL_UPDATEFILELIST);
	unsigned int niNb = ListView_GetItemCount(hUpgradeFileList);
	HCURSOR hOldCursor = ::SetCursor(::LoadCursor(NULL, IDC_WAIT));
	UINT dwNeedRestart = 0;

	for (unsigned int niI = 0; niI < niNb; niI++)
	{
		CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(hUpgradeFileList, niI);
		char szMessage[300] = {0};

		if (piEF != NULL)
		{
			if (ListView_GetCheckState(hUpgradeFileList, niI)==TRUE && 
					piEF->m_uiCurrentVersion!=piEF->m_uiNewVersion &&
					piEF->m_uiNewVersion != 0)
			{
				char szTempDownloadFile[MAX_PATH+1] = {0};
				char szURL[120] = {0};
				DWORD dwLastError = ERROR_SUCCESS;
				bool biRet = false;

				_snprintf(szMessage, sizeof(szMessage)-1, CLangue::LoadString(IDS_UPDATE_UPDATING), piEF->m_sName.c_str());
				SetTextRefresh(IDC_UPDATE_MESSAGE, szMessage);

				strncpy(l_szCurrentUpgradeName, piEF->m_sName.c_str(), sizeof(l_szCurrentUpgradeName)-1);
				l_szCurrentUpgradeSize = piEF->m_uiFileSize;
				_snprintf(szURL, sizeof(szURL)-1, "http://www.easyphp.org/upgrade/get.php?filename=%s&langue=%s", piEF->m_sName.c_str(), CLangue::GetLang(CLangue::GetCurrentLang()));
				if ((dwLastError = CUtils::DownloadFile(szURL, szTempDownloadFile, GetHandle())) == ERROR_SUCCESS)
				{
					uint8_t hashDownloaded[SHA1HashSize] = {0};
					char szHashASCII[HASH_SIZE+1] = {0};

					SHA1File(szTempDownloadFile, hashDownloaded);
					HashByteToASCII(hashDownloaded, szHashASCII);
					strupr(szHashASCII);

					if (strcmp(szHashASCII, (char *) piEF->m_Hash) != ERROR_SUCCESS)
					{
						_snprintf(szMessage, sizeof(szMessage)-1, CLangue::LoadString(IDS_UPDATE_BAD_HASH), piEF->m_sName.c_str(), szHashASCII, piEF->m_Hash);
						MessageBox(GetHandle(), szMessage, "EasyPHP", MB_OK | MB_ICONERROR);
					}
					else
					{
						char szFilePath[MAX_PATH] = {0};
						char szTempFilePath[MAX_PATH] = {0};

						_snprintf(szFilePath, sizeof(szFilePath)-1, "%s%s", CUtils::GetEasyPhpPath(), piEF->m_sName.c_str());

						if (piEF->m_uiRestart)
						{
							// MoveFile ne supprime pas le fichier si on le met dans un autre rep
							// et alors CopyFile foire avec l'erreur ERROR_SHARING_VIOLATION
							static niIndex = 0;
							_snprintf(szTempFilePath, sizeof(szTempFilePath)-1, "%stmp\\UpFile%02d.tmp", CUtils::GetEasyPhpPath(), niIndex++);

							if (DeleteFile(szTempFilePath) == FALSE) // GetTempFileName cree le fichier et ca fait foirer MoveFile...
							{
								dwLastError = GetLastError();
								dwLastError = ERROR_SUCCESS;
							}
							biRet = (MoveFile(szFilePath, szTempFilePath) == TRUE);
							if (biRet == FALSE)
								dwLastError = GetLastError();
						}

						if (CopyFile(szTempDownloadFile, szFilePath, FALSE))
						{
							char szIToA[10] =  {0};

							piEF->m_uiCurrentVersion = piEF->m_uiNewVersion;
							ListView_SetItemText(hUpgradeFileList, niI, 1, itoa(piEF->m_uiCurrentVersion, szIToA, 10));
							switch (piEF->m_uiRestart)
							{
							case 1: dwNeedRestart |= RESTART_MANAGER; break;
							case 2: dwNeedRestart |= RESTART_APACHE; break;
							case 3: dwNeedRestart |= RESTART_MYSQL; break;
							}
						}
						else 
						{
							dwLastError = GetLastError();
							if (piEF->m_uiRestart)
								MoveFile(szTempFilePath, szFilePath);
						}

						if (piEF->m_uiRestart)
							DeleteFile(szTempFilePath);
					}
				}
				
				if (dwLastError != ERROR_SUCCESS)
				{
					_snprintf(szMessage, sizeof(szMessage)-1, CLangue::LoadString(IDS_UPDATE_FILE_ERROR), piEF->m_sName.c_str(), dwLastError);
					MessageBox(GetHandle(), szMessage, "EasyPHP", MB_OK | MB_ICONERROR);
				}

				if (szTempDownloadFile[0] != '\0')
					DeleteFile(szTempDownloadFile);
			}
		}
	}
	SetCursor(hOldCursor);

	return dwNeedRestart;
}

void CUpgradeDlg::OnNotify(HWND haDlg, WPARAM waParam, LPNMHDR paNMHDR)
{
	if (paNMHDR->idFrom==IDL_UPDATEFILELIST)
	{
		switch (paNMHDR->code)
		{
		case LVN_ITEMCHANGING:
			{
				NM_LISTVIEW* pNMListView = (NM_LISTVIEW*) paNMHDR;
				bool biRefuseChange = false;

				if ((pNMListView->uOldState >> 13) != (pNMListView->uNewState >> 13))
				{
					if (pNMListView->uNewState >> 13) // On autorise toujours a decocher
					{
						CEasyFile *piEF = (CEasyFile *) pNMListView->lParam;

						biRefuseChange = (piEF ? !piEF->IsUpgradable() : true);
					}
				}
				SetWindowLong(haDlg, DWL_MSGRESULT, biRefuseChange ? TRUE : FALSE);
			}
			break;

		case LVN_GETINFOTIP:
			{
				NMLVGETINFOTIP* pNMListViewInfoTip = (NMLVGETINFOTIP*) paNMHDR;
				CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(pNMListViewInfoTip->hdr.hwndFrom, pNMListViewInfoTip->iItem);

				if (piEF)
					strncpy(pNMListViewInfoTip->pszText, piEF->m_sComment.c_str(), pNMListViewInfoTip->cchTextMax);
			}
			break;

		case NM_CUSTOMDRAW:
			{
				LPNMLVCUSTOMDRAW lplvcd = (LPNMLVCUSTOMDRAW) paNMHDR;

				switch(lplvcd->nmcd.dwDrawStage)
				{
				case CDDS_PREPAINT:     SetWindowLong(haDlg, DWL_MSGRESULT, CDRF_NOTIFYITEMDRAW);       break;
				case CDDS_ITEMPREPAINT:  SetWindowLong(haDlg, DWL_MSGRESULT, CDRF_NOTIFYSUBITEMDRAW);	break;
				case CDDS_SUBITEM | CDDS_ITEMPREPAINT:
				case CDDS_ITEM:
					{
						CEasyFile *piEF = (CEasyFile *) ListView_GetItemData(GetDlgItem(IDL_UPDATEFILELIST), lplvcd->nmcd.dwItemSpec);
						bool biGrise = true;

						if (piEF != NULL)
							biGrise = (piEF->IsUpgradable() == false);

						if (biGrise)
							lplvcd->clrTextBk = RGB(200, 200, 200);
					}
					break;

				default: SetWindowLong(haDlg, DWL_MSGRESULT, CDRF_DODEFAULT);
				}
			}
			break;
		}
	}
}
#define PM_QS_PAINT         (QS_PAINT << 16)
int CUpgradeDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	BOOL biTraite = TRUE;

	switch (message)
	{
	case WM_ERASEBKGND:			// Fout la merde avec le thême XP...
	case WM_CTLCOLORBTN:
	case WM_CTLCOLORSTATIC:		return FALSE;

	case WM_COMMAND:	OnCommand(waParam, laParam);			break;
	case WM_NOTIFY:		HANDLE_WM_NOTIFY(GetHandle(), waParam, laParam, OnNotify);	break;
	default:
		if (message == CUtils::GetDownloadNotifyMsg())
		{
			char szMessage[150] = {0};

			if (l_szCurrentUpgradeSize)
				_snprintf(szMessage, sizeof(szMessage)-1, "%s %-7d/%-7d (%d%%) bytes downloaded", l_szCurrentUpgradeName, laParam, l_szCurrentUpgradeSize, laParam*100/l_szCurrentUpgradeSize);
			else _snprintf(szMessage, sizeof(szMessage)-1, "%-7d bytes downloaded", laParam);
			SetWindowText(GetDlgItem(IDC_UPDATE_MESSAGE), szMessage);
			
			/*InvalidateRect(GetHandle(), NULL, TRUE);
			MSG msg;
			HWND hiWnd = GetHandle();
			while (::PeekMessage(&msg, hiWnd, 0, 0, PM_REMOVE | PM_QS_PAINT))
				DispatchMessage(&msg);
			//UpdateWindow(GetDlgItem(IDC_UPDATE_MESSAGE));
//			SetTextRefresh(IDC_UPDATE_MESSAGE, szMessage);*/
		}
		else biTraite = FALSE;						break;
	}
	return (biTraite ? biTraite : CEasyPHPDialogBase::WindowProc(message, waParam, laParam));
}