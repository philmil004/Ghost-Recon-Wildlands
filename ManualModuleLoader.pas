unit ManualModuleLoader;
{
This routine will examine a module and then load it into memory, taking care of the sections and IAT addresses
}

interface

uses windows, classes, sysutils, imagehlp, dialogs, peinfofunctions,cefuncproc,
     newkernelhandler, symbolhandler;

type TModuleLoader=class
  private
    filename: string;
    FLoaded: boolean;
  public
    Exporttable: TStringlist;
    constructor create(filename: string);
    property loaded: boolean read FLoaded;
end;

implementation


constructor TModuleLoader.create(filename: string);
var
  i,j,k: integer;
  filemap: TMemorystream;
  tempmap: tmemorystream;
  ImageNTHeader: PImageNtHeaders;
  ImageBaseRelocation: PIMAGE_BASE_RELOCATION;
  ImageSectionHeader: PImageSectionHeader;
  ImageExportDirectory: PImageExportDirectory;
  ImageImportDirectory: PImageImportDirectory;
  importmodulename: string;
  importaddress: dword;
  importfunctionname: string;
  importfunctionnamews: widestring;  
  is64bit, isDriver: boolean;

  numberofrva: integer;
  maxaddress: dword;

  destinationBase: uint64;

  basedifference: dword;
  basedifference64: uint64;
  x: dword;
  funcaddress: uint64;
  haserror: boolean;

  processhandle: thandle;
  pid: dword;
