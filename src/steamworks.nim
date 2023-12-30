# This version uses the DLL api directly (No C++ or .lib files).
# Not need to use VC++. Gcc works even on windows.
import os
import sequtils

when defined(Windows):
  const steam_api = "steam_api64.dll"
elif defined(MacOSX):
  const steam_api = "libsteam_api.dynlib"
else:
  const steam_api = "libsteam_api64.so"

type
  ISteamApps = distinct pointer
  ISteamUser = distinct ptr uint32
  ISteamFriends = distinct pointer
  ISteamUserStats = distinct pointer
  ISteamUtils = distinct pointer
  ISteamInput = distinct pointer
  ISteamPipe = distinct pointer

  SteamLeaderboard* = distinct uint64
  SteamAPICall* = distinct uint64
  SteamInputAnalogActionHandle* = distinct uint64
  SteamInputDigitalActionHandle* = distinct uint64
  SteamInputHandle* = distinct uint64
  SteamActionSetHandle* = distinct uint64

  InputDigitalData* {.pure, bycopy.} = object
    state*: bool
    active*: bool

  InputAnalogData* {.pure, bycopy.} = object
    emode*: cint
    x*: float32
    y*: float32
    active*: bool

  AppId = uint32
  SteamId* = uint64

  FriendFlags* = enum
    FriendFlagNone = 0x00,
    FriendFlagBlocked = 0x01,
    FriendFlagFriendshipRequested = 0x02,
    FriendFlagImmediate = 0x04, # "regular" friend
    FriendFlagClanMember = 0x08,
    FriendFlagOnGameServer = 0x10,
    FriendFlagRequestingFriendship = 0x80,
    FriendFlagRequestingInfo = 0x100,
    FriendFlagIgnored = 0x200,
    FriendFlagIgnoredFriend = 0x400,
    FriendFlagChatMember = 0x1000,
    FriendFlagAll = 0xFFFF,

  LeaderboardUploadMethod* = enum
    UploadMethodNone = 0x00
    UploadMethodBest = 0x01
    UploadMethodForce = 0x02

  InputMode* = enum
    imNormal = 0
    imPassword = 1

  InputLineMode* = enum
    ilSingle = 0
    ilMulti = 1

  InputActionOrigin* = cint

  NumberOfCurrentPlayers* {.pure, bycopy.} = object
    success: uint8 # Was the call successful? Returns 1 if it was; otherwise, 0 on failure.
    players: int32 # Number of players currently playing.

  APIData* = object of RootObj

  APICallback = object
    call: SteamAPICall
    p: proc(failed: bool, data: pointer)
    expectedData: cint
    done: bool
    finish: bool
    dataSize: int
  
  LeaderboardEntry* {.pure, bycopy.} = object
    id*: SteamID
    rank*: int32
    score*: int32
    details*: int32
    ugc*: uint64

  CallbackMsg {.pure, bycopy.} = object
    user: uint32
    callback: cint
    param: ptr uint8
    paramSize: uint32

  SteamCallCompleted {.pure, bycopy.} = object
    call: SteamAPICall
    callback: cint
    paramSize: uint32

{.push stdcall, dynlib: steam_api.}

proc RestartAppIfNecessary*(ownAppID: AppId): bool {.importc: "SteamAPI_RestartAppIfNecessary".}
proc Init*(): bool {.importc: "SteamAPI_Init".}

proc SteamApps*(): ISteamApps {.importc: "SteamAPI_SteamApps_v008".}
proc SteamPipe*(): ISteamPipe {.importc: "SteamAPI_GetHSteamPipe".}
proc SteamInput*(): ISteamInput {.importc: "SteamAPI_SteamInput_v006".}
proc isDlcInstalled*(self: ISteamApps, appID: AppId): bool {.importc: "SteamAPI_ISteamApps_BIsDlcInstalled".}
proc getAppInstallDir(self: ISteamApps, appID: AppId, folder: ptr char, folderBufferSize: uint32): uint32 {.importc: "SteamAPI_ISteamApps_GetAppInstallDir".}

