
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
	const char* installPath = CEasyPhpDlg::GetInstallPath();
	char filepath[MAX_PATH+1] = {0};

	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_BIG, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));
	::SendMessage(GetHandle(), WM_SETICON, (WPARAM) ICON_SMALL, (LPARAM)::LoadIcon(g_hInstance, MAKEINTRESOURCE(IDR_EASYPHP_LOIC)));

	SetDlgItemText(GetHandle(), IDC_RUN_MODE, "development");
	SetDlgItemText(GetHandle(), IDC_PORT, "9999");

	_snprintf(filepath, sizeof(filepath), "%srails_apps\\%s\\config\\scgi.yaml", installPath, m_szAppName);

	string line;
	size_t index;
	ifstream scgi_config (filepath);
	if (scgi_config.is_open())
	{
		while (! scgi_config.eof() )
		{
			getline (scgi_config,line);
			index = line.find(":port: ");
			if (index == 0) {
				line.erase(index,7);
				SetDlgItemText(GetHandle(), IDC_PORT, line.c_str());
			}
			index = line.find(":env: ");
			if (index == 0) {
				line.erase(index,6);
				SetDlgItemText(GetHandle(), IDC_RUN_MODE, line.c_str());
			}
		}
		scgi_config.close();
	}


	SetDlgItemText(GetHandle(), IDC_SCGI_INSTRUCTIONS, 
"\
To configure your Rails application to run with SCGI you must pick a port number that SCGI will\n\
use to communicate between Apache and your application, and a virtual host name that you will\n\
use (in the URL) to access the Rails application from your browser. If you want to run more\n\
than one Rails application at the same time, each one will need to use a different port number\n\
and a different host name.\n\
\n\
The values you enter above will be written to your app's 'config\\scgi.yaml' file. You must also\n\
edit you apache configuration file and specify the same port number in your app's VirtualHost\n\
directive. The hostname you decide to use must also be in the VirtualHost directrive. If this\n\
hostname is not a real, existing hostname in the DNS, then you must also edit your Windows\n\
HOSTS file and fake it by added a line like this:\n\
\n\
               127.0.0.1   www.my-fake-hostname.com\n\
\n\
Fake hostnames are for development purposes only, and can only be accessed from your local\n\
machine.\n\
\n\
WARNING: At the moment, 'Runtime Mode' and 'SCGI Port' items above are always set to the default\n\
values 'development' and '9999' and this dialog is displayed. In the next Instant Rails release\n\
the will be initialized to whatever you have previsouly set them. You can see you current settings\n\
by looking at the file 'rails_apps'\\app-name\\config\\scgi.yaml'.\n\
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
		// -p port - e run-mode -S -P
			char mode[50] = {0};
			char port[50] = {0};

			GetDlgItemText( GetHandle(), IDC_RUN_MODE, mode, sizeof(mode));
			GetDlgItemText( GetHandle(), IDC_PORT, port, sizeof(port));

			_snprintf(dest, sizeof(dest), "%srails_apps\\%s", installPath, m_szAppName);
			SetCurrentDirectory(dest);
			_snprintf(src, sizeof(src), "%sruby\\bin\\ruby.exe %sruby\\bin\\scgi_ctrl config -p %s -e %s -S -P mypass", installPath, installPath, port, mode);
			WinExec(src, SW_MINIMIZE);

			EndDialog(GetHandle(), IDOK);
		}
		break;

	case IDCANCEL:
		EndDialog(GetHandle(), IDCANCEL);
		break;
	}
	return true;
}

