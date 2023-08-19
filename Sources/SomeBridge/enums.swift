//
//  enums.swift
//  SomeBridge
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import SomeData

public enum FileType: UInt8 {
  case avatar
  case photo
  case photoPreview
  case video
  case videoPreview
  case chatFile
}

// outdated (v2)

public enum cmd: UInt8 {
  // connection
  case notification
  case download
  case upload
  
  case auth // throws // implemented
  case signup // throws // implemented
  
  // profile
  case removeAvatar // implemented
  case rename // throws, notification // implemented
  case addPushToken // no throws // implemented
  case removePushToken // no throws // implemented
  
  // users
  case searchUsers // no throws // implemented
  case userMains // no throws // implemented
  case addFriend // throws, notification, push // implemented
  case removeFriend // throws, notification // implemented
  case subscribe // throws // implemented
  case unsubscribe // throws // implemented
  
  // event
  case newEvent // throws // implemented
  case addPhoto // throws, notification
  case addVideo // throws, notification
  
  case remove
  case banUser
  
  case leaveEvent // throws, notification // implemented
  case removeContent // throws, notification // implemented
  case invite // throws, notification, push // implemented
  case uninvite // throws, notification // implemented
  case eventPrivacy // throws, notification // implemented
  case eventStatus // throws, notification // implemented
  case renameEvent // throws, notification // implemented
  case moveEvent // throws // implemented
  case eventTime // throws+notification // implemented
  
  // event comments
  case comments // throws, notification // deprecated (v2)
  case commentsSettings // throws, notification
  
  // private message
  case privateChat // throws, notification // deprecated (v2)
  case privateChatTyping
  
  // group chat
  case groupChat // throws, notification // deprecated (v2)
  case groupChatCreate
  
  // community chat
  case communityChat // throws, notification // deprecated (v2)
  
  /////// subscribe
  case sub
  
  // report
  case report
  case acceptReport // implemented
  case declineReport // implemented
  case reports
  
  // v3
  case chat
}

public enum subcmd: UInt8 {
  case response
  // my notifications
  case systemMessage // implemented
  
  case friendAdded // implemented
  case friendRemoved // implemented
  case incomingAdded // implemented
  case outcomingAdded // implemented
  
  // profile page
  case pName // implemented
  case pAvatarChanged // implemented
  case pAvatarRemoved // implemented
  case pSubs
  case pNewEvent // implemented
  case pEventRemoved // not implemented on server
  case pEventPreviewChanged // implemented
  case pEventPreviewRemoved
  
  // map
  case mAddEvent // not implemented on server
  case mRemoveEvent // not implemented on server
  
  // event page
  case eNewOwner
  case eNewContent // implemented
  case eContentRemoved // implemented
  case eContentPreviewLoaded // implemented
  case eContentLoaded // implemented
  case eName // implemented
  
  case ec // outdated (v2)
  case ecEnabled // outdated (v2)
  case ecDeleted // outdated (v2)
  case ecEdited // outdated (v2)
  case ecCleared // outdated (v2)
  
  case cc // outdated (v2)
  case ccDeleted // outdated (v2)
  case ccEdited // outdated (v2)
  case ccCleared // outdated (v2)
  
  case pm // outdated (v2)
  case pmDeleted // outdated (v2)
  case pmEdited // outdated (v2)
  case pmCleared // outdated (v2)
  
  case gcCreated
  case gc // outdated (v2)
  case gcDeleted // outdated (v2)
  case gcEdited // outdated (v2)
  case gcCleared // outdated (v2)
  
  case eStatus // implemented
  case ePrivate // implemented
  
  case eViews // implemented
  case eCurrent // implemented
  case eComments // implemented
  
  case eInvited // implemented
  case eUninvited // implemented
  
  case eMoved // implemented
  case eTimeChanged
  
  // chat
  case cTyping
  
  case reportSent // implemented
  case reportRemoved
  
  // moderator
  case reportAvailable // implemented
  case newReport
  
  case chat
}

public enum Response: UInt8, Error {
  case ok
  case wrongPassword
  case wrongDB
  case outdated
  
  case userNotFound
  case eventNotFound
  case contentNotFound
  case chatNotFound
  case reportNotFound
  case messageNotFound
  
  case eventPermissions
  case eventWrongTime
  
  case chatPermissions
  