proc isAppInstalled*(self: ISteamApps, appID: AppId): bool {.importc: "SteamAPI_ISteamApps_BIsAppInstalled".}
proc isVACBanned*(self: ISteamApps): bool {.importc: "SteamAPI_ISteamApps_BIsAppInstalled".}
proc getAppBuildId*(self: ISteamApps): int32 {.importc: "SteamAPI_ISteamApps_GetAppBuildId".}
proc getAppOwner*(self: ISteamApps): SteamID {.importc: "SteamAPI_ISteamApps_GetAppOwner".}
proc getCurrentBetaName*(self: ISteamApps, name: ptr char, nameBufferSize: cint): bool {.importc: "SteamAPI_ISteamApps_GetCurrentBetaName".}
proc GetCurrentGameLanguage*(self: ISteamApps): cstring {.importc: "SteamAPI_ISteamApps_GetCurrentGameLanguage".}

proc SteamUser*(): ISteamUser {.importc: "SteamAPI_SteamUser_v023".}
proc getSteamID*(self: ISteamUser): SteamId {.importc: "SteamAPI_ISteamUser_GetSteamID".}

# achievement stuff
proc getAchievement*(self: ISteamUserStats, name: cstring, achived: ptr bool): bool {.importc: "SteamAPI_ISteamUserStats_GetAchievement".}
proc getNumberOfAchievements*(self: ISteamUserStats): cint {.importc: "SteamAPI_ISteamUserStats_GetNumAchievements".}
proc setAchievement*(self: ISteamUserStats, name: cstring): bool {.importc: "SteamAPI_ISteamUserStats_SetAchievement".}
proc clearAchievement*(self: ISteamUserStats, name: cstring): bool {.importc: "SteamAPI_ISteamUserStats_ClearAchievement".}
proc getAchievementIcon*(self: ISteamUserStats, name: cstring): cint {.importc: "SteamAPI_ISteamUserStats_GetAchievementIcon".}
proc getAchievementName*(self: ISteamUserStats, id: cint): cstring {.importc: "SteamAPI_ISteamUserStats_GetAchievementName".}
proc getAchievementDisplayAttribute*(self: ISteamUserStats, name: cstring, key: cstring): cstring {.importc: "SteamAPI_ISteamUserStats_GetAchievementDisplayAttribute".}

# friend stuff
proc SteamUserStats*(): ISteamUserStats {.importc: "SteamAPI_SteamUserStats_v012".}
proc getNumberOfCurrentPlayers*(self: ISteamUserStats): SteamAPICall {.importc: "SteamAPI_ISteamUserStats_GetNumberOfCurrentPlayers".}
proc requestCurrentStats*(self: ISteamUserStats): SteamAPICall {.importc: "SteamAPI_ISteamUserStats_RequestCurrentStats".}
proc requestUserInformation*(self: ISteamFriends, id: SteamId, name: bool): bool {.importc: "SteamAPI_ISteamFriends_RequestUserInformation".}
proc SteamFriends*(): ISteamFriends {.importc: "SteamAPI_SteamFriends_v017".}
proc getPersonaName*(self: ISteamFriends): cstring {.importc: "SteamAPI_ISteamFriends_GetPersonaName".}
proc getFriendCount*(self: ISteamFriends, iFriendFlags: cint): cint {.importc: "SteamAPI_ISteamFriends_GetFriendCount".}
proc getFriendByIndex*(self: ISteamFriends, iFriend: cint, iFriendFlags: cint): SteamId {.importc: "SteamAPI_ISteamFriends_GetFriendByIndex".}
proc getFriendPersonaName*(self: ISteamFriends, steamIDFriend: SteamId): cstring {.importc: "SteamAPI_ISteamFriends_GetFriendPersonaName".}
proc replyToFriendMessage*(self: ISteamFriends, steamIDFriend: SteamId, msgToSend: cstring) {.importc: "SteamAPI_ISteamFriends_ReplyToFriendMessage".}
proc inviteUserToGame*(self: ISteamFriends, steamIDFriend: SteamId, connectString: cstring): bool {.importc: "SteamAPI_ISteamFriends_InviteUserToGame".}

# rpc stuff
proc setRichPresence*(self: ISteamFriends, key: cstring, value: cstring): bool {.importc: "SteamAPI_ISteamFriends_SetRichPresence".}

