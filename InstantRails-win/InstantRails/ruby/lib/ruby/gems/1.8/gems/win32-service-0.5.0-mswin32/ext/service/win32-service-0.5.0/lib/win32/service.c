#include "ruby.h"
#include <windows.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
#include <tchar.h>
#include "service.h"

#ifndef UNICODE
#define UNICODE
#endif

static VALUE cServiceError;
static VALUE cDaemonError;
static VALUE rbServiceStruct, rbServiceStatusStruct;

static HANDLE hStartEvent;
static HANDLE hStopEvent;
static SERVICE_STATUS_HANDLE   ssh;
static DWORD dwServiceState;
static TCHAR error[1024];

static VALUE EventHookHash;

void  WINAPI  Service_Main(DWORD dwArgc, LPTSTR *lpszArgv);
void  WINAPI  Service_Ctrl(DWORD dwCtrlCode);
void  ErrorStopService();
void  SetTheServiceStatus(DWORD dwCurrentState,DWORD dwWin32ExitCode,
                          DWORD dwCheckPoint,  DWORD dwWaitHint);

// Called by the service control manager after the call to
// StartServiceCtrlDispatcher.
void WINAPI Service_Main(DWORD dwArgc, LPTSTR *lpszArgv)
{
   DWORD bRet;
   DWORD dwWaitRes;
   int   i;

   // Obtain the name of the service.
   LPTSTR lpszServiceName = lpszArgv[0];

   // Register the service ctrl handler.
   ssh = RegisterServiceCtrlHandler(lpszServiceName,
           (LPHANDLER_FUNCTION)Service_Ctrl);

   if(ssh == (SERVICE_STATUS_HANDLE)0){
      ErrorStopService();
      rb_raise(cDaemonError,"RegisterServiceCtrlHandler failed");
   }

   // wait for sevice initialization
   for(i=1;TRUE;i++)
   {
    if(WaitForSingleObject(hStartEvent, 1000) == WAIT_OBJECT_0)
        break;

       SetTheServiceStatus(SERVICE_START_PENDING, 0, i, 1000);
   }

   // The service has started.
   SetTheServiceStatus(SERVICE_RUNNING, NO_ERROR, 0, 0);

   // Main loop for the service.
   while(WaitForSingleObject(hStopEvent, 1000) != WAIT_OBJECT_0)
   {
   }

   // Stop the service.
   SetTheServiceStatus(SERVICE_STOPPED, NO_ERROR, 0, 0);
}

// Handles control signals from the service control manager.
void WINAPI Service_Ctrl(DWORD dwCtrlCode)
{
   VALUE func,self,val;
   DWORD dwState = SERVICE_RUNNING;

   val = rb_hash_aref(EventHookHash, INT2NUM(dwCtrlCode));
   if(val!=Qnil) {
     self = RARRAY(val)->ptr[0];
     func = NUM2INT(RARRAY(val)->ptr[1]);
     rb_funcall(self,func,0);
   }

   switch(dwCtrlCode)
   {
      case SERVICE_CONTROL_STOP:
         dwState = SERVICE_STOP_PENDING;
         break;

      case SERVICE_CONTROL_SHUTDOWN:
         dwState = SERVICE_STOP_PENDING;
         break;

      case SERVICE_CONTROL_PAUSE:
         dwState = SERVICE_PAUSED;
        break;

      case SERVICE_CONTROL_CONTINUE:
         dwState = SERVICE_RUNNING;
        break;

      case SERVICE_CONTROL_INTERROGATE:
         break;

      default:
         break;
   }

   // Set the status of the service.
   SetTheServiceStatus(dwState, NO_ERROR, 0, 0);

   // Tell service_main thread to stop.
   if ((dwCtrlCode == SERVICE_CONTROL_STOP) ||
       (dwCtrlCode == SERVICE_CONTROL_SHUTDOWN))
   {
      if (!SetEvent(hStopEvent))
         ErrorStopService();
         // Raise an error here?
   }
}

//  Wraps SetServiceStatus.
void SetTheServiceStatus(DWORD dwCurrentState, DWORD dwWin32ExitCode,
                         DWORD dwCheckPoint,   DWORD dwWaitHint)
{
   SERVICE_STATUS ss;  // Current status of the service.

   // Disable control requests until the service is started.
   if (dwCurrentState == SERVICE_START_PENDING){
      ss.dwControlsAccepted = 0;
   }
   else{
      ss.dwControlsAccepted =
         SERVICE_ACCEPT_STOP|SERVICE_ACCEPT_SHUTDOWN|
         SERVICE_ACCEPT_PAUSE_CONTINUE|SERVICE_ACCEPT_SHUTDOWN;
   }

   // Initialize ss structure.
   ss.dwServiceType             = SERVICE_WIN32_OWN_PROCESS;
   ss.dwServiceSpecificExitCode = 0;
   ss.dwCurrentState            = dwCurrentState;
   ss.dwWin32ExitCode           = dwWin32ExitCode;
   ss.dwCheckPoint              = dwCheckPoint;
   ss.dwWaitHint                = dwWaitHint;

   dwServiceState = dwCurrentState;

   // Send status of the service to the Service Controller.
   if(!SetServiceStatus(ssh, &ss)){
      ErrorStopService();
   }
}

//  Handle API errors or other problems by ending the service
void ErrorStopService(){

   // If you have threads running, tell them to stop. Something went
   // wrong, and you need to stop them so you can inform the SCM.
   SetEvent(hStopEvent);

   // Stop the service.
   SetTheServiceStatus(SERVICE_STOPPED, GetLastError(), 0, 0);
}

DWORD WINAPI ThreadProc(LPVOID lpParameter){
    SERVICE_TABLE_ENTRY ste[] =
      {{TEXT(""),(LPSERVICE_MAIN_FUNCTION)Service_Main}, {NULL, NULL}};

    if (!StartServiceCtrlDispatcher(ste)){
       ErrorStopService();
       strcpy(error,ErrorDescription(GetLastError()));
       rb_raise(cDaemonError,error);
    }

    return 0;
}

static VALUE daemon_allocate(VALUE klass){
   EventHookHash = rb_hash_new();
   return Data_Wrap_Struct(klass, 0, 0, 0);
}

