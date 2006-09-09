require 'windows/unicode'

module Windows
   module Directory
      CreateDirectory             = Win32API.new('kernel32', 'CreateDirectory', 'PP', 'I')
      CreateDirectoryW            = Win32API.new('kernel32', 'CreateDirectoryW', 'PP', 'I')
      CreateDirectoryEx           = Win32API.new('kernel32', 'CreateDirectoryEx', 'PPP', 'I')
      FindCloseChangeNotification = Win32API.new('kernel32', 'FindCloseChangeNotification', 'L', 'I')
      FindFirstChangeNotification = Win32API.new('kernel32', 'FindFirstChangeNotification', 'PIL', 'L')
      FindNextChangeNotification  = Win32API.new('kernel32', 'FindFirstChangeNotification', 'PIL', 'I')
      GetCurrentDirectory         = Win32API.new('kernel32', 'GetCurrentDirectory', 'LP', 'L')
      ReadDirectoryChangesW       = Win32API.new('kernel32', 'ReadDirectoryChangesW', 'LPLILPPP', 'I')
      RemoveDirectory             = Win32API.new('kernel32', 'RemoveDirectory', 'P', 'I')
      RemoveDirectoryW            = Win32API.new('kernel32', 'RemoveDirectoryW', 'P', 'I')
      SetCurrentDirectory         = Win32API.new('kernel32', 'SetCurrentDirectory', 'P', 'I')
      SetCurrentDirectoryW        = Win32API.new('kernel32', 'SetCurrentDirectoryW', 'P', 'I')

      def CreateDirectory(path, attributes = 0)
         if $KCODE != 'NONE'
            CreateDirectoryW.call(path, attributes) != 0
         else
            CreateDirectory.call(path, attributes) != 0
         end
      end

      def CreateDirectoryEx(template, new, attributes)
         CreateDirectoryEx.call(template, new, attributes) != 0
      end

      def FindCloseChangeNotification(handle)
         FindCloseChangeNotification.call(handle) != 0
      end

      def FindFirstChangeNotification(path, subtree, filter)
         FindFirstChangeNotification.call(path, subtree, filter)
      end

      def FindNextChangeNotification(handle)
         FindNextChangeNotification.call(handle) != 0
      end

      def GetCurrentDirectory(buf_len, buf)
         GetCurrentDirectory.call(buf_len, buf)
      end

      def ReadDirectoryChangesW(handle, buf, buf_len, subtree, filter, bytes, overlapped, routine)
         ReadDirectoryChangesW.call(handle, buf, buf_len, subtree, filter, bytes, overlapped, routine) != 0
      end

      def RemoveDirectory(path)
         if $KCODE != 'NONE'
            RemoveDirectoryW.call(path) != 0
         else
            RemoveDirectory.call(path) != 0
         end
      end

      def SetCurrentDirectory(path)
         if $KCODE != 'NONE'
            SetCurrentDirectoryW.call(path) != 0
         else
            SetCurrentDirectory.call(path) != 0
         end
      end
   end
end
