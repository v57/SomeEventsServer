////
////  http.swift
////  PerfectThread
////
////  Created by Дмитрий Козлов on 7/16/17.
////
//
//import PerfectLib
//import PerfectHTTP
//import PerfectHTTPServer
//import SomeFunctions
//import Foundation
//import SomeBridge
//
//class HTTPManager {
//  let server = HTTPServer()
//  init() {
//
//    // Register your own routes and handlers
//    var routes = Routes()
//    routes.add(method: .get, uri: "/") { request, response in
//        response.appendBody(string: "Hello world")
//        response.completed()
//    }
//
////    routes.add(method: .get, uri: "/comments/*") { request, response in
////      let id = Int(request.pathComponents.last!)!
////
////      let event = events[id]
////      var dictionary = [String: Any]()
////      var array = [Any]()
////      for comment in event!.comments.messages {
////        var govno = [String: Any]()
////        govno["from"] = comment.from
////        govno["text"] = comment.description
////        govno["date"] = comment.time
////        array.append(govno)
////      }
////      dictionary["comments"] = array
////
////      let string = try! dictionary.jsonEncodedString()
////
////      var html = "templates/comments.html".data.string!
////      html.replacingOccurrences(of: "@comments", with: string)
////      response.appendBody(string: string)
////      response.completed()
////    }
//    routes.add(method: .get, uri: "/event/*") { request, response in
//      defer { response.completed() }
//      guard let id = Int(request.pathComponents.last!) else { return }
//      guard let event = events[id] else { return }
//      if event.privacy < .public {
//        response.appendBody(string: "Event is private")
//        return
//      }
//
//      let contents = event.content.values.sorted {$0.time > $1.time}
//      let previews = contents.map {
//        "http://" + ($0 as! PhysicalContent).previewLink(event: event)
//      }
//      let urls = contents.map {
//        "http://" + ($0 as! PhysicalContent).link(event: event)
//      }
//      let previewsString = try! previews.jsonEncodedString()
//      let urlsString = try! urls.jsonEncodedString()
//      guard var html = "event.html".htmlTemplates.data?.string else { return }
//      html = html.replacingOccurrences(of: "@eventName", with: event.name)
//        .replacingOccurrences(of: "@author", with: event.owner.user!.name)
//        .replacingOccurrences(of: "@urls", with: urlsString)
//        .replacingOccurrences(of: "@previews", with: previewsString)
//      response.appendBody(string: html)
//        response.completed()
//    }
//
//    server.addRoutes(routes)
//    server.serverPort = UInt16(httpPort)
//    server.documentRoot = "content".contentURL.path
//    print("http server directory: \(server.documentRoot)")
//  }
//  func start() throws {
//    do {
//      try server.start()
//      print("started http server")
//    } catch {
//      print("cannot start http server: \(error)")
//    }
//  }
//}
