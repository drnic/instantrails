
#include "GenConf.h"
#include "Utils.h"
#include <stdio.h>

#define PATH_TAG	"${path}"

#define ESC_PATH_TAG	"${esc-path}"

DWORD RegenerateConfFiles(HWND parent_window)
{
	char szCurrentPath[MAX_PATH] = {0},
		szCurrentPath2[MAX_PATH] = {0},
		szCurrentPathEsc[MAX_PATH] = {0},
		szApacheConfSrc[MAX_PATH] = {0},
		szApacheConfDest[MAX_PATH] = {0},
		szMySQLConfSrc[MAX_PATH] = {0},
		szMySQLConfDest[MAX_PATH] = {0},
		szPHPConfSrc[MAX_PATH] = {0},
		szPHPConfDest[MAX_PATH] = {0},
//		szRubyBinErbSrc[MAX_PATH] = {0},
//		szRubyBinErbDest[MAX_PATH] = {0},
//		szRubyBinIrbSrc[MAX_PATH] = {0},
//		szRubyBinIrbDest[MAX_PATH] = {0},
//		szRubyBinRdocSrc[MAX_PATH] = {0},
//		szRubyBinRdocDest[MAX_PATH] = {0},
//		szRubyBinRiSrc[MAX_PATH] = {0},
//		szRubyBinRiDest[MAX_PATH] = {0},
//		szRubyBinTestrbSrc[MAX_PATH] = {0},
//		szRubyBinTestrbDest[MAX_PATH] = {0},
//		szRubyBinGemSrc[MAX_PATH] = {0},
//		szRubyBinGemDest[MAX_PATH] = {0},
//		szRubyBinGem_serverSrc[MAX_PATH] = {0},
//		szRubyBinGem_serverDest[MAX_PATH] = {0},
//		szRubyBinGemwhichSrc[MAX_PATH] = {0},
//		szRubyBinGemwhichDest[MAX_PATH] = {0},
		szRubyBinRailsSrc[MAX_PATH] = {0},
		szRubyBinRailsDest[MAX_PATH] = {0},
//		szRubyBinRakeSrc[MAX_PATH] = {0},
//		szRubyBinRakeDest[MAX_PATH] = {0},
		//szRubyBinUpdate_rubygemsSrc[MAX_PATH] = {0},
		//szRubyBinUpdate_rubygemsDest[MAX_PATH] = {0},
		szRubyBinMongrelRailsSrc[MAX_PATH] = {0},
		szRubyBinMongrelRailsDest[MAX_PATH] = {0},
		szRubyBinMongrelRailsSvcSrc[MAX_PATH] = {0},
		szRubyBinMongrelRailsSvcDest[MAX_PATH] = {0},

		szRadRails1PrefsSrc[MAX_PATH] = {0},
		szRadRails1PrefsDest[MAX_PATH] = {0},
		szRadRails2PrefsSrc[MAX_PATH] = {0},
		szRadRails2PrefsDest[MAX_PATH] = {0},
		szRadRailsRubyPrefsSrc[MAX_PATH] = {0},
		szRadRails1RubyPrefsDest[MAX_PATH] = {0},

		szUseRubySrc[MAX_PATH] = {0},
		szUseRubyDest[MAX_PATH] = {0};//,
		//szFxriSrc[MAX_PATH] = {0},
		//szFxriDest[MAX_PATH] = {0};

	GetModuleFileName(NULL, szCurrentPath, sizeof(szCurrentPath));
	strcpy(strrchr(szCurrentPath, '\\'), "");
	strcpy(szCurrentPath2, szCurrentPath);
	strcpy(szCurrentPathEsc, szCurrentPath2);

	// Keep szCurrentPath2 with backslashes, change szCurrentPath
	// to use forward slashes
	for (int ii = 0; szCurrentPath[ii] != '\0'; ii++) {
		if (szCurrentPath[ii] == '\\') {
			szCurrentPath[ii] = '/';
		}
	}

	// Keep szCurrentPathEsc uses backslashes that are doubled (escpaped)
	int nn = 0;
	for (int ii = 0; szCurrentPath2[ii] != '\0'; ii++) {
		szCurrentPathEsc[nn++] = szCurrentPath2[ii];
		if (szCurrentPath2[ii] == '\\') {
			szCurrentPathEsc[nn++] = '\\'; // double up the backslashes
		}
	}
	szCurrentPathEsc[nn++] = '\0';

	// Make sure the path does not contain any space chars
	LPSTR space_char = strchr(szCurrentPath, ' ');
	if (space_char) {
		MessageBox(parent_window, 
			       "Instant Rails cannot be run from a path that contains space characters. Please move Instant Rails to a new directory that does not contain spaces.", 
				   "Instant Rails", MB_OK | MB_ICONSTOP);
		exit(1);
	}

	_snprintf(szApacheConfSrc,  sizeof(szApacheConfSrc),   "%s\\conf_files\\httpd.conf", szCurrentPath2);
	_snprintf(szApacheConfDest, sizeof(szApacheConfDest),  "%s\\Apache\\conf\\httpd.conf", szCurrentPath2);
	
	_snprintf(szMySQLConfSrc,  sizeof(szMySQLConfSrc),   "%s\\conf_files\\my.ini", szCurrentPath2);
	_snprintf(szMySQLConfDest, sizeof(szMySQLConfDest),  "%s\\MySql\\my.ini", szCurrentPath2);

	_snprintf(szPHPConfSrc,  sizeof(szPHPConfSrc),   "%s\\conf_files\\php.ini", szCurrentPath2);
	_snprintf(szPHPConfDest, sizeof(szPHPConfDest),  "%s\\Apache\\php.ini", szCurrentPath2);

//	_snprintf(szRubyBinErbSrc,  sizeof(szRubyBinErbSrc),   "%s\\conf_files\\erb.bat", szCurrentPath2);
//	_snprintf(szRubyBinErbDest, sizeof(szRubyBinErbDest),  "%s\\ruby\\bin\\erb.bat", szCurrentPath2);

//	_snprintf(szRubyBinIrbSrc,  sizeof(szRubyBinIrbSrc),   "%s\\conf_files\\irb.bat", szCurrentPath2);
//	_snprintf(szRubyBinIrbDest, sizeof(szRubyBinIrbDest),  "%s\\ruby\\bin\\irb.bat", szCurrentPath2);

//	_snprintf(szRubyBinRdocSrc,  sizeof(szRubyBinRdocSrc),   "%s\\conf_files\\rdoc.bat", szCurrentPath2);
//	_snprintf(szRubyBinRdocDest, sizeof(szRubyBinRdocDest),  "%s\\ruby\\bin\\rdoc.bat", szCurrentPath2);

//	_snprintf(szRubyBinRiSrc,  sizeof(szRubyBinRiSrc),   "%s\\conf_files\\ri.bat", szCurrentPath2);
//	_snprintf(szRubyBinRiDest, sizeof(szRubyBinRiDest),  "%s\\ruby\\bin\\ri.bat", szCurrentPath2);

//	_snprintf(szRubyBinTestrbSrc,  sizeof(szRubyBinTestrbSrc),   "%s\\conf_files\\testrb.bat", szCurrentPath2);
//	_snprintf(szRubyBinTestrbDest, sizeof(szRubyBinTestrbDest),  "%s\\ruby\\bin\\testrb.bat", szCurrentPath2);

//	_snprintf(szRubyBinGemSrc,  sizeof(szRubyBinGemSrc),   "%s\\conf_files\\gem.cmd", szCurrentPath2);
//	_snprintf(szRubyBinGemDest, sizeof(szRubyBinGemDest),  "%s\\ruby\\bin\\gem.cmd", szCurrentPath2);

//	_snprintf(szRubyBinGem_serverSrc,  sizeof(szRubyBinGem_serverSrc),   "%s\\conf_files\\gem_server.cmd", szCurrentPath2);
//	_snprintf(szRubyBinGem_serverDest, sizeof(szRubyBinGem_serverDest),  "%s\\ruby\\bin\\gem_server.cmd", szCurrentPath2);

//	_snprintf(szRubyBinGemwhichSrc,  sizeof(szRubyBinGemwhichSrc),   "%s\\conf_files\\gemwhich.cmd", szCurrentPath2);
//	_snprintf(szRubyBinGemwhichDest, sizeof(szRubyBinGemwhichDest),  "%s\\ruby\\bin\\gemwhich.cmd", szCurrentPath2);

	_snprintf(szRubyBinRailsSrc,  sizeof(szRubyBinRailsSrc),   "%s\\conf_files\\rails.cmd", szCurrentPath2);
	_snprintf(szRubyBinRailsDest, sizeof(szRubyBinRailsDest),  "%s\\ruby\\bin\\rails.cmd", szCurrentPath2);

//	_snprintf(szRubyBinRakeSrc,  sizeof(szRubyBinRakeSrc),   "%s\\conf_files\\rake.cmd", szCurrentPath2);
//	_snprintf(szRubyBinRakeDest, sizeof(szRubyBinRakeDest),  "%s\\ruby\\bin\\rake.cmd", szCurrentPath2);

	//_snprintf(szRubyBinUpdate_rubygemsSrc,  sizeof(szRubyBinUpdate_rubygemsSrc),   "%s\\conf_files\\update_rubygems.cmd", szCurrentPath2);
	//_snprintf(szRubyBinUpdate_rubygemsDest, sizeof(szRubyBinUpdate_rubygemsDest),  "%s\\ruby\\bin\\update_rubygems.cmd", szCurrentPath2);

	_snprintf(szRubyBinMongrelRailsSrc,  sizeof(szRubyBinMongrelRailsSrc),   "%s\\conf_files\\mongrel_rails.cmd", szCurrentPath2);
	_snprintf(szRubyBinMongrelRailsDest, sizeof(szRubyBinMongrelRailsDest),  "%s\\ruby\\bin\\mongrel_rails.cmd", szCurrentPath2);

	_snprintf(szRubyBinMongrelRailsSvcSrc,  sizeof(szRubyBinMongrelRailsSvcSrc),   "%s\\conf_files\\mongrel_rails_service.cmd", szCurrentPath2);
	_snprintf(szRubyBinMongrelRailsSvcDest, sizeof(szRubyBinMongrelRailsSvcDest),  "%s\\ruby\\bin\\mongrel_rails_service.cmd", szCurrentPath2);

	_snprintf(szRadRails1PrefsSrc,  sizeof(szRadRails1PrefsSrc),   "%s\\conf_files\\radrails\\.metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.radrails.rails.core.prefs", szCurrentPathEsc);
	_snprintf(szRadRails1PrefsDest, sizeof(szRadRails1PrefsDest),  "%s\\rails_apps\\.metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.radrails.rails.core.prefs", szCurrentPathEsc);

	_snprintf(szRadRails2PrefsSrc,  sizeof(szRadRails2PrefsSrc),   "%s\\conf_files\\radrails\\.metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.rubypeople.rdt.ui.prefs", szCurrentPathEsc);
	_snprintf(szRadRails2PrefsDest, sizeof(szRadRails2PrefsDest),  "%s\\rails_apps\\.metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.rubypeople.rdt.ui.prefs", szCurrentPathEsc);

	_snprintf(szRadRailsRubyPrefsSrc,  sizeof(szRadRailsRubyPrefsSrc),   "%s\\conf_files\\radrails\\.metadata\\.plugins\\org.rubypeople.rdt.launching\\runtimeConfiguration.xml", szCurrentPathEsc);
	_snprintf(szRadRails1RubyPrefsDest, sizeof(szRadRails1RubyPrefsDest),  "%s\\rails_apps\\.metadata\\.plugins\\org.rubypeople.rdt.launching\\runtimeConfiguration.xml", szCurrentPathEsc);

	_snprintf(szUseRubySrc,  sizeof(szUseRubySrc),   "%s\\conf_files\\use_ruby.cmd", szCurrentPath2);
	_snprintf(szUseRubyDest, sizeof(szUseRubyDest),  "%s\\use_ruby.cmd", szCurrentPath2);

	//_snprintf(szFxriSrc,  sizeof(szFxriSrc),   "%s\\conf_files\\fxri.cmd", szCurrentPath2);
	//_snprintf(szFxriDest, sizeof(szFxriDest),  "%s\\ruby\\bin\\fxri.cmd", szCurrentPath2);


	GenerateConfFile(szCurrentPath, szApacheConfSrc, szApacheConfDest, '#');
	GenerateConfFile(szCurrentPath, szMySQLConfSrc, szMySQLConfDest, '#');
	GenerateConfFile(szCurrentPath, szPHPConfSrc, szPHPConfDest, ';');

//	GenerateConfFile(szCurrentPath2, szRubyBinErbSrc, szRubyBinErbDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinIrbSrc, szRubyBinIrbDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinRdocSrc, szRubyBinRdocDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinRiSrc, szRubyBinRiDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinTestrbSrc, szRubyBinTestrbDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinGemSrc, szRubyBinGemDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinGem_serverSrc, szRubyBinGem_serverDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinGemwhichSrc, szRubyBinGemwhichDest, ':');
	GenerateConfFile(szCurrentPath2, szRubyBinRailsSrc, szRubyBinRailsDest, ':');
//	GenerateConfFile(szCurrentPath2, szRubyBinRakeSrc, szRubyBinRakeDest, ':');
	//GenerateConfFile(szCurrentPath2, szRubyBinUpdate_rubygemsSrc, szRubyBinUpdate_rubygemsDest, ':');
	GenerateConfFile(szCurrentPath2, szRubyBinMongrelRailsSrc, szRubyBinMongrelRailsDest, ':');
	GenerateConfFile(szCurrentPath2, szRubyBinMongrelRailsSvcSrc, szRubyBinMongrelRailsSvcDest, ':');
	GenerateConfFile(szCurrentPath2, szUseRubySrc, szUseRubyDest, ':');
//	GenerateConfFile(szCurrentPath2, szFxriSrc, szFxriDest, ':');
	GenerateEscConfFile(szCurrentPathEsc, szRadRails1PrefsSrc, szRadRails1PrefsDest, '#');
	GenerateEscConfFile(szCurrentPathEsc, szRadRails2PrefsSrc, szRadRails2PrefsDest, '#');
	GenerateConfFile(szCurrentPath, szRadRailsRubyPrefsSrc, szRadRails1RubyPrefsDest, '\0');

	return 0;
}

