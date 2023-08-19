import Vapor
import SomeBridge
import SomeFunctions

class HTTPManager {
  init() {
    
  }
  func start() throws {
    try app(.detect()).run()
  }
}

public func app(_ env: Environment) throws -> Application {
  var config = Config.default()

  var env = env
  var services = Services.default()
  try configure(&config, &env, &services)
  let app = try Application(config: config, environment: env, services: services)
  try boot(app)
  return app
}
/// Called after your application has initialized.
public func boot(_ app: Application) throws {
  // Your code here
}

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  
  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)
  
  // Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  let publicDirectory = FileMiddleware(publicDirectory: "content".contentURL.path)
  middlewares.use(publicDirectory)
  middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
  services.register(middlewares)
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  
  // Basic "Hello, world!" example
  router.get { req in
    return "Hello, world!"
  }
  
  router.get("event", Int.parameter, use: getEvent)
    
  
//  routes.add(method: .get, uri: "/event/*") { request, response in
//    defer { response.completed() }
//    guard let id = Int(request.pathComponents.last!) else { return }
//    guard let event = events[id] else { return }
//    if event.privacy < .public {
//      response.appendBody(string: "Event is private")
//      return
//    }
//
//    let contents = event.content.values.sorted {$0.time > $1.time}
//    let previews = contents.map {
//      "http://" + ($0 as! PhysicalContent).previewLink(event: event)
//    }
//    let urls = contents.map {
//      "http://" + ($0 as! PhysicalContent).link(event: event)
//    }
//    let previewsString = try! previews.jsonEncodedString()
//    let urlsString = try! urls.jsonEncodedString()
//    guard var html = "event.html".htmlTemplates.data?.string else { return }
//    html = html.replacingOccurrences(of: "@eventName", with: event.name)
//      .replacingOccurrences(of: "@author", with: event.owner.user!.name)
//      .replacingOccurrences(of: "@urls", with: urlsString)
//      .replacingOccurrences(of: "@previews", with: previewsString)
//    response.appendBody(string: html)
//    response.completed()
//  }
//
//  server.addRoutes(routes)
//  server.serverPort = UInt16(httpPort)
//  server.documentRoot = "content".contentURL.path
//  print("http server directory: \(server.documentRoot)")
}


private func getEvent(req: Vapor.Request) throws -> String {
  let id = try req.parameters.next(Int.self)
  guard let event = events[id] else { return "" }
  if event.privacy < .public {
    return "Event is private"
  }
  
  let contents = event.content.values.sorted {$0.time > $1.time}
  let previews = contents.map {
    "http://" + ($0 as! PhysicalContent).previewLink(event: event)
  }
  let urls = contents.map {
    "http://" + ($0 as! PhysicalContent).link(event: event)
  }
  let previewsString = try! previews.jsonEncodedString()
  let urlsString = try! urls.jsonEncodedString()
  guard var html = "event.html".htmlTemplates.data?.string else { return "" }
  html = html.replacingOccurrences(of: "@eventName", with: event.name)
    .replacingOccurrences(of: "@author", with: event.owner.user!.name)
    .replacingOccurrences(of: "@urls", with: urlsString)
    .replacingOccurrences(of: "@previews", with: previewsString)
  return html
}
