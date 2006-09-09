require 'Win32API'

module Windows
   module Memory
      GHND           = 0x0042
      GMEM_FIXED     = 0x0000
      GMEM_MOVABLE   = 0002
      GMEM_ZEROINIT  = 0x0040
      GPTR           = 0x0040

      GlobalAlloc          = Win32API.new('kernel32', 'GlobalAlloc', 'II', 'I')
      GlobalFlags          = Win32API.new('kernel32', 'GlobalFlags', 'I', 'I')
      GlobalFree           = Win32API.new('kernel32', 'GlobalFree', 'I', 'I')
      GlobalHandle         = Win32API.new('kernel32', 'GlobalHandle', 'P', 'I')
      GlobalLock           = Win32API.new('kernel32', 'GlobalLock', 'L', 'L')
      GlobalMemoryStatus   = Win32API.new('kernel32', 'GlobalMemoryStatus', 'P', 'V')
      GlobalMemoryStatusEx = Win32API.new('kernel32', 'GlobalMemoryStatus', 'P', 'V')
      GlobalReAlloc        = Win32API.new('kernel32', 'GlobalReAlloc', 'III', 'I')
      GlobalSize           = Win32API.new('kernel32', 'GlobalSize', 'I', 'I')
      GlobalUnlock         = Win32API.new('kernel32', 'GlobalUnlock', 'I', 'I')

      def GlobalAlloc(flags, bytes)
         GlobalAlloc.call(flags, bytes)
      end

      def GlobalFlags(handle)
         GlobalFlags.call(handle)
      end

      def GlobalFree(handle)
         GlobalFree.call(handle)
      end

      def GlobalHandle(handle)
         GlobalHandle.call(handle)
      end

      def GlobalLock(handle)
         GlobalHandle.call(handle)
      end

      def GlobalMemoryStatus(buf)
         GlobalMemoryStatus.call(buf)
      end

      def GlobalMemoryStatusEx(buf)
         GlobalMemoryStatusEx.call(buf)
      end

      def GlobalReAlloc(handle, bytes, flags)
         GlobalReAlloc.call(handle, bytes, flags)
      end

      def GlobalSize(handle)
         GlobalSize.call(handle)
      end

      def GlobalUnlock(handle)
         GlobalUnlock.call(handle)
      end
   end
end