// Enter mainloop
static VALUE
daemon_mainloop(VALUE self)
{
    DWORD ThreadId;
    DWORD dwWaitRes;
    HANDLE hThread;

    dwServiceState = 0;

    // Event hooks
    if(rb_respond_to(self,rb_intern("service_stop"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_STOP),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_stop"))));
    }
    
    if(rb_respond_to(self,rb_intern("service_pause"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_PAUSE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_pause"))));
    }
    
    if(rb_respond_to(self,rb_intern("service_resume"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_CONTINUE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_resume"))));
    }
    
    if(rb_respond_to(self,rb_intern("service_interrogate"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_INTERROGATE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_interrogate"))));
    }
    
    if(rb_respond_to(self,rb_intern("service_shutdown"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_SHUTDOWN),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_shutdown"))));
    }

#ifdef SERVICE_CONTROL_PARAMCHANGE    
    if(rb_respond_to(self,rb_intern("service_paramchange"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_PARAMCHANGE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_paramchange"))));
    }
#endif

#ifdef SERVICE_CONTROL_NETBINDADD    
    if(rb_respond_to(self,rb_intern("service_netbindadd"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_NETBINDADD),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_netbindadd"))));
    }
#endif

#ifdef SERVICE_CONTROL_NETBINDREMOVE    
    if(rb_respond_to(self,rb_intern("service_netbindremove"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_NETBINDREMOVE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_netbindremove"))));
    }
#endif

#ifdef SERVICE_CONTROL_NETBINDENABLE    
    if(rb_respond_to(self,rb_intern("service_netbindenable"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_NETBINDENABLE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_netbindenable"))));
    }
#endif

#ifdef SERVICE_CONTROL_NETBINDDISABLE    
    if(rb_respond_to(self,rb_intern("service_netbinddisable"))){
       rb_hash_aset(EventHookHash,INT2NUM(SERVICE_CONTROL_NETBINDDISABLE),
          rb_ary_new3(2,self,INT2NUM(rb_intern("service_netbinddisable"))));
    }
#endif

    // Create the event to signal the service to start.
    hStartEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if(hStartEvent == NULL){
       strcpy(error,ErrorDescription(GetLastError()));
       ErrorStopService();
       rb_raise(cDaemonError,error);
    }

    // Create the event to signal the service to stop.
    hStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if(hStopEvent == NULL){
       strcpy(error,ErrorDescription(GetLastError()));
       ErrorStopService();
       rb_raise(cDaemonError,error);
    }

    // Create Thread for service main
    hThread = CreateThread(NULL,0,ThreadProc,0,0,&ThreadId);
    if(hThread == INVALID_HANDLE_VALUE){
       strcpy(error,ErrorDescription(GetLastError()));
       ErrorStopService();
       rb_raise(cDaemonError,error);
    }

    if(rb_respond_to(self,rb_intern("service_init"))){
       rb_funcall(self,rb_intern("service_init"),0);
    }

 SetEvent(hStartEvent);

    // Call service_main method
    if(rb_respond_to(self,rb_intern("service_main"))){
       rb_funcall(self,rb_intern("service_main"),0);
    }

    while(WaitForSingleObject(hStopEvent, 1000) != WAIT_OBJECT_0)
    {
    }

    // Close the event handle and the thread handle.
    if(!CloseHandle(hStopEvent)){
       strcpy(error,ErrorDescription(GetLastError()));
       ErrorStopService();
       rb_raise(cDaemonError,error);
    }

    // Wait for Thread service main
    WaitForSingleObject(hThread, INFINITE);

    return self;
}

static VALUE daemon_state(VALUE self){
   return UINT2NUM(dwServiceState);
}

static VALUE service_allocate(VALUE klass){
   SvcStruct* ptr = malloc(sizeof(SvcStruct));
   return Data_Wrap_Struct(klass,0,service_free,ptr);
}

static VALUE service_init(int argc, VALUE *argv, VALUE self){
   VALUE rbMachineName, rbDesiredAccess, tdata;
   TCHAR* lpMachineName;
   DWORD dwDesiredAccess;
   SvcStruct* ptr;
   
   Data_Get_Struct(self,SvcStruct,ptr);

   rb_scan_args(argc, argv, "02", &rbMachineName, &rbDesiredAccess);

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   if(NIL_P(rbDesiredAccess)){
      dwDesiredAccess = SC_MANAGER_CREATE_SERVICE;
   }
   else{
      dwDesiredAccess = NUM2INT(rbDesiredAccess);
   }

   ptr->hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      dwDesiredAccess
   );

   if(!ptr->hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   rb_iv_set(self, "@machine_name", rbMachineName);
   rb_iv_set(self, "@desired_access", rbDesiredAccess);
   rb_iv_set(self, "@service_type",
      INT2FIX(SERVICE_WIN32_OWN_PROCESS | SERVICE_INTERACTIVE_PROCESS));

   rb_iv_set(self, "@start_type", INT2FIX(SERVICE_DEMAND_START));
   rb_iv_set(self, "@error_control", INT2FIX(SERVICE_ERROR_NORMAL));
   
   return self;
}

/*
 * call-seq:
 *    Service#close
 *
 * Closes the service handle.  This is the polite way to do things, although
 * the service handle should automatically be closed when it goes out of
 * scope.
 */
static VALUE service_close(VALUE self){
   SvcStruct* ptr;
   int rv;

   Data_Get_Struct(self,SvcStruct,ptr);

   rv = CloseServiceHandle(ptr->hSCManager);
   
   if(ptr->hSCManager){
      if(0 == rv){
         rb_raise(cServiceError,ErrorDescription(GetLastError()));
      }
   }
   
   return self;
}

/*
 * call-seq:
 *    Service#configure_service{ |service| ... }
 * 
 * Configures the service object.  Valid methods for the service object are
 * as follows:
 *
 * * desired_access= 
 * * service_name=
 * * display_name=
 * * service_type=
 * * start_type=
 * * error_control=
 * * tag_id=   
 * * binary_path_name= 
 * * load_order_group= 
 * * start_name= 
 * * password=
 * * dependencies=
 * * service_description=
 *   
 * See the docs for individual instance methods for more details.
 */
static VALUE service_configure(VALUE self){
   SvcStruct* ptr;
   SC_HANDLE hSCService;
   DWORD dwDesiredAccess, dwServiceType, dwStartType, dwErrorControl;
   TCHAR* lpServiceName;
   TCHAR* lpDisplayName;
   TCHAR* lpBinaryPathName;
   TCHAR* lpLoadOrderGroup;
   TCHAR* lpServiceStartName;
   TCHAR* lpPassword;
   TCHAR** lpDependencies = malloc(sizeof(TCHAR*));
   int rv;

   Data_Get_Struct(self,SvcStruct,ptr);

   if(rb_block_given_p())
      rb_yield(self);

   if(NIL_P(rb_iv_get(self, "@service_name"))){
      rb_raise(cServiceError, "No service name specified");
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@service_name");
      lpServiceName = TEXT(StringValuePtr(rbTmp));
   }

   hSCService = OpenService(
      ptr->hSCManager,
      lpServiceName,
      SERVICE_CHANGE_CONFIG
   );

   if(!hSCService)
      rb_raise(cServiceError, ErrorDescription(GetLastError()));

   if(NIL_P(rb_iv_get(self, "@service_type"))){
      dwServiceType = SERVICE_NO_CHANGE;
   }
   else{
      dwServiceType = NUM2INT(rb_iv_get(self,"@service_type"));
   }

   if(NIL_P(rb_iv_get(self, "@start_type"))){
      dwStartType = SERVICE_NO_CHANGE;
   }
   else{
      dwStartType = NUM2INT(rb_iv_get(self, "@start_type"));
   }

   if(NIL_P(rb_iv_get(self, "@error_control"))){
      dwErrorControl = SERVICE_NO_CHANGE;
   }
   else{
      dwErrorControl = NUM2INT(rb_iv_get(self, "@error_control"));
   }

   if(NIL_P(rb_iv_get(self, "@binary_path_name"))){
      lpBinaryPathName = NULL;
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@binary_path_name");
      lpBinaryPathName = TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@load_order_group"))){
      lpLoadOrderGroup = NULL;
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@load_order_group");
      lpLoadOrderGroup = TEXT(StringValuePtr(rbTmp));
   }

   // There are 3 possibilities for dependencies - Some, none, or unchanged
   // null = don't change
   // empty array = no dependencies (deletes any existing dependencies)
   // array = sets dependencies (deletes any existing dependencies)
   if(NIL_P(rb_iv_get(self, "@dependencies"))){
      lpDependencies[0] = NULL;
   }
   else{
      int i;
      VALUE rbDepArray = rb_iv_get(self, "@dependencies");

      if(0 == RARRAY(rbDepArray)->len){
         lpDependencies[0] = TEXT("");
      }
      else{
         lpDependencies =
            malloc(RARRAY(rbDepArray)->len * sizeof(*lpDependencies));

         for(i = 0; i < RARRAY(rbDepArray)->len; i++){
            VALUE rbTmp = rb_ary_entry(rbDepArray,i);
            TCHAR* string = TEXT(StringValuePtr(rbTmp));
            lpDependencies[i] = malloc(*string);
            lpDependencies[i] = string;
         }
      }
   }

   if(NIL_P(rb_iv_get(self, "@start_name"))){
      lpServiceStartName = NULL;
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@start_name");
      lpServiceStartName = TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@password"))){
      lpPassword = NULL;
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@password");
      lpPassword = TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@display_name"))){
      lpDisplayName = NULL;
   }
   else{
      VALUE rbTmp = rb_iv_get(self, "@display_name");
      lpDisplayName = TEXT(StringValuePtr(rbTmp));
   }

   rv = ChangeServiceConfig(
      hSCService,
      dwServiceType,
      dwStartType,
      dwErrorControl,
      lpBinaryPathName,
      lpLoadOrderGroup,
      NULL, // TagID
      *lpDependencies,
      lpServiceStartName,
      lpPassword,
      lpDisplayName
   );

   if(lpDependencies)
      free(lpDependencies);

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCService);
      rb_raise(cServiceError,error);
   }
   
   if(!NIL_P(rb_iv_get(self, "@service_description"))){
      TCHAR* lpDescription;
      SERVICE_DESCRIPTION servDesc;
      VALUE rbDesc = rb_iv_get(self, "@service_description");
      
      servDesc.lpDescription = TEXT(StringValuePtr(rbDesc));
      
      if(!ChangeServiceConfig2(
         hSCService,
         SERVICE_CONFIG_DESCRIPTION,
         &servDesc
      )){
         rb_raise(cServiceError,ErrorDescription(GetLastError()));
      }
   }

   CloseServiceHandle(hSCService);

   return self;
}

/*
 * call-seq:
 *    Service#create_service{ |service| ... }
 * 
 * Creates the specified service.  In order for this to work, the
 * 'service_name' and 'binary_path_name' attributes must be defined
 * or ServiceError will be raised.
    
 * See the Service#configure_service method for a list of valid methods to
 * pass to the service object.  See the individual methods for more
 * information, including default values.
*/
static VALUE service_create(VALUE self){
   VALUE rbTmp;
   SvcStruct* ptr;
   SC_HANDLE hSCService;
   DWORD dwDesiredAccess, dwServiceType, dwStartType, dwErrorControl;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   TCHAR* lpDisplayName;
   TCHAR* lpBinaryPathName;
   TCHAR* lpLoadOrderGroup;
   TCHAR* lpServiceStartName;
   TCHAR* lpPassword;
   TCHAR** lpDependencies = malloc(sizeof(TCHAR*));

   if(rb_block_given_p())
      rb_yield(self);

   Data_Get_Struct(self,SvcStruct,ptr);

   // The service name and exe name must be set to create a service
   if(NIL_P(rb_iv_get(self, "@service_name")))
      rb_raise(cServiceError, "Service Name must be defined");

   if(NIL_P(rb_iv_get(self, "@binary_path_name")))
      rb_raise(cServiceError, "Executable Name must be defined");

   // If the display name is not set, set it to the same as the service name
   if(NIL_P(rb_iv_get(self, "@display_name")))
      rb_iv_set(self,"@display_name", rb_iv_get(self,"@service_name"));

   rbTmp = rb_iv_get(self, "@service_name");
   lpServiceName = TEXT(StringValuePtr(rbTmp));
   
   rbTmp = rb_iv_get(self, "@display_name");
   lpDisplayName = TEXT(StringValuePtr(rbTmp));
   
   rbTmp = rb_iv_get(self, "@binary_path_name");
   lpBinaryPathName = TEXT(StringValuePtr(rbTmp));

   if(NIL_P(rb_iv_get(self, "@machine_name"))){
      lpMachineName = NULL;
   }
   else{
      rbTmp = rb_iv_get(self, "@machine_name");
      lpMachineName = TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@load_order_group"))){
      lpLoadOrderGroup = NULL;
   }
   else{
      rbTmp = rb_iv_get(self, "@load_order_group");
      lpLoadOrderGroup = TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@start_name"))){
      lpServiceStartName = NULL;
   }
   else{
      rbTmp = rb_iv_get(self,"@start_name");
      lpServiceStartName =
         TEXT(StringValuePtr(rbTmp));
   }

   if(NIL_P(rb_iv_get(self, "@password"))){
      lpPassword = NULL;
   }
   else{
      rbTmp = rb_iv_get(self,"@password");
      lpPassword = TEXT(StringValuePtr(rbTmp));
   }

   // There are 3 possibilities for dependencies - Some, none, or unchanged
   // null = don't change
   // empty array = no dependencies (deletes any existing dependencies)
   // array = sets dependencies (deletes any existing dependencies)
   if(NIL_P(rb_iv_get(self, "@dependencies"))){
      lpDependencies[0] = NULL;
   }
   else{
      int i;
      VALUE rbDepArray = rb_iv_get(self, "@dependencies");

      if(0 == RARRAY(rbDepArray)->len){
         lpDependencies[0] = TEXT("");
      }
      else{
         lpDependencies =
            malloc(RARRAY(rbDepArray)->len * sizeof(*lpDependencies));

         for(i = 0; i < RARRAY(rbDepArray)->len; i++){
            VALUE rbTmp = rb_ary_entry(rbDepArray,i);
            TCHAR* string = TEXT(StringValuePtr(rbTmp));
            lpDependencies[i] = malloc(*string);
            lpDependencies[i] = string;
         }
      }
   }

   if(NIL_P(rb_iv_get(self, "@desired_access"))){
      dwDesiredAccess = SERVICE_ALL_ACCESS;
   }
   else{
      dwDesiredAccess = NUM2INT(rb_iv_get(self, "@desired_access"));
   }

   if(NIL_P(rb_iv_get(self,"@service_type"))){
      dwServiceType = SERVICE_WIN32_OWN_PROCESS | SERVICE_INTERACTIVE_PROCESS;
   }
   else{
      dwServiceType = NUM2INT(rb_iv_get(self, "@service_type"));
   }

   if(NIL_P(rb_iv_get(self,"@start_type"))){
      dwStartType = SERVICE_DEMAND_START;
   }
   else{
      dwStartType = NUM2INT(rb_iv_get(self, "@start_type"));
   }

   if(NIL_P(rb_iv_get(self, "@error_control"))){
      dwErrorControl = SERVICE_ERROR_NORMAL;
   }
   else{
      dwErrorControl = NUM2INT(rb_iv_get(self, "@error_control"));
   }

   // Add support for tag id and dependencies
   hSCService = CreateService(
      ptr->hSCManager,
      lpServiceName,
      lpDisplayName,
      dwDesiredAccess,
      dwServiceType,
      dwStartType,
      dwErrorControl,
      lpBinaryPathName,
      lpLoadOrderGroup,
      NULL,                                              // Tag ID
      *lpDependencies,
      lpServiceStartName,
      lpPassword
   );
   
   if(lpDependencies)
      free(lpDependencies);

   if(!hSCService)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));
      
   // Set the description after the fact if specified, since we can't set it
   // in CreateService().   
   if(!NIL_P(rb_iv_get(self, "@service_description"))){
      TCHAR* lpDescription;
      SERVICE_DESCRIPTION servDesc;
      VALUE rbDesc = rb_iv_get(self, "@service_description");
      
      servDesc.lpDescription = TEXT(StringValuePtr(rbDesc));
      
      if(!ChangeServiceConfig2(
         hSCService,
         SERVICE_CONFIG_DESCRIPTION,
         &servDesc
      )){
         rb_raise(cServiceError,ErrorDescription(GetLastError()));
      }
   }

   CloseServiceHandle(hSCService);
   return self;
}

// CLASS METHODS

/*
 * call-seq:
 *    Service.delete(name, host=localhost)
 * 
 * Deletes the service +name+ from +host+, or the localhost if none is
 * provided.
 */
static VALUE service_delete(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   VALUE rbServiceName, rbMachineName;

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);

   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));
   
   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CREATE_SERVICE
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      DELETE
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   if(!DeleteService(hSCService)){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCService);
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);

   return klass;
}

/*
 * call-seq:
 *    Service.services(host=nil, group=nil){ |struct| ... }
 * 
 * Enumerates over a list of service types on host, or the local
 * machine if no host is specified, yielding a Win32Service struct for each
 * service.
 *   
 * If a 'group' is specified, then only those services that belong to
 * that group are enumerated.  If an empty string is provided, then only
 * services that do not belong to any group are enumerated. If this parameter
 * is nil, group membership is ignored and all services are enumerated.
 * 
 * The 'group' option is only available on Windows 2000 or later, and only
 * if compiled with VC++ 7.0 or later, or the .NET SDK.
 *
 * The Win32 service struct contains the following members.
 *  
 * * service_name
 * * display_name
 * * service_type
 * * current_state
 * * controls_accepted
 * * win32_exit_code
 * * service_specific_exit_code
 * * check_point
 * * wait_hint
 * * binary_path_name
 * * start_type
 * * error_control
 * * load_order_group
 * * tag_id
 * * start_name
 * * dependencies
 * * description
 * * interactive?
 * * pid           (Win2k or later)
 * * service_flags (Win2k or later)
*/
static VALUE services(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager = NULL;
   SC_HANDLE hSCService = NULL;
   DWORD dwBytesNeeded = 0;
   DWORD dwServicesReturned = 0;
   DWORD dwResumeHandle = 0;
   LPQUERY_SERVICE_CONFIG lpqscConf;
   LPSERVICE_DESCRIPTION lpqscDesc;
   TCHAR* lpMachineName;
   TCHAR* pszGroupName;
   VALUE rbMachineName = Qnil;
   VALUE rbDependencies = Qnil;
   VALUE rbGroup = Qnil;
   VALUE rbStruct;
   VALUE rbArray = Qnil;
   int rv = 0;
   unsigned i;  

#ifdef HAVE_ENUMSERVICESSTATUSEX
   ENUM_SERVICE_STATUS_PROCESS svcArray[MAX_SERVICES];
   rb_scan_args(argc, argv, "02", &rbMachineName, &rbGroup);  
#else   
   ENUM_SERVICE_STATUS svcArray[MAX_SERVICES];
   rb_scan_args(argc, argv, "01", &rbMachineName);
#endif

   // If no block is provided, return an array of struct's.
   if(!rb_block_given_p())
      rbArray = rb_ary_new();

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }
   
   if(NIL_P(rbGroup)){
      pszGroupName = NULL;
   }
   else{
      SafeStringValue(rbGroup);
      pszGroupName = TEXT(StringValuePtr(rbGroup));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_ENUMERATE_SERVICE
   );

   if(NULL == hSCManager){
      sprintf(error,"OpenSCManager() call failed: %s",
         ErrorDescription(GetLastError()));
      rb_raise(cServiceError,error);
   }

   lpqscConf = (LPQUERY_SERVICE_CONFIG) LocalAlloc(LPTR, MAX_BUF_SIZE);
   lpqscDesc = (LPSERVICE_DESCRIPTION) LocalAlloc(LPTR, MAX_BUF_SIZE);

#ifdef HAVE_ENUMSERVICESSTATUSEX
   rv = EnumServicesStatusEx(
      hSCManager,                       // SC Manager
      SC_ENUM_PROCESS_INFO,             // Info level (only possible value)
      SERVICE_WIN32 | SERVICE_DRIVER,   // Service type
      SERVICE_STATE_ALL,                // Service state
      (LPBYTE)svcArray,                 // Array of structs
      sizeof(svcArray),
      &dwBytesNeeded,
      &dwServicesReturned,
      &dwResumeHandle,
      pszGroupName
   );
#else
   rv = EnumServicesStatus(
      hSCManager,                       // SC Manager
      SERVICE_WIN32 | SERVICE_DRIVER,   // Service type
      SERVICE_STATE_ALL,                // Service state
      svcArray,                         // Array of structs
      sizeof(svcArray),
      &dwBytesNeeded,
      &dwServicesReturned,
      &dwResumeHandle
   );
#endif

   if(rv != 0)
   {
      unsigned i;
      int rv;
      VALUE rbServiceType, rbCurrentState, rbControlsAccepted;
      VALUE rbBinaryPathName, rbStartType, rbErrorControl, rbLoadOrderGroup;
      VALUE rbServiceStartName, rbDescription, rbInteractive;

      for(i = 0; i < dwServicesReturned; i++){
         DWORD dwBytesNeeded;
         rbControlsAccepted = rb_ary_new();
         rbInteractive = Qfalse;

         hSCService = OpenService(
            hSCManager,
            svcArray[i].lpServiceName,
            SERVICE_QUERY_CONFIG
         );

         if(!hSCService){
            sprintf(error,"OpenService() call failed: %s",
               ErrorDescription(GetLastError()));
            CloseServiceHandle(hSCManager);
            rb_raise(cServiceError,error);
         }

         // Retrieve a QUERY_SERVICE_CONFIG structure for the Service, from
         // which we can gather the service type, start type, etc.
         rv = QueryServiceConfig(
            hSCService,
            lpqscConf,
            MAX_BUF_SIZE,
            &dwBytesNeeded
         );

         if(0 == rv){
            sprintf(error,"QueryServiceConfig() call failed: %s",
               ErrorDescription(GetLastError()));
            CloseServiceHandle(hSCManager);
            rb_raise(cServiceError,error);
         }

         // Get the description for the Service
         rv = QueryServiceConfig2(
            hSCService,
            SERVICE_CONFIG_DESCRIPTION,
            (LPBYTE)lpqscDesc,
            MAX_BUF_SIZE,
            &dwBytesNeeded
         );

         if(0 == rv){
            sprintf(error,"QueryServiceConfig2() call failed: %s",
               ErrorDescription(GetLastError()));
            CloseServiceHandle(hSCManager);
            rb_raise(cServiceError,error);
         }

#ifdef HAVE_ENUMSERVICESSTATUSEX
         if(svcArray[i].ServiceStatusProcess.dwServiceType
            & SERVICE_INTERACTIVE_PROCESS){
            rbInteractive = Qtrue;
         }
#else
         if(svcArray[i].ServiceStatus.dwServiceType
            & SERVICE_INTERACTIVE_PROCESS){
            rbInteractive = Qtrue;
         }
#endif

#ifdef HAVE_ENUMSERVICESSTATUSEX
         rbServiceType =
            rb_get_service_type(svcArray[i].ServiceStatusProcess.dwServiceType);

         rbCurrentState =
            rb_get_current_state(
               svcArray[i].ServiceStatusProcess.dwCurrentState);

         rbControlsAccepted =
            rb_get_controls_accepted(
               svcArray[i].ServiceStatusProcess.dwControlsAccepted);
#else
         rbServiceType =
            rb_get_service_type(svcArray[i].ServiceStatus.dwServiceType);

         rbCurrentState =
            rb_get_current_state(svcArray[i].ServiceStatus.dwCurrentState);

         rbControlsAccepted =
            rb_get_controls_accepted(
               svcArray[i].ServiceStatus.dwControlsAccepted);
#endif

         if(strlen(lpqscConf->lpBinaryPathName) > 0){
            rbBinaryPathName = rb_str_new2(lpqscConf->lpBinaryPathName);
         }
         else{
            rbBinaryPathName = Qnil;
         }

         if(strlen(lpqscConf->lpLoadOrderGroup) > 0){
            rbLoadOrderGroup = rb_str_new2(lpqscConf->lpLoadOrderGroup);
         }
         else{
            rbLoadOrderGroup = Qnil;
         }

         if(strlen(lpqscConf->lpServiceStartName) > 0){
            rbServiceStartName = rb_str_new2(lpqscConf->lpServiceStartName);
         }
         else{
            rbServiceStartName = Qnil;
         }

         if(lpqscDesc->lpDescription != NULL){
            rbDescription = rb_str_new2(lpqscDesc->lpDescription);
         }
         else{
            rbDescription = Qnil;
         }

         switch(lpqscConf->dwStartType)
         {
            case SERVICE_AUTO_START:
               rbStartType = rb_str_new2("auto start");
               break;
            case SERVICE_BOOT_START:
               rbStartType = rb_str_new2("boot start");
               break;
            case SERVICE_DEMAND_START:
               rbStartType = rb_str_new2("demand start");
               break;
            case SERVICE_DISABLED:
               rbStartType = rb_str_new2("disabled");
               break;
            case SERVICE_SYSTEM_START:
               rbStartType = rb_str_new2("system start");
               break;
            default:
               rbStartType = Qnil;
         }

         switch(lpqscConf->dwErrorControl)
         {
            case SERVICE_ERROR_IGNORE:
               rbErrorControl = rb_str_new2("ignore");
               break;
            case SERVICE_ERROR_NORMAL:
               rbErrorControl = rb_str_new2("normal");
               break;
            case SERVICE_ERROR_SEVERE:
               rbErrorControl = rb_str_new2("severe");
               break;
            case SERVICE_ERROR_CRITICAL:
               rbErrorControl = rb_str_new2("critical");
               break;
            default:
               rbErrorControl = Qnil;
         }

         if(lpqscConf->lpDependencies)
         {
            TCHAR* pszDepend = 0;
            int i = 0;
            pszDepend = &lpqscConf->lpDependencies[i];
            rbDependencies = rb_ary_new();
            while(*pszDepend != 0){
               rb_ary_push(rbDependencies,rb_str_new2(pszDepend));
               i += _tcslen(pszDepend) + 1;
               pszDepend = &lpqscConf->lpDependencies[i];
            }
            if(RARRAY(rbDependencies)->len == 0){
               rbDependencies = Qnil;
            }
         }

         CloseServiceHandle(hSCService);

#ifdef HAVE_ENUMSERVICESSTATUSEX
         rbStruct = rb_struct_new(rbServiceStruct,
            rb_str_new2(svcArray[i].lpServiceName),
            rb_str_new2(svcArray[i].lpDisplayName),
            rbServiceType,
            rbCurrentState,
            rbControlsAccepted,
            INT2FIX(svcArray[i].ServiceStatusProcess.dwWin32ExitCode),
            INT2FIX(svcArray[i].ServiceStatusProcess.dwServiceSpecificExitCode),
            INT2FIX(svcArray[i].ServiceStatusProcess.dwCheckPoint),
            INT2FIX(svcArray[i].ServiceStatusProcess.dwWaitHint),
            rbBinaryPathName,
            rbStartType,
            rbErrorControl,
            rbLoadOrderGroup,
            INT2FIX(lpqscConf->dwTagId),
            rbServiceStartName,
            rbDependencies,
            rbDescription,
            rbInteractive,
            INT2FIX(svcArray[i].ServiceStatusProcess.dwProcessId),
            INT2FIX(svcArray[i].ServiceStatusProcess.dwServiceFlags)
         );
#else
         rbStruct = rb_struct_new(rbServiceStruct,
            rb_str_new2(svcArray[i].lpServiceName),
            rb_str_new2(svcArray[i].lpDisplayName),
            rbServiceType,
            rbCurrentState,
            rbControlsAccepted,
            INT2FIX(svcArray[i].ServiceStatus.dwWin32ExitCode),
            INT2FIX(svcArray[i].ServiceStatus.dwServiceSpecificExitCode),
            INT2FIX(svcArray[i].ServiceStatus.dwCheckPoint),
            INT2FIX(svcArray[i].ServiceStatus.dwWaitHint),
            rbBinaryPathName,
            rbStartType,
            rbErrorControl,
            rbLoadOrderGroup,
            INT2FIX(lpqscConf->dwTagId),
            rbServiceStartName,
            rbDependencies,
            rbDescription,
            rbInteractive
         );
#endif
         if(rb_block_given_p()){
            rb_yield(rbStruct);
         }
         else{
            rb_ary_push(rbArray, rbStruct);
         }
      }
   }
   else{
      sprintf(error,"EnumServiceStatus() call failed: %s",
         ErrorDescription(GetLastError()));
      LocalFree(lpqscConf);
      LocalFree(lpqscDesc);
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   LocalFree(lpqscConf);
   LocalFree(lpqscDesc);
   CloseServiceHandle(hSCManager);
   return rbArray; // Nil if a block was given
}

/*
 * call-seq:
 *    Service.stop(name, host=localhost)
 * 
 * Stop a service.  Attempting to stop an already stopped service raises
 * a ServiceError.
 */
static VALUE service_stop(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   SERVICE_STATUS serviceStatus;
   VALUE rbServiceName, rbMachineName;
   int rv;

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);

   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_STOP
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }
   
   rv = ControlService(
      hSCService,
      SERVICE_CONTROL_STOP,
      &serviceStatus
   );

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCService);
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);

   return klass;
}

/*
 * call-seq:
 *    Service.pause(name, host=localhost)
 * 
 * Pause a service.  Attempting to pause an already paused service will raise
 * a ServiceError.
 * 
 * Note that not all services are configured to accept a pause (or resume)
 * command.
 */
static VALUE service_pause(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   SERVICE_STATUS serviceStatus;
   VALUE rbServiceName, rbMachineName;
   int rv;

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);

   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_PAUSE_CONTINUE
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   rv = ControlService(
      hSCService,
      SERVICE_CONTROL_PAUSE,
      &serviceStatus
   );

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCService);
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);

   return klass;
}