# leaderboard stuff
proc getLeaderboard*(self: ISteamUserStats, name: cstring): SteamAPICall {.importc: "SteamAPI_ISteamUserStats_FindLeaderboard".}
proc uploadLeaderboardScore*(self: ISteamUserStats, leaderboard: SteamLeaderboard, uploadMethod: LeaderboardUploadMethod, score: int32, details: pointer, detailsCount: cint): SteamAPICall {.importc: "SteamAPI_ISteamUserStats_UploadLeaderboardScore".}
proc downloadLeaderboardEntries*(self: ISteamUserStats, leaderboard: SteamLeaderboard, kind: int, start: int, stop: int): SteamAPICall {.importc: "SteamAPI_ISteamUserStats_DownloadLeaderboardEntries".}
proc getDownloadedLeaderboardEntry*(self: ISteamUserStats, entries: uint64, idx: int, entry: ptr LeaderboardEntry, details: ptr int, max: int) {.importc: "SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry".}

# api stuff
proc SteamUtils*(): ISteamUtils {.importc: "SteamAPI_SteamUtils_v010".}
proc getAPICallResult*(self: ISteamUtils, steamAPICall: SteamAPICall, data: pointer, dataSize: cint, callbackExpected: cint, failed: ptr[bool]): bool {.importc: "SteamAPI_ISteamUtils_GetAPICallResult".}
proc isAPICallCompleted*(self: ISteamUtils, steamAPICall: SteamAPICall, failed: ptr[bool]): bool {.importc: "SteamAPI_ISteamUtils_IsAPICallCompleted".}
proc getAPICallFailureReason*(self: ISteamUtils, steamAPICall: SteamAPICall): cint  {.importc: "SteamAPI_ISteamUtils_GetAPICallFailureReason".}

# image stuff
proc getImageSize*(self: ISteamUtils, image: cint, w, h: ptr cint): bool  {.importc: "SteamAPI_ISteamUtils_GetImageSize".}
proc getImageRGBA*(self: ISteamUtils, image: cint, buffer: pointer, bufferSize: cint): bool  {.importc: "SteamAPI_ISteamUtils_GetImageRGBA".}
proc showGamepadTextInput*(self: ISteamUtils, mode: InputMode, lineMode: InputLineMode, desc: cstring, maxi: uint32, existing: ptr char): bool  {.importc: "SteamAPI_ISteamUtils_ShowGamepadTextInput".}
proc showFloatingGamepadTextInput*(self: ISteamUtils, mode: InputMode, x, y, w, h: int): bool {.importc: "SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput".}
proc getEnteredTextLength*(self: ISteamUtils): uint32  {.importc: "SteamAPI_ISteamUtils_GetEnteredGamepadTextLength".}
proc getEnteredText*(self: ISteamUtils, chars: ptr char, length: uint32): bool  {.importc: "SteamAPI_ISteamUtils_GetEnteredGamepadTextInput".}
proc isSteamInBigPictureMode*(self: ISteamUtils): bool {.importc: "SteamAPI_ISteamUtils_IsSteamInBigPictureMode".}

# input stuff
proc init*(self: ISteamInput) {.importc: "SteamAPI_ISteamInput_Init".}
proc runFrame*(self: ISteamInput) {.importc: "SteamAPI_ISteamInput_RunFrame".}
proc getActionSetHandle*(self: ISteamInput, index: cstring): SteamActionSetHandle  {.importc: "SteamAPI_ISteamInput_GetActionSetHandle".}
proc getControllerForGamepadIndex*(self: ISteamInput, index: cint): SteamInputHandle  {.importc: "SteamAPI_ISteamInput_GetControllerForGamepadIndex".}
proc getAnalogActionHandle*(self: ISteamInput, index: cstring): SteamInputAnalogActionHandle  {.importc: "SteamAPI_ISteamInput_GetAnalogActionHandle".}
proc getDigitalActionHandle*(self: ISteamInput, index: cstring): SteamInputDigitalActionHandle  {.importc: "SteamAPI_ISteamInput_GetDigitalActionHandle".}
proc getAnalogActionData*(self: ISteamInput, handle: SteamInputHandle, action: SteamInputAnalogActionHandle): InputAnalogData {.importc: "SteamAPI_ISteamInput_GetAnalogActionData".}
proc getDigitalActionData*(self: ISteamInput, handle: SteamInputHandle, action: SteamInputDigitalActionHandle): InputDigitalData {.importc: "SteamAPI_ISteamInput_GetDigitalActionData".}
proc activateActionSet*(self: ISteamInput, handle: SteamInputHandle, actionHandle: SteamActionSetHandle) {.importc: "SteamAPI_ISteamInput_ActivateActionSet".}
proc getConnectedControllers*(self: ISteamInput, handles: ptr SteamInputHandle): int {.importc: "SteamAPI_ISteamInput_GetConnectedControllers".}
proc enableDeviceCallbacks*(self: ISteamInput) {.importc: "SteamAPI_ISteamInput_EnableDeviceCallbacks".}
proc getAnalogActionOrigins*(self: ISteamInput, handle: SteamInputHandle, actionHandle: SteamActionSetHandle, analog: SteamInputAnalogActionHandle, output: ptr InputActionOrigin): cint {.importc: "SteamAPI_ISteamInput_GetAnalogActionOrigins".}
proc getDigitalActionOrigins*(self: ISteamInput, handle: SteamInputHandle, actionHandle: SteamActionSetHandle, analog: SteamInputDigitalActionHandle, output: ptr InputActionOrigin): cint {.importc: "SteamAPI_ISteamInput_GetDigitalActionOrigins".}
proc getGlyphForActionOrigin*(self: ISteamInput, origin: InputActionOrigin, size: uint32 = 2, misc: uint32 = 0): cstring {.importc: "SteamAPI_ISteamInput_GetGlyphPNGForActionOrigin".}