begin
  inherited create;
  self.filename:=filename;

  exporttable:=tstringlist.create;

  pid:=processid;

  if pid=0 then
    pid:=GetCurrentProcessId;
    
  processhandle:=KernelOpenProcess(PROCESS_ALL_ACCESS, true, pid);

  filemap:=tmemorystream.Create;
  try
    filemap.LoadFromFile(filename);
    
    if PImageDosHeader(filemap.Memory)^.e_magic<>IMAGE_DOS_SIGNATURE then
      exit; //not a valid file


    tempmap:=tmemorystream.Create;
    try
      ImageNtHeader:=peinfo_getImageNtHeaders(filemap.Memory, filemap.Size);
      if ImageNtHeader=nil then exit; //invalid

      if ImageNTHeader^.FileHeader.Machine=$8664 then
      begin
        is64bit:=true;
        if not Is64bitOS then exit; //can't be handled

        numberofrva:=PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.NumberOfRvaAndSizes;
      end else
      begin
        is64bit:=false;
        numberofrva:=ImageNTHeader^.OptionalHeader.NumberOfRvaAndSizes;        
      end;

      ImageSectionHeader:=PImageSectionHeader(dword(@ImageNTHeader^.OptionalHeader)+ImageNTHeader^.FileHeader.SizeOfOptionalHeader);

      maxaddress:=0;
      for i:=0 to ImageNTHeader^.FileHeader.NumberOfSections-1 do
      begin
        if maxaddress<(ImageSectionHeader.VirtualAddress+ImageSectionHeader.SizeOfRawData) then
          maxaddress:=ImageSectionHeader.VirtualAddress+ImageSectionHeader.SizeOfRawData;

        inc(ImageSectionHeader);
      end;

      //maxaddress is now known
      ImageSectionHeader:=PImageSectionHeader(dword(@ImageNTHeader^.OptionalHeader)+ImageNTHeader^.FileHeader.SizeOfOptionalHeader);

      tempmap.Size:=maxaddress;
      ZeroMemory(tempmap.memory, tempmap.size);

      //place the sections at the appropriate locations
      for i:=0 to ImageNTHeader^.FileHeader.NumberOfSections-1 do
      begin
        CopyMemory(@pbytearray(tempmap.memory)[ImageSectionHeader.VirtualAddress], @pbytearray(filemap.memory)[ImageSectionHeader.PointerToRawData], ImageSectionHeader.SizeOfRawData);
        inc(ImageSectionHeader);
      end;

      if uppercase(ExtractFileExt(filename))='.SYS' then
      begin
        //kernel memory location
        LoadDBK32;
        isdriver:=true;

        destinationBase:=KernelAlloc64(maxaddress);
      end
      else
      begin
        //normal memory location
        isdriver:=false;
        destinationBase:=dword(VirtualAllocEx(processhandle, nil,maxaddress, MEM_COMMIT, PAGE_EXECUTE_READWRITE));

      end;

      if destinationBase=0 then exit; //alloc error

      //copy the header and get the base difference (needed for relocs)
      if is64bit then
      begin
        CopyMemory(tempmap.memory, filemap.memory, PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.SizeOfHeaders);

        basedifference:=dword(destinationBase)-PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.ImageBase;
        basedifference64:=destinationBase-PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.ImageBase;
      end
      else
      begin
        CopyMemory(tempmap.memory, filemap.memory, ImageNTHeader^.OptionalHeader.SizeOfHeaders);
        basedifference:=dword(destinationBase)-ImageNTHeader^.OptionalHeader.ImageBase;
        basedifference64:=0;
      end;

      for i:=0 to numberofrva-1 do
      begin
        if (is64bit and (PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].VirtualAddress=0)) or
           ((not is64bit) and (ImageNTHeader^.OptionalHeader.DataDirectory[i].VirtualAddress=0)) then
          continue; //don't look into it (virtual address=0) bug...

        case i of
          0: //exports
          begin

            if is64bit then
              ImageExportDirectory:=PImageExportDirectory(dword(tempmap.memory)+PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].VirtualAddress)
            else
              ImageExportDirectory:=PImageExportDirectory(dword(tempmap.memory)+ImageNTHeader^.OptionalHeader.DataDirectory[i].VirtualAddress);


            if ImageExportDirectory.NumberOfFunctions=ImageExportDirectory.NumberOfNames then
            begin //consistent
              for j:=0 to ImageExportDirectory.NumberOfFunctions-1 do
              begin
                k:=pwordarray(dword(tempmap.memory)+dword(ImageExportDirectory.AddressOfNameOrdinals))[j];
                exporttable.Add(format('%s - %s',[inttohex(destinationBase+pdwordarray(dword(tempmap.memory)+dword(ImageExportDirectory.AddressOfFunctions))[k],1), pchar(dword(tempmap.memory)+pdwordarray(dword(tempmap.memory)+dword(ImageExportDirectory.AddressOfNames))[j])]));
              end;
            end;
          end;

          1: //imports
          begin
            j:=0;
            if is64bit then
              ImageImportDirectory:=PImageImportDirectory(dword(tempmap.memory)+PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].VirtualAddress)
            else
              ImageImportDirectory:=PImageImportDirectory(dword(tempmap.memory)+ImageNTHeader^.OptionalHeader.DataDirectory[i].VirtualAddress);


            while (j<45) do
            begin
              if ImageImportDirectory.name=0 then break;

              if ImageImportDirectory.ForwarderChain<>$ffffffff then
              begin
                importmodulename:=pchar(dword(tempmap.memory)+ImageImportDirectory.name);
                if not isdriver then
                  InjectDll(importmodulename);

                importmodulename:=ChangeFileExt(importmodulename, '');

                //--
                k:=0;
                if is64bit then
                begin
                  while PUINT64(dword(tempmap.memory)+ImageImportDirectory.FirstThunk+8*k)^<>0 do
                  begin
                    importaddress:=dword(tempmap.memory)+ImageImportDirectory.FirstThunk+8*k;
                    importfunctionname:=pchar(dword(tempmap.memory)+pdword(importaddress)^+2);


                    if isDriver then
                    begin
                      importfunctionnamews:=importfunctionname;
                      funcaddress:=GetKProcAddress64(@importfunctionnamews[1]);
                      if funcaddress=0 then exit;
                    end
                    else
                    begin
                      funcaddress:=symhandler.getAddressFromName(importmodulename+'!'+importfunctionname, true, haserror);
                      if haserror then exit;
                    end;

                    puint64(importaddress)^:=funcaddress;
                         
                    inc(k);
                  end;
                end
                else
                begin
                  while PDWORD(dword(tempmap.memory)+ImageImportDirectory.FirstThunk+4*k)^<>0 do
                  begin
                    importaddress:=dword(@pdwordarray(dword(tempmap.memory)+ImageImportDirectory.FirstThunk)[k]);
                    importfunctionname:=pchar(dword(tempmap.memory)+pdwordarray(dword(tempmap.memory)+ImageImportDirectory.FirstThunk)[k]+2);

                    if isDriver then
                    begin
                      importfunctionnamews:=importfunctionname;
                      funcaddress:=GetKProcAddress64(@importfunctionnamews[1]);
                      if funcaddress=0 then exit;
                    end
                    else
                    begin
                      funcaddress:=symhandler.getAddressFromName(importmodulename+'!'+importfunctionname, true, haserror);
                      if haserror then exit;
                    end;

                    pdword(importaddress)^:=funcaddress;
                    inc(k);
                  end;
                end;
                //--


              end;



              inc(j);
              ImageImportDirectory:=PImageImportDirectory(dword(ImageImportDirectory)+sizeof(TImageImportDirectory));
            end;


          end;

          5: //relocation table
          begin
            if is64bit then
            begin
              ImageBaseRelocation:=PIMAGE_BASE_RELOCATION(dword(tempmap.memory)+PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].VirtualAddress);
              maxaddress:=dword(tempmap.memory)+PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].VirtualAddress+PImageOptionalHeader64(@ImageNTHeader^.OptionalHeader)^.DataDirectory[i].Size;
            end
            else
            begin
              ImageBaseRelocation:=PIMAGE_BASE_RELOCATION(dword(tempmap.memory)+ImageNTHeader^.OptionalHeader.DataDirectory[i].VirtualAddress);
              maxaddress:=dword(tempmap.memory)+ImageNTHeader^.OptionalHeader.DataDirectory[i].VirtualAddress+ImageNTHeader^.OptionalHeader.DataDirectory[i].Size;
            end;

            while dword(ImageBaseRelocation)<maxaddress do
            begin
              if ImageBaseRelocation.SizeOfBlock=0 then break;

              for j:=0 to ((ImageBaseRelocation.SizeOfBlock-8) div 2)-1 do
              begin
                if (ImageBaseRelocation.rel[j] shr 12)=3 then            //replace the address at this address with a relocated one (dword)
                  pdword(dword(tempmap.memory)+ImageBaseRelocation.virtualaddress+(ImageBaseRelocation.rel[j] and $fff))^:=pdword(dword(tempmap.memory)+ImageBaseRelocation.virtualaddress+(ImageBaseRelocation.rel[j] and $fff))^+basedifference;

                if (ImageBaseRelocation.rel[j] shr 12)=10 then            //replace the address at this address with a relocated one (dword)
                  PUINT64(dword(tempmap.memory)+ImageBaseRelocation.virtualaddress+(ImageBaseRelocation.rel[j] and $fff))^:=PUINT64(dword(tempmap.memory)+ImageBaseRelocation.virtualaddress+(ImageBaseRelocation.rel[j] and $fff))^+basedifference64;
              end;

              ImageBaseRelocation:=PIMAGE_BASE_RELOCATION(dword(ImageBaseRelocation)+ImageBaseRelocation.SizeOfBlock);
            end;
          end;

        end;

      end;


      WriteProcessMemory64(processhandle, destinationbase, tempmap.memory, tempmap.size, x);
      floaded:=true;

      

      //at the end, copy the tempmap contexts to the actual allocated memory using WriteProcessMemory(64)
    finally
      tempmap.free;
    end;
  finally
    filemap.free;
  end;
end;

end.
