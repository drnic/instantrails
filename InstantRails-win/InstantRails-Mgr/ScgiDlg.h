#pragma once

#include "resource.h"
#include "EasyPHPDialogBase.h"

/////////////////////////////////////////////////////////////////////////////
// CEasyPhpAboutDlg dialog

class CScgiDlg : public CEasyPHPDialogBase
{
// Construction
public:
	CScgiDlg(HWND haParent, const char* szAppName);
	~CScgiDlg();

// Implementation
	virtual bool	OnInitDialog();

protected:
	virtual int		WindowProc(UINT message, WPARAM wParam, LPARAM lParam);
	virtual bool	OnCommand(WPARAM waCommand);
	void			OnNotify(HWND haWnd, WPARAM waParam, LPNMHDR paNMHDR);

private:

	enum { IDD_TEMPLATE = IDD_SCGI };
	char	m_szAppName[MAX_PATH+1];
	bool	m_bIsChanged;
	bool	m_bIsInit;
};