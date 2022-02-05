;- ############### Amiga Magazine Reader Info
;
; Version 0.1a
;
; © 2022 Paul Vince (MrV2k)
;
; https://easyemu.mameworld.info
;
; [ PB V5.7x/V6.x / 32Bit / 64Bit / Windows / DPI ]
;
; An Amiga PDF Magazine Reader
;
;- ############### Version Info
;
;============================================
; VERSION INFO v0.1
;============================================
;
; Initial Release
;
;============================================

EnableExplicit

;- ############### Enumerations

Enumeration
  
  #MAIN_WINDOW
  #MAIN_SPLITTER
  #MAGAZINE_TREE
  #WEB_GADGET
  
EndEnumeration

;- ############### Lists & Structures

Structure Mag_Data
  Mag_Name.s
  Mag_Path.s
EndStructure

Structure Mag_Root
  Mag_Title.s
  List Mag_Files.Mag_Data()
EndStructure

Global NewList File_List.s()
Global NewList Mag_List.Mag_Root()

;- ############### Global Variables

Global Version.s="0.1a"
Global event, count, path.s
Global Home_Path.s=GetCurrentDirectory()
Global Magazine_Folder.s=Home_Path+"Magazines\"
Global Magazine_Data.s=Home_Path+"Magazine_Data\"

;- ############### Macros

Macro DpiX(value) ; <--------------------------------------------------> DPI X Scaling
  DesktopScaledX(value)
EndMacro

Macro DpiY(value) ; <--------------------------------------------------> DPI Y Scaling
  DesktopScaledY(value)
EndMacro

