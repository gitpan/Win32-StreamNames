#include <windows.h>
#include <stdio.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Code for listing an Alternate Data Stream (ADS) on Microsoft Windows 2000 or later (NTFS) */

MODULE = Win32::StreamNames		PACKAGE = Win32::StreamNames		

SV *
StreamNames(szName)
   const char *szName;

   PROTOTYPE: $
   
   CODE:
   
      HANDLE hFile;
      DWORD dwRead;
      WIN32_STREAM_ID StreamId = {0};
      VOID *lpContext = NULL;
      BOOL bResult;
      int iArgs = 0;
      int i;
      size_t iLen = 0;
      
      /* DEBUG
      PerlIO * debug = PerlIO_open ("debug.txt", "a");
      PerlIO_printf(debug, "\nEntry, File: %s\n", szName);
      */
      
      /* Loose the arguments on the stack */
      for ( i = 0; i < items; i++)
         POPs;  

      /* Might be nice to allow a file handle to be passed instead of
         a name, but would that be useful?  Probably not. */
      hFile = CreateFile (szName, GENERIC_READ, 
                          FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);

      if (hFile == INVALID_HANDLE_VALUE)
      {
         /* On error, CreateFile calls SetLastError, which sets $^E */
         
         /* DEBUG
         PerlIO_printf (debug, "INVALID_HANDLE_VALUE\n");
         PerlIO_close (debug);
         */
         
         XSRETURN(0);   /* Return an empty list, */
      }

      /* Loop for each file stream */
      do
      {
         char szStreamName[MAX_PATH] = {0};
         
         /* We only want the header info, which is the first n bytes of the struct */
         DWORD dwSize = (DWORD)((LPBYTE)&StreamId.cStreamName - (LPBYTE)&StreamId);
   
         /* DEBUG
         PerlIO_printf (debug , "Main loop, dwSize = %d\n", dwSize);
         */
         
         /* Get the header information (20 bytes) */
         bResult = BackupRead (hFile, (LPBYTE)&StreamId, dwSize, 
                              &dwRead, FALSE, FALSE, &lpContext);

         /* If the function returns a nonzero value, and dwRead is zero, 
            then all the data associated with the file handle has been read.*/

         if (bResult)
         {
            wchar_t wStreamName[MAX_PATH] = {0}; 
            DWORD dw1, dw2;
   
            /* Read the stream name */
            bResult = BackupRead(hFile, (LPBYTE)wStreamName, StreamId.dwStreamNameSize, 
                                 &dwRead, FALSE, FALSE, &lpContext);
      
            if (bResult && dwRead)
            {
               /* Convert from wide character */
               wcstombs( szStreamName, wStreamName, dwRead);
            }
      
            /* Move the 'pointer' on by the number of bytes read */        
            bResult = BackupSeek(hFile, StreamId.Size.LowPart, StreamId.Size.HighPart, 
                                 &dw1, &dw2, &lpContext);

         }


         
         iLen = strlen (szStreamName);
         if (bResult && iLen)
         {  
            /* DEBUG
            PerlIO_printf (debug, "Stream found: %s\n", szStreamName);
            */
            
	    XPUSHs(sv_2mortal(newSVpvn (szStreamName, iLen))); 
	    iArgs++;
	 }
      
      } while (bResult);
      
      /* Free up resources */
      bResult = BackupRead(hFile, NULL, 0, &dwRead, TRUE, FALSE, &lpContext);
      
      if (bResult && GetLastError() == ERROR_ACCESS_DENIED)
      {
         /* Expected, set current error ($^E) to success (0) */
         SetLastError (ERROR_SUCCESS);
      }
      
      bResult = CloseHandle (hFile);
      if (bResult && GetLastError() == ERROR_INVALID_HANDLE)
      {
         /* Expected, set current error ($^E) to success (0) */
         SetLastError (ERROR_SUCCESS);
      }
   
      /* DEBUG
      PerlIO_close (debug);
      */
      
      /* Return the list on the stack */
      XSRETURN(iArgs);

   
   OUTPUT:
         RETVAL