/*
 * call-seq:
 *    Service.resume(name, host=localhost)
 * 
 * Resume a service.  Attempting to resume a service that isn't paused will
 * raise a ServiceError.
 * 
 * Note that not all services are configured to accept a resume (or pause)
 * command.  In that case, a ServiceError will be raised.
 */
static VALUE service_resume(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   SERVICE_STATUS serviceStatus;
   VALUE rbServiceName, rbMachineName;
   int rv;

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);

   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }
   
   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager){
      rb_raise(cServiceError,ErrorDescription(GetLastError()));
   }

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_PAUSE_CONTINUE
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   rv = ControlService(
      hSCService,
      SERVICE_CONTROL_CONTINUE,
      &serviceStatus
   );

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCService);
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);

   return klass;
}

/*
 * call-seq:
 *    Service.start(name, host=localhost, args=nil)
 * 
 * Attempts to start service +name+ on +host+, or the local machine if no
 * host is provided.  If +args+ are provided, they are passed to the service's
 * Service_Main() function.
 * 
 *-- Note that the WMI interface does not allow you to pass arguments to the
 *-- Service_Main function.
 */
static VALUE service_start(int argc, VALUE *argv, VALUE klass){
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   TCHAR** lpServiceArgVectors;
   VALUE rbServiceName, rbMachineName, rbArgs;
   int rv;

   rb_scan_args(argc, argv, "11*", &rbServiceName, &rbMachineName, &rbArgs);

   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }
   
   if( (NIL_P(rbArgs)) || (RARRAY(rbArgs)->len == 0) ){
      lpServiceArgVectors = NULL;
   }
   else{
      int i;
      lpServiceArgVectors =
         malloc(RARRAY(rbArgs)->len * sizeof(*lpServiceArgVectors));

      for(i = 0; i < RARRAY(rbArgs)->len; i++){
         VALUE rbTmp = rb_ary_entry(rbArgs, i);
         TCHAR* string = TEXT(StringValuePtr(rbTmp));
         lpServiceArgVectors[i] = malloc(*string);
         lpServiceArgVectors[i] = string;
      }
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_START
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

   rv = StartService(
      hSCService,
      0,
      lpServiceArgVectors
   );
   
   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      CloseServiceHandle(hSCService);
      if(lpServiceArgVectors){
         free(lpServiceArgVectors);
      }
      rb_raise(cServiceError,error);
   }

   CloseServiceHandle(hSCManager);
   CloseServiceHandle(hSCService);
   
   if(lpServiceArgVectors)
      free(lpServiceArgVectors);

   return klass;
}

