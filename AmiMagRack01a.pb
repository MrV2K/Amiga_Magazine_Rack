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
  #MAIN_MENU
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
Global NewMap Mag_Map.i()

;- ############### Global Variables

Global Version.s="0.1a"
Global event, count, path.s, Html$
Global Home_Path.s=GetCurrentDirectory()
Global Magazine_Folder.s=Home_Path+"Magazines\"
Global Magazine_Data.s=Home_Path+"Magazine_Data\"
Global Coverdisk_Path.s=Home_Path+"Coverdisks\"

;- ############### Macros

Macro DpiX(value) ; <--------------------------------------------------> DPI X Scaling
  DesktopScaledX(value)
EndMacro

Macro DpiY(value) ; <--------------------------------------------------> DPI Y Scaling
  DesktopScaledY(value)
EndMacro

Macro Pause_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#True,0)
  RedrawWindow_(WindowID(window),#Null,#Null,#RDW_INVALIDATE)
EndMacro

Macro Update_Webgadget()
  
  Pause_Window(#MAIN_WINDOW)
  
  FreeGadget(#WEB_GADGET)
  
  WebGadget(#WEB_GADGET, 0, 0, 0, 0,"")
  SetGadgetAttribute(#WEB_GADGET,#PB_Web_BlockPopupMenu,#True)
  SetGadgetAttribute(#MAIN_SPLITTER,#PB_Splitter_SecondGadget,#WEB_GADGET)
  
  If GetGadgetItemAttribute(#MAGAZINE_TREE,GetGadgetState(#MAGAZINE_TREE),#PB_Tree_SubLevel)=0
    path=Magazine_Data+GetFilePart(GetGadgetText(#MAGAZINE_TREE),#PB_FileSystem_NoExtension)+".jpg"
    Html$="<!doctype html>"+Chr(13)
    Html$+"<html>"+Chr(13)
    Html$+"<head>"+Chr(13)
    Html$+"<meta charset="+#DOUBLEQUOTE$+"utf-8"+#DOUBLEQUOTE$+">"+Chr(13)
    Html$+"<title>AmiMagRack Preview</title>"+Chr(13)
    Html$+"</head>"+Chr(13) 
    Html$+""+Chr(13)
    Html$+"<style>"+Chr(13)
    Html$+" .center {"+Chr(13)
    Html$+" position: absolute;"+Chr(13)
    Html$+" margin: auto;"+Chr(13)
    Html$+" top: 0;"+Chr(13)
    Html$+" left: 0;"+Chr(13)
    Html$+" right: 0;"+Chr(13)
    Html$+" bottom: 0;"+Chr(13)
    Html$+"}"+Chr(13)
    Html$+"</style>"+Chr(13) 
    Html$+""+Chr(13)
    Html$+"<body>"+Chr(13)
    Html$+" <div>"+Chr(13)
    Html$+"   <img class="+#DOUBLEQUOTE$+"center"+#DOUBLEQUOTE$+" src="+#DOUBLEQUOTE$+path+#DOUBLEQUOTE$+" width="+#DOUBLEQUOTE$+"100%"+#DOUBLEQUOTE$+" height="+#DOUBLEQUOTE$+"100%"+#DOUBLEQUOTE$+">"+Chr(13)
    Html$+" </div>"+Chr(13)
    Html$+"</body>"+Chr(13)
    Html$+"</html>"
    SetGadgetItemText(#WEB_GADGET,#PB_Web_HtmlCode,Html$)
    SetActiveGadget(#MAGAZINE_TREE)
  EndIf
  
  If GetGadgetItemAttribute(#MAGAZINE_TREE,GetGadgetState(#MAGAZINE_TREE),#PB_Tree_SubLevel)>0
    SetActiveGadget(#WEB_GADGET)
    path=Mag_List()\Mag_Files()\Mag_Path
    SetGadgetText(#WEB_GADGET,path)  
  EndIf
  
  Resume_Window(#MAIN_WINDOW)
  
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

Procedure OnSizeWindow() ; <----------------------------------------------> Resizes The Gadgets When The Window Is Resized
  
ResizeGadget(#MAIN_SPLITTER,5,5,WindowWidth(#MAIN_WINDOW)-10,WindowHeight(#MAIN_WINDOW)-10-MenuHeight())

EndProcedure

Procedure Draw_Main_Window()
  
  Protected NewList Magazine_List.s()
  
  Protected old_folder.s
  
  OpenWindow(#MAIN_WINDOW, 0, 0, 800, 700, "Amiga Magazine Rack "+Version, #PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget|#PB_Window_Invisible|#PB_Window_SizeGadget|#PB_Window_MaximizeGadget)  
  
  CreateMenu(#MAIN_MENU,WindowID(#MAIN_WINDOW))
  MenuTitle("File")
  MenuItem(0,"Open Coverdisks")
  MenuBar()
  MenuItem(1,"Exit")
  MenuTitle("Help")
  MenuItem(2,"About")
  
  WindowBounds(#MAIN_WINDOW,800,700,#PB_Ignore,#PB_Ignore)
  
  BindEvent(#PB_Event_SizeWindow,@OnSizeWindow())
  
  SmartWindowRefresh(#MAIN_WINDOW,#True)
  
  TreeGadget(#MAGAZINE_TREE, 0, 0, 0, 0,#PB_Tree_AlwaysShowSelection)
  WebGadget(#WEB_GADGET, 0, 0, 0, 0,"")
  SetGadgetAttribute(#WEB_GADGET,#PB_Web_BlockPopupMenu,#True)
  
  SplitterGadget(#MAIN_SPLITTER,5,5,WindowWidth(#MAIN_WINDOW)-10,WindowHeight(#MAIN_WINDOW)-10-MenuHeight(),#MAGAZINE_TREE,#WEB_GADGET,#PB_Splitter_Vertical)
  
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
      Mag_Map(Mag_List()\Mag_Files()\Mag_Name)=ListIndex(Mag_List())
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
      
    Case #PB_Event_Menu
      
      Select EventMenu()
          
        Case 0
          RunProgram(Coverdisk_Path)
          
        Case 1
          End
          
        Case 2
          MessageRequester("About","Amiga Magazine Rack"+Chr(13)+Chr(13)+"Version "+Version+Chr(13)+Chr(13)+"© 2022 Paul Vince (MrV2K)",#PB_MessageRequester_Info)
          
      EndSelect
      
      
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
          
      EndSelect
      
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

; IDE Options = PureBasic 6.00 Beta 5 (Windows - x64)
; CursorPosition = 256
; FirstLine = 75
; Folding = A9
; Optimizer
; EnableXP
; DPIAware
; UseIcon = amr.ico
; Executable = E:\AmiMagRack\AmiMagRack.exe
; CurrentDirectory = E:\AmiMagRack\
; Compiler = PureBasic 6.00 Beta 5 - C Backend (Windows - x64)
; Debugger = Standalone