DWORD GenerateConfFile(const char *szaPath, const char *szaTemplateFile, const char *szaDestFile, char caCommentChar)
{
	DWORD dwRetour = ERROR_SUCCESS;
	FILE *piTemplate = NULL;

	if ((piTemplate = fopen(szaTemplateFile, "rt")) !=NULL)
	{
		char szTempFileName[MAX_PATH] = {0};
		FILE *piDestFile = NULL;

		GetTempPath(MAX_PATH, szTempFileName);
		GetTempFileName(szTempFileName, "InstantRails", 0, szTempFileName);

		if ((piDestFile = fopen(szTempFileName, "wt")) != NULL)
		{
			char szMonGrosBuffer[200] = {0};

			if (caCommentChar != '\0') {
	fprintf(piDestFile, "\
%c------------------------- WARNING ! ----------------------\n\
%c         This file is GENERATED by Instant Rails.\n\
%c\n\
%c If you need to make changes to this file, you should edit\n\
%c the source template file instead. The source template is\n\
%c %s\n\
%c-----------------------------------------------------------\n",
			caCommentChar, caCommentChar, caCommentChar, 
			caCommentChar, caCommentChar, caCommentChar, 
			szaTemplateFile, caCommentChar);
			}

			while (fgets(szMonGrosBuffer, sizeof(szMonGrosBuffer)-1, piTemplate))
			{
				char *pciTag = strstr(szMonGrosBuffer, PATH_TAG);
				if (pciTag)
				{
					*pciTag = '\0';
					fputs(szMonGrosBuffer, piDestFile);
					fputs(szaPath, piDestFile);
					// hacked to allow ${path} to appear in a line twice.
					// should be able to be "n" times, but we'll save
					// that for the rewrite. -- curt
					char *pciTag2 = strstr(pciTag+strlen(PATH_TAG), PATH_TAG);
					if (pciTag2) {
						*pciTag2 = '\0';
						fputs(pciTag+strlen(PATH_TAG), piDestFile);
						fputs(szaPath, piDestFile);
						pciTag = pciTag2;
					}
					fputs(pciTag+strlen(PATH_TAG), piDestFile);
				}
				else fputs(szMonGrosBuffer, piDestFile);
			}
			fclose(piDestFile);
		}
		else dwRetour = ERROR_FILE_NOT_FOUND;

		fclose(piTemplate);
		
		if (dwRetour == ERROR_SUCCESS)
		{
			if (CopyFile(szTempFileName, szaDestFile, FALSE) == FALSE)
				dwRetour = GetLastError();
			DeleteFile(szTempFileName);
		}
	}
	else dwRetour = ERROR_FILE_NOT_FOUND;

	if (dwRetour != ERROR_SUCCESS)
		CUtils::Log("GenerateConfFile %s -> %s return %d", szaTemplateFile, szaDestFile, dwRetour);

	return dwRetour;
}