/*
 * call-seq:
 *    Service.getservicename(display_name, host=localhost)
 * 
 * Returns the service name for the corresponding +display_name+ on +host+, or
 * the local machine if no host is specified.
 */
static VALUE service_get_service_name(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager;
   TCHAR* lpMachineName;
   TCHAR* lpDisplayName;
   TCHAR szRegKey[MAX_PATH];
   DWORD dwKeySize = sizeof(szRegKey);
   VALUE rbMachineName, rbDisplayName;
   int rv;

   rb_scan_args(argc, argv, "11", &rbDisplayName, &rbMachineName);
   
   SafeStringValue(rbDisplayName);
   lpDisplayName = TEXT(StringValuePtr(rbDisplayName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager)
      rb_raise(rb_eArgError,ErrorDescription(GetLastError()));

   rv = GetServiceKeyName(
      hSCManager,
      lpDisplayName,
      szRegKey,
      &dwKeySize
   );

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(rb_eArgError,error);
   }

   CloseServiceHandle(hSCManager);

   return rb_str_new2(szRegKey);
}

/*
 * call-seq:
 *    Service.getdisplayname(service_name, host=localhost)
 * 
 * Returns the display name for the service +service_name+ on +host+, or the
 * localhost if no host is specified.
 */
static VALUE service_get_display_name(int argc, VALUE *argv, VALUE klass)
{
   SC_HANDLE hSCManager;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   TCHAR szRegKey[MAX_PATH];
   DWORD dwKeySize = sizeof(szRegKey);
   VALUE rbMachineName, rbServiceName;
   int rv;

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);
   
   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));

   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_CONNECT
   );

   if(!hSCManager)
      rb_raise(rb_eArgError,ErrorDescription(GetLastError()));

   rv = GetServiceDisplayName(
      hSCManager,
      lpServiceName,
      szRegKey,
      &dwKeySize
   );

   if(0 == rv){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(rb_eArgError,error);
   }

   CloseServiceHandle(hSCManager);

   return rb_str_new2(szRegKey);
}

