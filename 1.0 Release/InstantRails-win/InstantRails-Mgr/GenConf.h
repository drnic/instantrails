
#include <Windows.h>

DWORD RegenerateConfFiles(HWND parent_window);
DWORD GenerateConfFile(const char *szaPath, const char *szaTemplateFile, const char *szaDestFile, char caCommentChar);