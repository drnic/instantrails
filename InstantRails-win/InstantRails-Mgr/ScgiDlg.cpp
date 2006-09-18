
// Scgi.cpp : implementation file
//

#include "EasyPHPDlg.h"
#include "ScgiDlg.h"
#include "Utils.h"
#include "Langue.h"
#include <stdio.h>
#include  <io.h>			// _access
#include <commctrl.h>
#include <iostream>
#include <fstream>
#include <string>
using namespace std;

extern HINSTANCE g_hInstance;


CScgiDlg::CScgiDlg(HWND haParent, const char* szAppName)
{
	strncpy(m_szAppName, szAppName, MAX_PATH);
	m_bIsChanged = false;
	m_bIsInit = false;
	Create(IDD_TEMPLATE, haParent, true);
}

CScgiDlg::~CScgiDlg()
{
	m_szAppName[0] = '\0';
}

bool CScgiDlg::OnInitDialog()
{
	char title[100];
	_snprintf(title, sizeof(title)-1, "Configure %s", m_szAppName);

	const char* installPath = CEasyPhpDlg::GetInstallPath();
	char iniPath[MAX_PATH];
	_snprintf(iniPath, sizeof(iniPath)-1, "%sInstantRails.ini", installPath);
	char port[50] = {0};
	char mode[50] = {0};

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	GetPrivateProfileString(m_szAppName, "mode", "development", mode, 50, iniPath);
	GetPrivateProfileString(m_szAppName, "port", "3000", port, 50, iniPath);

	SetDlgItemText(GetHandle(), IDC_RUN_MODE, mode);
	SetDlgItemText(GetHandle(), IDC_PORT, port);

	SetDlgItemText(GetHandle(), IDC_SCGI_TITLE, title);

	SetDlgItemText(GetHandle(), IDC_SCGI_INSTRUCTIONS2, 
"\n\
To configure the startup mode of your Rails application, pick a port number and a runtime\n\
mode. \"development\" mode will reload your application's classes before each request for\n\
easy development. \"production\" mode will load your classes only once for better performance.\n\
\n\
If, for example you choose to run you application on port 3001, you could browse to:\n\
\n\
   http://127.0.0.1:3000/\n\
\n\
You can also set up an Apache virtual host to use mod_proxy to take http requests sent\n\
to a particular hostname and forward them to this running instance of your Rails app.\n\
\n\
You must edit you apache configuration file and specify the same port number in your app's\n\
VirtualHost directive. The hostname you decide to use must also be in the VirtualHost directrive.\n\
If this hostname is not a real, existing hostname in the DNS, then you must also edit your\n\
Windows HOSTS file and fake it by added a line like this:\n\
\n\
               127.0.0.1   www.my-fake-hostname.com\n\
\n\
Fake hostnames are for development purposes only, and can only be accessed from your local\n\
machine.\n\
"
		);

	return true;
}

int CScgiDlg::WindowProc(UINT message, WPARAM waParam, LPARAM laParam)
{
	BOOL biTraite = TRUE;
	
	switch (message)
	{
	case WM_COMMAND:	OnCommand(waParam);											break;
	default: biTraite = FALSE;
	}

	return (biTraite ? biTraite : CEasyPHPDialogBase::WindowProc(message, waParam, laParam));
}

bool CScgiDlg::OnCommand(WPARAM waCommand)
{
	const char* installPath = CEasyPhpDlg::GetInstallPath();
	char src[MAX_PATH+1] = {0};
	char dest[MAX_PATH+1] = {0};

	switch (waCommand)
	{
	case ID_EDIT_APACHE:
			CUtils::ViewFile(CEasyPhpDlg::GetApache()->GetTemplateConfFile());
		break;

	case ID_EDIT_HOSTS:
		{
			LPCSTR windir = getenv("WINDIR");
			_snprintf(src, sizeof(src), "%s\\system32\\drivers\\etc\\hosts", windir);
			CUtils::ViewFile(src);
		}
		break;

	case IDOK:
		{
			char iniPath[MAX_PATH];
			_snprintf(iniPath, sizeof(iniPath)-1, "%sInstantRails.ini", installPath);

			char mode[50] = {0};
			char port[50] = {0};

			GetDlgItemText( GetHandle(), IDC_RUN_MODE, mode, sizeof(mode));
			GetDlgItemText( GetHandle(), IDC_PORT, port, sizeof(port));

			WritePrivateProfileString(m_szAppName, "mode", mode, iniPath);
			WritePrivateProfileString(m_szAppName, "port", port, iniPath);

//			SetCurrentDirectory(dest);
//			_snprintf(src, sizeof(src), "%sruby\\bin\\ruby.exe %sruby\\bin\\mongrel_rails config -p %s -e %s", installPath, installPath, port, mode);
//			WinExec(src, SW_MINIMIZE);

			EndDialog(GetHandle(), IDOK);
		}
		break;

	case IDCANCEL:
		EndDialog(GetHandle(), IDCANCEL);
		break;
	}
	return true;
}