// The only instance method where I do type checking
static VALUE service_set_dependencies(VALUE self,VALUE array)
{
   Check_Type(array,T_ARRAY);
   rb_iv_set(self,"@dependencies",array);
   return self;
}

static VALUE service_get_dependencies(VALUE self){
   return rb_iv_get(self,"@dependencies");
}

/*
 * call-seq:
 *    Service.status(name, host=localhost)
 * 
 * Returns a ServiceStatus struct indicating the status of service +name+ on
 * +host+, or the localhost if none is provided.
 * 
 * The ServiceStatus struct contains the following members:
 * 
 * * service_type
 * * current_state
 * * controls_accepted
 * * win32_exit_code
 * * service_specific_exit_code
 * * check_point
 * * wait_hint
 * * pid (Win2k or later)
 * * service_flags (Win2k or later)
 */
static VALUE service_status(int argc, VALUE *argv, VALUE klass){
   SC_HANDLE hSCManager, hSCService;
   VALUE rbServiceName, rbMachineName, rbStatus;
   VALUE rbServiceType, rbCurrentState, rbControlsAccepted, rbExitCode;
   VALUE rbSpecificExitCode, rbCheckPoint, rbWaitHint;
   VALUE rbInteractive = Qfalse;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   DWORD dwBytesNeeded;
   int rv;
   
#ifdef HAVE_QUERYSERVICESTATUSEX
   SERVICE_STATUS_PROCESS ssProcess;
   VALUE rbPID, rbServiceFlags;
#else
   SERVICE_STATUS ssProcess;
#endif

   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);
  
   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));
   
   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_ENUMERATE_SERVICE
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_QUERY_STATUS
   );

   if(!hSCService){
      strcpy(error,ErrorDescription(GetLastError()));
      CloseServiceHandle(hSCManager);
      rb_raise(cServiceError,error);
   }

