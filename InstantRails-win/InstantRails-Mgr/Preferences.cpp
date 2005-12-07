
#include "Preferences.h"
#include "EasyPHPAboutDlg.h"
#include "Langue.h"
#include "Utils.h"

extern HINSTANCE g_hInstance;

CPreferencesDlg::CPreferencesDlg(HWND haParent, CEasyPHP *paEasyPHP)
{
	m_pEasyPHP = paEasyPHP;
	m_hParent = haParent;

	Create(IDD_TEMPLATE, haParent, true);
}

bool CPreferencesDlg::OnInitDialog()
{
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	HWND hComboLang = GetDlgItem(IDC_LANG);
	unsigned char niNbLangues = CLangue::GetLangCount();
	for (unsigned char niI = 0; niI < niNbLangues; niI++)
		SendMessage(hComboLang, CB_ADDSTRING, 0, (LPARAM) CLangue::GetLang(niI));
	SendMessage(hComboLang, CB_SETCURSEL, CLangue::GetCurrentLang(), 0);

//	UpdateLang();
	UpdateData(false);

/*	// On ne le fait qu'une fois ici...
	CreateTooltip(GetDlgItem(IDC_CHECK_EASYPHP_VERSION), CLangue::LoadString(IDS_HELPCTX_IDC_CHECK_EASYPHP_VERSION));
	CreateTooltip(GetDlgItem(IDC_CONFAUTORELOAD), CLangue::LoadString(IDS_HELPCTX_IDC_CONFAUTORELOAD));
	CreateTooltip(GetDlgItem(IDC_SERVICE), CLangue::LoadString(IDS_HELPCTX_IDC_SERVICE));
	CreateTooltip(GetDlgItem(IDC_AUTOSERVEURSSTART), CLangue::LoadString(IDS_HELPCTX_IDC_AUTOSERVEURSSTART));
*/
	EnableWindow(GetDlgItem(IDOK), FALSE);

	SetFocus(GetDlgItem(IDOK));

	return false;
}

bool CPreferencesDlg::OnCommand(WPARAM waCommand, LPARAM laParam)
{
	switch (LOWORD(waCommand))
	{
	// boite de dialogue
	case IDC_SERVICE:
		{
			BOOL biIsService = ::SendMessage(GetDlgItem(IDC_SERVICE), BM_GETCHECK, 0, 0);
			::EnableWindow(GetDlgItem(IDC_AUTOSERVEURSSTART), !biIsService);
			::EnableWindow(GetDlgItem(IDE_MYSQL_ARGUMENTS), !biIsService);
		}
		// pas de break !

	case IDC_CHECK_WINDOWSTART:
	case IDC_AUTOSERVEURSSTART:
	case IDC_CHECK_EASYPHP_VERSION:
	case IDC_CONFAUTORELOAD:
	case IDC_CHECK_SERVERS_PORT:
		EnableWindow(GetDlgItem(IDOK), TRUE);
		break;

	case IDC_LANG:	
		if (HIWORD(waCommand) ==  CBN_SELCHANGE && m_pEasyPHP)
		{
			CLangue::SetCurrentLang((unsigned char) SendMessage(GetDlgItem(IDC_LANG), CB_GETCURSEL, 0, 0));
			strncpy(m_pEasyPHP->m_szSelectedLang, CLangue::GetLang(CLangue::GetCurrentLang()), 49);
//			UpdateLang();
			EnableWindow(GetDlgItem(IDOK), TRUE);
		}
		break;

	// Posté par ABOUT : on retransmet au a la fenetre parent
	case ID_CHECK_VERSION:  SendMessage(GetParent(GetHandle()), WM_COMMAND, ID_CHECK_VERSION, 0); break;

/*	case ID_HELP_CONTEXT:	// Si on utilise un autre bouton que le "?" standard dans la barre de titre...
							// provoque le curseur "?"
		{
			POINT stPoint;

			GetCursorPos(&stPoint);
			SendMessage(GetHandle(), WM_SYSCOMMAND, SC_CONTEXTHELP, MAKELPARAM(stPoint.x, stPoint.y));
		}
		break;
*/
	case ID_APPLY:
		UpdateData(true);
		break;

	case IDOK:
		UpdateData(true);
		EndDialog(GetHandle(), 1);
		break;

	case IDCANCEL:
		EndDialog(GetHandle(), 0);
		break;
	}

	return true;
}

void CPreferencesDlg::OnHelpContext(LPHELPINFO paHI)
{
	if (paHI)
	{
		const char *szHelpText = NULL;
		switch (paHI->iCtrlId)
		{
		case IDC_SERVICE:				szHelpText = CLangue::LoadString(IDS_HELPCTX_IDC_SERVICE); break;
		case IDE_MYSQL_ARGUMENTS:		szHelpText = CLangue::LoadString(IDS_HELPCTX_IDE_MYSQL_ARGUMENTS); break;
		case IDC_AUTOSERVEURSSTART:		szHelpText = CLangue::LoadString(IDS_HELPCTX_IDC_AUTOSERVEURSSTART); break;
//		default: szHelpText = CUtils::LoadString(IDS_HELPCTX_NOHELP); break;
		}
		if (szHelpText)
		{
			// CreateTooltip(GetItemHandle(paHI->iCtrlId), szHelpText);
			MessageBox(GetHandle(), szHelpText, m_pEasyPHP->GetAppName(), MB_OK | MB_ICONINFORMATION);
		}
	}
}