proc SteamAPI_ManualDispatch_Init*() {.importc.}
proc SteamAPI_ManualDispatch_RunFrame(pipe: ISteamPipe) {.importc.}
proc SteamAPI_ManualDispatch_GetNextCallback(pipe: ISteamPipe, callback: ptr CallbackMsg): bool {.importc.}
proc SteamAPI_ManualDispatch_FreeLastCallback(pipe: ISteamPipe) {.importc.}
proc SteamAPI_ManualDispatch_GetAPICallResult(pipe: ISteamPipe, call: SteamAPICall, callback: pointer, size: cuint, expected: cint, failed: ptr bool): bool {.importc.}

{.pop.}

proc zeroCap(s: var string) =
  for i, c in s:
    if c == char(0):
      s.setLen(i)
      return

proc getAppInstallDir*(self: ISteamApps, appID: AppId): string =
  result = newString(1024)
  result.setLen(self.getAppInstallDir(appID, result[0].addr, result.len.uint32).int)

proc getCurrentBetaName*(self: ISteamApps): string =
  result = newString(1024)
  discard self.getCurrentBetaName(result[0].addr, result.len.cint)
  result.zeroCap()

# callback system
var
  callbacks: seq[APICallback]

proc registerCallbackInternal*(steamUtils: ISteamUtils, id: cint, apiCall: SteamAPICall, dataSize: int, cb: proc(failed: bool, data: pointer), finish: bool) =
  callbacks &= APICallback(
    call: apiCall,
    p: cb,
    expectedData: id,
    dataSize: dataSize,
    finish: finish,
  )

template registerPermCallback*(steamUtils: ISteamUtils, apiCall: SteamAPICall, id: cint, dataType: untyped, body: untyped) =
  steamUtils.registerCallbackInternal(id, apiCall, sizeof(dataType), body, false)

template registerCallback*(steamUtils: ISteamUtils, apiCall: SteamAPICall, id: cint, dataType: untyped, body: untyped) =
  steamUtils.registerCallbackInternal(id, apiCall, sizeof(dataType), body, true)

proc checkCallbacks*(steamUtils: ISteamUtils) =
  callbacks.keepItIf(not it.done)
  var steamPipe = SteamPipe()
  steamPipe.SteamAPI_ManualDispatch_RunFrame()

  var cbm: CallbackMsg
  while SteamAPI_ManualDispatch_GetNextCallback(steamPipe, addr cbm):
    if cbm.callback == 703:
      let completed = cast[ptr SteamCallCompleted](cbm.param)
      var data = alloc(completed.paramSize)
      let failed = true

      if SteamAPI_ManualDispatch_GetAPICallResult(steamPipe, completed.call, data, completed.paramSize, completed.callback, addr failed):
        for ci in 0..<len callbacks:
          template c: untyped = callbacks[ci]
          if c.call.uint64 == completed.call.uint64:
            c.p(failed, data)

            c.done = c.finish
    else:
      for ci in 0..<len callbacks:
        template c: untyped = callbacks[ci]
        if c.expectedData == cbm.callback:
          var data: pointer = addr cbm.param
          var fail: bool = false
          c.p(fail, data)

          c.done = c.finish

    SteamAPI_ManualDispatch_FreeLastCallback(steamPipe)