#ifdef HAVE_QUERYSERVICESTATUSEX
   rv = QueryServiceStatusEx(
      hSCService,
      SC_STATUS_PROCESS_INFO,
      (LPBYTE)&ssProcess,
      sizeof(SERVICE_STATUS_PROCESS),
      &dwBytesNeeded
   );
#else
   rv = QueryServiceStatus(
      hSCService,
      &ssProcess
   );
#endif

   rbServiceType = rb_get_service_type(ssProcess.dwServiceType);
   rbCurrentState = rb_get_current_state(ssProcess.dwCurrentState);
   rbControlsAccepted = rb_get_controls_accepted(ssProcess.dwControlsAccepted);

   if(ssProcess.dwServiceType & SERVICE_INTERACTIVE_PROCESS){
      rbInteractive = Qtrue;
   }

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);

   return rb_struct_new(rbServiceStatusStruct,
      rbServiceType,
      rbCurrentState,
      rbControlsAccepted,
      INT2FIX(ssProcess.dwWin32ExitCode),
      INT2FIX(ssProcess.dwServiceSpecificExitCode),
      INT2FIX(ssProcess.dwCheckPoint),
      INT2FIX(ssProcess.dwWaitHint),
      rbInteractive
#ifdef HAVE_QUERYSERVICESTATUSEX
      ,INT2FIX(ssProcess.dwProcessId)
      ,INT2FIX(ssProcess.dwServiceFlags)
#endif
   );
}

