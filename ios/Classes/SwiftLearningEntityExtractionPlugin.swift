import Flutter
import UIKit
import MLKitEntityExtraction

public class SwiftLearningEntityExtractionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "LearningEntityExtraction", binaryMessenger: registrar.messenger())
    let instance = SwiftLearningEntityExtractionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      instance.setModelManager(registrar: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "extract" {
      extract(call, result: result)
    } else if call.method == "dispose" {
      dispose(result: result)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  func extract(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String
    let text: String? = args["text"] as? String

    if modelIdentifier == nil || text == nil {
      result(FlutterError(
        code: "NOTEXT", 
        message: "No argument text",
        details: nil))
      return
    }

      let options = EntityExtractorOptions(modelIdentifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!) )
    let extractor = EntityExtractor.entityExtractor(options: options)
    
      extractor.downloadModelIfNeeded(completion: { data in
      extractor.annotateText(
        text ?? "",
        params: EntityExtractionParams(),
        completion: { annotations, error in
          if error != nil {
            result(FlutterError(
              code: "FAILED", 
              message: "Entity extraction failed with error: \(error!)",
              details: error))
            return
          }
result(annotations)
//            let result : [Entity] = annotations?.first?.entities ?? []
//            [EntityAnnotation]
//          for annotation in (annotations ?? []) {
//
//            let item = [
//                "annotation": annotation.entities,
//                "start": annotation.range.lowerBound,
//                "end": annotation.range.upperBound
//            ] as [String : Any]
//
//            let entities = annotation.entities
//
//            for entity in entities {
//
//            }
//          }
        }
      )
    })
  }

  func dispose(result: @escaping FlutterResult) {
    result(true)
  }

  func setModelManager(registrar: FlutterPluginRegistrar) {
    let modelManagerChannel = FlutterMethodChannel(
      name: "LearningEntityModelManager", binaryMessenger: registrar.messenger())
    
    modelManagerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: FlutterResult) -> Void in
        if call.method == "list" {
            self.listModel(result: result)
        } else if call.method == "download" {
            self.downloadModel(call: call, result: result)
        } else if call.method == "check" {
            self.checkModel(call: call, result: result)
        } else if call.method == "delete" {
            self.deleteModel(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
    })
  }

  func listModel(result: @escaping FlutterResult) {
    let modelManager = ModelManager.modelManager()
    let models = modelManager.downloadedEntityExtractionModels.map { $0.modelIdentifier }
    result(models)
  }

  func checkModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let modelManager = ModelManager.modelManager()
    let downloadedModels = Set(modelManager.downloadedEntityExtractionModels.map { $0.modelIdentifier })
    let isDownloaded = downloadedModels.contains(EntityExtractionModelIdentifier(rawValue: modelIdentifier!))

    result(isDownloaded)
  }

  func downloadModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String
    let isRequireWifi: Bool = (args["isRequireWifi"] as? Bool) ?? true

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let model = EntityExtractorRemoteModel.entityExtractorRemoteModel(identifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!))
    let modelManager = ModelManager.modelManager()
    let conditions = ModelDownloadConditions(
      allowsCellularAccess: !isRequireWifi,
      allowsBackgroundDownloading: true
    )
    modelManager.download(model, conditions: conditions)
    result(true)
  }

  func deleteModel(call: FlutterMethodCall, result:  @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let model = EntityExtractorRemoteModel.entityExtractorRemoteModel(identifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!))
    let modelManager = ModelManager.modelManager()
    
    modelManager.deleteDownloadedModel(model) { error in 
      result(true)
    }
  }
    
//    func stringFromAnnotation(annotation: EntityAnnotation) -> String {
//        var outputs: [String] = []
//        for entity in annotation.entities {
//          var output = ""
//          if entity.entityType == EntityType.address {
//            // Identifies a physical address.
//            // No structured data available.
//            output = "Address"
//          } else if entity.entityType == EntityType.dateTime {
//            // Identifies a date and time reference that may include a specific time. May be absolute
//            // such as "01/01/2000 5:30pm" or relative like "tomorrow at 5:30pm".
//            output = "Datetime: "
//            let formatter = DateFormatter()
//            formatter.timeZone = TimeZone.current
//            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            output.append(formatter.string(from: entity.dateTimeEntity!.dateTime))
//            output.append(" (")
//            output.append(
//              EntityViewController.stringFromGranularity(entity.dateTimeEntity!.dateTimeGranularity))
//          } else if entity.entityType == EntityType.email {
//            // Identifies an e-mail address.
//            // No structured data available.
//            output = "E-mail"
//          } else if entity.entityType == EntityType.flightNumber {
//            // Identifies a flight number in IATA format.
//            output = "Flight number: "
//            output.append(entity.flightNumberEntity!.airlineCode)
//            output.append(" ")
//            output.append(entity.flightNumberEntity!.flightNumber)
//          } else if entity.entityType == EntityType.IBAN {
//            // Identifies an International Bank Account Number (IBAN).
//            output = "IBAN: "
//            output.append(entity.ibanEntity!.countryCode)
//            output.append(" ")
//            output.append(entity.ibanEntity!.iban)
//          } else if entity.entityType == EntityType.ISBN {
//            // Identifies an International Standard Book Number (ISBN).
//            output = "ISBN: "
//            output.append(entity.isbnEntity!.isbn)
//          } else if entity.entityType == EntityType.paymentCard {
//            // Identifies a payment card.
//            output = "Payment card: "
////            output.append()
////              EntityViewController.stringFromPaymentCardNetwork(
////                entity.paymentCardEntity!.paymentCardNetwork))
//            output.append(" ")
//            output.append(entity.paymentCardEntity!.paymentCardNumber)
//          } else if entity.entityType == EntityType.phone {
//            // Identifies a phone number.
//            // No structured data available.
//            output = "Phone number"
//          } else if entity.entityType == EntityType.trackingNumber {
//            // Identifies a shipment tracking number.
//            output = "Tracking number: "
////            output.append()
////              EntityViewController.stringFromCarrier(entity.trackingNumberEntity!.parcelCarrier))
//            output.append(" ")
//            output.append(entity.trackingNumberEntity!.parcelTrackingNumber)
//          } else if entity.entityType == EntityType.URL {
//            // Identifies a URL.
//            // No structured data available.
//            output = "URL"
//          } else if entity.entityType == EntityType.money {
//            // Identifies currencies.
//            output = "Money: "
//            output.append(entity.moneyEntity!.description)
//          }
//          outputs.append(output)
//        }
//        return "[" + outputs.joined(separator: ", ") + "]\n"
//      }
}