Macro Update_Webgadget()

  If GetGadgetItemAttribute(#MAGAZINE_TREE,GetGadgetState(#MAGAZINE_TREE),#PB_Tree_SubLevel)=0
    path=Magazine_Data+GetFilePart(GetGadgetText(#MAGAZINE_TREE),#PB_FileSystem_NoExtension)+".jpg"
    SetGadgetText(#WEB_GADGET,path)
  EndIf
  
  If GetGadgetItemAttribute(#MAGAZINE_TREE,GetGadgetState(#MAGAZINE_TREE),#PB_Tree_SubLevel)>0
    path=Mag_List()\Mag_Files()\Mag_Path
    SetGadgetText(#WEB_GADGET,path)  
    SetActiveGadget(#WEB_GADGET)
  EndIf

EndMacro

Procedure List_Files_Recursive(Dir.s, List Files.s(), Extension.s) ; <------> Adds All Files In A Folder Into The Supplied List
  
  Protected NewList Directories.s()
  
  Protected FOLDER_LIST
  
  If Right(Dir, 1) <> "\"
    Dir + "\"
  EndIf
  
  If ExamineDirectory(FOLDER_LIST, Dir, Extension)
    While NextDirectoryEntry(FOLDER_LIST)
      Select DirectoryEntryType(FOLDER_LIST)
        Case #PB_DirectoryEntry_File
          AddElement(Files())
          Files() = Dir + DirectoryEntryName(FOLDER_LIST)
        Case #PB_DirectoryEntry_Directory
          Select DirectoryEntryName(FOLDER_LIST)
            Case ".", ".."
              Continue
            Default
              AddElement(Directories())
              Directories() = Dir + DirectoryEntryName(FOLDER_LIST)
          EndSelect
      EndSelect
    Wend
    FinishDirectory(FOLDER_LIST)
    ForEach Directories()
      List_Files_Recursive(Directories(), Files(), Extension)
    Next
  EndIf 
  FreeList(Directories())
  
EndProcedure

Procedure Draw_Main_Window()
  
  Protected NewList Magazine_List.s()
  
  Protected old_folder.s
  
  OpenWindow(#MAIN_WINDOW, 0, 0, 800, 700, "Amiga Magazine Reader "+Version, #PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget|#PB_Window_Invisible|#PB_Window_SizeGadget|#PB_Window_MaximizeGadget)  

  WindowBounds(#MAIN_WINDOW,800,700,#PB_Ignore,#PB_Ignore)
  
  SmartWindowRefresh(#MAIN_WINDOW,#True)
  
  TreeGadget(#MAGAZINE_TREE, 0, 0, 0, 0,#PB_Tree_AlwaysShowSelection)
  WebGadget(#WEB_GADGET, 0, 0, 0, 0,"")
  
  SplitterGadget(#MAIN_SPLITTER,5,5,790,690,#MAGAZINE_TREE,#WEB_GADGET,#PB_Splitter_Vertical)
  
  SetGadgetAttribute(#MAIN_SPLITTER,#PB_Splitter_SecondMinimumSize,250)
  SetGadgetState(#MAIN_SPLITTER,250)
  SetWindowLongPtr_(GadgetID(#WEB_GADGET),#GWL_STYLE,GetWindowLongPtr_(GadgetID(1),#GWL_STYLE)|#WS_BORDER)
  SetWindowPos_(GadgetID(#WEB_GADGET),0,0,0,0,0,#SWP_NOZORDER|#SWP_NOMOVE|#SWP_NOSIZE|#SWP_FRAMECHANGED) 
  
  List_Files_Recursive(Magazine_Folder,Magazine_List(),"*.*")
  
  old_folder=""
  
  ForEach Magazine_List()
    count=CountString(Magazine_List(),"\")
    If old_folder<>StringField(Magazine_List(),count,"\") : AddElement(Mag_List()) : Mag_List()\Mag_Title=StringField(Magazine_List(),count,"\") : EndIf
    AddElement(Mag_List()\Mag_Files())
    If GetExtensionPart(StringField(Magazine_List(),count+1,"\"))="pdf"
      Mag_List()\Mag_Files()\Mag_Name=StringField(Magazine_List(),count+1,"\")
      Mag_List()\Mag_Files()\Mag_Path=Magazine_List()
    EndIf
    old_folder=StringField(Magazine_List(),count,"\")
  Next
  
  ForEach Mag_List()
    AddGadgetItem(#MAGAZINE_TREE,-1,Mag_List()\Mag_Title,0,0)
    ForEach Mag_List()\Mag_Files()
      AddGadgetItem(#MAGAZINE_TREE,-1,Mag_List()\Mag_Files()\Mag_Name,0,1)
    Next
  Next
  
  SetGadgetState(#MAGAZINE_TREE,0)
  
  Update_Webgadget()
  
  HideWindow(#MAIN_WINDOW,#False)
  
EndProcedure

Draw_Main_Window() 

;- ############### Main Loop

Repeat
  
  event=WaitWindowEvent()
  
  Select event  
      
    Case #PB_Event_Gadget
      
      Select EventGadget()
          
        Case #MAGAZINE_TREE
          If CountGadgetItems(#MAGAZINE_TREE)>0 And GetGadgetState(#MAGAZINE_TREE)>-1                         
            If EventType()= #PB_EventType_Change
              path=GetGadgetText(#MAGAZINE_TREE)
              ForEach Mag_List()
                ForEach Mag_List()\Mag_Files()
                  If path=Mag_List()\Mag_Files()\Mag_Name 
                    Break(2)
                  EndIf
                Next
              Next
              Update_Webgadget()
            EndIf
          EndIf 
          
        Case #WEB_GADGET
          If ListSize(Mag_List())>0
            If EventType()= #PB_EventType_LeftDoubleClick
              Update_Webgadget()
            EndIf
          EndIf
          
      EndSelect
      
    Case #PB_Event_SizeWindow
      count=GetGadgetState(#MAIN_SPLITTER)
      ResizeGadget(#MAIN_SPLITTER,5,5,WindowWidth(#MAIN_WINDOW)-10,WindowHeight(#MAIN_WINDOW)-10)
      SetGadgetState(#MAIN_SPLITTER,count)
      
    Case #PB_Event_CloseWindow
      Select EventWindow()
        Case #MAIN_WINDOW 
          If MessageRequester("Info","Close program?",#PB_MessageRequester_Info|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
            CloseWindow(#MAIN_WINDOW)
            Break
          EndIf
          
      EndSelect
      
  EndSelect
  
ForEver
    
End

; IDE Options = PureBasic 6.00 Beta 3 (Windows - x64)
; CursorPosition = 128
; FirstLine = 78
; Folding = w
; Optimizer
; EnableXP
; DPIAware
; UseIcon = Images\joystick.ico
; Executable = E:\AmiMagRack\AmiMagRack.exe
; CurrentDirectory = E:\AmiMagRack\
; Compiler = PureBasic 6.00 Beta 3 (Windows - x64)
; Debugger = Standalone