bool CPreferencesDlg::UpdateData(bool baSaveAndValidate)
{
	if (baSaveAndValidate)
	{
		m_pEasyPHP->m_bAutoStartServeurs = (IsDlgButtonChecked(GetHandle(), IDC_AUTOSERVEURSSTART) ? true : false);
		m_pEasyPHP->m_bAutoStartEasyPhp = (IsDlgButtonChecked(GetHandle(), IDC_CHECK_WINDOWSTART) ? true : false);
		m_pEasyPHP->m_bAutoReloadConf = (IsDlgButtonChecked(GetHandle(), IDC_CONFAUTORELOAD) ? true : false);
		m_pEasyPHP->m_bCheckServerPorts = (IsDlgButtonChecked(GetHandle(), IDC_CHECK_SERVERS_PORT) ? true : false);
		// GetWindowText(GetItemHandle(IDE_MYSQL_ARGUMENTS), m_pEasyPHP->m_sMySql_Arguments, sizeof(m_pEasyPHP->m_sMySql_Arguments)-1);
		m_pEasyPHP->m_bModeSSL = (IsDlgButtonChecked(GetHandle(), IDC_SSL) ? true : false);
		m_pEasyPHP->m_bCheckVersionAtStartup = (IsDlgButtonChecked(GetHandle(), IDC_CHECK_EASYPHP_VERSION) ? true : false);
		m_pEasyPHP->m_bStartAsService = (IsDlgButtonChecked(GetHandle(), IDC_SERVICE) ? true : false);
	}
	else
	{
		CheckDlgButton(GetHandle(), IDC_AUTOSERVEURSSTART, m_pEasyPHP->m_bAutoStartServeurs ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(GetHandle(), IDC_CHECK_WINDOWSTART, m_pEasyPHP->m_bAutoStartEasyPhp ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(GetHandle(), IDC_CONFAUTORELOAD, m_pEasyPHP->m_bAutoReloadConf ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(GetHandle(), IDC_CHECK_SERVERS_PORT, m_pEasyPHP->m_bCheckServerPorts ? BST_CHECKED : BST_UNCHECKED);
		// SetWindowText(GetItemHandle(IDE_MYSQL_ARGUMENTS), m_pEasyPHP->m_sMySql_Argumentsm_sMySql_Arguments);
		CheckDlgButton(GetHandle(), IDC_SSL, m_pEasyPHP->m_bModeSSL ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(GetHandle(), IDC_CHECK_EASYPHP_VERSION, m_pEasyPHP->m_bCheckVersionAtStartup ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(GetHandle(), IDC_SERVICE, m_pEasyPHP->m_bStartAsService ? BST_CHECKED : BST_UNCHECKED);
		::EnableWindow(GetDlgItem(IDC_SERVICE), CUtils::UserIsAdmin() && CUtils::IsWindowsNTPlatform() && CUtils::IsFixedDrive());
		::EnableWindow(GetDlgItem(IDC_CHECK_WINDOWSTART), CUtils::UserIsAdmin() && CUtils::IsWindowsNTPlatform() && CUtils::IsFixedDrive());
		::EnableWindow(GetDlgItem(IDC_AUTOSERVEURSSTART), !m_pEasyPHP->m_bStartAsService);
		::EnableWindow(GetDlgItem(IDE_MYSQL_ARGUMENTS), !m_pEasyPHP->m_bStartAsService);
	}
	EnableWindow(GetDlgItem(IDOK), FALSE);

	return true;
}

void CPreferencesDlg::UpdateLang()
{
/*
	//	SetWindowText(GetDlgItem(IDC_PREFERENCES), CLangue::LoadString(IDS_CONF_PREFERENCES));
	SetWindowText(GetDlgItem(IDC_CHECK_WINDOWSTART), CLangue::LoadString(IDS_MAIN_CHECK_WINDOWSTART));
	SetWindowText(GetDlgItem(IDC_SERVICE), CLangue::LoadString(IDS_MAIN_SERVICE));
	SetWindowText(GetDlgItem(IDC_AUTOSERVEURSSTART), CLangue::LoadString(IDS_MAIN_AUTOSERVEURSSTART));
	SetWindowText(GetDlgItem(IDC_CHECK_EASYPHP_VERSION), CLangue::LoadString(IDS_MAIN_CHECK_EASYPHP_VERSION_AT_STARTUP));
	SetWindowText(GetDlgItem(IDC_CONFAUTORELOAD), CLangue::LoadString(IDS_MAIN_CONFAUTORELOAD));
	SetWindowText(GetDlgItem(IDC_CHECK_SERVERS_PORT), CLangue::LoadString(IDS_CONF_CHECK_SERVERS_PORT));
	SetWindowText(GetDlgItem(IDC_MAIN_MYSQL_ARGUMENTS), CLangue::LoadString(IDS_MAIN_MYSQL_ARGUMENTS));
	SetWindowText(GetDlgItem(IDC_LANGUAGE), CLangue::LoadString(IDS_CONF_LANGUAGE));
 	SetWindowText(GetDlgItem(IDOK), CLangue::LoadString(IDS_MAIN_APPLIQUER));
	SetWindowText(GetDlgItem(IDCANCEL), CLangue::LoadString(IDS_MAIN_FERMER));
	SetWindowText(GetDlgItem(ID_ABOUT), CLangue::LoadString(IDS_MAIN_ABOUT));

	InvalidateRect(GetHandle(), NULL, TRUE);
*/
}

int CPreferencesDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	bool biTraite = TRUE;

	switch (message)
	{
	case WM_ERASEBKGND:			// Fout la merde avec le thême XP...
	case WM_CTLCOLORBTN:
	case WM_CTLCOLORSTATIC:		return FALSE;
	case WM_COMMAND:			OnCommand(waParam, laParam);			break;
	case WM_HELP:				OnHelpContext((LPHELPINFO) laParam);	break;
	default:					biTraite = false;						break;
	}
	return (biTraite ? biTraite : CEasyPHPDialogBase::WindowProc(message, waParam, laParam));
}