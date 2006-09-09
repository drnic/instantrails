require 'Win32API'

module Windows
   module EventLog
      EVENTLOG_SEQUENTIAL_READ = 0x0001
      EVENTLOG_SEEK_READ       = 0x0002
      EVENTLOG_FORWARDS_READ   = 0x0004
      EVENTLOG_BACKWARDS_READ  = 0x0008

      EVENTLOG_SUCCESS          = 0x0000
      EVENTLOG_ERROR_TYPE       = 0x0001
      EVENTLOG_WARNING_TYPE     = 0x0002
      EVENTLOG_INFORMATION_TYPE = 0x0004
      EVENTLOG_AUDIT_SUCCESS    = 0x0008
      EVENTLOG_AUDIT_FAILURE    = 0x0010
      
      EVENTLOG_FULL_INFO = 0

      BackupEventLog             = Win32API.new('advapi32', 'BackupEventLog', 'LP', 'I')
      ClearEventLog              = Win32API.new('advapi32', 'ClearEventLog', 'LP', 'I')
      CloseEventLog              = Win32API.new('advapi32', 'CloseEventLog', 'L', 'I')
      DeregisterEventSource      = Win32API.new('advapi32', 'DeregisterEventSource', 'L', 'I')
      GetEventLogInformation     = Win32API.new('advapi32', 'GetEventLogInformation', 'LLPLP', 'I')
      GetNumberOfEventLogRecords = Win32API.new('advapi32', 'GetNumberOfEventLogRecords', 'LP', 'I')
      GetOldestEventLogRecord    = Win32API.new('advapi32', 'GetOldestEventLogRecord', 'LP', 'I')
      NotifyChangeEventLog       = Win32API.new('advapi32', 'NotifyChangeEventLog', 'LL', 'I')
      OpenBackupEventLog         = Win32API.new('advapi32', 'OpenBackupEventLog', 'PP', 'L')
      OpenEventLog               = Win32API.new('advapi32', 'OpenEventLog', 'PP', 'L')
      ReadEventLog               = Win32API.new('advapi32', 'ReadEventLog', 'LLLPLPP', 'I')
      RegisterEventSource        = Win32API.new('advapi32', 'RegisterEventSource', 'PP', 'L')
      ReportEvent                = Win32API.new('advapi32', 'ReportEvent', 'LIILPILPP', 'I')

      def BackupEventLog(handle, file)
         BackupEventLog.call(handle, file) != 0
      end

      def ClearEventLog(handle, file = 0)
         ClearEventLog.call(handle, file) != 0
      end

      def CloseEventLog(handle)
         CloseEventLog.call(handle) != 0
      end

      def DeregisterEventSource(handle)
         DeregisterEventSource.call(handle) != 0
      end

      def GetEventLogInformation(handle, level, buf, buf_size, bytes)
         GetEventLogInformation.call(handle, level, buf, buf_size, bytes) != 0
      end

      def GetNumberOfEventLogRecords(handle, num)
         GetNumberOfEventLogRecords.call(handle, num) != 0
      end
      
      def GetOldestEventLogRecord(handle, rec)
         GetOldestEventLogRecord.call(handle, rec) != 0
      end

      def NotifyChangeEventLog(handle, event)
         NotifyChangeEventLog.call(handle, event) != 0
      end

      def OpenBackupEventLog(server, file)
         OpenBackupEventLog.call(server, file)
      end

      def OpenEventLog(server, source)
         OpenEventLog.call(server, source)
      end

      def ReadEventLog(handle, flags, offset, buf, bytes, bytes_read, min_bytes)
         ReadEventLog.call(handle, flags, offset, buf, bytes, bytes_read, min_bytes) != 0
      end

      def RegisterEventSource(server, source)
         RegisterEventSource.call(server, source)
      end

      def ReportEvent(handle, type, cat, id, sid, num, size, strings, raw)
         ReportEvent.call(handle, type, cat, id, sid, num, size, strings, raw) != 0
      end
   end
end