/* call-seq:
 *    Service.exists?(name, host=localhost)
 * 
 * Returns whether or not the service +name+ exists on +host+, or the localhost
 * if none is provided.
 */
static VALUE service_exists(int argc, VALUE *argv, VALUE klass){
   SC_HANDLE hSCManager, hSCService;
   TCHAR* lpMachineName;
   TCHAR* lpServiceName;
   VALUE rbServiceName, rbMachineName;
   VALUE rbExists = Qtrue;
   
   rb_scan_args(argc, argv, "11", &rbServiceName, &rbMachineName);
   
   SafeStringValue(rbServiceName);
   lpServiceName = TEXT(StringValuePtr(rbServiceName));
   
   if(NIL_P(rbMachineName)){
      lpMachineName = NULL;
   }
   else{
      SafeStringValue(rbMachineName);
      lpMachineName = TEXT(StringValuePtr(rbMachineName));
   }

   hSCManager = OpenSCManager(
      lpMachineName,
      NULL,
      SC_MANAGER_ENUMERATE_SERVICE
   );

   if(!hSCManager)
      rb_raise(cServiceError,ErrorDescription(GetLastError()));

   hSCService = OpenService(
      hSCManager,
      lpServiceName,
      SERVICE_QUERY_STATUS
   );

   if(!hSCService)
      rbExists = Qfalse;

   CloseServiceHandle(hSCService);
   CloseServiceHandle(hSCManager);
   
   return rbExists;
}