DWORD GenerateEscConfFile(const char *szaPath, const char *szaTemplateFile, const char *szaDestFile, char caCommentChar)
{
	DWORD dwRetour = ERROR_SUCCESS;
	FILE *piTemplate = NULL;

	if ((piTemplate = fopen(szaTemplateFile, "rt")) !=NULL)
	{
		char szTempFileName[MAX_PATH] = {0};
		FILE *piDestFile = NULL;

		GetTempPath(MAX_PATH, szTempFileName);
		GetTempFileName(szTempFileName, "InstantRails", 0, szTempFileName);

		if ((piDestFile = fopen(szTempFileName, "wt")) != NULL)
		{
			char szMonGrosBuffer[200] = {0};

			if (caCommentChar != '\0') {
	fprintf(piDestFile, "\
%c------------------------- WARNING ! ----------------------\n\
%c         This file is GENERATED by Instant Rails.\n\
%c\n\
%c If you need to make changes to this file, you should edit\n\
%c the source template file instead. The source template is\n\
%c %s\n\
%c-----------------------------------------------------------\n",
			caCommentChar, caCommentChar, caCommentChar, 
			caCommentChar, caCommentChar, caCommentChar, 
			szaTemplateFile, caCommentChar);
			}

			while (fgets(szMonGrosBuffer, sizeof(szMonGrosBuffer)-1, piTemplate))
			{
				char *pciTag = strstr(szMonGrosBuffer, ESC_PATH_TAG);
				if (pciTag)
				{
					*pciTag = '\0';
					fputs(szMonGrosBuffer, piDestFile);
					fputs(szaPath, piDestFile);
					// hacked to allow ${esc-path} to appear in a line twice.
					// should be able to be "n" times, but we'll save
					// that for the rewrite. -- curt
					char *pciTag2 = strstr(pciTag+strlen(ESC_PATH_TAG), ESC_PATH_TAG);
					if (pciTag2) {
						*pciTag2 = '\0';
						fputs(pciTag+strlen(ESC_PATH_TAG), piDestFile);
						fputs(szaPath, piDestFile);
						pciTag = pciTag2;
					}
					fputs(pciTag+strlen(ESC_PATH_TAG), piDestFile);
				}
				else fputs(szMonGrosBuffer, piDestFile);
			}
			fclose(piDestFile);
		}
		else dwRetour = ERROR_FILE_NOT_FOUND;

		fclose(piTemplate);
		
		if (dwRetour == ERROR_SUCCESS)
		{
			if (CopyFile(szTempFileName, szaDestFile, FALSE) == FALSE)
				dwRetour = GetLastError();
			DeleteFile(szTempFileName);
		}
	}
	else dwRetour = ERROR_FILE_NOT_FOUND;

	if (dwRetour != ERROR_SUCCESS)
		CUtils::Log("GenerateConfFile %s -> %s return %d", szaTemplateFile, szaDestFile, dwRetour);

	return dwRetour;
}