  case wrongFileOffset
  case wrongFileSize
  case fileIsTooBig
  case fileNoAccess
  case contentWrongAuthor
  
  case contentNotUploaded
  case contentPreviewNotUploaded
  case contentWrongType
  
  case subscriptionNotFound
  
  case permissionsRequired
  case commandNotFound
  
  case requestCorrupted
  case responseCorrupted
  case keyOutdated
  case keyCorrupted
  
  case fileNotUploaded
}

public enum Subtype: UInt8 {
  case map
  case profile
  case event
  case comments
  case groupChat
  case privateChat
  case communityChat
  case reports
  case news
}

public enum PushType: UInt8 {
  case friends
  case event
  case comments
  case profile
  case map
  case report
}

// MARK:- Chat
public enum MessageType: UInt8 {
  case text
  case richText
  case photo
  case video
  case coordinate
//  case youtube
}
public enum RichTextParameter: UInt8 {
  case font
  case options
}
public enum RichTextOption: UInt8 {
  case inline
}
public enum RichTextFont: UInt8 {
  case largeTitle
  case title1
  case title2
  case title3
  case body
  case headline
  case subheadline
  case callout
  case footnote
  case caption1
  case caption2
}


public enum ChatCommands: UInt8 {
  case send
  case delete
  case edit
  case clear
}

public enum ChatNotifications: UInt8 {
  case received
  case deleted
  case edited
  case cleared
  case uploaded
}

public enum CommentsOptions: UInt8 {
  case disabled
  case permissions
}

// MARK:- Content
public enum ContentType: UInt8 {
  case photo
  case video
//  case stream
//  case audio
//  case audioStream
//  case link
//  case youtube
}

public struct PhotoData {
  public var width: Int16 = 1
  public var height: Int16 = 1
  public var size: Int32 = 0
  public init() {}
}
public enum PhotoOptions: UInt8 {
  case protected
  case uploaded
  case previewUploaded
}

public struct VideoData {
  public var width: Int16 = 1
  public var height: Int16 = 1
  public var duration: Int32 = 0
  public var size: UInt64 = 0
  public init() {}
}
public enum VideoOptions: UInt8 {
  case protected
  case uploaded
  case previewUploaded
}
public enum AudioOptions: UInt8 {
  case protected
  case uploaded
}
public enum LinkOptions: UInt8 {
  case protected
}
public enum YoutubeOptions: UInt8 {
  case protected
}
public enum AudioStreamOptions: UInt8 {
  case streaming
}
public enum StreamOptions: UInt8 {
  case streaming
}
public enum VideoQuality: UInt8 {
  case q240
  case q360
  case q720
  case q1080
  case q4k
}


// MARK:- User
public enum PublicUserOptions: UInt8 {
  case online
  case avatar
  case deleted
  case banned
  public static let `default`: PublicUserOptions.Set = 0b0
}
public enum PrivateUserOptions: UInt8 {
  case allowReports
  case moderator
  case admin
  public static let `default`: PrivateUserOptions.Set = 0b1
}
public enum ServerUserOptions: UInt8 {
  case protected
  case allowOnlineEvents
  case allowComments
  public static let `default`: ServerUserOptions.Set = 0b110
}

public enum UserSettings: UInt8 {
  case some
}

public enum DeviceSettings: UInt8 {
  case pushEnabled
}

// MARK:- Event
public enum EventStatus: UInt8 {
  case started
  case paused
  case ended
}
public enum EventOptions: UInt8 {
  case online
  case onMap
  case removed
  case banned
  case protected
}
public enum EventPrivacy: UInt8 {
  case `private`
  case friends
  case subscribers
  case `public`
  case open
}

// MARK:- Reports
public enum ReportType: UInt8 {
  case user
  case event
  case content
  case comment
}
public enum UserRules: UInt8 {
  case other
  case userSpam
  case userName
  case avatar
  case toxic
}
public enum EventRules: UInt8 {
  case other
  case adultEvent
  case notEvent
  case eventName
}
public enum ContentRules: UInt8 {
  case other
  case adultContent
  case realContent
  case spamContent
}
public enum CommentRules: UInt8 {
  case other
  case adultContent
  case spam
  case toxic
}
public enum ConnectionSecurity: UInt8 {
  case rsa, key, fast, rsa2
}
public enum ConnectionOptions: UInt8 {
  case debug, file, auth
}