void Init_service()
{
   VALUE mWin32, cService, cDaemon;
   int i = 0;

   // Modules and classes
   mWin32   = rb_define_module("Win32");
   cService = rb_define_class_under(mWin32, "Service", rb_cObject);
   cDaemon  = rb_define_class_under(mWin32, "Daemon", rb_cObject);
   cServiceError = rb_define_class_under(
      mWin32,"ServiceError",rb_eStandardError);
   cDaemonError = rb_define_class_under(
      mWin32,"DaemonError",rb_eStandardError);

   // Service class and instance methods 
   rb_define_alloc_func(cService,service_allocate);
   rb_define_method(cService,"initialize",service_init,-1);
   rb_define_method(cService,"close",service_close,0);
   rb_define_method(cService,"create_service",service_create,0);
   rb_define_method(cService,"configure_service",service_configure,0);

   // We do type checking for these two methods, so they're defined
   // indepedently.
   rb_define_method(cService,"dependencies=",service_set_dependencies,1);
   rb_define_method(cService,"dependencies",service_get_dependencies,0);

   rb_define_singleton_method(cService,"delete",service_delete,-1);
   rb_define_singleton_method(cService,"start",service_start,-1);
   rb_define_singleton_method(cService,"stop",service_stop,-1);
   rb_define_singleton_method(cService,"pause",service_pause,-1);
   rb_define_singleton_method(cService,"resume",service_resume,-1);
   rb_define_singleton_method(cService,"services",services,-1);
   rb_define_singleton_method(cService,"status",service_status,-1);
   rb_define_singleton_method(cService,"exists?",service_exists,-1);

   rb_define_singleton_method(cService,"getdisplayname",
      service_get_display_name,-1);

   rb_define_singleton_method(cService,"getservicename",
      service_get_service_name,-1);

   // Daemon class and instance methods
   rb_define_alloc_func(cDaemon, daemon_allocate);
   rb_define_method(cDaemon, "mainloop", daemon_mainloop, 0);
   rb_define_method(cDaemon, "state", daemon_state, 0);

   // Constants
   rb_define_const(cService,"VERSION",rb_str_new2(WIN32_SERVICE_VERSION));
   rb_define_const(cDaemon,"VERSION",rb_str_new2(WIN32_SERVICE_VERSION));
   set_service_constants(cService);
   set_daemon_constants(cDaemon);
   
   // Structs
   rbServiceStatusStruct = rb_struct_define("Win32ServiceStatus",
      "service_type","current_state","controls_accepted","win32_exit_code",
      "service_specific_exit_code","check_point","wait_hint",
      "interactive?"
#ifdef HAVE_QUERYSERVICESTATUSEX
      ,"pid","service_flags"
#endif     
      ,0);
   
   rbServiceStruct = rb_struct_define("Win32Service","service_name",
      "display_name","service_type","current_state","controls_accepted",
      "win32_exit_code","service_specific_exit_code","check_point",
      "wait_hint","binary_path_name","start_type","error_control",
      "load_order_group","tag_id","start_name","dependencies",
      "description","interactive?"
#ifdef HAVE_ENUMSERVICESSTATUSEX
      ,"pid","service_flags"
#endif        
   ,0);

   // Create an attr_accessor for each valid instance method
   for(i = 0; i < sizeof(keys)/sizeof(char*); i++){
      rb_define_attr(cService,keys[i],1,1);
   }
}